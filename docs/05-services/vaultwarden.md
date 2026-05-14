# Vaultwarden

Self-hosted password manager, compatible with Bitwarden clients.

## Access

- URL: `https://vault.example.com`
- Admin panel: `https://vault.example.com/admin` (token in `local.yml`)

## What It Does

- Stores passwords, notes, credit cards, identities
- Auto-fill in browsers and mobile apps
- Secure password generation
- TOTP (2FA) code storage

## Client Setup

### Browser Extension
Install the [Bitwarden extension](https://bitwarden.com/download/) for your browser. In settings, set the server URL to `https://vault.example.com` before logging in.

### Mobile (Android/iOS)
Install the [Bitwarden app](https://bitwarden.com/download/), set the server URL to `https://vault.example.com`.

### Desktop
Install the [Bitwarden desktop app](https://bitwarden.com/download/), set the server URL to `https://vault.example.com`.

## First Steps

1. Create your account at `https://vault.example.com`
2. Disable signups after account creation (already set: `SIGNUPS_ALLOWED=false`)
3. Enable 2FA on your account
4. Install browser extension + mobile app
5. Import passwords from your current manager if applicable

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
