---
name: journal
description: Development journal for AI coding agents. Write entries capturing decisions and context, search past work, and review recent entries. Use when the user invokes /journal, asks to log what was done, or wants to search past decisions.
compatibility: Requires @workjournal/mcp-server MCP tools (create_entry, search_entries, list_entries, list_journals, get_journal, create_journal)
metadata:
  author: humanesky
  version: "0.1"
---

You are handling a `/journal` command for the Workjournal skill. Parse the user's arguments and execute the appropriate action using the workjournal MCP tools.

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

## Commands

### Write Entry (no arguments or explicit title)

Write a new journal entry capturing what was done in this conversation.

**Requires an active journal.** If no journal has been selected in this session, run `list_journals` first and ask the user to pick one.

1. Review the conversation so far to understand what work was performed.
2. If no title was provided, generate a concise title summarizing the work.
3. Call the `create_entry` MCP tool with:
   - `journal_id` (required): The active journal's ID.
   - `summary` (required): A 1-3 sentence summary of what was accomplished. Include the title here.
   - `what_changed` (required): A detailed description of the changes made. Include file paths, function names, and specific modifications. Use Markdown formatting. Include any relevant background, decisions made, trade-offs considered, or links to issues/PRs here.

4. After the entry is created, confirm to the user with the entry summary.

### `search <query>`

Search past journal entries for the given query.

**Requires an active journal.**

1. Call the `search_entries` MCP tool with `journal_id` and the `query` string.
2. Display the results in a readable format:
   - Entry summary and date
   - Relevant excerpt
   - If no results, let the user know and suggest broadening the search.

### `last [N]`

Show the N most recent journal entries (default: 1).

**Requires an active journal.**

1. Parse N from the arguments. If not provided, default to 1.
2. Call the `list_entries` MCP tool with `journal_id` and `limit` set to N.
3. Display each entry with:
   - Date and sequence number
   - Summary
   - If details are available, show what_changed as well.

### `check`

Find journal entries relevant to the current conversation context.

**Requires an active journal.**

1. Analyze the current conversation to extract key topics, file paths, feature names, and technical terms.
2. Run multiple `search_entries` calls with `journal_id` and the most relevant keywords (2-4 searches).
3. Deduplicate and rank the results by relevance.
4. Present the most relevant entries:
   - Date and summary
   - Why it might be relevant to the current work
   - If no relevant entries are found, say so.

### `login`

Authenticate with the Workjournal API.

1. Tell the user you will run the login command.
2. Execute `npx @workjournal/cli login` via the shell.
3. This opens a browser window for OAuth login and stores credentials locally.
4. If the browser cannot open (SSH, containers), the CLI prints a URL for the user to visit manually.
5. After successful login, confirm the authenticated user.

### `init`

Initialize Workjournal for the current session.

1. If no stored credentials exist, run the `login` flow first.
2. Call `list_journals` to show available journals.
3. Ask the user to select a journal or create a new one.
4. Remember the selected journal for the remainder of this conversation.

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

## MCP Tools Reference

The following MCP tools are available from the workjournal server:

- `create_entry` — Create a new journal entry. Required: `journal_id`, `summary`, `what_changed`.
- `search_entries` — Search entries by keyword. Required: `journal_id`, `query`.
- `list_entries` — List recent entries. Required: `journal_id`. Optional: `limit`.
- `list_journals` — List available journals.
- `get_journal` — Get details of a specific journal. Required: `journal_id`.
- `create_journal` — Create a new journal. Required: `name`. Optional: `description`.

---

## Formatting Guidelines

- Use markdown formatting in all output.
- Keep summaries concise but informative.
- When displaying multiple entries, use clear visual separation (headings or horizontal rules).
- For dates, use a human-readable format (e.g., "March 15, 2026").
- When writing entries, be thorough in `what_changed` -- future you will thank present you.
