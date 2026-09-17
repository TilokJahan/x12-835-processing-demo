USE X12835Demo;
GO

DECLARE @BatchID INT =
(
    SELECT TOP (1) BatchID
    FROM dbo.EDI835Batch
    ORDER BY BatchID DESC
);

IF @BatchID IS NULL
    THROW 50100, 'TEST SETUP FAILED: no batch exists.', 1;

/* Test 1: batch is reconciled. */
IF NOT EXISTS
(
    SELECT 1
    FROM dbo.EDI835Batch
    WHERE BatchID = @BatchID
      AND Status = 'RECONCILED'
)
    THROW 50101, 'TEST FAILED: batch did not reach RECONCILED status.', 1;

/* Test 2: exactly one synthetic claim was parsed. */
IF
(
    SELECT COUNT(*)
    FROM dbo.Claim
    WHERE BatchID = @BatchID
) <> 1
    THROW 50102, 'TEST FAILED: expected exactly one claim.', 1;

/* Test 3: payment was parsed correctly. */
IF
(
    SELECT SUM(InsurancePayment)
    FROM dbo.Claim
    WHERE BatchID = @BatchID
) <> 1250.00
    THROW 50103, 'TEST FAILED: expected insurance payment of 1250.00.', 1;

/* Test 4: adjustments total 250. */
IF
(
    SELECT SUM(A.Amount)
    FROM dbo.ClaimAdjustment AS A
    INNER JOIN dbo.Claim AS C
        ON C.ClaimID = A.ClaimID
    WHERE C.BatchID = @BatchID
) <> 250.00
    THROW 50104, 'TEST FAILED: expected adjustments totaling 250.00.', 1;

/* Test 5: ledger activity balances to the claim charge. */
IF EXISTS
(
    SELECT 1
    FROM dbo.Claim AS C
    INNER JOIN
    (
        SELECT
            ClaimID,
            SUM(Amount) AS LedgerApplied
        FROM dbo.LedgerEntry
        WHERE BatchID = @BatchID
        GROUP BY ClaimID
    ) AS L
        ON L.ClaimID = C.ClaimID
    WHERE C.BatchID = @BatchID
      AND ABS(C.TotalCharge - L.LedgerApplied) > 0.01
)
    THROW 50105, 'TEST FAILED: ledger does not balance to claim charge.', 1;

/* Test 6: duplicate posting is rejected. */
BEGIN TRY
    EXEC dbo.Post835Ledger @BatchID = @BatchID;
    THROW 50106, 'TEST FAILED: duplicate ledger posting was not blocked.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (50010, 50011)
        THROW;
END CATCH;

PRINT 'ALL VERSION 1 SMOKE TESTS PASSED.';
GO
