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

## MCP Tools

These MCP tools must be available for the skill to function:

| Tool | Purpose |
|------|---------|
| `create_entry` | Create a new journal entry with title, summary, what_changed, and context |
| `search_entries` | Search entries by keyword or phrase |
| `list_entries` | List entries with optional limit |
| `list_journals` | List journals the user has access to |
| `create_journal` | Create a new journal |

## Authentication

The skill uses `@workjournal/cli` for authentication. Run `/journal login` or `npx @workjournal/cli login` to authenticate via browser-based OAuth. Credentials are stored at `~/.workjournal/credentials.json`.

For environments without a browser (SSH, CI), set the `WORKJOURNAL_API_KEY` environment variable with a valid Supabase JWT.
