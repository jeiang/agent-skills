# Actual CLI Reference

Use the installed `actual` CLI. The CLI connects to the configured Actual sync server and accepts global configuration from environment variables, flags, or config files.

## Entity Lookup

```bash
actual accounts list --format json
actual payees list --format json
actual payees create --name "Payee Name"
actual server get-id --type accounts --name "Checking"
```

Prefer list commands for fuzzy matching because exact `get-id` lookups are not enough for approximate user names.

## Transaction Import

Use import for normal entry so Actual can reconcile duplicates and run rules:

```bash
actual transactions import --account <account-id> --data '[{"date":"2026-06-25","amount":-1000,"payee_name":"Superpharm"}]'
actual transactions import --account <account-id> --file transactions.json
actual transactions import --account <account-id> --data '[...]' --dry-run
```

Use `transactions add` only when explicitly avoiding reconciliation:

```bash
actual transactions add --account <account-id> --data '[{"date":"2026-06-25","amount":-1000,"payee_name":"Superpharm"}]'
```

## Transaction Fields

Common fields:

- `date`: `YYYY-MM-DD`
- `amount`: integer cents; payments are negative, deposits are positive
- `payee`: existing payee id; overrides `payee_name`
- `payee_name`: ordinary payee name; Actual can create or reuse a matching payee
- `imported_payee`: raw original description, useful for traceability
- `notes`: user-provided memo/note
- `imported_id`: unique bank id if available; omit for ad hoc manual entries unless a stable user-provided id exists
- `cleared`: optional boolean

## Transfers

For transfers, do not create an ordinary payee. Actual represents account transfers using transfer payees. Load payees and find the payee whose `transfer_acct` equals the other account's id.

Example: For `Transfer $3000 from CIBC Savings to Republic Checking - Payment for Trip`, import into the CIBC Savings account:

```json
[
  {
    "date": "2026-06-25",
    "amount": -300000,
    "payee": "<transfer-payee-id-for-Republic-Checking>",
    "notes": "Payment for Trip",
    "imported_payee": "Transfer from CIBC Savings to Republic Checking"
  }
]
```

Actual creates the paired transaction when the transaction uses a transfer payee.

## Example Mapping

Input:

```text
1. Superpharm - $10.00 - Republic Mastercard
2. Transfer $3000 from CIBC Savings to Republic Checking - Payment for Trip
3. Got $450 from Noel on CIBC Savings
4. Digicel - $950 - CIBC Checking - Internet Bill
```

Output intent:

- Import `-1000` to `Republic Mastercard`, payee `Superpharm`, no note.
- Import `-300000` to `CIBC Savings`, transfer payee for `Republic Checking`, note `Payment for Trip`.
- Import `45000` to `CIBC Savings`, payee `Noel`, no note.
- Import `-95000` to `CIBC Checking`, payee `Digicel`, note `Internet Bill`.
