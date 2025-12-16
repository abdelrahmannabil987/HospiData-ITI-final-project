import json
import threading
from datetime import datetime, date, timezone
from collections import defaultdict
import base64

from kafka import KafkaConsumer
from flask import Flask, jsonify
from flask_cors import CORS

# =========================
# Kafka topics / config
# =========================
BOOTSTRAP_SERVERS = ["localhost:9092"]

VISITS_TOPIC = "hospital.Hospital_Salam.dbo.Visits"
ADMISSIONS_TOPIC = "hospital.Hospital_Salam.dbo.Admissions"
BILLS_TOPIC = "hospital.Hospital_Salam.dbo.Bills"
STATUS_TOPIC = "hospital.Hospital_Salam.dbo.VisitStatusHistory"

# =========================
# Reference mappings
# =========================

# VisitClassification
CLASSIFICATION_NAMES = {
    1: "Inpatient",
    2: "Outpatient",
    3: "Emergency",
    4: "Ambulatory",
}

# VisitStatuswٍ
STATUS_NAMES = {
    1: "Registered",
    2: "Waiting",
    3: "In Consultation",
    4: "Finished",
    5: "Admitted",
    6: "In Ward",
    7: "Discharged",
    8: "Cancelled",
    9: "No-Show",
}

WAITING_STATUS_ID = 2

SPECIALITY_NAMES = {
    1: "Emergency",
    2: "Internal Medicine",
    3: "General Surgery",
    4: "Orthopedics",
    5: "Pediatrics",
    6: "Cardiology",
    7: "Radiology",
    8: "Laboratory",
    9: "ICU",
}

DOCTOR_SPECIALITY = {
    1: SPECIALITY_NAMES[3],
    2: SPECIALITY_NAMES[2],
    3: SPECIALITY_NAMES[1],
    4: SPECIALITY_NAMES[4],
    5: SPECIALITY_NAMES[5],
    6: SPECIALITY_NAMES[6],
    7: SPECIALITY_NAMES[7],
    8: SPECIALITY_NAMES[8],
}

# =========================
# Shared state
# =========================

lock = threading.Lock()

stats = {
    # Visits
    "visits_today_total": 0,
    "visits_today_by_classification": defaultdict(int),
    # Admissions
    "admissions_today": 0,
    "inpatients_now": 0,
    # Waiting
    "waiting_now_by_speciality": defaultdict(int),
    "waiting_now_by_classification": defaultdict(int),
    # Bills
    "revenue_paid_today": 0.0,
    # Meta
    "last_update": None,
}

visits_today_ids = set()          
active_admissions = set()         
visit_info_by_id = {}             
current_status_by_visit = {}      

# =========================
# Helper functions
# =========================

def is_today(ts):

    if ts is None:
        return False

    try:
        # numeric (Debezium Timestamp as epoch millis أو micros)
        if isinstance(ts, (int, float)):
            value = float(ts)

            if value > 1e15:      # nanos
                seconds = value / 1e9
            elif value > 1e12:    # millis
                seconds = value / 1000.0
            elif value > 1e9:     # seconds
                seconds = value
            else:
                seconds = value

            dt = datetime.fromtimestamp(seconds)
            return dt.date() == date.today()

        # string
        if isinstance(ts, str):
            s = ts.strip()
            if not s:
                return False
            s = s.replace("T", " ").replace("Z", "")
            try:
                dt = datetime.fromisoformat(s)
                return dt.date() == date.today()
            except Exception:
                try:
                    d = datetime.strptime(s[:10], "%Y-%m-%d").date()
                    return d == date.today()
                except Exception:
                    return False
    except Exception:
        return False

    return False


def decode_decimal_value(val, scale=2):

    if val is None:
        return 0.0

    if isinstance(val, (int, float)):
        return float(val)

    if isinstance(val, dict):
        inner_val = val.get("value")
        inner_scale = int(val.get("scale", scale))
        return decode_decimal_value(inner_val, scale=inner_scale)

    if isinstance(val, str):
        try:
            return float(val)
        except ValueError:
            pass
        try:
            raw = base64.b64decode(val)
            unscaled = int.from_bytes(raw, byteorder="big", signed=True)
            return unscaled / (10 ** scale)
        except Exception:
            return 0.0

    return 0.0


def paid_today_amount(record):

    if not record:
        return 0.0

    if record.get("PaymentStatus") != "Paid":
        return 0.0

    pay_date = record.get("PaymentDate")
    if not is_today(pay_date):
        return 0.0

    amount = decode_decimal_value(record.get("TotalAmount"), scale=2)
    return amount


def get_speciality_for_visit(visit_id):

    info = visit_info_by_id.get(visit_id)
    if not info:
        return None

    doctor_id = info.get("doctor_id")
    if not doctor_id:
        return None

    return DOCTOR_SPECIALITY.get(doctor_id, None)


# =========================
# Handlers
# =========================

def handle_visits_event(payload):
    op = payload.get("op")
    after = payload.get("after") or {}
    before = payload.get("before") or {}

    if not after:
        return

    visit_id = after.get("VisitID")
    if visit_id is None:
        return

    doctor_id = after.get("DoctorID")
    classification_id = after.get("ClassificationID")

    visit_info_by_id[visit_id] = {
        "doctor_id": doctor_id,
        "classification_id": classification_id,
    }

    visit_date = after.get("VisitDate")

    if is_today(visit_date):
        with lock:
            if visit_id not in visits_today_ids:
                visits_today_ids.add(visit_id)
                stats["visits_today_total"] += 1

                class_name = CLASSIFICATION_NAMES.get(
                    classification_id, f"Classification {classification_id}"
                )
                stats["visits_today_by_classification"][class_name] += 1

            stats["last_update"] = datetime.now(timezone.utc).isoformat()


def handle_admissions_event(payload):
    op = payload.get("op")
    after = payload.get("after") or {}
    before = payload.get("before") or {}

    record = after or before
    if not record:
        return

    admission_id = record.get("AdmissionID")
    if admission_id is None:
        return

    admission_date = record.get("AdmissionDate")
    before_discharge = before.get("DischargeDate")
    after_discharge = after.get("DischargeDate")

    with lock:
        if op in ("c", "r"):
            if is_today(admission_date):
                stats["admissions_today"] += 1

            if after_discharge is None:
                active_admissions.add(admission_id)
                stats["inpatients_now"] = len(active_admissions)

        elif op == "u":
            if before_discharge is None and after_discharge is not None:
                active_admissions.discard(admission_id)
                stats["inpatients_now"] = len(active_admissions)
            elif before_discharge is not None and after_discharge is None:
                active_admissions.add(admission_id)
                stats["inpatients_now"] = len(active_admissions)

        elif op == "d":
            if before_discharge is None:
                active_admissions.discard(admission_id)
                stats["inpatients_now"] = len(active_admissions)
        stats["last_update"] = datetime.now(timezone.utc).isoformat()


def handle_status_event(payload):
    op = payload.get("op")
    after = payload.get("after") or {}
    if op not in ("c", "r", "u") or not after:
        return

    visit_id = after.get("VisitID")
    status_id = after.get("StatusID")
    if visit_id is None or status_id is None:
        return

    with lock:
        old_status = current_status_by_visit.get(visit_id)
        current_status_by_visit[visit_id] = status_id

        info = visit_info_by_id.get(visit_id, {})
        class_id = info.get("classification_id")
        class_name = CLASSIFICATION_NAMES.get(class_id, None)

        speciality_name = get_speciality_for_visit(visit_id)

        if old_status == WAITING_STATUS_ID:
            if speciality_name:
                stats["waiting_now_by_speciality"][speciality_name] = max(
                    stats["waiting_now_by_speciality"][speciality_name] - 1, 0
                )
            if class_name:
                stats["waiting_now_by_classification"][class_name] = max(
                    stats["waiting_now_by_classification"][class_name] - 1, 0
                )

        if status_id == WAITING_STATUS_ID:
            if speciality_name:
                stats["waiting_now_by_speciality"][speciality_name] += 1
            if class_name:
                stats["waiting_now_by_classification"][class_name] += 1

        stats["last_update"] = datetime.now(timezone.utc).isoformat()


def handle_bills_event(payload):
    op = payload.get("op")
    after = payload.get("after") or {}
    before = payload.get("before") or {}

    before_amt = paid_today_amount(before)
    after_amt = paid_today_amount(after)

    delta = after_amt - before_amt

    if abs(delta) < 1e-9:
        return

    with lock:
        stats["revenue_paid_today"] += delta
        if stats["revenue_paid_today"] < 0:
            stats["revenue_paid_today"] = 0.0

        stats["last_update"] = datetime.now(timezone.utc).isoformat()


# =========================
# Kafka consumer loop
# =========================

def kafka_loop():
    consumer = KafkaConsumer(
        VISITS_TOPIC,
        ADMISSIONS_TOPIC,
        BILLS_TOPIC,
        STATUS_TOPIC,
        bootstrap_servers=BOOTSTRAP_SERVERS,
        group_id="hospital-dashboard-group",
        auto_offset_reset="earliest",
        enable_auto_commit=True,
        value_deserializer=lambda m: json.loads(m.decode("utf-8")) if m is not None else None,
    )

    print("Starting Kafka consumer...")

    for msg in consumer:
        try:
            data = msg.value
            if not isinstance(data, dict):
                continue

            payload = data.get("payload")
            if not payload:
                continue

            topic = msg.topic

            if topic == VISITS_TOPIC:
                handle_visits_event(payload)
            elif topic == ADMISSIONS_TOPIC:
                handle_admissions_event(payload)
            elif topic == STATUS_TOPIC:
                handle_status_event(payload)
            elif topic == BILLS_TOPIC:
                handle_bills_event(payload)

        except Exception as e:
            try:
                print("Error processing message from topic", msg.topic, ":", e)
            except Exception:
                print("Error processing message (and failed to print payload):", e)


def start_kafka_thread():
    t = threading.Thread(target=kafka_loop, daemon=True)
    t.start()


# =========================
# Flask API
# =========================

app = Flask(__name__)
CORS(app)


@app.route("/stats", methods=["GET"])
def get_stats():
    with lock:
        response = {
            "visits_today_total": stats["visits_today_total"],
            "visits_today_by_classification": dict(stats["visits_today_by_classification"]),
            "admissions_today": stats["admissions_today"],
            "inpatients_now": stats["inpatients_now"],
            "waiting_now_by_speciality": dict(stats["waiting_now_by_speciality"]),
            "waiting_now_by_classification": dict(stats["waiting_now_by_classification"]),
            "revenue_paid_today": stats["revenue_paid_today"],
            "last_update": stats["last_update"],
        }
    return jsonify(response)


if __name__ == "__main__":
    start_kafka_thread()
    print("HTTP API running on http://localhost:5000/stats")
    app.run(host="0.0.0.0", port=5000)
