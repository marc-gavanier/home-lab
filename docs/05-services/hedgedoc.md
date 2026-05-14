# HedgeDoc

Collaborative markdown editor — personal note-taking.

## Access

- URL: `https://notes.example.com`

## What It Does

- Write and edit notes in markdown
- Real-time collaboration
- Syntax highlighting for code blocks
- Export to PDF, HTML
- Presentation mode (slide shows from markdown)

## First Steps

1. Open `https://notes.example.com`
2. Create an account
3. Start writing notes in markdown

## Data

| Path                                   | Content                         |
|----------------------------------------|---------------------------------|
| `/mnt/data/services/hedgedoc/uploads/` | Uploaded images and attachments |
| `/mnt/data/services/hedgedoc/db/`      | PostgreSQL database             |

## Backup

Backed up daily by Restic. Database is dumped before each snapshot (`hedgedoc.sql`).

## Restore

```bash
# Stop HedgeDoc
docker stop hedgedoc hedgedoc-db

# Restore from backup
restic restore latest --target / --include /mnt/data/services/hedgedoc

# Restore database
docker start hedgedoc-db
sleep 10
docker exec -i hedgedoc-db psql -U hedgedoc hedgedoc < /mnt/data/backups/dumps/hedgedoc.sql

# Start HedgeDoc
docker start hedgedoc
```
