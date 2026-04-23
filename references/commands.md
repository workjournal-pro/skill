# Workjournal Command Reference

The skill is a thin shell over the `workjournal` CLI (0.4.0+, slug-based). A small set of invocations are handled as *agent shortcuts* (they need the agent to synthesise something or look up the active selection); everything else is a verbatim CLI passthrough. See `SKILL.md` for the dispatch logic.

## Agent shortcuts

| Command | Description |
|---|---|
| `/workjournal` | Write a new entry (title auto-generated from the conversation) |
| `/workjournal <title>` | Write a new entry with an explicit title |
| `/workjournal search <query>` | Resolve active selection, then call `workjournal entries search <ws> <j> <query>` |
| `/workjournal last [N]` | Resolve active selection, then call `workjournal entries last <ws> <j> [N]` — full body |
| `/workjournal check` | Orchestrates 2–4 search calls based on the current conversation |
| `/workjournal login` | Two-phase browser OAuth (CLI can't run both phases unattended) |
| `/workjournal help` | Print command reference |

## CLI passthrough

Any `/workjournal <first-word> …` where the first word is `workspaces`, `journal`, `journals`, `entries`, `shares`, `invites`, `export`, `auth`, or `config` is run verbatim as `workjournal <args>` (with `--json` appended for data-producing commands).

### Workspaces (`/workjournal workspaces …`)

| Command | Description |
|---|---|
| `workspaces list` | List workspaces you belong to |
| `workspaces get <ws>` | Show details of a workspace |
| `workspaces new <name> [--slug <slug>]` | Create a workspace |
| `workspaces select <ws>` | Set active workspace in project-config |

### Selected journal (`/workjournal journal`)

| Command | Description |
|---|---|
| `journal` | Show selected journal details |

The old `journal entries …` / `journal shares …` etc. forms are gone. Use the top-level resource verbs below with explicit `<ws> <j>` positionals.

### Manage journals (`/workjournal journals …`)

| Command | Description |
|---|---|
| `journals list [<ws>]` | List journals in workspace (defaults to selected) |
| `journals get <ws> <j>` | Show details of a journal |
| `journals new <ws> <name> [--slug <slug>]` | Create a journal |
| `journals select <ws> <j>` | Set active journal in project-config |
| `journals delete <ws> <j>` | Delete a journal (destructive) |

### Entries (`/workjournal entries …`)

| Command | Description |
|---|---|
| `entries list <ws> <j>` | List entries (slim — no body) |
| `entries last <ws> <j> [N]` | Last N entries with full body |
| `entries get <ws> <j> <index>` | Fetch a single entry by index |
| `entries write <ws> <j> -s <summary> -b <body>` | Create an entry |
| `entries delete <ws> <j> <index>` | Delete an entry (destructive) |
| `entries search <ws> <j> <query>` | Search entries |

### Shares — members (`/workjournal shares …`)

| Command | Description |
|---|---|
| `shares list <ws> <j>` | List members |
| `shares delete <ws> <j> <email>` | Remove a member (destructive — CLI resolves email to user_id) |

### Invites (`/workjournal invites …`)

| Command | Description |
|---|---|
| `invites list <ws> <j>` | List pending invitations |
| `invites new <ws> <j> <email>` | Invite a collaborator |
| `invites delete <ws> <j> <invitationId>` | Revoke an invitation (destructive) |

### Export (`/workjournal export …`)

| Command | Description |
|---|---|
| `export <ws> <j> [-f json\|md\|csv] [-p <path>]` | Export journal data |

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
| `config show` | Show resolved config (project + global), including the selected workspace + journal |

## Destructive guardrail

Before running any of these destructive patterns, the skill prints the resolved command and waits for the user to confirm:

- `entries delete <ws> <j> <index>`
- `shares delete <ws> <j> <email>`
- `invites delete <ws> <j> <id>`
- `journals delete <ws> <j>`

## Selection resolution

The shortcuts that operate on entries (write, search, last, check) need a `<ws>` + `<j>` pair. The skill resolves them by parsing the output of `workjournal config show`, which prints lines like:

```
Project config:
  Path: /path/to/.workjournal
  Workspace: acme
  Journal:   engineering
Global config:
  Workspace: acme
  Journal:   engineering
```

Project values take precedence over global values. If neither produces both slugs, the skill tells the user how to set them with `workjournal workspaces select` + `workjournal journals select`.

## Setup

There's no `init` shortcut — walk new users through it explicitly:

1. `/workjournal login` — browser OAuth, writes credentials.
2. `/workjournal workspaces list` — see what workspaces they belong to.
3. `/workjournal journals list <ws>` — see existing journals.
4. `/workjournal journals new <ws> "<name>"` — create one if needed.
5. `/workjournal journals select <ws> <j>` — make it the default.

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
