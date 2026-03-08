# Project Instructions - Agent Workflows

> **Note**: This is the main orchestrator file. For detailed guides, see `AgentUsage/README.md`

---

## Project Purpose

Claw is a personal OpenClaw agent setup — configuration, personality (SOUL.md), and security hardening for a locally-hosted AI assistant on Mac Mini M4. The agent processes communications, surfaces financial alerts, sends daily briefings, and manages reminders/calendar.

## Tech Stack

- **Platform**: OpenClaw (Node.js-based personal AI agent)
- **Hardware**: Mac Mini M4 32GB
- **Models**: MiniMax M2.5 (primary), Gemini 2.5 Flash Lite (heartbeat/fallback) via OpenRouter
- **Channels**: iMessage, Telegram
- **Skills**: Apple Reminders, Apple Calendar
- **OS**: macOS (dedicated `openclaw` Standard user)

## Architecture Notes

- **Config-driven project** — no application code; deliverables are SOUL.md, openclaw.json, and security docs
- **SOUL.md** defines agent behavior: priority tiers (financial > action-required > low > spam), communication style, security rules, trusted/untrusted input sources
- **Security posture**: gateway localhost-only, exec/shell/browser denied, all write actions require approval, email content treated as untrusted data
- **Deployment target**: `~/.openclaw/` on the dedicated macOS user

---

## Essential Instructions (Always Follow)

### Core Behavior
- Do what has been asked; nothing more, nothing less
- NEVER create files unless absolutely necessary for achieving your goal
- ALWAYS prefer editing existing files to creating new ones
- NEVER proactively create documentation files (*.md) or README files unless explicitly requested

### Naming Conventions
- **Directories**: Use CamelCase (e.g., `VideoProcessor`, `AudioTools`, `DataAnalysis`)
- **Date-based paths**: Use skewer-case with YYYY-MM-DD (e.g., `logs-2025-01-15`, `backup-2025-12-31`)
- **No spaces or underscores** in directory names (except date-based paths)

### TODO Management
- **Always check `TODOS.md` first** when starting a task or session
- **Check `COMPLETED.md`** for context on past decisions and implementation details
- **Update immediately** when tasks are completed, added, or changed
- **Move completed tasks** from `TODOS.md` to `COMPLETED.md` to keep the TODO list focused
- Keep both lists current and accurate

### Git Workflow Essentials

**After completing major changes, you MUST commit your work.**

**Conventional Commits Format:**
```bash
<type>: <brief description>

<optional body>
```

**Common Types:** `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`

**For complete details:** See `AgentUsage/git_guide.md`

### Pull Requests

Use conventional commits format for PR titles. Write a brief description of what the PR does and why.

---

## Key Files

| File | Purpose |
|------|---------|
| `SOUL.md` | Agent personality, priority rules, security rules, tone |
| `docs/SecuritySetup.md` | 9-phase hardening guide for Mac Mini deployment |
| `config/openclaw.json.example` | Hardened baseline config template |
| `TODOS.md` | Current task tracking |

---

## When to Use Skills

**This project uses Claude Code Skills for specialized workflows. Invoke skills using the Skill tool when you encounter these situations:**

### Most Relevant for This Project

- **When managing API keys or secrets** → Use skill: `secrets-management`
- **When auditing security** → Use skill: `raccoon-audit` / `hawk-survey` / `turtle-harden`
- **Before making a git commit** → Use skill: `git-workflows`
- **When writing documentation** → Use skill: `owl-archive`

### Available Skills Reference

See `.claude/skills/` for the full list of available skills.

---

## Communication Style
- Be concise but thorough
- Explain reasoning for significant decisions
- Ask for clarification when requirements are ambiguous

---

*Last updated: 2026-03-08*
*Model: Claude Opus 4.6*
