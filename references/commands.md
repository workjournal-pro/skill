# Workjournal Command Reference

## Commands

| Command | Description |
|---------|-------------|
| `/journal` | Write a new entry (title auto-generated from conversation) |
| `/journal <title>` | Write a new entry with an explicit title |
| `/journal search <query>` | Search entries by keyword |
| `/journal last [N]` | Show the last N entries (default 1) |
| `/journal check` | Find entries relevant to current conversation |
| `/journal login` | Authenticate with the Workjournal API |
| `/journal init` | Initialize session and select journal |
| `/journal help` | Print command reference |

## API Endpoints

Base URL: `https://api.workjournal.pro`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/v1/journals` | List journals |
| GET | `/v1/journals/:id` | Get journal details |
| POST | `/v1/journals` | Create journal |
| GET | `/v1/journals/:id/entries?limit=N` | List entries |
| POST | `/v1/journals/:id/entries` | Create entry |
| GET | `/v1/journals/:id/entries/search?q=...` | Search entries |
| POST | `/v1/auth/refresh` | Refresh access token |

## Authentication

Credentials are stored at `~/.workjournal/credentials.json` with the shape:

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "expires_at": "2026-04-07T12:00:00.000Z"
}
```

Run `/journal login` or `bash skills/journal/scripts/login.sh` to authenticate via browser-based OAuth.

For environments without a browser (SSH, CI), set the `WORKJOURNAL_API_KEY` environment variable with a valid access token.
