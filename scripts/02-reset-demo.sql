USE X12835Demo;
GO

DELETE FROM dbo.LedgerEntry;
DELETE FROM dbo.ClaimAdjustment;
DELETE FROM dbo.Claim;
DELETE FROM dbo.EDI835Segment;
DELETE FROM dbo.EDI835Batch;

DBCC CHECKIDENT ('dbo.LedgerEntry', RESEED, 0);
DBCC CHECKIDENT ('dbo.ClaimAdjustment', RESEED, 0);
DBCC CHECKIDENT ('dbo.Claim', RESEED, 0);
DBCC CHECKIDENT ('dbo.EDI835Segment', RESEED, 0);
DBCC CHECKIDENT ('dbo.EDI835Batch', RESEED, 0);

PRINT 'Version 1 demo data reset.';
GO
