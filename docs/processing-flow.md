# Version 1 Processing Flow

## 1. Inbound file

A synthetic X12 835 file represents an external remittance.

A production system could retrieve the file from cloud storage or SFTP. Version 1 deliberately keeps that dependency outside the demo.

## 2. Batch registration

The complete file is stored in `EDI835Batch`.

The batch lifecycle is:

```text
RECEIVED → PARSED → POSTED → RECONCILED
```

A failure changes the batch to `FAILED` and stores an error message.

## 3. Segment staging

The file is split into X12 segments and staged in `EDI835Segment`.

Each segment has:

- batch ID
- ordinal position
- segment type
- original segment text

Preserving order is important because later segments such as `CAS` are interpreted relative to the preceding claim.

## 4. Claim processing

`CLP` segments become `Claim` rows.

Version 1 extracts:

- patient control number
- claim status
- total charge
- insurance payment

## 5. Adjustment processing

`CAS` segments are associated with the most recent preceding claim.

Version 1 extracts:

- adjustment group code
- adjustment reason code
- amount

The sample includes contractual adjustments and patient responsibility.

## 6. Ledger posting

`Post835Ledger` creates separate ledger activity for:

- insurance payment
- contractual adjustments
- patient responsibility

Posting occurs in a transaction. A basic idempotency guard prevents posting the same batch twice.

## 7. Reconciliation

`Reconcile835Batch` compares the claim charge with total ledger-applied activity.

For the sample:

```text
Charge                  1500.00
Payment                 1250.00
Adjustments              250.00
                         -------
Ledger applied          1500.00
Remaining balance          0.00
```

## Future versions

The architecture is intended to grow toward:

```text
Version 1
  Basic claim/payment/adjustment flow

Version 1.x
  Service-line hierarchy
  Multiple claims
  Multiple transactions
  Better X12 validation

Version 2
  Primary / secondary / tertiary COB
  Transfers
  Reversals

Version 3
  Crossover claims
  Additional post-processing
  More production-like SQL Agent orchestration

Future modernization
  .NET service/API layer
```
