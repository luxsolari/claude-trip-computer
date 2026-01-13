# Troubleshooting Guide

This guide helps resolve common issues with Claude Trip Computer (v0.13.0 TypeScript).

## Installation Issues

### Try the Automated Installer First

If you haven't already, run the automated installer:

**Linux/macOS:**
```bash
./install.sh
```

**Windows:**
```cmd
install.bat
```

The installer handles all configuration automatically and tests the setup.

### Installer Fails

If the installer fails, check the error message and proceed to the relevant section below.

## Quick Checks

### 1. Verify Node.js Installation
```bash
node --version  # Should be 18.0.0 or higher
```

If Node.js is missing, install from https://nodejs.org/

### 2. Verify Status Line Configuration
```bash
cat ~/.claude/settings.json | grep -A 3 statusLine
```

Should show:
```json
"statusLine": {
  "type": "command",
  "command": "npx -y tsx /full/path/to/claude-trip-computer/src/index.ts"
}
```

### 3. Test Script Manually
```bash
cd /path/to/claude-trip-computer
npx tsx src/index.ts
```

Should display status line output (not errors).

### 4. Test Trip Computer
```bash
npx tsx src/index.ts --trip-computer
```

Should display full analytics dashboard.

## Common Issues

### Status Line Shows "Error"

**Symptoms:**
```
💬 Error | 📈 /trip
```

**Causes & Fixes:**

1. **Path incorrect in settings.json**
   - Fix: Use absolute path, not relative
   - Example: `/Users/username/Code/claude-trip-computer/src/index.ts`
   - NOT: `~/Code/claude-trip-computer/src/index.ts`

2. **Node.js not in PATH**
   - Fix: Restart terminal or add to PATH
   - Test: `which node` should return path

3. **tsx not installing**
   - Fix: Run manually first: `npm install -g tsx`
   - Alternative: Use `node --loader tsx` instead of `npx tsx`

4. **Transcript file not found**
   - Check: `ls ~/.claude/projects/`
   - Ensure you're in a project directory with session history

### Status Line Shows Zeros

**Symptoms:**
```
💬 0 msgs | 🔧 0 tools | 🎯 0 tok
```

**Causes & Fixes:**

1. **New session (no history yet)**
   - Expected: First interaction shows zeros
   - Solution: Normal, will populate after first message

2. **Wrong project directory**
   - Check: Transcript files in `~/.claude/projects/`
   - Solution: Verify working directory matches project

3. **Transcript parsing error**
   - Check: `npx tsx src/index.ts 2>&1 | grep Error`
   - Solution: Check transcript file permissions

### Trip Computer Not Showing

**Issue:** When you ask for trip computer stats, only see command documentation.

**Explanation:** `/trip` is a user skill that requires the assistant to invoke it.

**Solutions:**
1. **Ask Claude:** "Show me the trip computer stats" or "Run trip computer"
2. **Run directly:**
   ```bash
   npx tsx /path/to/claude-trip-computer/src/index.ts --trip-computer
   ```

### Model Mix Shows 0% Cost

**Fixed in v0.13.0**

If you see this on older versions, update to v0.13.0+.

### Context Tracking Unavailable

**Symptoms:**
```
Context Management: ➡️ 15/30 points
Context tracking unavailable
```

**Explanation:** Context data only available when running as status line (stdin access).

**Workaround:** Use `/context` command for accurate context information.

**Not Available When:**
- Running directly via bash (no stdin from Claude Code)
- Testing manually with `npx tsx`

**Available When:**
- Configured as status line in settings.json
- Claude Code invokes the script automatically

## Manual Setup (Step by Step)

### 1. Install Prerequisites

**Node.js 18+:**
```bash
# macOS (Homebrew)
brew install node

# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Windows
# Download from https://nodejs.org/
```

### 2. Clone Repository

```bash
cd ~/Code  # or your preferred location
git clone <repository-url> claude-trip-computer
cd claude-trip-computer
```

### 3. Configure Status Line

Edit `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "npx -y tsx /Users/username/Code/claude-trip-computer/src/index.ts"
  }
}
```

**Important:** Use your actual absolute path!

### 4. Create Billing Config

Create `~/.claude/hooks/.stats-config`:

```bash
# Create directory if needed
mkdir -p ~/.claude/hooks

# Create config file
cat > ~/.claude/hooks/.stats-config << 'EOF'
# Claude Code Session Stats Configuration
BILLING_MODE="API"  # or "Sub" for subscription
BILLING_ICON="💳"   # or "📅" for subscription
SAFETY_MARGIN="1.00"  # 1.10 for subscription (10% buffer)
EOF
```

### 5. Restart Claude Code

Close and reopen Claude Code to activate the status line.

### 6. Verify Installation

Status line should appear at bottom of Claude Code window.

## Platform-Specific Issues

### macOS

**Issue:** "Permission denied" when running tsx

**Fix:**
```bash
chmod +x /path/to/claude-trip-computer/src/index.ts
```

**Issue:** "node: command not found"

**Fix:**
```bash
# Verify Node.js installed
which node

# If missing, install via Homebrew
brew install node
```

### Linux

**Issue:** "npx: command not found"

**Fix:**
```bash
# Ensure npm is installed with Node.js
sudo apt-get install npm

# Or use n to manage Node versions
npm install -g n
sudo n latest
```

### Windows

**Issue:** "npx is not recognized"

**Fix:**
- Ensure Node.js installed from https://nodejs.org/
- Restart terminal/PowerShell after installation
- Add to PATH if needed: `C:\Program Files\nodejs\`

**Issue:** Path with spaces

**Fix:** Use quotes in settings.json:
```json
"command": "npx -y tsx \"C:\\Users\\Your Name\\Code\\claude-trip-computer\\src\\index.ts\""
```

## Performance Issues

### Slow Status Line Updates

**Cause:** Cache not working, parsing transcript every time.

**Check:**
```bash
ls -la ~/.claude/session-stats/
```

Should show recent `.json` cache files.

**Fix:**
- Ensure `~/.claude/session-stats/` directory exists and is writable
- Check disk space: `df -h ~`

### High CPU Usage

**Cause:** Parsing very large transcripts repeatedly.

**Solution:**
- Use `/clear` to reset session if transcript is huge (>1000 messages)
- Cache should prevent repeated parsing (5-second TTL)

## Getting Help

**Still having issues?**

1. Check console output:
   ```bash
   npx tsx src/index.ts 2>&1
   ```

2. Verify configuration files exist:
   ```bash
   ls -la ~/.claude/settings.json
   ls -la ~/.claude/hooks/.stats-config
   ```

3. Check repository for updates: Latest version may fix your issue

4. Review [README.md](README.md) for setup instructions

5. Check [CLAUDE.md](CLAUDE.md) for technical details

---

**Last Updated:** 2026-01-12 (v0.13.2)
