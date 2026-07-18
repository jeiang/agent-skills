---
name: actual-budget-import
description: Convert casual transaction lists into Actual Budget transactions and import them with the installed `actual` CLI. Use when the user asks to save, add, enter, record, or import budget transactions into Actual Budget, especially when account or payee names are approximate, transaction text is natural language, or transfers/deposits/payments need to be inferred before running Actual CLI commands.
---

# Actual Budget Import

## Overview

Turn natural-language transaction notes into Actual Budget imports. Resolve approximate account and payee names against the current budget, shape transactions with correct signs and notes, preview the planned records, and import them through the configured `actual` CLI.

## Workflow

1. Read `references/actual-cli.md` before running Actual CLI commands or shaping transaction JSON.
2. Parse each user line into:
   - transaction type: payment, deposit, or transfer
   - amount in major currency units
   - account to import into
   - payee or transfer counterparty
   - note, when the user provided trailing descriptive text
   - date, using the user's explicit date or today's date if omitted
3. Load current budget entities:
   - `actual accounts list --format json`
   - `actual payees list --format json`
4. Fuzzy-match account names against existing accounts. Use an existing account unless the match is not close. Do not create accounts for ambiguous input; ask the user to clarify.
5. Fuzzy-match ordinary payees against existing payees. Use an existing payee unless the match is not close. If there is no close ordinary payee match, create a payee with `actual payees create --name "<name>"` or use `payee_name` and let Actual create it.
6. For transfers, resolve both accounts first. Then find the transfer payee whose `transfer_acct` points at the other account. Use that payee's id/name for the imported transaction so Actual creates the paired transfer.
7. Build one transaction array per source account and import per account with `actual transactions import --account <account-id> --data '<json>'`.
8. Show the user a concise summary of what was imported, including any newly created payees and any assumptions made.

## Parsing Rules

Use these defaults unless the user states otherwise:

- `Payee - $amount - Account` means a payment from `Account` to `Payee`; amount is negative.
- `Got/Received $amount from Payee on Account` means a deposit into `Account`; amount is positive.
- `Transfer $amount from Source to Destination - Note` means import a negative transfer transaction in `Source` using the transfer payee for `Destination`; include the note when present.
- Text after the account in a payment line is a note, not a category, unless the user explicitly asks for categorization.
- Preserve user-provided notes exactly except for trimming whitespace.
- Convert amounts to integer cents by multiplying by 100 and rounding to the nearest cent.
- If no date is stated, use today's local date.

## Matching Guidance

Normalize names by lowercasing, trimming punctuation, collapsing whitespace, and ignoring small words such as `the`, `card`, and `account` when helpful. Prefer the user's known budget names over inventing new ones.

Use close matches confidently when one candidate is clearly best, for example `Republic Mastercard` matching `Republic MasterCard`. Ask before importing when two existing accounts/payees are similarly plausible.

Do not create a new payee for transfer counterparties. Transfers must use Actual's transfer payee for the destination/source account.

## Safety

Prefer `actual transactions import` over `actual transactions add` so Actual can reconcile duplicates and run rules. Use `--dry-run` first when the request is large, ambiguous, or the user asks to preview before saving.

If the CLI is not configured or cannot reach the sync server, report the command failure and stop before fabricating transaction IDs or claiming imports succeeded.
