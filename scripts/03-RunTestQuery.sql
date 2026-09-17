SELECT * FROM dbo.EDI835Batch;

SELECT *
FROM dbo.EDI835Segment
ORDER BY BatchID, SegmentOrdinal;

SELECT *
FROM dbo.EDI835Segment
ORDER BY BatchID, SegmentOrdinal;

SELECT *
FROM dbo.Claim;

SELECT * from dbo.ClaimAdjustment;

SELECT *
FROM dbo.LedgerEntry
ORDER BY LedgerEntryID;