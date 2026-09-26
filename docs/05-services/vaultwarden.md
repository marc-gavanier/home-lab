# Vaultwarden

Self-hosted password manager for Bitwarden clients: passwords, notes, cards,
identities, TOTP codes.

## At a glance

| Item   | Value                                                                              |
|--------|------------------------------------------------------------------------------------|
| URL    | `https://vault.example.com`; admin at `/admin` with the plain token from `local.yml` |
| Data   | `/mnt/data/services/vaultwarden/` (SQLite, attachments, keys)                      |
| Backup | Restic, daily, plus a consistent `sqlite3 .backup` copy (`backup_sqlite_dumps`)    |
| ADR    | ADR-016                                                                            |

## How it works

- `vaultwarden_admin_token` and `vaultwarden_admin_salt` (16 hex bytes) are in the
  encrypted `local.yml`.
- The `deploy` role hashes the token with `python3-argon2` (Argon2id, m=65540, t=3,
  p=4, hash_len=32, fixed salt: deterministic) into the Docker secret
  `/mnt/data/secrets/docker/vaultwarden_admin_token_hash`, read via `ADMIN_TOKEN_FILE`.
- Redeploying a new token does **not** rotate it: `admin_token` in Vaultwarden's
  `config.json` wins. Use [rotate-a-secret.md](../../knowledge/runbooks/rotate-a-secret.md)
  → "Rotating the Vaultwarden admin token".

## Common tasks

First account (`SIGNUPS_ALLOWED=false`):

1. `/admin` → **Users** > **Invite User**, your email. Without SMTP nothing is sent,
   but the email can now register.
2. Register at `/#/register` with that email.
3. Enable 2FA (Account Settings > Security > Two-step Login); save the recovery code.

Clients: the [Bitwarden apps](https://bitwarden.com/download/); set the server URL
to `https://vault.example.com` before logging in.

Restore: restore the consistent `.backup` copy, not the live `db.sqlite3`, which
can be torn. Follow [restore-from-backup.md](../../knowledge/runbooks/restore-from-backup.md)
→ "Restore Vaultwarden (SQLite)".
