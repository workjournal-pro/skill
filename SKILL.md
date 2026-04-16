---
name: workjournal
description: Development journal for AI coding agents. Write entries capturing decisions and context, search past work, review recent entries, and manage journals/members/invitations through the Workjournal CLI. Use when the user invokes /workjournal, asks to log what was done, or wants to search past decisions.
compatibility: Requires Bash tool and internet access. Credentials stored at ~/.workjournal/credentials.json.
metadata:
  author: Venture Squad LTD
  version: "0.8"
---

You are handling a `/workjournal` command for the Workjournal skill. The skill is a thin shell over the `workjournal` CLI: most invocations pass straight through to the CLI, with a small set of ergonomic shortcuts where the CLI alone can't do the job (because they need the agent to synthesise a title, correlate with the conversation, or drive a multi-step interactive flow).

**Never call MCP tools for journal operations.** This skill always runs the CLI. The MCP server exists for other clients (Claude Desktop, ChatGPT, Perplexity) that don't load skills.

## Dispatch

The user invoked: `/workjournal {args}`

Split `{args}` on the first whitespace to get `keyword` and the remainder. Route by `keyword`:

| First word | Behaviour |
|---|---|
| *(empty)* | **Shortcut** — write entry with an auto-generated title |
| `search`, `last`, `check`, `login`, `help` | **Shortcut** — see sections below |
| `journal`, `journals`, `auth`, `config` | **CLI passthrough** — run `workjournal {args}` verbatim |
| anything else | **Shortcut** — write entry, using `{args}` as the title |

## CLI invocation

Every call goes through the published CLI:

```sh
npx --yes @workjournal/cli <subcommand> --json
```

Append `--json` to any data-producing command so you get machine-readable output you can parse and reformat. The CLI handles authentication, token refresh, journal resolution (`.workjournal` file or global config), and error handling internally — do not try to duplicate that logic here.

## Authentication precheck

Before any shortcut or passthrough that needs auth, confirm credentials exist:

```sh
cat ~/.workjournal/credentials.json 2>/dev/null
```

If the file is missing, tell the user: *"No credentials found. Run `/workjournal login` to authenticate."* and stop. Otherwise proceed — the CLI refreshes expired tokens itself.

## Shortcuts

### Write entry — `(no args)` or `<title>`

The default action when the first word isn't a recognised keyword. Writes a journal entry summarising the current conversation.

1. Review the conversation so far. Identify what work was performed — files touched, decisions made, bugs fixed, trade-offs accepted.
2. If the user provided a title (`/workjournal Some title`), use it. Otherwise synthesise a concise 3–8 word title that captures the outcome, not the process.
3. Create the entry:
   ```sh
   npx --yes @workjournal/cli journal entries write \
     -s "1–3 sentence summary including the title" \
     -b "Detailed markdown body: file paths, decisions, rationale, trade-offs" \
     --json
   ```
4. Parse the JSON response and confirm with the user — quote the assigned index (`#N`) and summary line back.

### `search <query>`

Short alias for entry search.

```sh
npx --yes @workjournal/cli journal entries search "QUERY" --json
```

Render results as a compact list: `#N (date) summary`. On empty results, say so and suggest broader terms.

### `last [N]`

Full-body view of the N most recent entries (default 1).

```sh
npx --yes @workjournal/cli journal entries last N --json
```

Display each entry with its index, date, summary, and `what_changed` body. Separate entries with a horizontal rule.

### `check`

Find past entries relevant to the current conversation. The CLI has no native "conversation-aware search" command, so orchestrate 2–4 search calls:

1. Extract 2–4 key terms from the conversation (file names, feature names, error strings, technical concepts).
2. For each term:
   ```sh
   npx --yes @workjournal/cli journal entries search "TERM" --json
   ```
3. Deduplicate by entry ID. Rank by how many search terms each entry matched.
4. Present the top results, each with a one-line "why this might be relevant" annotation tied to the matched term.
5. If nothing lands, say so briefly — don't invent relevance.

### `login`

Two-phase interactive login. The CLI can't run both phases unattended because the user has to open a browser and paste a code back.

1. **Start** — generate the PKCE-protected authorize URL:
   ```sh
   bash skills/journal/scripts/login.sh start
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
   bash skills/journal/scripts/login.sh finish <CODE>
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
/workjournal login                              Authenticate with Workjournal (two-phase browser flow)

Passthrough — run the CLI command verbatim:
  /workjournal journal <resource> <verb>        entries / shares / invites / export for the selected journal
  /workjournal journals list|new|delete|select  Manage journals
  /workjournal journals <id> <resource> <verb>  Same as `/workjournal journal …` against an explicit journal
  /workjournal auth login|logout|whoami|status
  /workjournal config show
```

## CLI passthrough

When the first word is `journal`, `journals`, `auth`, or `config`:

1. **Destructive guard** — if the remaining args name a destructive operation, *show the resolved command to the user and ask for confirmation before running it*. The four destructive patterns are:
   - `journal entries delete <index>`
   - `journal shares delete <email>`
   - `journal invites delete <id>`
   - `journals delete <id>`
   Also catch the explicit-id form: `journals <id> entries delete …`, etc.
   Example confirmation: *"About to run `workjournal journal entries delete 4` — this removes the entry permanently. Confirm?"* If the user doesn't confirm, stop.

2. Run the command verbatim, appending `--json` for data-producing invocations (list, get, show):
   ```sh
   npx --yes @workjournal/cli {args} --json
   ```
   For mutation commands where `--json` changes output format helpfully (write, new, create), include it. For commands with no meaningful JSON representation (`auth logout`, `config show`), run without `--json`.

3. Parse the response. Format it for the user — table for lists, single-record view for gets, confirmation line for mutations.

4. On non-zero exit, show the CLI's stderr verbatim. Do not try to guess at fixes.

### Passthrough examples

| User types | Skill runs |
|---|---|
| `/workjournal journal entries get 5` | `workjournal journal entries get 5 --json` |
| `/workjournal journal shares list` | `workjournal journal shares list --json` |
| `/workjournal journal invites new alice@example.com` | `workjournal journal invites new alice@example.com --json` |
| `/workjournal journal export -f md -p /tmp/out.md` | `workjournal journal export -f md -p /tmp/out.md` |
| `/workjournal journals list` | `workjournal journals list --json` |
| `/workjournal journals new "My Project"` | `workjournal journals new "My Project" --json` |
| `/workjournal journals delete 7f3a…` | *confirm* → `workjournal journals delete 7f3a…` |
| `/workjournal auth whoami` | `workjournal auth whoami` |
| `/workjournal config show` | `workjournal config show` |

## Setup guidance

There's no `/workjournal init` shortcut — it conflated auth, journal creation, and journal selection into one opaque flow. If the user needs to get set up from scratch, walk them through it explicitly:

1. `/workjournal login` — browser OAuth, writes credentials.
2. `/workjournal journals list` — see what they already have access to.
3. `/workjournal journals new "<name>"` — create a journal if they have none.
4. `/workjournal journals select <id>` — make it the default for this machine.

Afterwards `/workjournal` (no args) will write to that journal.

## Formatting

- Markdown output. Use tables for lists, horizontal rules between entry bodies, dates in human form (e.g. "April 16, 2026").
- Keep summaries tight. Verbose bodies in `what_changed` are fine — they're a record for future-you.
- Never include bearer credentials (invitation tokens, access tokens, refresh tokens) in your output. If a CLI response contains one, redact it or omit that field.
