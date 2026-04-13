---
name: journal
description: Development journal for AI coding agents. Write entries capturing decisions and context, search past work, and review recent entries. Use when the user invokes /journal, asks to log what was done, or wants to search past decisions.
compatibility: Requires Bash tool (curl) and internet access. Credentials stored at ~/.workjournal/credentials.json.
metadata:
  author: Venture Squad LTD
  version: "0.5"
---

You are handling a `/journal` command for the Workjournal skill. Parse the user's arguments and execute the appropriate action by calling the Workjournal REST API via curl.

## Arguments

The user invoked: `/journal {args}`

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

## Authentication

All API calls require a Bearer token. Before any API call, follow this procedure:

1. Read `~/.workjournal/credentials.json`. It contains:
   ```json
   {
     "access_token": "...",
     "refresh_token": "...",
     "expires_at": "2026-04-07T12:00:00.000Z"
   }
   ```
2. If the file does not exist, tell the user: *"No credentials found. Run `/journal login` to authenticate."* and stop.
3. Compare `expires_at` to the current date/time. If the token is expired, refresh it:
   ```sh
   curl -s -X POST https://api.workjournal.pro/v1/auth/refresh \
     -H 'Content-Type: application/json' \
     -d '{"refresh_token":"REFRESH_TOKEN_HERE"}'
   ```
   The response contains `{"access_token":"...","refresh_token":"...","expires_in":3600}`. Compute new `expires_at` and write the updated credentials back to `~/.workjournal/credentials.json` (with file mode 600).
4. If the refresh call returns a non-200 status, tell the user: *"Session expired. Run `/journal login` to re-authenticate."* and stop.
5. Use the `access_token` as the Bearer token for all subsequent API calls.

Set these values for use in commands below:
- `API_URL=https://api.workjournal.pro`
- `TOKEN=<access_token from credentials>`

---

## Commands

### Write Entry (no arguments or explicit title)

Write a new journal entry capturing what was done in this conversation.

**Requires an active journal.** If no journal has been selected in this session, list journals first and ask the user to pick one.

1. Review the conversation so far to understand what work was performed.
2. If no title was provided, generate a concise title summarizing the work.
3. List journals if needed:
   ```sh
   curl -s "$API_URL/v1/journals" -H "Authorization: Bearer $TOKEN"
   ```
4. Create the entry:
   ```sh
   curl -s -X POST "$API_URL/v1/journals/$JOURNAL_ID/entries" \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "summary": "1-3 sentence summary including the title",
       "what_changed": "Detailed markdown description of changes, file paths, decisions, trade-offs",
       "client": "claude-code"
     }'
   ```
5. After the entry is created, confirm to the user with the entry summary.

### `search <query>`

Search past journal entries for the given query.

**Requires an active journal.**

1. URL-encode the query string.
2. Search:
   ```sh
   curl -s "$API_URL/v1/journals/$JOURNAL_ID/entries/search?q=QUERY" \
     -H "Authorization: Bearer $TOKEN"
   ```
3. Display the results in a readable format:
   - Entry summary and date
   - Relevant excerpt
   - If no results, let the user know and suggest broadening the search.

### `last [N]`

Show the N most recent journal entries (default: 1).

**Requires an active journal.**

1. Parse N from the arguments. If not provided, default to 1.
2. List entries:
   ```sh
   curl -s "$API_URL/v1/journals/$JOURNAL_ID/entries?limit=N" \
     -H "Authorization: Bearer $TOKEN"
   ```
3. Display each entry with:
   - Date and sequence number
   - Summary
   - If details are available, show what_changed as well.

### `check`

Find journal entries relevant to the current conversation context.

**Requires an active journal.**

1. Analyze the current conversation to extract key topics, file paths, feature names, and technical terms.
2. Run multiple search calls with the most relevant keywords (2-4 searches):
   ```sh
   curl -s "$API_URL/v1/journals/$JOURNAL_ID/entries/search?q=KEYWORD" \
     -H "Authorization: Bearer $TOKEN"
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
   npx --yes @workjournal/cli login start
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
   npx --yes @workjournal/cli login finish <CODE>
   ```

5. On success the CLI prints "Authenticated successfully!" and writes credentials to `~/.workjournal/credentials.json`. Confirm the login to the user. If the command exits non-zero, surface the error message verbatim and suggest re-running `login` to start over.

**Notes:**
- The code expires 5 minutes after `start` and is single-use. If the user delays too long, run `start` again to get a fresh URL.
- This flow does not require a browser on the same machine as the assistant — the user can open the URL on any device. It works equally well in SSH sessions, dev containers, and CI.
- In Claude.ai web and Cowork sandboxes, `~/.workjournal/credentials.json` does not persist between conversations. Those environments should use the Workjournal MCP server (`@workjournal/mcp-server`) instead, which stores credentials in the MCP client config.

### `init`

Initialize Workjournal for the current session.

1. If no stored credentials exist, run the `login` flow first.
2. List available journals:
   ```sh
   curl -s "$API_URL/v1/journals" -H "Authorization: Bearer $TOKEN"
   ```
3. Ask the user to select a journal or create a new one.
4. To create a new journal:
   ```sh
   curl -s -X POST "$API_URL/v1/journals" \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"name": "Journal Name", "description": "Optional description"}'
   ```
5. Remember the selected journal for the remainder of this conversation.

### `help`

Print the following command reference:

```
/journal                          Write a new entry (auto-title from conversation)
/journal <title>                  Write a new entry with an explicit title
/journal search <query>           Search entries by keyword
/journal last [N]                 Show the last N entries (default 1)
/journal check                    Find entries relevant to current conversation
/journal login                    Authenticate with Workjournal
/journal init                     Initialize session and select journal
/journal help                     Print this help message
```

---

## API Reference

Base URL: `https://api.workjournal.pro`

All endpoints require `Authorization: Bearer <token>` header.

| Method | Endpoint | Body / Query | Description |
|--------|----------|-------------|-------------|
| GET | `/v1/journals` | — | List journals |
| GET | `/v1/journals/:id` | — | Get journal details |
| POST | `/v1/journals` | `{"name", "description?"}` | Create journal |
| GET | `/v1/journals/:id/entries` | `?limit=N&offset=N` | List entries |
| POST | `/v1/journals/:id/entries` | `{"summary", "what_changed", "client?"}` | Create entry |
| GET | `/v1/journals/:id/entries/search` | `?q=query` | Search entries |
| POST | `/v1/auth/refresh` | `{"refresh_token"}` | Refresh access token |

List endpoints return: `{"data": [...], "total": N, "offset": N, "limit": N}`

---

## Formatting Guidelines

- Use markdown formatting in all output.
- Keep summaries concise but informative.
- When displaying multiple entries, use clear visual separation (headings or horizontal rules).
- For dates, use a human-readable format (e.g., "March 15, 2026").
- When writing entries, be thorough in `what_changed` -- future you will thank present you.
