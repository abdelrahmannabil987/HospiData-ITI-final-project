USE Hospital_Salam;
GO

DELETE FROM BillItems;
DELETE FROM Bills;

DELETE FROM OperationSessions;
DELETE FROM Admissions;

DELETE FROM EmergencyDetails;

DELETE FROM VisitStatusHistory;
DELETE FROM Appointments;

DELETE FROM Visits;

DELETE FROM Patients;
GO


USE Hospital_Salam;
GO

DBCC CHECKIDENT ('Patients', RESEED, 0);
DBCC CHECKIDENT ('Visits', RESEED, 0);
DBCC CHECKIDENT ('VisitStatusHistory', RESEED, 0);
DBCC CHECKIDENT ('Appointments', RESEED, 0);
DBCC CHECKIDENT ('Admissions', RESEED, 0);
DBCC CHECKIDENT ('OperationSessions', RESEED, 0);
DBCC CHECKIDENT ('EmergencyDetails', RESEED, 0);
DBCC CHECKIDENT ('Bills', RESEED, 0);
DBCC CHECKIDENT ('BillItems', RESEED, 0);
GO


USE Hospital_Salam;
GO

-- Patients
INSERT INTO Patients (FirstName, LastName, Phone, Age, Gender, Nationality, InsuranceProvider) VALUES
('Omar',    'Ali',      '01011111111', 32, 'M', 'Egyptian', 'AXA Insurance'),
('Salma',   'Hassan',   '01022222222', 27, 'F', 'Egyptian', NULL),
('Mahmoud', 'Youssef',  '01033333333', 45, 'M', 'Egyptian', 'Allianz'),
('Nour',    'Ibrahim',  '01044444444', 8,  'F', 'Egyptian', 'AXA Insurance'),
('Hanan',   'Kamel',    '01055555555', 60, 'F', 'Egyptian', NULL);

---------------------------------------------------------
-- PATIENT 1 – Omar Ali
---------------------------------------------------------


INSERT INTO Visits (PatientID, DoctorID, ClassificationID, TypeID, VisitDate)
VALUES
    (1, 2, 2, 1, '2025-12-03T10:00:00'),
    (1, 2, 2, 2, '2025-12-03T10:30:00');  -- VisitIDs 1,2

INSERT INTO VisitStatusHistory (VisitID, StatusID, StatusTime) VALUES
(1, 1, '2025-12-01T09:50:00'),
(1, 2, '2025-12-01T09:55:00'),
(1, 3, '2025-12-01T10:05:00'),
(1, 4, '2025-12-01T10:20:00');

INSERT INTO Appointments (PatientID, DoctorID, AppointmentDate, AppointmentTime, Purpose, Status, VisitID)
VALUES
(1, 2, '2025-12-01', '10:00:00',
 'Initial check-up for hypertension',
 'Completed',
 1);

INSERT INTO Bills (VisitID, AdmissionID, PayerTypeID, BillDate, TotalAmount, PaymentStatus, PaymentDate)
VALUES
(1, NULL, 1, '2025-12-01T10:30:00', 270.00, 'Paid', '2025-12-01T10:35:00');  -- BillID 1

INSERT INTO BillItems (BillID, ServiceID, Quantity, Price) VALUES
(1, 2, 1, 150.00),
(1, 14, 1, 120.00);

---------------------------------------------------------
-- PATIENT 2 – Salma Hassan
---------------------------------------------------------

INSERT INTO Visits (PatientID, DoctorID, ClassificationID, TypeID, VisitDate)
VALUES
(2, 3, 3, 5, '2025-12-02T22:15:00');  -- VisitID 3

INSERT INTO EmergencyDetails (VisitID, TriageLevelID, ChiefComplaint)
VALUES
(3, 2, 'Road traffic accident with leg pain');

INSERT INTO VisitStatusHistory (VisitID, StatusID, StatusTime) VALUES
(3, 1, '2025-12-02T22:15:00'),
(3, 2, '2025-12-02T22:18:00'),
(3, 3, '2025-12-02T22:25:00'),
(3, 5, '2025-12-02T23:10:00');

INSERT INTO Appointments (PatientID, DoctorID, AppointmentDate, AppointmentTime, Purpose, Status, VisitID)
VALUES
(2, 2, '2025-12-06', '11:30:00',
 'Follow-up after ER visit',
 'No-Show',
 NULL);

INSERT INTO Bills (VisitID, AdmissionID, PayerTypeID, BillDate, TotalAmount, PaymentStatus, PaymentDate)
VALUES
(3, NULL, 2, '2025-12-02T23:30:00', 500.00, 'Pending', NULL);  -- BillID 2

INSERT INTO BillItems (BillID, ServiceID, Quantity, Price) VALUES
(2, 3, 1, 300.00),
(2, 10, 1, 200.00);

---------------------------------------------------------
-- PATIENT 3 – Mahmoud Youssef
---------------------------------------------------------

INSERT INTO Visits (PatientID, DoctorID, ClassificationID, TypeID, VisitDate)
VALUES
(3, 1, 1, 6, '2025-12-03T09:00:00');  -- VisitID 4

INSERT INTO VisitStatusHistory (VisitID, StatusID, StatusTime) VALUES
(4, 1, '2025-12-03T09:00:00'),
(4, 5, '2025-12-03T13:00:00'),
(4, 6, '2025-12-03T13:30:00');

INSERT INTO Admissions (VisitID, BedID, AdmissionDate, DischargeDate)
VALUES
(4, 4, '2025-12-03T13:00:00', NULL);    -- AdmissionID 1

INSERT INTO OperationSessions (AdmissionID, OperationTypeID, SurgeonID, StartTime, EndTime)
VALUES
(1, 1, 1, '2025-12-04T08:00:00', '2025-12-04T09:15:00');

INSERT INTO Bills (VisitID, AdmissionID, PayerTypeID, BillDate, TotalAmount, PaymentStatus, PaymentDate)
VALUES
(NULL, 1, 2, '2025-12-05T12:00:00', 7500.00, 'Pending', NULL);  -- BillID 3

INSERT INTO BillItems (BillID, ServiceID, Quantity, Price) VALUES
(3, 4, 3, 500.00),
(3, 17, 1, 6000.00);

---------------------------------------------------------
-- PATIENT 4 – Nour Ibrahim
---------------------------------------------------------

INSERT INTO Visits (PatientID, DoctorID, ClassificationID, TypeID, VisitDate)
VALUES
(4, 5, 4, 9, '2025-12-04T11:00:00');   -- VisitID 5

INSERT INTO VisitStatusHistory (VisitID, StatusID, StatusTime) VALUES
(5, 1, '2025-12-04T10:50:00'),
(5, 3, '2025-12-04T11:05:00'),
(5, 4, '2025-12-04T11:15:00');

INSERT INTO Appointments (PatientID, DoctorID, AppointmentDate, AppointmentTime, Purpose, Status, VisitID)
VALUES
(4, 5, '2025-12-04', '11:00:00',
 'Injection clinic visit',
 'Completed',
 5);

INSERT INTO Bills (VisitID, AdmissionID, PayerTypeID, BillDate, TotalAmount, PaymentStatus, PaymentDate)
VALUES
(5, NULL, 3, '2025-12-04T11:20:00', 140.00, 'Paid', '2025-12-04T11:25:00');  -- BillID 4

INSERT INTO BillItems (BillID, ServiceID, Quantity, Price) VALUES
(4, 7, 1, 60.00),
(4, 6, 1, 80.00);

---------------------------------------------------------
-- PATIENT 5 – Hanan Kamel
---------------------------------------------------------

INSERT INTO Visits (PatientID, DoctorID, ClassificationID, TypeID, VisitDate)
VALUES
(5, 4, 4, 11, '2025-12-05T12:30:00');  -- VisitID 6

INSERT INTO VisitStatusHistory (VisitID, StatusID, StatusTime) VALUES
(6, 1, '2025-12-05T12:10:00'),
(6, 2, '2025-12-05T12:15:00'),
(6, 3, '2025-12-05T12:35:00'),
(6, 4, '2025-12-05T12:50:00');

INSERT INTO Bills (VisitID, AdmissionID, PayerTypeID, BillDate, TotalAmount, PaymentStatus, PaymentDate)
VALUES
(6, NULL, 1, '2025-12-05T13:00:00', 150.00, 'Pending', NULL);  -- BillID 5

INSERT INTO BillItems (BillID, ServiceID, Quantity, Price) VALUES
(5, 9, 1, 150.00);


