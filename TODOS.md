# TODOs — Claw

## Phase 0: Pre-Install (Done Before Mac Mini)
- [x] Write SOUL.md agent personality
- [x] Write security hardening guide
- [x] Scaffold project structure
- [x] Add quiet hours (11 PM – 8 AM, queue everything)
- [x] Add memory system spec (bills, contacts, preferences, Grove, job search, medical)
- [x] Clarify communication channels (iMessage outbound to me only, Telegram reply-only)
- [x] Clarify Arturo handling (trusted contact, surface in briefings, no replies)
- [x] Add error handling rules (retry once, then alert)
- [x] Add "unsure priority" default rule
- [x] Fix model name to MiniMax M2.5
- [x] Create deploy.sh install script
- [x] Extract openclaw.json.example to config/

## On the Mac Mini (Requires Hardware)
- [ ] Run Phase 0 pre-install checklist (UPnP, firewall, FileVault)
- [ ] Create dedicated `openclaw` macOS user (Standard, not Admin)
- [ ] Run `bash deploy.sh` on the openclaw user
- [ ] Fill in openclaw.json placeholders (phone number, Apple ID, Telegram ID)
- [ ] Store OpenRouter key in macOS Keychain
- [ ] Store Telegram bot token in macOS Keychain
- [ ] Create OpenRouter sub-key with $20/mo cap
- [ ] Run `openclaw doctor --fix` and `openclaw security audit --deep`
- [ ] Load LaunchAgent and verify localhost-only binding
- [ ] Grant macOS permissions (Full Disk, Messages, Contacts, Calendar, Reminders)
- [ ] Configure energy settings (prevent sleep, auto-restart after power failure)

## Post-Deploy Testing
- [ ] Send test iMessage to verify agent receives it
- [ ] Verify daily briefing arrives at 9 AM
- [ ] Verify quiet hours work (no alerts between 11 PM – 8 AM)
- [ ] Test prompt injection with fake malicious email content
- [ ] Verify agent does NOT reply to Arturo or any contact
- [ ] Verify Telegram reply-only behavior
- [ ] Test financial alert flow (reminder + calendar + iMessage)
- [ ] Test error handling (what happens when model request fails)
- [ ] Check memory persistence across sessions

## Future
- [ ] Write prompt injection test suite (fake emails with SYSTEM: instructions)
- [ ] Set up monthly security review reminder
- [ ] Evaluate MiniMax M2.5 prompt injection resistance with real email flow
- [ ] Document memory system patterns once live (what it remembers well, what it misses)
