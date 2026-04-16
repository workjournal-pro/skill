---
name: workjournal
description: Development journal for AI coding agents. Write entries capturing decisions and context, search past work, and review recent entries. Use when the user invokes /workjournal, asks to log what was done, or wants to search past decisions.
compatibility: Requires Bash tool and internet access. Credentials stored at ~/.workjournal/credentials.json.
metadata:
  author: Venture Squad LTD
  version: "0.7"
---

You are handling a `/workjournal` command for the Workjournal skill. Parse the user's arguments and execute the appropriate action using the `workjournal` CLI.

## Arguments

The user invoked: `/workjournal {args}`

Parse `{args}` to determine which subcommand to run:

- No arguments → **write entry** (auto-generate title)
- Arguments that do NOT start with a known subcommand keyword → **write entry** with the arguments as the explicit title
- `search <query>` → **search entries**
- `last` or `last <N>` → **list recent entries**
- `check` → **find relevant entries**
- `login` → **authenticate**
- `init` → **initialize session**
- `help` → **print help**

---

## CLI Usage

All data operations use the `workjournal` CLI with the `--json` flag for machine-readable output. The CLI is invoked via:

```sh
npx --yes @workjournal/cli <command> --json
```

The CLI handles authentication (token refresh), journal resolution (`.workjournal` file or global config), and error handling internally.

---

## Authentication

Before running any command, check if credentials exist:

```sh
cat ~/.workjournal/credentials.json 2>/dev/null
```

If the file does not exist, tell the user: *"No credentials found. Run `/workjournal login` to authenticate."* and stop.

If credentials exist, proceed — the CLI handles token refresh automatically.

---

## Commands

### Write Entry (no arguments or explicit title)

Write a new journal entry capturing what was done in this conversation.

**Requires an active journal.** If no journal is configured, run `init` first.

1. Review the conversation so far to understand what work was performed.
2. If no title was provided, generate a concise title summarizing the work.
3. Create the entry:
   ```sh
   npx --yes @workjournal/cli journal entries write \
     -s "1-3 sentence summary including the title" \
     -b "Detailed markdown description of changes, file paths, decisions, trade-offs" \
     --json
   ```
4. After the entry is created, confirm to the user with the entry summary.

### `search <query>`

Search past journal entries for the given query.

1. Search:
   ```sh
   npx --yes @workjournal/cli journal entries search "QUERY" --json
   ```
2. Display the results in a readable format:
   - Entry summary and date
   - Relevant excerpt
   - If no results, let the user know and suggest broadening the search.

### `last [N]`

Show the N most recent journal entries (default: 1).

1. Parse N from the arguments. If not provided, default to 1.
2. List entries:
   ```sh
   npx --yes @workjournal/cli journal entries last N --json
   ```
3. Display each entry with:
   - Date and sequence number
   - Summary
   - If details are available, show what_changed as well.

### `check`

Find journal entries relevant to the current conversation context.

1. Analyze the current conversation to extract key topics, file paths, feature names, and technical terms.
2. Run multiple search calls with the most relevant keywords (2-4 searches):
   ```sh
   npx --yes @workjournal/cli journal entries search "KEYWORD" --json
   ```
3. Deduplicate and rank the results by relevance.
4. Present the most relevant entries:
   - Date and summary
   - Why it might be relevant to the current work
   - If no relevant entries are found, say so.

### `login`

Authenticate with the Workjournal API. The flow is two phases — *start* (print a URL) and *finish* (exchange the pasted code) — driven by the assistant on behalf of the user.

1. **Run the start command** to generate a PKCE-protected authorize URL:
   ```sh
   bash skills/journal/scripts/login.sh start
   ```
   If the script is not found at that path (e.g. the skill is installed globally), fall back to:
   ```sh
   npx --yes @workjournal/cli auth login start
   ```
   Capture the authorize URL from the command's stdout. It looks like `https://app.workjournal.pro/authorize?...&code_challenge=...&code_challenge_method=S256`.

2. **Tell the user**, in your own words, to:
   - Open the URL in any browser.
   - Log in if prompted.
   - Click **Approve** on the consent screen.
   - Copy the 8-character code shown on the page.
   - Paste the code back into this conversation.

   Show them the URL.

3. **Wait for the user's next message containing the code.** It will be 8 characters from the alphabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`. Trim whitespace; the CLI uppercases it for you.

4. **Run the finish command** with the code:
   ```sh
   bash skills/journal/scripts/login.sh finish <CODE>
   ```
   Or, in fallback mode:
   ```sh
   npx --yes @workjournal/cli auth login finish <CODE>
   ```

5. On success the CLI prints "Authenticated successfully!" and writes credentials to `~/.workjournal/credentials.json`. Confirm the login to the user. If the command exits non-zero, surface the error message verbatim and suggest re-running `login` to start over.

**Notes:**
- The code expires 5 minutes after `start` and is single-use. If the user delays too long, run `start` again to get a fresh URL.
- This flow does not require a browser on the same machine as the assistant — the user can open the URL on any device. It works equally well in SSH sessions, dev containers, and CI.

### `init`

Initialize Workjournal for the current session.

1. If no stored credentials exist, run the `login` flow first.
2. List available journals:
   ```sh
   npx --yes @workjournal/cli journals list --json
   ```
3. Ask the user to select a journal or create a new one.
4. To create a new journal:
   ```sh
   npx --yes @workjournal/cli journals new "Journal Name" --json
   ```
5. Select the journal:
   ```sh
   npx --yes @workjournal/cli journals select <JOURNAL_ID>
   ```
6. Confirm the selection to the user.

### `help`

Print the following command reference:

```text
/workjournal                          Write a new entry (auto-title from conversation)
/workjournal <title>                  Write a new entry with an explicit title
/workjournal search <query>           Search entries by keyword
/workjournal last [N]                 Show the last N entries (default 1)
/workjournal check                    Find entries relevant to current conversation
/workjournal login                    Authenticate with Workjournal
/workjournal init                     Initialize session and select journal
/workjournal help                     Print this help message
```

---

## Formatting Guidelines

- Use markdown formatting in all output.
- Keep summaries concise but informative.
- When displaying multiple entries, use clear visual separation (headings or horizontal rules).
- For dates, use a human-readable format (e.g., "March 15, 2026").
- When writing entries, be thorough in `what_changed` — future you will thank present you.
