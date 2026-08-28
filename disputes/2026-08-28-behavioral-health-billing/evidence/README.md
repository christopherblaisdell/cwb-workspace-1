# Evidence

Scanned proof of delivery and documents received. **Contents of this folder are
git-ignored** — see the note below.

## Naming convention

```
YYYY-MM-DD-NN-short-description-TYPE.ext
```

Where `NN` is the letter number from the case file and `TYPE` is one of:

- `SENT` — PDF of the exact document you sent
- `FAX-CONFIRM-<dept>` — fax transmission confirmation page
- `EMAIL-SENT` — PDF/print of the sent email including headers and timestamp
- `PORTAL-SCREENSHOT` — screenshot of the portal sent message with timestamp visible
- `CERT-MAIL-RECEIPT` — USPS receipt with tracking number (photograph it at the counter)
- `DELIVERY-PROOF` — signed green card (PS 3811) or the USPS electronic return receipt
- `RECEIVED` — documents the facility or insurer sent you

Example:

```
2026-08-28-01-records-request-SENT.pdf
2026-08-28-01-records-request-CERT-MAIL-RECEIPT.jpg
2026-08-28-01-records-request-FAX-CONFIRM-billing.pdf
2026-09-03-01-records-request-DELIVERY-PROOF.pdf
2026-09-20-itemized-statement-RECEIVED.pdf
```

## Also keep here

- Original statements and bills
- All EOBs
- Admission paperwork, consents, financial responsibility agreement, Good Faith Estimate
- Notice of Privacy Practices (names the Privacy Officer)
- Medical records once produced
- Any collection letters (photograph the envelope postmark too)

---

## ⚠️ Privacy note — why this folder is git-ignored

This folder will contain your own protected health information and behavioral health
treatment records, which are among the most sensitive categories of personal data.

The `.gitignore` at the repository root excludes everything in this directory so that
records are **never committed to git history**. That matters because:

- Git history is effectively permanent — a file committed once and deleted later is
  still recoverable from the repo.
- If this repository is ever pushed to a remote, synced, backed up to a cloud service,
  or shared, committed PHI goes with it.

Keep the templates and the log in version control. Keep the actual records out of it.

If you do want the evidence backed up, use full-disk encryption (FileVault is on by
default on macOS) plus an encrypted backup, not git.
