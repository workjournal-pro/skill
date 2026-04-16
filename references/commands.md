# Workjournal Command Reference

## Skill Commands

| Command | Description |
|---------|-------------|
| `/workjournal` | Write a new entry (title auto-generated from conversation) |
| `/workjournal <title>` | Write a new entry with an explicit title |
| `/workjournal search <query>` | Search entries by keyword |
| `/workjournal last [N]` | Show the last N entries (default 1) |
| `/workjournal check` | Find entries relevant to current conversation |
| `/workjournal login` | Authenticate with the Workjournal API |
| `/workjournal init` | Initialize session and select journal |
| `/workjournal help` | Print command reference |

## CLI Commands

All skill operations use the `workjournal` CLI. The skill invokes these via `npx --yes @workjournal/cli <command> --json`.

### Selected journal

| Command | Description |
|---------|-------------|
| `workjournal journal entries` | List entries |
| `workjournal journal entries write -s "..." -b "..."` | Create entry |
| `workjournal journal entries last [N]` | Show last N entries |
| `workjournal journal entries search "query"` | Search entries |
| `workjournal journal entries delete <number>` | Delete entry |

### Manage journals

| Command | Description |
|---------|-------------|
| `workjournal journals list` | List all journals |
| `workjournal journals new "name"` | Create journal |
| `workjournal journals select <id>` | Set active journal |
| `workjournal journals delete <id>` | Delete journal |

### Auth

| Command | Description |
|---------|-------------|
| `workjournal auth login` | Interactive login |
| `workjournal auth login start` | Print authorize URL (headless) |
| `workjournal auth login finish <CODE>` | Exchange code for credentials |
| `workjournal auth logout` | Remove stored credentials |

## Authentication

Credentials are stored at `~/.workjournal/credentials.json` with the shape:

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "expires_at": "2026-04-07T12:00:00.000Z"
}
```

Run `/workjournal login` or `bash skills/journal/scripts/login.sh` to authenticate via browser-based OAuth.
