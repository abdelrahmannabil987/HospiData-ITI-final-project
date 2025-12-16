------------------------------------------------
-- Weekly snapshot tables
------------------------------------------------

-- Visits
CREATE TABLE Weekly_Visits (
    BatchID       INT IDENTITY(1,1) PRIMARY KEY,
    WeekStart     DATE       NOT NULL,
    WeekEnd       DATE       NOT NULL,
    VisitID       INT        NOT NULL,
    PatientID     INT        NOT NULL,
    DoctorID      INT        NULL,
    ClassificationID INT     NOT NULL,
    TypeID        INT        NOT NULL,
    VisitDate     DATETIME   NOT NULL
);

-- VisitStatusHistory
CREATE TABLE Weekly_VisitStatusHistory (
    BatchID       INT IDENTITY(1,1) PRIMARY KEY,
    WeekStart     DATE       NOT NULL,
    WeekEnd       DATE       NOT NULL,
    HistoryID     INT        NOT NULL,
    VisitID       INT        NOT NULL,
    StatusID      INT        NOT NULL,
    StatusTime    DATETIME   NOT NULL
);

-- Admissions
CREATE TABLE Weekly_Admissions (
    BatchID       INT IDENTITY(1,1) PRIMARY KEY,
    WeekStart     DATE       NOT NULL,
    WeekEnd       DATE       NOT NULL,
    AdmissionID   INT        NOT NULL,
    VisitID       INT        NOT NULL,
    BedID         INT        NOT NULL,
    AdmissionDate DATETIME   NOT NULL,
    DischargeDate DATETIME   NULL
);

-- OperationSessions
CREATE TABLE Weekly_OperationSessions (
    BatchID            INT IDENTITY(1,1) PRIMARY KEY,
    WeekStart          DATE       NOT NULL,
    WeekEnd            DATE       NOT NULL,
    OperationSessionID INT        NOT NULL,
    AdmissionID        INT        NOT NULL,
    OperationTypeID    INT        NOT NULL,
    SurgeonID          INT        NOT NULL,
    StartTime          DATETIME   NOT NULL,
    EndTime            DATETIME   NULL
);

-- EmergencyDetails
CREATE TABLE Weekly_EmergencyDetails (
    BatchID          INT IDENTITY(1,1) PRIMARY KEY,
    WeekStart        DATE       NOT NULL,
    WeekEnd          DATE       NOT NULL,
    EmergencyDetailID INT       NOT NULL,
    VisitID          INT        NOT NULL,
    TriageLevelID    INT        NOT NULL,
    ChiefComplaint   VARCHAR(255) NULL
);

-- Appointments
CREATE TABLE Weekly_Appointments (
    BatchID          INT IDENTITY(1,1) PRIMARY KEY,
    WeekStart        DATE       NOT NULL,
    WeekEnd          DATE       NOT NULL,
    AppointmentID    INT        NOT NULL,
    PatientID        INT        NOT NULL,
    DoctorID         INT        NOT NULL,
    AppointmentDate  DATE       NOT NULL,
    AppointmentTime  TIME       NOT NULL,
    Purpose          VARCHAR(255) NULL,
    Status           VARCHAR(20)  NOT NULL,
    VisitID          INT        NULL
);

-- Bills
CREATE TABLE Weekly_Bills (
    BatchID       INT IDENTITY(1,1) PRIMARY KEY,
    WeekStart     DATE       NOT NULL,
    WeekEnd       DATE       NOT NULL,
    BillID        INT        NOT NULL,
    VisitID       INT        NULL,
    AdmissionID   INT        NULL,
    PayerTypeID   INT        NOT NULL,
    BillDate      DATETIME   NOT NULL,
    TotalAmount   DECIMAL(10,2) NULL,
    PaymentStatus VARCHAR(20)  NOT NULL,
    PaymentDate   DATETIME   NULL
);

-- BillItems
CREATE TABLE Weekly_BillItems (
    BatchID       INT IDENTITY(1,1) PRIMARY KEY,
    WeekStart     DATE       NOT NULL,
    WeekEnd       DATE       NOT NULL,
    BillItemID    INT        NOT NULL,
    BillID        INT        NOT NULL,
    ServiceID     INT        NOT NULL,
    Quantity      INT        NOT NULL,
    Price         DECIMAL(10,2) NOT NULL
);

