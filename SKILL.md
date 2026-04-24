---
name: workjournal
description: Development journal for AI coding agents. Write entries capturing decisions and context, search past work, review recent entries, and manage workspaces/journals/members/invitations through the Workjournal CLI. Use when the user invokes /workjournal, asks to log what was done, or wants to search past decisions.
compatibility: Requires Bash tool and internet access. Credentials stored at ~/.workjournal/credentials.json.
metadata:
  author: Venture Squad LTD
  version: "1.1"
---

You are handling a `/workjournal` command for the Workjournal skill. The skill is a thin shell over the `workjournal` CLI: most invocations pass straight through to the CLI, with a small set of ergonomic shortcuts where the CLI alone can't do the job (because they need the agent to synthesise a title, correlate with the conversation, or drive an interactive picker).

**Never call MCP tools for journal operations.** This skill always runs the CLI. The MCP server exists for other clients (Claude Desktop, ChatGPT, Perplexity) that don't load skills.

## Dispatch

The user invoked: `/workjournal {args}`

Split `{args}` on the first whitespace to get `keyword` and the remainder. Route by `keyword`:

| First word | Sub | Behaviour |
|---|---|---|
| *(empty)* | — | **Shortcut** — write entry with an auto-generated title |
| `search`, `last`, `check`, `login`, `help` | — | **Shortcut** — see sections below |
| `workspaces` | *(none)* | **Shortcut** — workspace picker (see below) |
| `workspaces` | `list` / `get` / `select` | **CLI passthrough** |
| `journals` | *(none)* | **Shortcut** — journal picker (see below) |
| `journals` | `list` / `get` / `new` / `delete` / `select` / `rename` / `set-slug` | **CLI passthrough** |
| `journal`, `entries`, `shares`, `invites`, `export`, `auth`, `config` | any | **CLI passthrough** — run `workjournal {args}` verbatim |
| anything else | — | **Shortcut** — write entry, using `{args}` as the title |

## CLI invocation

Every call goes through the published CLI:

```sh
npx --yes @workjournal/cli <subcommand> --json
```

Append `--json` to any data-producing command so you get machine-readable output you can parse and reformat. The CLI handles authentication, token refresh, slug resolution from project-config, and error handling internally — do not try to duplicate that logic here.

## Authentication precheck

Before any shortcut or passthrough that needs auth, confirm credentials exist:

```sh
cat ~/.workjournal/credentials.json 2>/dev/null
```

If the file is missing, tell the user: *"No credentials found. Run `/workjournal login` to authenticate."* and stop. Otherwise proceed — the CLI refreshes expired tokens itself.

## Selection precheck (for write/search/last/check shortcuts)

The shortcuts that operate on entries need a `<workspaceSlug>` + `<journalSlug>` pair. Resolve the active selection by running:

```sh
npx --yes @workjournal/cli config show
```

Parse the output for `Workspace:` and `Journal:` lines. Use the project-config values if present; otherwise fall back to global-config values. If neither produces both slugs, tell the user:

*"No journal selected. Run `/workjournal journals` to pick one."*

Once resolved, reuse the same slugs across the rest of the skill invocation — don't re-query.

## Shortcuts

### Write entry — `(no args)` or `<title>`

The default action when the first word isn't a recognised keyword. Writes a journal entry summarising the current conversation.

1. Run the auth precheck and the selection precheck. Capture `<ws>` and `<j>`.
2. Review the conversation so far. Identify what work was performed — files touched, decisions made, bugs fixed, trade-offs accepted.
3. If the user provided a title (`/workjournal Some title`), use it. Otherwise synthesise a concise 3–8 word title that captures the outcome, not the process.
4. Create the entry:
   ```sh
   npx --yes @workjournal/cli entries write <ws> <j> \
     -s "1–3 sentence summary including the title" \
     -b "Detailed markdown body: file paths, decisions, rationale, trade-offs" \
     --json
   ```
5. Parse the JSON response and confirm with the user — quote the assigned index (`#N`) and summary line back.

### `search <query>`

Short alias for entry search.

```sh
npx --yes @workjournal/cli entries search <ws> <j> "QUERY" --json
```

Render results as a compact list: `#N (date) summary`. On empty results, say so and suggest broader terms.

### `last [N]`

Full-body view of the N most recent entries (default 1).

```sh
npx --yes @workjournal/cli entries last <ws> <j> N --json
```

Display each entry with its index, date, summary, and `what_changed` body. Separate entries with a horizontal rule.

### `check`

Find past entries relevant to the current conversation. The CLI has no native "conversation-aware search" command, so orchestrate 2–4 search calls:

1. Run the selection precheck once to capture `<ws>` + `<j>`.
2. Extract 2–4 key terms from the conversation (file names, feature names, error strings, technical concepts).
3. For each term:
   ```sh
   npx --yes @workjournal/cli entries search <ws> <j> "TERM" --json
   ```
4. Deduplicate by entry index. Rank by how many search terms each entry matched.
5. Present the top results, each with a one-line "why this might be relevant" annotation tied to the matched term.
6. If nothing lands, say so briefly — don't invent relevance.

### `workspaces` (no further args) — workspace picker

An interactive picker for switching the active workspace. Drives a single round-trip through the user's chat: render a numbered list, wait for a number, run `select`.

1. Auth precheck.
2. Fetch the list:
   ```sh
   npx --yes @workjournal/cli workspaces list --json
   ```
3. Read the current active workspace by parsing `workjournal config show` (the `Workspace:` line under either Project or Global).
4. Render a numbered list to the user. Use `→` to mark the current selection. Example:
   ```text
   Workspaces:
     [1] → acme               (Acme Inc — owner)
     [2]   personal           (Personal — owner)

   Reply with a number to select.
   ```
5. **Wait for the user's next message.** Parse it as the picked number.
6. Resolve the chosen workspace's slug, then run:
   ```sh
   npx --yes @workjournal/cli workspaces select <slug>
   ```
7. Confirm: *"Active workspace: `<slug>`."*

If the list is empty (which shouldn't happen — every user has at least one), surface the error and stop.

### `journals` (no further args) — journal picker

Interactive picker for the active workspace's journals, with a substring filter and a four-action submenu per journal.

1. Auth precheck. Resolve the active workspace via `config show`. If no active workspace is set, run the workspace picker first (or tell the user to run `/workjournal workspaces`).
2. Fetch the journals:
   ```sh
   npx --yes @workjournal/cli journals list <ws> --json
   ```
3. Read the current active journal from `config show` (the `Journal:` line).
4. Render a numbered list with `slug` and `name`. Mark the current journal with `→`. Example:
   ```text
   Journals in acme:
     [1] → engineering        (Engineering Notes)
     [2]   product            (Product Decisions)
     [3]   ops                (Ops Runbook)

   Reply with a number to pick a journal, or type a substring to filter.
   ```
5. **Wait for the user's reply.**
   - If the reply parses as a number that maps to a row, that journal is picked — go to step 6.
   - Otherwise treat the reply as a substring filter. Re-render the list filtered to journals where `slug` or `name` contains the substring (case-insensitive). Show a fresh numbered list and prompt again.
   - Loop step 5 until a number is picked or the user says "cancel".
6. Render the submenu:
   ```text
   <ws>/<slug> — what next?
     [1] select         — make this the active journal
     [2] delete         — destructive, will ask to confirm
     [3] rename         — change the human name (slug stays)
     [4] change url     — change the slug (breaks existing links)
   ```
7. **Wait for the user's reply.** Resolve the action:
   - **select** → run `workjournal journals select <ws> <slug>`. Confirm: *"Active journal: `<ws>/<slug>`."*
   - **delete** → confirm again with the user (*"Delete `<ws>/<slug>` and all its entries? This cannot be undone."*). If confirmed, run `workjournal journals delete <ws> <slug>`.
   - **rename** → ask: *"New name?"*. On reply, run `workjournal journals rename <ws> <slug> "<newName>" --json`. Confirm with the new name.
   - **change url** → warn explicitly: *"Changing the slug breaks any existing links — old URLs to `<ws>/<slug>` will start returning 404. New slug?"*. After receiving `<newSlug>`, ask for explicit confirmation: *"About to change `<ws>/<slug>` to `<ws>/<newSlug>`. This will break old links. Confirm?"*. Only run `workjournal journals set-slug <ws> <slug> <newSlug> --json` on an affirmative reply; otherwise abort and tell the user the slug change was cancelled.

If the journal list is empty, suggest `/workjournal journals new <ws> "<name>"` to create one.

### `login`

Two-phase interactive login. The CLI can't run both phases unattended because the user has to open a browser and paste a code back.

1. **Start** — generate the PKCE-protected authorize URL:
   ```sh
   bash skills/workjournal/scripts/login.sh start
   ```
   If the script isn't at that path (e.g. the skill is installed globally), fall back to:
   ```sh
   npx --yes @workjournal/cli auth login start
   ```
   Capture the authorize URL from stdout. It looks like `https://app.workjournal.pro/authorize?...&code_challenge=...&code_challenge_method=S256`.

2. **Tell the user**, in your own words:
   - Open the URL in any browser (it doesn't need to be on this machine).
   - Log in, click **Approve** on the consent screen.
   - Copy the 8-character code shown.
   - Paste it back into this conversation.

   Show them the URL.

3. **Wait for their next message** containing the code. It's 8 characters from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`. Trim whitespace; the CLI uppercases it automatically.

4. **Finish** with the code:
   ```sh
   bash skills/workjournal/scripts/login.sh finish <CODE>
   ```
   Or fallback:
   ```sh
   npx --yes @workjournal/cli auth login finish <CODE>
   ```

5. On success the CLI writes credentials to `~/.workjournal/credentials.json` and prints "Authenticated successfully!". Confirm back. On non-zero exit, surface the error verbatim and suggest re-running `login` for a fresh code.

Notes:
- The code expires 5 minutes after `start` and is single-use.
- Works in SSH sessions, dev containers, and CI — the URL can be opened on any device.

### `help`

Print the reference block below and stop:

```text
/workjournal                                    Write a new entry (auto-title from conversation)
/workjournal <title>                            Write a new entry with an explicit title
/workjournal search <query>                     Search entries by keyword
/workjournal last [N]                           Show the last N entries (default 1, full body)
/workjournal check                              Find entries relevant to the current conversation
/workjournal workspaces                         Interactive workspace picker
/workjournal journals                           Interactive journal picker (select / delete / rename / change url)
/workjournal login                              Authenticate with Workjournal (two-phase browser flow)

Passthrough — run the CLI command verbatim:
  /workjournal workspaces list|get|select       Manage workspaces
  /workjournal journal                          Show selected journal details
  /workjournal journals list|get|new|delete|select|rename|set-slug   Manage journals (most take <ws> <j>)
  /workjournal entries list|write|last|get|delete|search <ws> <j> …  Entries within a journal
  /workjournal shares list|delete <ws> <j> …    Members of a journal
  /workjournal invites list|new|delete <ws> <j> …  Pending invitations
  /workjournal export <ws> <j> [-f json|md|csv] [-p <path>]
  /workjournal auth login|logout|whoami|status
  /workjournal config show
```

## CLI passthrough

When the routing rules above resolve to passthrough:

1. **Destructive guard** — if the remaining args name a destructive operation, *show the resolved command to the user and ask for confirmation before running it*. The destructive patterns are:
   - `entries delete <ws> <j> <index>`
   - `shares delete <ws> <j> <email>`
   - `invites delete <ws> <j> <id>`
   - `journals delete <ws> <j>`
   - `journals set-slug <ws> <j> <newSlug>` — not strictly destructive, but old URLs 404 immediately, so warn and confirm.

   Example confirmation: *"About to run `workjournal entries delete acme engineering 4` — this removes the entry permanently. Confirm?"* If the user doesn't confirm, stop.

2. Run the command verbatim, appending `--json` for data-producing invocations (list, get, show):
   ```sh
   npx --yes @workjournal/cli {args} --json
   ```
   For mutation commands where `--json` changes output format helpfully (write, new, rename, set-slug), include it. For commands with no meaningful JSON representation (`auth logout`, `config show`), run without `--json`.

3. Parse the response. Format it for the user — table for lists, single-record view for gets, confirmation line for mutations.

4. On non-zero exit, show the CLI's stderr verbatim. Do not try to guess at fixes.

### Passthrough examples

| User types | Skill runs |
|---|---|
| `/workjournal entries get acme engineering 5` | `workjournal entries get acme engineering 5 --json` |
| `/workjournal shares list acme engineering` | `workjournal shares list acme engineering --json` |
| `/workjournal invites new acme engineering alice@example.com` | `workjournal invites new acme engineering alice@example.com --json` |
| `/workjournal export acme engineering -f md -p /tmp/out.md` | `workjournal export acme engineering -f md -p /tmp/out.md` |
| `/workjournal workspaces list` | `workjournal workspaces list --json` |
| `/workjournal journals list acme` | `workjournal journals list acme --json` |
| `/workjournal journals new acme "Engineering"` | `workjournal journals new acme "Engineering" --json` |
| `/workjournal journals rename acme staging "Staging Notes"` | `workjournal journals rename acme staging "Staging Notes" --json` |
| `/workjournal journals set-slug acme staging staging-notes` | *warn + confirm* → `workjournal journals set-slug acme staging staging-notes --json` |
| `/workjournal journals delete acme staging` | *confirm* → `workjournal journals delete acme staging` |
| `/workjournal auth whoami` | `workjournal auth whoami` |
| `/workjournal config show` | `workjournal config show` |

## Setup guidance

If the user needs to get set up from scratch, walk them through it explicitly:

1. `/workjournal login` — browser OAuth, writes credentials.
2. `/workjournal workspaces` — pick the active workspace (every signed-in user has at least their personal one).
3. `/workjournal journals new <ws> "<name>"` — create a journal if they have none. Slug is derived from name; `--slug <slug>` overrides.
4. `/workjournal journals` — pick the new journal as active.

Afterwards `/workjournal` (no args) will write to that journal.

## Formatting

- Markdown output. Use tables for lists, horizontal rules between entry bodies, dates in human form (e.g. "April 23, 2026").
- Keep summaries tight. Verbose bodies in `what_changed` are fine — they're a record for future-you.
- Never include bearer credentials (invitation tokens, access tokens, refresh tokens) in your output. If a CLI response contains one, redact it or omit that field.
