# Evidence

Scanned proof of delivery and documents received.

## What is and is not in git — updated 2026-09-05

| | Tracked in git? | Why |
|---|---|---|
| **Everything in this folder by default** | ❌ No | It is protected health information. It never enters git history. |
| **`*-website-capture/` subfolders** | ✅ **Yes, as of 2026-09-05** | These are captures of the facility's **public marketing website**. No PHI, and none was ever possible. |

**The reason for the exception is chain of custody, and it matters more than it sounds.**

A SHA-256 manifest proves that files have not changed *since the manifest was written*.
It proves nothing about **when** it was written — the sums file was produced by the same
operator, on the same machine, in the same minute as the files it certifies, and it can be
regenerated at will. Under the old blanket exclusion, the capture had **no anchored
timeline at all**.

Committing it fixes that. Do all three of these, they take minutes and they are free:

1. **Commit it signed** — `git commit -S` — and then leave it alone. Do not amend.
2. **Email `SHA256SUMS.txt` to yourself** through an external provider. The provider's
   received-header timestamp is third-party evidence you do not control.
3. **Run OpenTimestamps** over `SHA256SUMS.txt` for an RFC 3161 trusted timestamp.

Verify the capture at any time from inside the capture directory:

```
shasum -a 256 -c SHA256SUMS.txt
```

*Last verified 2026-09-05: 48 of 48 files OK, 0 failed.*

> ⚠️ **Full-disk encryption.** The earlier note here assumed FileVault is on by default.
> That is true only for Macs configured through Setup Assistant on recent versions. For a
> folder holding substance-use treatment records, **check it rather than assume it**:
> System Settings → Privacy & Security → FileVault.

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
