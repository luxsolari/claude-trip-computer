# Troubleshooting & Manual Installation Guide

**Version 0.6.7** | [Back to README](README.md)

This guide helps you troubleshoot common issues and provides manual installation instructions if needed.

---

## Table of Contents

1. [Quick Fixes](#quick-fixes)
2. [Common Issues](#common-issues)
3. [Verification Steps](#verification-steps)
4. [Manual Installation](#manual-installation-advanced)
5. [Platform-Specific Notes](#platform-specific-notes)

---

## Quick Fixes

### Status Line Not Updating
```bash
# Solution 1: Restart Claude Code completely
# Solution 2: Test script manually
bash ~/.claude/hooks/brief-stats.sh

# Solution 3: Check settings.json
cat ~/.claude/settings.json
```

### Costs Seem Wrong
```bash
# Compare with official /cost command
# Expected variance: 0-10% (with 5% safety margin)
# Script should be slightly higher than /cost (conservative)
```

### Windows: Username with Spaces
```bash
# If your username has spaces (e.g., "Lux Solari"):
# - Installer v0.6.1+ handles this automatically
# - Or manually edit settings.json to wrap path in quotes:
{
  "statusLine": {
    "type": "command",
    "command": "bash \"/c/Users/Your Name/.claude/hooks/brief-stats.sh\""
  }
}
```

### Permission Denied Errors
```bash
# Make scripts executable
chmod +x ~/.claude/hooks/*.sh
```

---

## Common Issues

### 1. Status Line Shows All Zeros

**Symptoms**: `💬 0 msgs | 🔧 0 tools | 🎯 0 tok | ⚡ 0% eff`

**Causes & Solutions**:
- **Transcript not found**: Check `~/.claude/projects/` directory exists
- **Wrong project mapping**: Verify project directory name (uses `-` instead of `/` and `_`)
- **New session**: Expected behavior for brand new sessions

**Debug**:
```bash
# Check debug log (if you added debug logging)
cat ~/.claude/hooks/brief-stats-debug.log

# Manually test with current directory
cd /path/to/your/project
bash ~/.claude/hooks/brief-stats.sh
```

### 2. "/trip-computer" Command Not Found

**Cause**: Slash command not installed

**Solution**:
```bash
# Check if command file exists
ls ~/.claude/commands/trip-computer.md

# If missing, reinstall:
./install-claude-stats.sh
```

### 3. Wrong Billing Mode Icon

**Symptoms**: Shows 💳 but you have subscription (or vice versa)

**Solution**:
```bash
# Edit config file
nano ~/.claude/hooks/.stats-config

# Change to:
BILLING_MODE="Sub"    # or "API"
BILLING_ICON="📅"     # or "💳"
```

### 4. Cache Efficiency Always 0%

**Cause**: Session too short or cache not yet utilized

**Solution**: Normal for sessions <5 messages. Cache reads increase over time.

### 5. jq or bc Not Found

**Symptoms**: Scripts fail with "command not found"

**Solution**:
```bash
# Linux
sudo apt-get install jq bc    # Debian/Ubuntu
sudo dnf install jq bc         # Fedora/RHEL

# macOS
brew install jq bc

# Windows Git Bash
# jq usually included; bc available via Git Bash
```

---

## Verification Steps

### Check Installation

Run these commands to verify everything is installed correctly:

```bash
# 1. Check directory structure
ls -la ~/.claude/hooks/
ls -la ~/.claude/commands/

# Expected files:
# ~/.claude/hooks/brief-stats.sh          (executable)
# ~/.claude/hooks/show-session-stats.sh   (executable)
# ~/.claude/hooks/.stats-config           (readable)
# ~/.claude/commands/trip-computer.md     (readable)

# 2. Verify executability
[ -x ~/.claude/hooks/brief-stats.sh ] && echo "✓ brief-stats.sh is executable" || echo "✗ Not executable"
[ -x ~/.claude/hooks/show-session-stats.sh ] && echo "✓ show-session-stats.sh is executable" || echo "✗ Not executable"

# 3. Check settings.json
cat ~/.claude/settings.json

# Should contain:
# {
#   "statusLine": {
#     "type": "command",
#     "command": "bash ~/.claude/hooks/brief-stats.sh"
#   }
# }

# 4. Test scripts manually
bash ~/.claude/hooks/brief-stats.sh
bash ~/.claude/hooks/show-session-stats.sh

# 5. Check version
grep "Version" ~/.claude/hooks/brief-stats.sh
```

### Test in Claude Code

1. Open Claude Code in a project directory
2. Check bottom status bar for stats line
3. Run `/trip-computer` command
4. Compare with `/cost` command (should be within 0-10%)

---

## Manual Installation (Advanced)

**⚠️ Warning**: The automated installer (`./install-claude-stats.sh`) is strongly recommended. Manual installation is error-prone and harder to maintain.

If you must install manually (e.g., installer fails, custom modifications needed):

### Step 1: Create Directory Structure

```bash
mkdir -p ~/.claude/hooks
mkdir -p ~/.claude/commands
```

### Step 2: Get Script Contents

**DO NOT copy scripts from old documentation** - they may be outdated.

**Method 1** (Recommended): Extract from installer
```bash
# View current scripts in installer
less install-claude-stats.sh

# Extract brief-stats.sh (lines ~145-420)
sed -n '145,420p' install-claude-stats.sh > ~/.claude/hooks/brief-stats.sh

# Extract show-session-stats.sh (lines ~430-1320)  
sed -n '430,1320p' install-claude-stats.sh > ~/.claude/hooks/show-session-stats.sh

# Note: Line numbers may vary between versions
# Search for "#!/bin/bash" markers in installer to find exact ranges
```

**Method 2**: Copy from working installation
```bash
# If you have access to a working installation
scp user@working-machine:~/.claude/hooks/*.sh ~/.claude/hooks/
```

### Step 3: Create Configuration

Create `~/.claude/hooks/.stats-config`:

```bash
cat > ~/.claude/hooks/.stats-config << 'EOF'
# Claude Code Session Stats Configuration
BILLING_MODE="API"    # or "Sub" for subscription
BILLING_ICON="💳"     # or "📅" for subscription

# Cost Estimate Safety Margin (conservative buffer)
# 1.00 = exact, 1.05 = 5% buffer, 1.10 = 10% buffer
SAFETY_MARGIN="1.05"
EOF
```

### Step 4: Create Slash Command

Create `~/.claude/commands/trip-computer.md`:

```bash
cat > ~/.claude/commands/trip-computer.md << 'EOF'
---
name: trip-computer
---

Execute the session statistics script and display its output directly in your message text (not in a code block) so it's immediately visible without requiring expansion:

1. Run: ~/.claude/hooks/show-session-stats.sh
2. Capture the output
3. Display the full output as plain text in your response
4. Do not add any commentary, analysis, or interpretation - just show the trip computer output
EOF
```

### Step 5: Set Permissions

```bash
chmod +x ~/.claude/hooks/brief-stats.sh
chmod +x ~/.claude/hooks/show-session-stats.sh
chmod 644 ~/.claude/hooks/.stats-config
chmod 644 ~/.claude/commands/trip-computer.md
```

### Step 6: Configure settings.json

Edit `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/hooks/brief-stats.sh"
  }
}
```

**Windows Git Bash** - if username has spaces, use quotes:
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash \"/c/Users/Your Name/.claude/hooks/brief-stats.sh\""
  }
}
```

### Step 7: Restart Claude Code

Close and reopen Claude Code completely for changes to take effect.

---

## Platform-Specific Notes

### macOS

**Default bash**: macOS Catalina+ uses zsh by default, but ships with bash 3.2.57 which works fine.

**BSD vs GNU tools**: Scripts use BSD-compatible commands:
- `stat -f %m` (macOS) vs `stat -c %Y` (Linux)
- Both versions included in scripts

**Homebrew**: Used for installing prerequisites
```bash
brew install jq    # Usually already present
# bc typically pre-installed
```

### Linux

**Distribution differences**:
- Debian/Ubuntu: `apt-get install jq bc`
- Fedora/RHEL: `dnf install jq bc`  
- Arch: `pacman -S jq bc`

**bash version**: Any version 3.2+ works (tested on 3.2-5.2)

**File paths**: Standard Unix paths, no special handling needed

### Windows (Git Bash)

**Requirements**:
- Git Bash (recommended) or WSL
- jq (usually included with Git Bash)
- bc (available in Git Bash)

**Path handling**:
- Scripts auto-detect `/c/Users/` style paths
- Converts Windows paths to Git Bash format
- Handles spaces in usernames (v0.6.1+)

**HOME variable**: Script normalizes `HOME` if set to `/home/Username` instead of `/c/Users/username`

**Line endings**: Use Unix (LF) not Windows (CRLF)
```bash
# Convert if needed
dos2unix ~/.claude/hooks/*.sh
```

---

## Getting Help

### Check Version
```bash
grep "Version" ~/.claude/hooks/brief-stats.sh
cat VERSION
```

### Useful Debug Commands
```bash
# Check Claude Code projects directory
ls ~/.claude/projects/

# Find recent transcripts
find ~/.claude/projects/ -name "*.jsonl" -mtime -1

# Test token counting
jq -s '[.[] | select(.message.usage)] | length' ~/.claude/projects/*/LATEST_SESSION.jsonl

# Check config
cat ~/.claude/hooks/.stats-config
```

### Still Stuck?

1. **Check CHANGELOG.md** - Recent fixes for your issue
2. **Check CLAUDE.md** - Technical implementation details  
3. **Re-run installer** - Often fixes configuration issues
4. **Compare with `/cost`** - Official billing for validation

### Reporting Issues

When reporting issues, include:
- Version number (`cat VERSION`)
- Platform (OS, bash version)
- Output of `bash -x ~/.claude/hooks/brief-stats.sh` (debug mode)
- `/cost` output for comparison
- Any error messages

---

## Reference Documentation

- **README.md** - Quick start and overview
- **CLAUDE.md** - Complete technical documentation
- **CHANGELOG.md** - Version history and changes
- **CONTRIBUTING.md** - Development guidelines
- **install-claude-stats.sh** - Authoritative script source

---

**Last Updated**: 2026-01-03 (v0.6.7)

