# x12-835-processing-demo
end-to-end lifecycle of an 835 through a database-heavy financial processing system

Disclaimer

This project is an independently developed demonstration inspired by concepts encountered during my professional work in healthcare revenue cycle management. It does not contain source code, database schemas, customer data, proprietary business rules, or other confidential information belonging to my employer. All data and implementations in this repository are synthetic and original.

                    ┌──────────────────┐
                    │  Synthetic 835   │
                    │      File        │
                    └────────┬─────────┘
                             │
                             ▼
                 ┌────────────────────┐
                 │ 1. File Retrieval  │
                 │  (simulated cloud) │
                 └─────────┬──────────┘
                           │
                           ▼
                 ┌────────────────────┐
                 │ 2. Import / Parse  │
                 │     835 Segments   │
                 └─────────┬──────────┘
                           │
                           ▼
              ┌──────────────────────────┐
              │ 3. Business Processing   │
              │                          │
              │ • Claims                 │
              │ • Payments               │
              │ • Adjustments            │
              │ • Transfers               │
              │ • COB / Payer sequencing │
              └────────────┬─────────────┘
                           │
                           ▼
                 ┌────────────────────┐
                 │ 4. Ledger Posting  │
                 │                    │
                 │ Primary            │
                 │ Secondary          │
                 │ Tertiary           │
                 │ Adjustments        │
                 │ Transfers          │
                 └─────────┬──────────┘
                           │
                           ▼
                 ┌────────────────────┐
                 │ 5. Post-Processing │
                 │                    │
                 │ Services           │
                 │ Crossover Claims   │
                 │ Reconciliation     │
                 └────────────────────┘
