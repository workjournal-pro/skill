# Workjournal Command Reference

The skill is a thin shell over the `workjournal` CLI. A small set of invocations are handled as *agent shortcuts* (they need the agent to synthesise something); everything else is a verbatim CLI passthrough. See `SKILL.md` for the dispatch logic.

## Agent shortcuts

| Command | Description |
|---|---|
| `/workjournal` | Write a new entry (title auto-generated from the conversation) |
| `/workjournal <title>` | Write a new entry with an explicit title |
| `/workjournal search <query>` | Alias for `workjournal journal entries search` |
| `/workjournal last [N]` | Alias for `workjournal journal entries last` — full-body view |
| `/workjournal check` | Orchestrates 2–4 search calls based on the current conversation |
| `/workjournal login` | Two-phase browser OAuth (CLI can't run both phases unattended) |
| `/workjournal help` | Print command reference |

## CLI passthrough

Any `/workjournal <first-word> …` where the first word is `journal`, `journals`, `auth`, or `config` is run verbatim as `workjournal <args>` (with `--json` appended for data-producing commands).

### Selected journal (`/workjournal journal …`)

| Command | Description |
|---|---|
| `journal` | Show selected journal details |
| `journal entries [list]` | List entries (slim — no body) |
| `journal entries last [N]` | Last N entries with full body |
| `journal entries get <index>` | Fetch a single entry by index |
| `journal entries write -s <summary> -b <body>` | Create an entry |
| `journal entries delete <index>` | Delete an entry (destructive — skill confirms first) |
| `journal entries search <query>` | Search entries |
| `journal shares [list]` | List members |
| `journal shares delete <email>` | Remove a member (destructive) |
| `journal invites [list]` | List invitations |
| `journal invites new <email>` | Invite a collaborator |
| `journal invites delete <id>` | Revoke an invitation (destructive) |
| `journal export [-f json\|md\|csv] [-p <path>]` | Export journal data |

### Manage journals (`/workjournal journals …`)

| Command | Description |
|---|---|
| `journals list` | List journals you have access to |
| `journals new <name>` | Create a new journal |
| `journals select <id>` | Set active journal for this machine |
| `journals delete <id>` | Delete a journal (destructive) |
| `journals <id>` | Show details of a specific journal |
| `journals <id> <resource> <verb>` | Same as `/workjournal journal …` against an explicit journal ID |

### Auth (`/workjournal auth …`)

| Command | Description |
|---|---|
| `auth login` | Interactive login (prefer the `/workjournal login` shortcut) |
| `auth login start` | Print the authorize URL (headless) |
| `auth login finish <CODE>` | Exchange the pasted code for credentials |
| `auth logout` | Remove stored credentials |
| `auth whoami` | Print the authenticated user |
| `auth status` | Print token status + expiry |

### Config (`/workjournal config …`)

| Command | Description |
|---|---|
| `config show` | Show resolved config (project + global) |

## Destructive guardrail

Before running any of the four destructive patterns, the skill prints the resolved command and waits for the user to confirm:

- `journal entries delete <index>`
- `journal shares delete <email>`
- `journal invites delete <id>`
- `journals delete <id>`

The explicit-id form is also caught (`journals <id> entries delete …`, etc.).

## Setup

There's no `init` shortcut — walk new users through it explicitly:

1. `/workjournal login` — browser OAuth, writes credentials.
2. `/workjournal journals list` — see existing journals.
3. `/workjournal journals new "<name>"` — create one if needed.
4. `/workjournal journals select <id>` — make it the default.

## Authentication

Credentials are stored at `~/.workjournal/credentials.json`:

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "expires_at": "2026-04-07T12:00:00.000Z"
}
```

Use `/workjournal login` or `bash skills/journal/scripts/login.sh` to authenticate via browser-based OAuth. The CLI refreshes tokens automatically before each call.
