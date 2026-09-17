# X12 835 Processing Demo

A SQL Server–first demonstration of an end-to-end healthcare electronic remittance (X12 835) processing pipeline.

> **Portfolio disclaimer:** This project is independently developed and contains only synthetic data and original implementation. It does not contain employer source code, database schemas, customer data, proprietary business rules, or confidential information.

## Version 1

Version 1 demonstrates a simplified primary-payer workflow:

```text
Synthetic 835
    ↓
Inbound file registration
    ↓
X12 segment staging/parsing
    ↓
Claim extraction
    ↓
Payment + adjustment processing
    ↓
Financial ledger posting
    ↓
Batch reconciliation
```

The implementation is intentionally SQL-first. It demonstrates database/backend engineering concepts relevant to enterprise RCM systems without reproducing any employer-specific implementation.

### Version 1 demonstrates

- X12 835 segment parsing
- Relational staging of EDI segments
- Claim extraction from `CLP`
- Adjustment extraction from `CAS`
- Insurance payment posting
- Contractual adjustment posting
- Patient responsibility posting
- Transactional financial posting
- Batch status tracking
- Reconciliation
- Duplicate-posting protection
- SQL-based smoke tests

### Version 1 simplifications

This is a portfolio/teaching implementation, not a complete X12 engine. It does not implement every X12 rule, payer-specific business rule, secondary/tertiary COB, crossover claims, external cloud retrieval, or production financial semantics.

## Local development environment

This project is designed to run with:

- Ubuntu 22.04+ with SQL Server 2022 Developer Edition
- VS Code on macOS/Linux/Windows
- Microsoft's **MSSQL** VS Code extension
- Git/GitHub

For this setup, the SQL Server database runs in your Ubuntu VM and VS Code runs on your Mac.

## Run Version 1 from VS Code

### 1. Connect to the `master` database

Use your existing MSSQL connection to SQL Server and select:

```text
Database: master
```

### 2. Create the demo database

Open:

```text
database/schema/01-create-database.sql
```

Execute the entire file.

This creates:

```text
X12835Demo
```

### 3. Select `X12835Demo`

Create/select a connection to:

```text
Database: X12835Demo
```

### 4. Create the stored procedures

Execute these files:

```text
database/procedures/02-parse-835.sql
database/procedures/03-post-ledger.sql
database/procedures/04-reconcile-batch.sql
```

Each script contains `USE X12835Demo`, so the scripts can also be run from a connection with a different default database.

### 5. Load the synthetic 835 and execute the pipeline

Open:

```text
scripts/01-load-and-run-demo.sql
```

Execute it.

This file contains the synthetic 835 inline, so no Windows/Mac/Linux file path is required.

The script:

1. Registers the synthetic file.
2. Parses the 835.
3. Posts the ledger.
4. Reconciles the claim.
5. Displays the resulting data.

### 6. Run the tests

Open:

```text
tests/01-v1-smoke-tests.sql
```

Execute it.

Expected final message:

```text
ALL VERSION 1 SMOKE TESTS PASSED.
```

## Expected financial result

The fixture contains one synthetic claim:

```text
Charge                         $1,500.00
Insurance payment             $1,250.00
Contractual adjustments          $100.00
Patient responsibility           $150.00
                               ----------
Total applied                  $1,500.00
```

The demo therefore verifies:

```text
Claim charge = ledger-applied activity
$1,500.00    = $1,500.00
```

## Database model

```text
EDI835Batch
    │
    └── EDI835Segment
            │
            └── Claim
                  │
                  ├── ClaimAdjustment
                  │
                  └── LedgerEntry
```

## Repository structure

```text
database/
  schema/
    01-create-database.sql
  procedures/
    02-parse-835.sql
    03-post-ledger.sql
    04-reconcile-batch.sql
  jobs/
    05-sql-agent-job-definition.sql

sample-data/
  835/
    payment-basic.835

scripts/
  01-load-and-run-demo.sql
  02-reset-demo.sql

tests/
  01-v1-smoke-tests.sql

docs/
  processing-flow.md
```

## Professional connection

The concepts in this demo are inspired by work on healthcare revenue-cycle software, including X12 835 processing, SQL Server business logic, batch processing, financial posting, and reconciliation.

The implementation, schema, data, and simplified business rules in this repository are original and synthetic.
