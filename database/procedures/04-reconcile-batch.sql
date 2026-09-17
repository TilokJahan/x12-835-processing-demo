USE X12835Demo;
GO

CREATE OR ALTER PROCEDURE dbo.Reconcile835Batch
    @BatchID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.EDI835Batch
        WHERE BatchID = @BatchID
          AND Status = 'POSTED'
    )
        THROW 50020, 'Batch must be in POSTED status before reconciliation.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.Claim AS C
        LEFT JOIN dbo.LedgerEntry AS L
            ON L.ClaimID = C.ClaimID
        WHERE C.BatchID = @BatchID
        GROUP BY C.ClaimID, C.TotalCharge
        HAVING ABS(C.TotalCharge - ISNULL(SUM(L.Amount), 0)) > 0.01
    )
        THROW 50021, 'Batch reconciliation failed: one or more claims are unbalanced.', 1;

    UPDATE dbo.EDI835Batch
    SET
        Status = 'RECONCILED',
        ProcessedAt = SYSUTCDATETIME()
    WHERE BatchID = @BatchID;

    SELECT
        C.PatientControlNumber,
        C.TotalCharge,
        SUM(L.Amount) AS LedgerApplied,
        C.TotalCharge - SUM(L.Amount) AS RemainingBalance
    FROM dbo.Claim AS C
    INNER JOIN dbo.LedgerEntry AS L
        ON L.ClaimID = C.ClaimID
    WHERE C.BatchID = @BatchID
    GROUP BY
        C.PatientControlNumber,
        C.TotalCharge;
END;
GO
