USE X12835Demo;
GO

/*
    Portable Version 1 demo loader.

    The synthetic 835 is embedded in this script so the demo does not depend
    on a Windows filesystem path, Mac path, or Linux path.
*/

DECLARE @FileContent NVARCHAR(MAX) =
N'ISA*00*          *00*          *ZZ*SYNTHETIC835    *ZZ*DEMO-PAYER     *260916*1200*U*00401*000000001*0*P*:~GS*HP*SYNTHETIC835*DEMO-PAYER*20260916*1200*1*X*005010X221A1~ST*835*0001~BPR*I*1250.00*C*ACH*CCP*01*111000025*DA*123456789*1512345678**01*111000025*DA*987654321*20260916~TRN*1*835000001*1512345678~DTM*405*20260916~N1*PR*DEMO INSURANCE PLAN~N3*100 SAMPLE STREET~N4*ANYTOWN*MI*49001~N1*PE*SYNTHETIC HEALTH SERVICES~LX*1~CLP*CLM10001*1*1500.00*1250.00**MC*P10001*11*1~NM1*QC*1*DOE*JANE****MI*SUB10001~DTM*232*20260901~DTM*233*20260901~SVC*HC:99213*150.00*125.00**1~CAS*CO*45*10.00~SVC*HC:90834*600.00*500.00**1~CAS*CO*45*40.00~SVC*HC:90837*750.00*625.00**1~CAS*CO*45*50.00~CAS*PR*2*150.00~SE*20*0001~GE*1*1~IEA*1*000000001~';

DECLARE @BatchID INT;

INSERT dbo.EDI835Batch
(
    FileName,
    FileContent,
    Status
)
VALUES
(
    N'payment-basic.835',
    @FileContent,
    'RECEIVED'
);

SET @BatchID = CONVERT(INT, SCOPE_IDENTITY());

PRINT CONCAT('Created BatchID: ', @BatchID);

EXEC dbo.Parse835Batch @BatchID = @BatchID;
EXEC dbo.Post835Ledger @BatchID = @BatchID;
EXEC dbo.Reconcile835Batch @BatchID = @BatchID;

PRINT '--- Batch ---';
SELECT *
FROM dbo.EDI835Batch
WHERE BatchID = @BatchID;

PRINT '--- Segments ---';
SELECT *
FROM dbo.EDI835Segment
WHERE BatchID = @BatchID
ORDER BY SegmentOrdinal;

PRINT '--- Claims ---';
SELECT *
FROM dbo.Claim
WHERE BatchID = @BatchID;

PRINT '--- Adjustments ---';
SELECT A.*
FROM dbo.ClaimAdjustment AS A
INNER JOIN dbo.Claim AS C
    ON C.ClaimID = A.ClaimID
WHERE C.BatchID = @BatchID;

PRINT '--- Ledger ---';
SELECT *
FROM dbo.LedgerEntry
WHERE BatchID = @BatchID
ORDER BY LedgerEntryID;
GO
