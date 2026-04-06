# Workjournal Skill

An [Open Agent Skill](https://agentskills.io) for [Workjournal](https://workjournal.pro) — a cloud-hosted development journal for AI agents and developers.

## What it does

The Workjournal skill provides `/journal` commands to write entries, search past decisions, and review recent work. It works with any agent that supports the [Open Agent Skills](https://agentskills.io) format.

## Installation

### From a marketplace

If your agent has a skill marketplace, search for **Workjournal** and install it directly.

### From GitHub releases

Download the latest release zip from the [Releases](https://github.com/workjournal-pro/skill/releases) page and extract it into your agent's skills directory.

For Claude Code:

```bash
curl -sL https://github.com/workjournal-pro/skill/releases/latest/download/skill.zip -o /tmp/workjournal-skill.zip
unzip /tmp/workjournal-skill.zip -d skills/journal
```

### Manual clone

```bash
git clone https://github.com/workjournal-pro/skill.git skills/journal
```

## Prerequisites

- An account at [app.workjournal.pro](https://app.workjournal.pro)

## Quick start

1. Install the skill (see above)
2. Run `/journal login` to authenticate via browser-based OAuth
3. Run `/journal` to write your first entry

## Commands

| Command | Description |
|---------|-------------|
| `/journal` | Write a new entry (auto-title from conversation) |
| `/journal <title>` | Write a new entry with explicit title |
| `/journal search <query>` | Search past entries |
| `/journal last [N]` | Show recent entries |
| `/journal check` | Find entries relevant to current work |
| `/journal login` | Authenticate with Workjournal |
| `/journal init` | Initialize session and select journal |
| `/journal help` | Print command reference |

## Compatible agents

This skill follows the Open Agent Skills specification and works with Claude Code, Cursor, GitHub Copilot, JetBrains Junie, Gemini CLI, and [many more](https://agentskills.io).

## Links

- [Workjournal](https://workjournal.pro)
- [Get Started](https://workjournal.pro/docs/get-started)
- [Web App](https://app.workjournal.pro)
- [Open Agent Skills](https://agentskills.io)
