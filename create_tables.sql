-- Supporting tables for reference data
CREATE TABLE VisitClassification (
    ClassificationID     INT          IDENTITY(1,1) PRIMARY KEY,
    ClassificationName   VARCHAR(50)  NOT NULL
);


CREATE TABLE VisitType (
    TypeID         INT          IDENTITY(1,1) PRIMARY KEY,
    TypeName       VARCHAR(50)  NOT NULL,
    ClassificationID     INT          NOT NULL,
    CONSTRAINT FK_VisitType_Category FOREIGN KEY (ClassificationID) REFERENCES VisitClassification(ClassificationID)
);


-------------------------
CREATE TABLE VisitStatus (
    StatusID       INT          IDENTITY(1,1) PRIMARY KEY,
    StatusName     VARCHAR(20)  NOT NULL
);

------------------------
CREATE TABLE OperationType (
    OperationTypeID INT         IDENTITY(1,1) PRIMARY KEY,
    OperationName   VARCHAR(100) NOT NULL
);

-----------------------------
CREATE TABLE PayerTypes (
    PayerTypeID    INT          IDENTITY(1,1) PRIMARY KEY,
    PayerTypeName  VARCHAR(50)  NOT NULL
);


CREATE TABLE TriageLevels (
    TriageLevelID  INT          IDENTITY(1,1) PRIMARY KEY,
    LevelDescription VARCHAR(50) NOT NULL
);


CREATE TABLE ServiceCatalog (
    ServiceID      INT          IDENTITY(1,1) PRIMARY KEY,
    ServiceName    VARCHAR(100) NOT NULL,
    Price          DECIMAL(10,2) NOT NULL,
    Description    VARCHAR(255) NULL
);



-- Core entity tables
CREATE TABLE Patients (
    PatientID      INT          IDENTITY(1,1) PRIMARY KEY,
    FirstName      VARCHAR(50)  NOT NULL,
    LastName       VARCHAR(50)  NOT NULL,
    Phone          VARCHAR(20)  NOT NULL,
    Age            INT          NOT NULL,
    Gender         CHAR(1)      NOT NULL,
    Nationality    VARCHAR(50)  NOT NULL,
    InsuranceProvider VARCHAR(100) NULL,
    CONSTRAINT CHK_Patients_Gender CHECK (Gender IN ('M','F','O')),
    CONSTRAINT CHK_Patients_Age CHECK (Age BETWEEN 0 AND 120)
);


CREATE TABLE Speciality (
    SpecialityID   INT          IDENTITY(1,1) PRIMARY KEY,
    SpecialityName VARCHAR(100) NOT NULL,
    Location       VARCHAR(100) NULL
);




CREATE TABLE Doctors (
    DoctorID       INT          IDENTITY(1,1) PRIMARY KEY,
    FirstName      VARCHAR(50)  NOT NULL,
    LastName       VARCHAR(50)  NOT NULL,
    Phone          VARCHAR(20)  NULL,
    Email          VARCHAR(100) NULL
);


CREATE TABLE Doctor_Speciality (
    DoctorID       INT          NOT NULL,
    SpecialityID   INT          NOT NULL,
    PRIMARY KEY (DoctorID, SpecialityID),
    CONSTRAINT FK_DoctorDept_Doctor FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID),
    CONSTRAINT FK_DoctorDept_Dept FOREIGN KEY (SpecialityID) REFERENCES Speciality(SpecialityID)
);


CREATE TABLE Wards (
    WardID         INT          IDENTITY(1,1) PRIMARY KEY,
    WardName       VARCHAR(50)  NOT NULL,
    WardType       VARCHAR(50)  NULL,
    Location       VARCHAR(100) NULL
);


CREATE TABLE Beds (
    BedID          INT          IDENTITY(1,1) PRIMARY KEY,
    BedNumber      VARCHAR(10)  NOT NULL,
    WardID         INT          NOT NULL,
    BedType        VARCHAR(50)  NULL,
    CONSTRAINT FK_Beds_Ward FOREIGN KEY (WardID) REFERENCES Wards(WardID)
);



-- Visit/encounter tables
CREATE TABLE Visits (
    VisitID        INT          IDENTITY(1,1) PRIMARY KEY,
    PatientID      INT          NOT NULL,
    DoctorID       INT          NULL,
    ClassificationID     INT          NOT NULL,
    TypeID         INT          NOT NULL,
    VisitDate      DATETIME     NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT FK_Visits_Patient FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
    CONSTRAINT FK_Visits_Doctor FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID),
    CONSTRAINT FK_Visits_Category FOREIGN KEY (ClassificationID) REFERENCES VisitClassification(ClassificationID),
    CONSTRAINT FK_Visits_Type FOREIGN KEY (TypeID) REFERENCES VisitType(TypeID)
);





CREATE TABLE VisitStatusHistory (
    HistoryID      INT          IDENTITY(1,1) PRIMARY KEY,
    VisitID        INT          NOT NULL,
    StatusID       INT          NOT NULL,
    StatusTime     DATETIME     NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT FK_VisitHistory_Visit FOREIGN KEY (VisitID) REFERENCES Visits(VisitID),
    CONSTRAINT FK_VisitHistory_Status FOREIGN KEY (StatusID) REFERENCES VisitStatus(StatusID)
);



CREATE TABLE Admissions (
    AdmissionID    INT          IDENTITY(1,1) PRIMARY KEY,
    VisitID        INT          NOT NULL,
    BedID          INT          NOT NULL,
    AdmissionDate  DATETIME     NOT NULL,
    DischargeDate  DATETIME     NULL,
    CONSTRAINT FK_Admissions_Visit FOREIGN KEY (VisitID) REFERENCES Visits(VisitID),
    CONSTRAINT FK_Admissions_Bed FOREIGN KEY (BedID) REFERENCES Beds(BedID),
    CONSTRAINT UQ_Admissions_Visit UNIQUE (VisitID),
    CONSTRAINT CHK_Admissions_Dates CHECK (DischargeDate IS NULL OR DischargeDate >= AdmissionDate)
);



CREATE TABLE OperationSessions (
    OperationSessionID INT      IDENTITY(1,1) PRIMARY KEY,
    AdmissionID    INT          NOT NULL,
    OperationTypeID INT         NOT NULL,
    SurgeonID      INT          NOT NULL,
    StartTime      DATETIME     NOT NULL,
    EndTime        DATETIME     NULL,
    CONSTRAINT FK_OpSession_Admission FOREIGN KEY (AdmissionID) REFERENCES Admissions(AdmissionID),
    CONSTRAINT FK_OpSession_OpType FOREIGN KEY (OperationTypeID) REFERENCES OperationType(OperationTypeID),
    CONSTRAINT FK_OpSession_Surgeon FOREIGN KEY (SurgeonID) REFERENCES Doctors(DoctorID),
    CONSTRAINT CHK_OpSession_Times CHECK (EndTime IS NULL OR EndTime > StartTime)
);



CREATE TABLE EmergencyDetails (
    EmergencyDetailID INT       IDENTITY(1,1) PRIMARY KEY,
    VisitID        INT          NOT NULL,
    TriageLevelID  INT          NOT NULL,
    ChiefComplaint VARCHAR(255) NULL,
    CONSTRAINT FK_Emergency_Visit FOREIGN KEY (VisitID) REFERENCES Visits(VisitID),
    CONSTRAINT FK_Emergency_Triage FOREIGN KEY (TriageLevelID) REFERENCES TriageLevels(TriageLevelID),
    CONSTRAINT UQ_Emergency_Visit UNIQUE (VisitID)
);



CREATE TABLE Appointments (
    AppointmentID  INT          IDENTITY(1,1) PRIMARY KEY,
    PatientID      INT          NOT NULL,
    DoctorID       INT          NOT NULL,
    AppointmentDate DATE        NOT NULL,
    AppointmentTime TIME        NOT NULL,
    Purpose        VARCHAR(255) NULL,
    Status         VARCHAR(20)  NOT NULL DEFAULT 'Scheduled',
    VisitID        INT          NULL,
    CONSTRAINT FK_Appointments_Patient FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
    CONSTRAINT FK_Appointments_Doctor FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID),
    CONSTRAINT FK_Appointments_Visit FOREIGN KEY (VisitID) REFERENCES Visits(VisitID),
    CONSTRAINT CHK_Appointment_Status CHECK (Status IN ('Scheduled','Completed','Cancelled','No-Show'))
);



-- Billing tables
CREATE TABLE Bills (
    BillID         INT          IDENTITY(1,1) PRIMARY KEY,
    VisitID        INT          NULL,
    AdmissionID    INT          NULL,
    PayerTypeID    INT          NOT NULL,
    BillDate       DATETIME     NOT NULL DEFAULT (GETDATE()),
    TotalAmount    DECIMAL(10,2) NULL,
    PaymentStatus  VARCHAR(20)  NOT NULL DEFAULT 'Pending',
    PaymentDate    DATETIME     NULL,
    CONSTRAINT FK_Bills_Visit FOREIGN KEY (VisitID) REFERENCES Visits(VisitID),
    CONSTRAINT FK_Bills_Admission FOREIGN KEY (AdmissionID) REFERENCES Admissions(AdmissionID),
    CONSTRAINT FK_Bills_PayerType FOREIGN KEY (PayerTypeID) REFERENCES PayerTypes(PayerTypeID),
    CONSTRAINT CHK_Bills_VisitOrAdmission CHECK (
        (VisitID IS NOT NULL AND AdmissionID IS NULL) OR 
        (VisitID IS NULL AND AdmissionID IS NOT NULL)
    ),
    CONSTRAINT CHK_Bills_PaymentDates CHECK (
        (PaymentStatus = 'Paid' AND PaymentDate IS NOT NULL) OR 
        (PaymentStatus <> 'Paid' AND PaymentDate IS NULL)
    ),
    CONSTRAINT CHK_Bills_PaymentStatus CHECK (PaymentStatus IN ('Pending','Paid','Cancelled'))
);


CREATE TABLE BillItems (
    BillItemID     INT          IDENTITY(1,1) PRIMARY KEY,
    BillID         INT          NOT NULL,
    ServiceID      INT          NOT NULL,
    Quantity       INT          NOT NULL DEFAULT 1,
    Price          DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_BillItems_Bill FOREIGN KEY (BillID) REFERENCES Bills(BillID),
    CONSTRAINT FK_BillItems_Service FOREIGN KEY (ServiceID) REFERENCES ServiceCatalog(ServiceID),
    CONSTRAINT CHK_BillItems_Quantity CHECK (Quantity > 0)
);



-- Drop child tables first (those that depend on others)

IF OBJECT_ID('dbo.BillItems', 'U') IS NOT NULL
    DROP TABLE dbo.BillItems;
GO

IF OBJECT_ID('dbo.Bills', 'U') IS NOT NULL
    DROP TABLE dbo.Bills;
GO

IF OBJECT_ID('dbo.OperationSessions', 'U') IS NOT NULL
    DROP TABLE dbo.OperationSessions;
GO

IF OBJECT_ID('dbo.EmergencyDetails', 'U') IS NOT NULL
    DROP TABLE dbo.EmergencyDetails;
GO

IF OBJECT_ID('dbo.VisitStatusHistory', 'U') IS NOT NULL
    DROP TABLE dbo.VisitStatusHistory;
GO

IF OBJECT_ID('dbo.Appointments', 'U') IS NOT NULL
    DROP TABLE dbo.Appointments;
GO

IF OBJECT_ID('dbo.Admissions', 'U') IS NOT NULL
    DROP TABLE dbo.Admissions;
GO

IF OBJECT_ID('dbo.Doctor_Speciality', 'U') IS NOT NULL
    DROP TABLE dbo.Doctor_Speciality;
GO

IF OBJECT_ID('dbo.Visits', 'U') IS NOT NULL
    DROP TABLE dbo.Visits;
GO

IF OBJECT_ID('dbo.Beds', 'U') IS NOT NULL
    DROP TABLE dbo.Beds;
GO

IF OBJECT_ID('dbo.Wards', 'U') IS NOT NULL
    DROP TABLE dbo.Wards;
GO

-- Core entities (after all references to them are gone)

IF OBJECT_ID('dbo.Patients', 'U') IS NOT NULL
    DROP TABLE dbo.Patients;
GO

IF OBJECT_ID('dbo.Doctors', 'U') IS NOT NULL
    DROP TABLE dbo.Doctors;
GO

IF OBJECT_ID('dbo.Speciality', 'U') IS NOT NULL
    DROP TABLE dbo.Speciality;
GO

-- Lookup / reference tables

IF OBJECT_ID('dbo.VisitType', 'U') IS NOT NULL
    DROP TABLE dbo.VisitType;
GO

IF OBJECT_ID('dbo.VisitCategory', 'U') IS NOT NULL
    DROP TABLE dbo.VisitCategory;
GO

IF OBJECT_ID('dbo.VisitStatus', 'U') IS NOT NULL
    DROP TABLE dbo.VisitStatus;
GO

IF OBJECT_ID('dbo.OperationType', 'U') IS NOT NULL
    DROP TABLE dbo.OperationType;
GO

IF OBJECT_ID('dbo.PayerTypes', 'U') IS NOT NULL
    DROP TABLE dbo.PayerTypes;
GO

IF OBJECT_ID('dbo.TriageLevels', 'U') IS NOT NULL
    DROP TABLE dbo.TriageLevels;
GO

IF OBJECT_ID('dbo.ServiceCatalog', 'U') IS NOT NULL
    DROP TABLE dbo.ServiceCatalog;
GO
