# Vaultwarden

Self-hosted password manager, compatible with Bitwarden clients.

## Access

- URL: `https://vault.example.com`
- Admin panel: `https://vault.example.com/admin` (use the plain token from `local.yml`)

## What It Does

- Stores passwords, notes, credit cards, identities
- Auto-fill in browsers and mobile apps
- Secure password generation
- TOTP (2FA) code storage

## Admin Token Security

The `ADMIN_TOKEN` is stored as an Argon2id hash (not plain text) — Vaultwarden recommends this to avoid leaking the admin token if config files are exposed.

Ansible automates the hashing:
- `vaultwarden_admin_token` (plain) and `vaultwarden_admin_salt` (16 hex bytes) live in encrypted `local.yml`
- The `deploy` role hashes the token using `python3-argon2` (Argon2id, m=65540, t=3, p=4, hash_len=32) with the fixed salt → **deterministic** output, no caching needed
- The resulting `$argon2id$...` hash goes into the `.env` as `VAULTWARDEN_ADMIN_TOKEN_HASH`
- Compose injects it as `ADMIN_TOKEN` env var

Login at `/admin` uses the **plain token** — Vaultwarden compares it against the stored hash.

To rotate the admin token: change `vaultwarden_admin_token` in `local.yml`, redeploy. The salt can stay the same (or rotate it too for extra hygiene).

## Client Setup

### Browser Extension
Install the [Bitwarden extension](https://bitwarden.com/download/) for your browser. In settings, set the server URL to `https://vault.example.com` before logging in.

### Mobile (Android/iOS)
Install the [Bitwarden app](https://bitwarden.com/download/), set the server URL to `https://vault.example.com`.

### Desktop
Install the [Bitwarden desktop app](https://bitwarden.com/download/), set the server URL to `https://vault.example.com`.

## First Steps

1. With `SIGNUPS_ALLOWED=false`, you can't self-register. Use the admin panel to invite yourself:
   - Open `/admin`, log in with the plain token
   - **Users** > **Invite User**, enter your email
   - Without SMTP, the invitation isn't emailed but allows registration for that email — go to `/#/register` with the same email
2. Enable 2FA (Account Settings > Security > Two-step Login) and save the recovery code
3. Install the browser extension + mobile app
4. Import passwords from your current manager if applicable

## Data

| Path                              | Content                            |
|-----------------------------------|------------------------------------|
| `/mnt/data/services/vaultwarden/` | SQLite database, attachments, keys |

## Backup

Backed up daily by Restic. Vaultwarden uses SQLite — the file is backed up directly.

## Restore

```bash
docker stop vaultwarden
restic restore latest --target / --include /mnt/data/services/vaultwarden
docker start vaultwarden
```