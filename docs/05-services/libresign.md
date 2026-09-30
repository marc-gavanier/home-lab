# LibreSign

Cryptographic PDF signing inside Nextcloud, for signatures that must be verifiable
or that someone else gives. To paste a signature image on a form, use Nextcloud's
built-in PDF viewer instead.

## At a glance

| Item     | Value                                                                                   |
|----------|-----------------------------------------------------------------------------------------|
| Access   | `https://drive.example.com` (VPN) → **LibreSign** in the top bar                        |
| Runs as  | Nextcloud app `libresign`, no container. JSignPdf (Java) runs per signature: zero idle RAM |
| Binaries | JRE 21, JSignPdf, pdftk in `data/appdata_*/libresign/aarch64/` (185 MB, not backed up)  |
| Root CA  | `ca.pem`, `ca-key.pem` in `data/appdata_*/libresign/pki/<id>/` (backed up)              |
| Deploy   | `ansible/roles/deploy/tasks/libresign.yml`                                              |
| ADR      | [ADR-022](../../knowledge/decisions/ADR-022-libresign-pdf-signing.md)                  |

## Stamp or sign?

|              | Built-in viewer             | LibreSign                                          |
|--------------|-----------------------------|----------------------------------------------------|
| Produces     | an image on a page          | a cryptographic signature                          |
| Tamper-proof | no                          | yes: any later edit breaks it                      |
| Steps        | open, stamp, save           | request, add signers, place, sign with a password  |
| Prerequisite | none                        | a personal certificate                             |

The viewer's edit mode offers *Add image* (`editorStamp`), ink (`editorInk`) and
free text (`editorFreeText`). No admin setting gates them.

## How it works

- A self-signed root CA on the Pi issues every certificate.
- The CA does not sign. Each user creates a **certificate password** in LibreSign,
  which mints a personal certificate; it is asked at every signature. Then add a
  signature graphic.
- Add signers by **Nextcloud account**, not email (no SMTP).
- Readers see "signature validity unknown" until they import `ca.pem` (downloadable
  in LibreSign). The signature still proves the document is unchanged. A
  certificate strangers trust must be bought (ADR-022).
- `signing_mode` stays `sync`. `async` moves signing into `nextcloud-cron`, whose
  32 MB tmpfs `/tmp` is too small for large scans (ADR-022).

### The root CA is created once

`libresign:configure:openssl` replaces the CA silently (exit 0) and orphans every
certificate issued from it. The deploy creates the CA only when it can read the CA
directory and `ca.pem` or `ca-key.pem` is missing; a directory it cannot read stops the
run.

- `libresign_cert_cn` / `_o` / `_c` in `local.yml` are read only at creation.
- Losing `ca-key.pem` keeps signed documents valid, but no new certificate can be issued.

## Common tasks

Run from the workstation. Setup report (the deploy fails on `error` rows):

```bash
ssh homelab 'docker exec -u www-data nextcloud php occ libresign:configure:check'
```

Re-download the binaries (idempotent):

```bash
ssh homelab 'docker exec -u www-data nextcloud php occ libresign:install --java --jsignpdf --pdftk'
```

Show where the CA lives:

```bash
ssh homelab 'docker exec -u www-data nextcloud php occ config:app:get libresign config_path'
```

Disable (binaries and CA stay; `app:remove` would delete the CA):

```bash
ssh homelab 'docker exec -u www-data nextcloud php occ app:disable libresign'
```

## Troubleshooting

| Symptom                              | Cause                                         | Action                         |
|--------------------------------------|-----------------------------------------------|--------------------------------|
| `info` row **poppler**               | `pdfsig`/`pdfinfo` not in the image, unused   | None                           |
| `info` row **java encoding**         | `LANG`/`LC_ALL` missing, accents mangled      | Restore them (ADR-022)         |
| Sign button leads nowhere            | No personal certificate                       | Create a certificate password  |
| Signing email never arrives          | Signer added by email, no SMTP                | Add by Nextcloud account       |
