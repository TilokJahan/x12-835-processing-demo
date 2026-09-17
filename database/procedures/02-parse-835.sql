USE X12835Demo;
GO

CREATE OR ALTER PROCEDURE dbo.Parse835Batch
    @BatchID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @FileContent NVARCHAR(MAX);

        SELECT @FileContent = FileContent
        FROM dbo.EDI835Batch
        WHERE BatchID = @BatchID;

        IF @FileContent IS NULL
            THROW 50001, '835 batch was not found.', 1;

        /*
            Reset parsed/staged child data so a failed or manually re-run
            parse does not create duplicate claim/segment rows.
        */
        DELETE FROM dbo.ClaimAdjustment
        WHERE ClaimID IN
        (
            SELECT ClaimID
            FROM dbo.Claim
            WHERE BatchID = @BatchID
        );

        DELETE FROM dbo.Claim
        WHERE BatchID = @BatchID;

        DELETE FROM dbo.EDI835Segment
        WHERE BatchID = @BatchID;

        /*
            X12 segments are separated by ~ in the synthetic fixture.
            STRING_SPLIT with ordinal preserves segment order.
        */
        INSERT dbo.EDI835Segment
        (
            BatchID,
            SegmentOrdinal,
            SegmentType,
            SegmentText
        )
        SELECT
            @BatchID,
            CONVERT(INT, S.ordinal),
            LEFT(S.value, CHARINDEX('*', S.value + '*') - 1),
            LTRIM(RTRIM(S.value))
        FROM STRING_SPLIT(@FileContent, '~', 1) AS S
        WHERE LTRIM(RTRIM(S.value)) <> N'';

        /*
            Parse CLP segments into claim records.
            X12 element positions:
              CLP01 = patient control number
              CLP02 = claim status
              CLP03 = total charge
              CLP04 = payment amount
        */
        INSERT dbo.Claim
        (
            BatchID,
            CLPSegmentOrdinal,
            PatientControlNumber,
            ClaimStatus,
            TotalCharge,
            InsurancePayment
        )
        SELECT
            S.BatchID,
            S.SegmentOrdinal,
            MAX(CASE WHEN P.ordinal = 2 THEN P.value END),
            CASE MAX(CASE WHEN P.ordinal = 3 THEN P.value END)
                WHEN '1' THEN 'PROCESSED AS PRIMARY'
                WHEN '2' THEN 'PROCESSED AS SECONDARY'
                WHEN '3' THEN 'PROCESSED AS TERTIARY'
                ELSE 'OTHER'
            END,
            TRY_CONVERT(DECIMAL(18,2), MAX(CASE WHEN P.ordinal = 4 THEN P.value END)),
            TRY_CONVERT(DECIMAL(18,2), MAX(CASE WHEN P.ordinal = 5 THEN P.value END))
        FROM dbo.EDI835Segment AS S
        CROSS APPLY STRING_SPLIT(S.SegmentText, '*', 1) AS P
        WHERE S.BatchID = @BatchID
          AND S.SegmentType = 'CLP'
        GROUP BY
            S.BatchID,
            S.SegmentOrdinal
        HAVING
            TRY_CONVERT(DECIMAL(18,2), MAX(CASE WHEN P.ordinal = 4 THEN P.value END)) IS NOT NULL
            AND
            TRY_CONVERT(DECIMAL(18,2), MAX(CASE WHEN P.ordinal = 5 THEN P.value END)) IS NOT NULL;

        /*
            Associate each CAS segment with the most recent preceding CLP.
            Version 1 intentionally aggregates all CAS activity within the
            claim scope rather than modeling full service-line hierarchy.
        */
        INSERT dbo.ClaimAdjustment
        (
            ClaimID,
            AdjustmentGroup,
            AdjustmentReason,
            Amount
        )
        SELECT
            C.ClaimID,
            MAX(CASE WHEN P.ordinal = 2 THEN P.value END),
            MAX(CASE WHEN P.ordinal = 3 THEN P.value END),
            TRY_CONVERT(DECIMAL(18,2), MAX(CASE WHEN P.ordinal = 4 THEN P.value END))
        FROM dbo.EDI835Segment AS S
        CROSS APPLY STRING_SPLIT(S.SegmentText, '*', 1) AS P
        CROSS APPLY
        (
            SELECT TOP (1)
                C1.ClaimID
            FROM dbo.Claim AS C1
            WHERE C1.BatchID = S.BatchID
              AND C1.CLPSegmentOrdinal < S.SegmentOrdinal
            ORDER BY C1.CLPSegmentOrdinal DESC
        ) AS C
        WHERE S.BatchID = @BatchID
          AND S.SegmentType = 'CAS'
        GROUP BY
            C.ClaimID,
            S.SegmentID
        HAVING
            TRY_CONVERT(DECIMAL(18,2), MAX(CASE WHEN P.ordinal = 4 THEN P.value END)) IS NOT NULL;

        UPDATE dbo.EDI835Batch
        SET
            Status = 'PARSED',
            ProcessedAt = SYSUTCDATETIME(),
            ErrorMessage = NULL
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
