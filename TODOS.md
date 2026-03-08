# TODOs — Claw

## Phase 0: Pre-Install (Before Touching the Mac Mini)
- [x] Write SOUL.md agent personality
- [x] Write security hardening guide
- [x] Scaffold project structure
- [ ] Review SOUL.md for any missing priority rules or edge cases
- [ ] Finalize model choice (MiniMax M2 vs alternatives) — test prompt injection resistance

## Phase 1-2: Install & Filesystem Hardening
- [ ] Create dedicated `openclaw` macOS user on Mac Mini
- [ ] Install OpenClaw (verify version >= 2026.1.29)
- [ ] Lock down `~/.openclaw/` permissions (700/600)
- [ ] Store OpenRouter key in macOS Keychain (not plaintext)

## Phase 3: Config Deployment
- [ ] Copy `config/openclaw.json.example` to `~/.openclaw/openclaw.json`
- [ ] Generate gateway auth token (`openssl rand -hex 32`)
- [ ] Fill in real values (phone number, Apple ID, Telegram ID)
- [ ] Deploy `SOUL.md` to `~/.openclaw/workspace/`

## Phase 4: Skills
- [ ] Install `apple-reminders` and `apple-calendar` skills
- [ ] Audit each skill source before installing

## Phase 5-6: Prompt Injection Defense & LaunchAgent
- [ ] Verify email content is treated as untrusted (test with fake injection)
- [ ] Set up LaunchAgent plist for auto-start
- [ ] Configure energy settings (prevent sleep, auto-restart after power failure)

## Phase 7: Cost Safety
- [ ] Create OpenRouter sub-key with $20/mo cap
- [ ] Verify sub-key is the one in config (not root key)

## Phase 8-9: Permissions & Ongoing
- [ ] Grant macOS permissions (Full Disk Access, Messages, Contacts, Calendar, Reminders)
- [ ] Deny Screen Recording, Location, Camera/Mic
- [ ] Run `openclaw doctor --fix` and `openclaw security audit --deep`
- [ ] Verify gateway only on 127.0.0.1 (`netstat -an | grep 18789`)
- [ ] Set monthly security review reminder
