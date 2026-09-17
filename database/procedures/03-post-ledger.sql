USE X12835Demo;
GO

CREATE OR ALTER PROCEDURE dbo.Post835Ledger
    @BatchID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.EDI835Batch
            WHERE BatchID = @BatchID
              AND Status = 'PARSED'
        )
            THROW 50010, 'Batch must be in PARSED status before ledger posting.', 1;

        /*
            Basic idempotency guard: a batch may only produce one ledger set.
        */
        IF EXISTS
        (
            SELECT 1
            FROM dbo.LedgerEntry
            WHERE BatchID = @BatchID
        )
            THROW 50011, 'Ledger entries already exist for this batch.', 1;

        /*
            Version 1 uses positive "applied activity" amounts so the demo can
            reconcile charge = payment + adjustments. Real RCM ledger semantics
            can use different debit/credit conventions depending on the ledger.
        */
        INSERT dbo.LedgerEntry
        (
            BatchID,
            ClaimID,
            LedgerType,
            Amount,
            SourceDescription
        )
        SELECT
            C.BatchID,
            C.ClaimID,
            'INSURANCE_PAYMENT',
            C.InsurancePayment,
            '835 claim payment'
        FROM dbo.Claim AS C
        WHERE C.BatchID = @BatchID
          AND C.InsurancePayment <> 0;

        INSERT dbo.LedgerEntry
        (
            BatchID,
            ClaimID,
            LedgerType,
            Amount,
            SourceDescription
        )
        SELECT
            C.BatchID,
            C.ClaimID,
            CASE A.AdjustmentGroup
                WHEN 'PR' THEN 'PATIENT_RESPONSIBILITY'
                ELSE 'CONTRACTUAL_ADJUSTMENT'
            END,
            A.Amount,
            CONCAT('835 CAS ', A.AdjustmentGroup, '/', A.AdjustmentReason)
        FROM dbo.ClaimAdjustment AS A
        INNER JOIN dbo.Claim AS C
            ON C.ClaimID = A.ClaimID
        WHERE C.BatchID = @BatchID;

        UPDATE dbo.EDI835Batch
        SET
            Status = 'POSTED',
            ProcessedAt = SYSUTCDATETIME()
        WHERE BatchID = @BatchID;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        UPDATE dbo.EDI835Batch
        SET
            Status = 'FAILED',
            ErrorMessage = ERROR_MESSAGE()
        WHERE BatchID = @BatchID;

        THROW;
    END CATCH
END;
GO
