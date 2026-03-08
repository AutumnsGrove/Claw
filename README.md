# Claw

Personal OpenClaw setup for a locally-hosted AI agent on Mac Mini M4. Processes communications (email, iMessage, Telegram), surfaces financial alerts, sends daily briefings, and manages reminders and calendar events.

## What's Here

```
Claw/
├── SOUL.md                        # Agent personality, rules, and priority tiers
├── docs/
│   └── SecuritySetup.md           # 9-phase security hardening guide
├── config/
│   └── openclaw.json.example      # Hardened baseline config (never commit real keys)
├── AGENT.md                       # Project instructions for Claude Code
├── TODOS.md                       # Current task list
└── .gitignore
```

## Stack

| Component | Choice |
|-----------|--------|
| Platform | OpenClaw (Node.js) |
| Hardware | Mac Mini M4 32GB |
| Primary model | MiniMax M2 via OpenRouter |
| Heartbeat/fallback | Gemini 2.5 Flash Lite via OpenRouter |
| Channels | iMessage, Telegram |
| Skills | Apple Reminders, Apple Calendar |

## Setup

Follow `docs/SecuritySetup.md` phases 0-9 in order. The short version:

1. Create dedicated `openclaw` macOS user (Standard, not Admin)
2. Install OpenClaw (`npm install -g openclaw`, must be >= 2026.1.29)
3. Harden filesystem permissions on `~/.openclaw/`
4. Copy `config/openclaw.json.example` to `~/.openclaw/openclaw.json`, fill in real values
5. Store API keys in macOS Keychain, not config files
6. Copy `SOUL.md` to `~/.openclaw/workspace/SOUL.md`
7. Install only audited skills (apple-reminders, apple-calendar)
8. Set up LaunchAgent for auto-start
9. Cap OpenRouter spending with a sub-key ($20/mo)

## Key Security Decisions

- Gateway bound to `127.0.0.1` only (no network exposure)
- `exec`, `shell`, `browser`, `web_fetch` all denied
- All write actions require approval (except pre-approved automations in SOUL.md)
- Email content treated as untrusted data, never executed as instructions
- Dedicated macOS user isolates the agent from personal data

## Files Not in This Repo

These live on the Mac Mini at deployment time and must never be committed:

- `~/.openclaw/openclaw.json` (real config with auth token)
- `~/.openclaw/credentials/*` (API keys, tokens)
- `~/Library/LaunchAgents/com.openclaw.gateway.plist`
