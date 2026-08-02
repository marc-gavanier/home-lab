# LibreSign

Digital signature of PDFs inside Nextcloud — sign a document yourself, or send
it to someone else for signature, without it leaving the Pi.

## Access

- No address of its own. Open `https://drive.example.com` (VPN required, like
  everything else) and pick **LibreSign** in the top bar, or use *Sign* in a
  PDF's context menu in Files.

## Architecture

No container. LibreSign is a Nextcloud app, and the signature itself is produced
by **JSignPdf**, a Java program the app downloads on first setup:

| Piece | Where |
|-------|-------|
| `libresign` app | Nextcloud, installed and enabled by the deploy |
| JRE 21 + JSignPdf + pdftk | `data/appdata_*/libresign/aarch64/` — 185 MB on `/mnt/data`, not in the image |
| Root CA (`ca.pem`, `ca-key.pem`) | `data/appdata_*/libresign/pki/<id>/` — in the backup, unlike the binaries |

Permanent RAM cost: **zero**. The JVM starts when a document is signed and exits
when it is done.

## The root certificate can only be created once

Every signature is issued from a self-signed CA generated on the Pi.
`libresign:configure:openssl` **replaces** it if run again — it creates a new PKI
directory and bumps the generation counter, silently, exiting 0 — and every
certificate issued from the old root is then orphaned.

The deploy therefore generates it only when `ca.pem` and `ca-key.pem` are both
missing, and never touches an existing one. Its identity comes from
`libresign_cert_cn` / `_o` / `_c` (real values in `local.yml`), read **only at
generation time**: editing them later changes nothing at all.

Losing `ca-key.pem` does not invalidate documents already signed — it means no
new signer certificate can ever be issued under the same root.

## What the signature proves, and what it does not

The CA is ours, so a reader has no reason to trust it: Acrobat and Firefox
display *"signature validity unknown"* until the recipient imports `ca.pem`
(downloadable from LibreSign's own interface). What the signature does prove,
to anyone, is that the document has not been altered since it was signed.

For a signature strangers accept without importing anything, the certificate has
to be bought from a qualified provider — see ADR-022.

## Operations

Everything below runs from the workstation over SSH.

```bash
# Full setup report — the deploy fails on any `error` row, ignores `info`
ssh homelab 'docker exec -u www-data nextcloud php occ libresign:configure:check'

# Re-download the binaries (safe, idempotent — verifies hashes, skips what is intact)
ssh homelab 'docker exec -u www-data nextcloud php occ libresign:install --java --jsignpdf --pdftk'

# Where the CA lives
ssh homelab 'docker exec -u www-data nextcloud php occ config:app:get libresign config_path'
```

Two `info` rows are expected and are not failures:

- **poppler** — `pdfsig`/`pdfinfo` are absent from the Nextcloud image. LibreSign
  14 validates signatures in pure PHP and falls back to its bundled parser for
  page dimensions, so neither is used. Installing them would mean maintaining a
  custom Nextcloud image.
- **java encoding**, *if it ever comes back* — it means `LANG`/`LC_ALL` are
  missing from the container again. Accented characters in document names and
  signature reasons get mangled at the JSignPdf boundary. See ADR-022.

### Undo

```bash
ssh homelab 'docker exec -u www-data nextcloud php occ app:disable libresign'
```

The binaries and the CA stay on disk; re-enabling picks them up again. Removing
the app entirely (`app:remove`) also removes its data — including the CA.

## Do not switch signing to async

`signing_mode` is `sync`: signing runs in the `nextcloud` container, whose
`/tmp` is on disk. The `async` setting moves it into `nextcloud-cron`, which has
a **32 MB tmpfs `/tmp`** — enough for small documents, not for a large scan, and
the failure lands in a background job instead of in front of the user. Raising
that tmpfs is the prerequisite, not the toggle (ADR-022).

## References

- [ADR-022 — LibreSign for PDF signing](../../knowledge/decisions/ADR-022-libresign-pdf-signing.md)
- Deploy tasks: `ansible/roles/deploy/tasks/libresign.yml`
- [Nextcloud](nextcloud.md) — the host application
