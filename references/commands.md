# Workjournal Command Reference

The skill is a thin shell over the `workjournal` CLI (0.5.0+, slug-based). A small set of invocations are handled as *agent shortcuts* — picker menus and entry-orchestration that need either user interaction or context the CLI doesn't have. Everything else is a verbatim CLI passthrough. See `SKILL.md` for the dispatch logic.

## Agent shortcuts

| Command | Description |
|---|---|
| `/workjournal` | Write a new entry (title auto-generated from the conversation) |
| `/workjournal <title>` | Write a new entry with an explicit title |
| `/workjournal search <query>` | Resolve active selection, then call `workjournal entries search <ws> <j> <query>` |
| `/workjournal last [N]` | Resolve active selection, then call `workjournal entries last <ws> <j> [N]` — full body |
| `/workjournal check` | Orchestrates 2–4 search calls based on the current conversation |
| `/workjournal workspaces` | Numbered picker for switching the active workspace |
| `/workjournal journals` | Numbered picker (with substring filter) for journals; pick → submenu (select / delete / rename / change url) |
| `/workjournal login` | Two-phase browser OAuth (CLI can't run both phases unattended) |
| `/workjournal help` | Print command reference |

## CLI passthrough

When the first word + sub maps to a real CLI invocation (per the dispatch table in `SKILL.md`), the skill runs `workjournal <args>` verbatim — with `--json` appended for data-producing commands.

### Workspaces (`/workjournal workspaces …`)

| Command | Description |
|---|---|
| `workspaces list` | List workspaces you belong to |
| `workspaces get <ws>` | Show details of a workspace |
| `workspaces select <ws>` | Set active workspace in project-config |

(There is no `workspaces new` from the CLI — workspace creation is API-only until the paid-tier signup flow ships.)

### Selected journal (`/workjournal journal`)

| Command | Description |
|---|---|
| `journal` | Show selected journal details |

The old `journal entries …` / `journal shares …` etc. forms are gone. Use the top-level resource verbs below with explicit `<ws> <j>` positionals.

### Manage journals (`/workjournal journals …`)

| Command | Description |
|---|---|
| `journals list [<ws>]` | List journals in workspace (defaults to selected) |
| `journals list shared-with-me` | List journals shared with you from workspaces you don't own |
| `journals get <ws> <j>` | Show details of a journal |
| `journals new <ws> <name> [--slug <slug>]` | Create a journal |
| `journals select <ws> <j>` | Set active journal in config (global + project when available). Works for owned and shared journals — for shared, pass the real workspace slug returned by `journals list shared-with-me`. |
| `journals rename <ws> <j> <newName>` | Change the human name (slug stays) |
| `journals set-slug <ws> <j> <newSlug>` | Change the URL slug (breaks existing links — skill warns and confirms) |
| `journals delete <ws> <j>` | Delete a journal (destructive) |

### Entries (`/workjournal entries …`)

| Command | Description |
|---|---|
| `entries list <ws> <j>` | List entries (slim — no body) |
| `entries last <ws> <j> [N]` | Last N entries with full body |
| `entries get <ws> <j> <index>` | Fetch a single entry by index |
| `entries write <ws> <j> -t <title> -s <summary> -b <body>` | Create an entry (title required, ≤80 chars) |
| `entries update <ws> <j> <index> [-t <title>] [-s <summary>] [-b <file>\|-]` | Update title, summary, and/or body of an existing entry. At least one field required; `-b -` reads stdin |
| `entries delete <ws> <j> <index>` | Delete an entry (destructive) |
| `entries search <ws> <j> <query>` | Search entries |

### Shares — contributors (`/workjournal shares …`)

| Command | Description |
|---|---|
| `shares list <ws> <j>` | List contributors |
| `shares delete <ws> <j> <email>` | Remove a contributor (destructive — CLI resolves email to user_id) |

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

Before running any of these patterns, the skill prints the resolved command and waits for the user to confirm:

- `entries delete <ws> <j> <index>`
- `shares delete <ws> <j> <email>`
- `invites delete <ws> <j> <id>`
- `journals delete <ws> <j>`
- `journals set-slug <ws> <j> <newSlug>` — not strictly destructive, but old URLs return 404 immediately, so the skill warns and confirms before running.

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

Project values take precedence over global values. If neither produces both slugs, the skill points the user at `/workjournal journals` to pick one.

## Setup

There's no `init` shortcut — walk new users through it explicitly:

1. `/workjournal login` — browser OAuth, writes credentials.
2. `/workjournal workspaces` — pick the active workspace (interactive picker).
3. `/workjournal journals new <ws> "<name>"` — create a journal if they have none.
4. `/workjournal journals` — pick the new journal as active (interactive picker).

### Working with shared journals

A "shared journal" is one where the caller is a contributor in a workspace someone else owns. Two-step flow:

1. `workjournal journals list shared-with-me` — surfaces a two-column table of `(workspace_slug, journal_slug)` pairs. The workspace slug is the *real* one (e.g. `acme`), not `shared-with-me`. Owner email and role are still on the JSON payload via `--json`.
2. `workjournal journals select <real-workspace> <journal-slug>` — pin the journal using the workspace slug from step 1. `journals select` works identically for owned and shared journals because the underlying `journals_visible` view permits both. After this, all other commands (`workjournal`, `workjournal last`, `workjournal entries write`, etc.) work normally.

`shared-with-me` is a discovery-only slug — only `journals list` accepts it. Anywhere else (e.g. `workspaces select shared-with-me`, `journals get shared-with-me <j>`) it's treated as an unknown slug and produces a 404.

In the interactive `/workjournal journals` picker, a `(shared with me — K journals)` footer row appears when K > 0, pivoting into a sub-picker that runs the two-step above on the user's behalf (using the real workspace slug from the row to avoid slug-collision ambiguity).

## Authentication

Credentials are stored in the user config directory (`~/.config/workjournal/credentials.json` on Linux/macOS, `%APPDATA%\workjournal\credentials.json` on Windows; override with `WORKJOURNAL_CONFIG_DIR`):

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "expires_at": "2026-04-07T12:00:00.000Z"
}
```

Use `/workjournal login` or `bash skills/workjournal/scripts/login.sh` to authenticate via browser-based OAuth. The CLI refreshes tokens automatically before each call.
