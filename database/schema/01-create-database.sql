/*
    X12 835 Processing Demo - Version 1

    Run this script while connected to the master database.
*/

IF DB_ID(N'X12835Demo') IS NULL
BEGIN
    CREATE DATABASE X12835Demo;
END
GO

USE X12835Demo;
GO

/*
    Re-running this setup script intentionally resets Version 1 objects.
    This is acceptable for a local portfolio/demo database.
*/

IF OBJECT_ID(N'dbo.LedgerEntry', N'U') IS NOT NULL DROP TABLE dbo.LedgerEntry;
IF OBJECT_ID(N'dbo.ClaimAdjustment', N'U') IS NOT NULL DROP TABLE dbo.ClaimAdjustment;
IF OBJECT_ID(N'dbo.Claim', N'U') IS NOT NULL DROP TABLE dbo.Claim;
IF OBJECT_ID(N'dbo.EDI835Segment', N'U') IS NOT NULL DROP TABLE dbo.EDI835Segment;
IF OBJECT_ID(N'dbo.EDI835Batch', N'U') IS NOT NULL DROP TABLE dbo.EDI835Batch;
GO

CREATE TABLE dbo.EDI835Batch
(
    BatchID         INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_EDI835Batch PRIMARY KEY,
    FileName        NVARCHAR(255) NOT NULL,
    FileContent     NVARCHAR(MAX) NOT NULL,
    Status          VARCHAR(20) NOT NULL
        CONSTRAINT CK_EDI835Batch_Status
        CHECK (Status IN ('RECEIVED','PARSED','POSTED','FAILED','RECONCILED')),
    ReceivedAt      DATETIME2(0) NOT NULL
        CONSTRAINT DF_EDI835Batch_ReceivedAt DEFAULT SYSUTCDATETIME(),
    ProcessedAt     DATETIME2(0) NULL,
    ErrorMessage    NVARCHAR(2000) NULL
);
GO

CREATE TABLE dbo.EDI835Segment
(
    SegmentID       BIGINT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_EDI835Segment PRIMARY KEY,
    BatchID         INT NOT NULL,
    SegmentOrdinal  INT NOT NULL,
    SegmentType     VARCHAR(10) NOT NULL,
    SegmentText     NVARCHAR(2000) NOT NULL,

    CONSTRAINT FK_EDI835Segment_Batch
        FOREIGN KEY (BatchID) REFERENCES dbo.EDI835Batch(BatchID),

    CONSTRAINT UQ_EDI835Segment_BatchOrdinal
        UNIQUE (BatchID, SegmentOrdinal)
);
GO

CREATE TABLE dbo.Claim
(
    ClaimID               INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Claim PRIMARY KEY,
    BatchID               INT NOT NULL,
    CLPSegmentOrdinal     INT NOT NULL,
    PatientControlNumber  VARCHAR(50) NOT NULL,
    ClaimStatus           VARCHAR(30) NOT NULL,
    TotalCharge           DECIMAL(18,2) NOT NULL,
    InsurancePayment      DECIMAL(18,2) NOT NULL,

    CONSTRAINT FK_Claim_Batch
        FOREIGN KEY (BatchID) REFERENCES dbo.EDI835Batch(BatchID)
);
GO

CREATE TABLE dbo.ClaimAdjustment
(
    AdjustmentID       BIGINT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_ClaimAdjustment PRIMARY KEY,
    ClaimID            INT NOT NULL,
    AdjustmentGroup    VARCHAR(10) NOT NULL,
    AdjustmentReason   VARCHAR(20) NOT NULL,
    Amount             DECIMAL(18,2) NOT NULL,

    CONSTRAINT FK_ClaimAdjustment_Claim
        FOREIGN KEY (ClaimID) REFERENCES dbo.Claim(ClaimID)
);
GO

CREATE TABLE dbo.LedgerEntry
(
    LedgerEntryID      BIGINT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_LedgerEntry PRIMARY KEY,
    BatchID            INT NOT NULL,
    ClaimID            INT NOT NULL,
    LedgerType         VARCHAR(40) NOT NULL,
    Amount             DECIMAL(18,2) NOT NULL,
    SourceDescription  VARCHAR(200) NOT NULL,
    PostedAt            DATETIME2(0) NOT NULL
        CONSTRAINT DF_LedgerEntry_PostedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_LedgerEntry_Batch
        FOREIGN KEY (BatchID) REFERENCES dbo.EDI835Batch(BatchID),

    CONSTRAINT FK_LedgerEntry_Claim
        FOREIGN KEY (ClaimID) REFERENCES dbo.Claim(ClaimID)
);
GO

CREATE INDEX IX_EDI835Segment_Batch_Type_Ordinal
    ON dbo.EDI835Segment(BatchID, SegmentType, SegmentOrdinal);

CREATE INDEX IX_Claim_Batch
    ON dbo.Claim(BatchID);

CREATE INDEX IX_LedgerEntry_Claim
    ON dbo.LedgerEntry(ClaimID);
GO

PRINT 'X12835Demo schema created successfully.';
GO
