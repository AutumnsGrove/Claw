#!/bin/bash
# deploy.sh — Claw deployment script for Mac Mini
# Run this on the openclaw macOS user account.
# Prerequisites: Phase 0 checklist completed (see docs/SecuritySetup.md)
#
# Usage:
#   bash deploy.sh              # Interactive (prompts for values)
#   bash deploy.sh --check      # Dry run — verify prerequisites only

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
step() { echo -e "\n${YELLOW}─── $1 ───${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK_ONLY=false
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=true

# ─── Phase 0: Prerequisites Check ───

step "Phase 0: Prerequisites"

# Verify we're not running as admin/root
if [[ "$EUID" -eq 0 ]]; then
    fail "Do NOT run as root. Run as the dedicated openclaw Standard user."
    exit 1
fi
ok "Running as non-root user: $(whoami)"

# Check macOS firewall
if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -q "enabled"; then
    ok "macOS Firewall is ON"
else
    warn "macOS Firewall appears OFF — enable in System Settings → Network → Firewall"
fi

# Check FileVault
if fdesetup status 2>/dev/null | grep -q "On"; then
    ok "FileVault is ON"
else
    warn "FileVault appears OFF — enable in System Settings → Privacy & Security → FileVault"
fi

# Check Node.js
if command -v node &>/dev/null; then
    ok "Node.js installed: $(node --version)"
else
    fail "Node.js not found. Install with: brew install node"
    exit 1
fi

# Check OpenClaw
if command -v openclaw &>/dev/null; then
    OC_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
    ok "OpenClaw installed: $OC_VERSION"
else
    warn "OpenClaw not installed. Will install now."
    if [[ "$CHECK_ONLY" == true ]]; then
        fail "Rerun without --check to install"
    fi
fi

if [[ "$CHECK_ONLY" == true ]]; then
    step "Check complete"
    echo "Run without --check to proceed with installation."
    exit 0
fi

# ─── Phase 1: Install OpenClaw ───

step "Phase 1: Install"

if ! command -v openclaw &>/dev/null; then
    echo "Installing OpenClaw..."
    npm install -g openclaw
    ok "OpenClaw installed: $(openclaw --version)"
fi

# Version check
OC_VERSION=$(openclaw --version 2>/dev/null || echo "0.0.0")
ok "OpenClaw version: $OC_VERSION"
echo "  Verify this is >= 2026.1.29. If not, run: npm update -g openclaw"

# ─── Phase 2: Filesystem Hardening ───

step "Phase 2: Filesystem Hardening"

mkdir -p ~/.openclaw
chmod 700 ~/.openclaw
ok "~/.openclaw/ created with 700 permissions"

mkdir -p ~/.openclaw/workspace
chmod 700 ~/.openclaw/workspace
ok "~/.openclaw/workspace/ created"

mkdir -p ~/.openclaw/credentials
chmod 700 ~/.openclaw/credentials
ok "~/.openclaw/credentials/ created"

# ─── Phase 3: Config Deployment ───

step "Phase 3: Config"

if [[ -f ~/.openclaw/openclaw.json ]]; then
    warn "openclaw.json already exists — skipping (delete it manually to redeploy)"
else
    cp "$SCRIPT_DIR/config/openclaw.json.example" ~/.openclaw/openclaw.json
    chmod 600 ~/.openclaw/openclaw.json
    ok "Config deployed to ~/.openclaw/openclaw.json (600 permissions)"

    # Generate auth token
    AUTH_TOKEN=$(openssl rand -hex 32)
    # Use a temp file for safe in-place replacement
    sed "s/GENERATE_WITH_openssl_rand_-hex_32/$AUTH_TOKEN/" ~/.openclaw/openclaw.json > ~/.openclaw/openclaw.json.tmp
    mv ~/.openclaw/openclaw.json.tmp ~/.openclaw/openclaw.json
    chmod 600 ~/.openclaw/openclaw.json
    ok "Gateway auth token generated and inserted"

    echo ""
    echo "  You still need to fill in these placeholders in ~/.openclaw/openclaw.json:"
    echo "    - YOUR_PERSONAL_PHONE_NUMBER"
    echo "    - YOUR_PERSONAL_APPLE_ID_EMAIL"
    echo "    - YOUR_TELEGRAM_NUMERIC_USER_ID"
fi

# ─── API Keys via Keychain ───

step "Phase 3b: API Keys"

echo "Checking macOS Keychain for stored keys..."

if security find-generic-password -a openclaw -s OPENROUTER_API_KEY -w &>/dev/null; then
    ok "OPENROUTER_API_KEY found in Keychain"
else
    warn "OPENROUTER_API_KEY not in Keychain"
    echo "  Store it with:"
    echo "  security add-generic-password -a openclaw -s OPENROUTER_API_KEY -w \"sk-or-YOUR-KEY\""
fi

if security find-generic-password -a openclaw -s TELEGRAM_BOT_TOKEN -w &>/dev/null; then
    ok "TELEGRAM_BOT_TOKEN found in Keychain"
else
    warn "TELEGRAM_BOT_TOKEN not in Keychain"
    echo "  Store it with:"
    echo "  security add-generic-password -a openclaw -s TELEGRAM_BOT_TOKEN -w \"YOUR-TOKEN\""
fi

# ─── SOUL.md Deployment ───

step "Phase 3c: SOUL.md"

cp "$SCRIPT_DIR/SOUL.md" ~/.openclaw/workspace/SOUL.md
chmod 600 ~/.openclaw/workspace/SOUL.md
ok "SOUL.md deployed to ~/.openclaw/workspace/"

# ─── Phase 4: Skills ───

step "Phase 4: Skills"

echo "Installing official skills..."
if command -v openclaw &>/dev/null; then
    openclaw skills install apple-reminders 2>/dev/null && ok "apple-reminders installed" || warn "apple-reminders install failed (may need onboarding first)"
    openclaw skills install apple-calendar 2>/dev/null && ok "apple-calendar installed" || warn "apple-calendar install failed (may need onboarding first)"
else
    warn "OpenClaw not available — install skills manually after onboarding"
fi

# ─── Phase 6: LaunchAgent ───

step "Phase 6: LaunchAgent"

PLIST_PATH="$HOME/Library/LaunchAgents/com.openclaw.gateway.plist"
mkdir -p "$HOME/Library/LaunchAgents"

if [[ -f "$PLIST_PATH" ]]; then
    warn "LaunchAgent plist already exists — skipping"
else
    # Build env loader script that pulls from Keychain at launch
    LOADER_PATH="$HOME/.openclaw/launch-env.sh"
    cat > "$LOADER_PATH" << 'LOADER'
#!/bin/bash
export OPENROUTER_API_KEY=$(security find-generic-password -a openclaw -s OPENROUTER_API_KEY -w 2>/dev/null || echo "")
export TELEGRAM_BOT_TOKEN=$(security find-generic-password -a openclaw -s TELEGRAM_BOT_TOKEN -w 2>/dev/null || echo "")
exec /opt/homebrew/bin/openclaw gateway start
LOADER
    chmod 700 "$LOADER_PATH"
    ok "Launch wrapper created at $LOADER_PATH"

    cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.openclaw.gateway</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${HOME}/.openclaw/launch-env.sh</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>/tmp/openclaw.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/openclaw-error.log</string>
</dict>
</plist>
EOF
    ok "LaunchAgent plist created at $PLIST_PATH"
    echo "  Load with: launchctl load $PLIST_PATH"
    echo "  NOT loading automatically — verify config is correct first."
fi

# ─── Phase 8: Permission Reminders ───

step "Phase 8: macOS Permissions Checklist"

echo "  After first launch, grant these permissions to Terminal.app:"
echo "    ✅ Full Disk Access (required for Messages DB)"
echo "    ✅ Automation → Messages (required for iMessage)"
echo "    ✅ Contacts"
echo "    ✅ Calendars"
echo "    ✅ Reminders"
echo "    ❌ Screen Recording — deny"
echo "    ❌ Location — deny"
echo "    ❌ Camera/Mic — deny"

# ─── Phase 9: Verification ───

step "Phase 9: Post-Deploy Verification"

echo "Checking file permissions..."

check_perms() {
    local path="$1"
    local expected="$2"
    local actual
    actual=$(stat -f "%Lp" "$path" 2>/dev/null || echo "missing")
    if [[ "$actual" == "$expected" ]]; then
        ok "$path — $actual"
    elif [[ "$actual" == "missing" ]]; then
        fail "$path — not found"
    else
        fail "$path — got $actual, expected $expected"
    fi
}

check_perms "$HOME/.openclaw" "700"
check_perms "$HOME/.openclaw/openclaw.json" "600"
check_perms "$HOME/.openclaw/credentials" "700"
check_perms "$HOME/.openclaw/workspace" "700"
check_perms "$HOME/.openclaw/workspace/SOUL.md" "600"

# ─── Summary ───

step "Deployment Complete"

echo ""
echo "  Remaining manual steps:"
echo "    1. Edit ~/.openclaw/openclaw.json — fill in phone number, Apple ID, Telegram ID"
echo "    2. Store API keys in Keychain (see commands above)"
echo "    3. Run: openclaw doctor --fix"
echo "    4. Run: openclaw security audit --deep"
echo "    5. Load LaunchAgent: launchctl load ~/Library/LaunchAgents/com.openclaw.gateway.plist"
echo "    6. Grant macOS permissions when prompted"
echo "    7. Verify localhost-only: netstat -an | grep 18789"
echo "    8. Create OpenRouter sub-key with \$20/mo cap at openrouter.ai"
echo ""
echo "  Logs: /tmp/openclaw.log and /tmp/openclaw-error.log"
echo ""
