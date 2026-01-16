#!/bin/bash
#
# Claude Trip Computer - Installation Script
# Version: 0.13.2
# Platform: Linux, macOS, Windows (Git Bash/WSL)
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
VERIFY_ONLY=false
for arg in "$@"; do
    case $arg in
        --verify)
            VERIFY_ONLY=true
            shift
            ;;
    esac
done

# Script directory (where this script is located)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# On Windows (Git Bash/MSYS), convert Unix path to Windows path for Node.js compatibility
# Claude Code runs natively on Windows and needs Windows-style paths
if command -v cygpath &> /dev/null; then
    SCRIPT_DIR="$(cygpath -m "$SCRIPT_DIR")"
fi

echo ""
echo "================================================"
echo "  Claude Trip Computer - Installation"
echo "  Version 0.13.2"
echo "================================================"
echo ""

# Check Node.js version
echo -e "${BLUE}Checking prerequisites...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ Node.js not found${NC}"
    echo ""
    echo "Node.js 18+ is required. Please install from:"
    echo "  https://nodejs.org/"
    echo ""
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}✗ Node.js version $NODE_VERSION is too old${NC}"
    echo ""
    echo "Node.js 18+ is required. Current version: $(node --version)"
    echo "Please update from: https://nodejs.org/"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Node.js $(node --version) detected${NC}"

# Check if we're in the project directory
if [ ! -f "$SCRIPT_DIR/src/index.ts" ]; then
    echo -e "${RED}✗ Error: src/index.ts not found${NC}"
    echo ""
    echo "Please run this script from the claude-trip-computer directory."
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Project files found${NC}"
echo ""

# Verify-only mode: skip installation, just validate existing setup
if [ "$VERIFY_ONLY" = true ]; then
    echo "================================================"
    echo "  Verification Mode"
    echo "================================================"
    echo ""

    SETTINGS_FILE=~/.claude/settings.json
    TRIP_COMMAND_FILE=~/.claude/commands/trip.md
    VALIDATION_PASSED=true

    echo -e "${BLUE}Checking configuration files...${NC}"
    echo ""

    # Check trip.md exists and has correct path
    if [ -f "$TRIP_COMMAND_FILE" ]; then
        if grep -q "SCRIPT_PATH_PLACEHOLDER" "$TRIP_COMMAND_FILE" 2>/dev/null; then
            echo -e "${RED}✗ trip.md contains unresolved placeholder${NC}"
            echo "  Fix: sed -i '' \"s|SCRIPT_PATH_PLACEHOLDER|$SCRIPT_DIR|g\" $TRIP_COMMAND_FILE"
            VALIDATION_PASSED=false
        elif grep -q "$SCRIPT_DIR" "$TRIP_COMMAND_FILE" 2>/dev/null; then
            echo -e "${GREEN}✓ trip.md configured correctly${NC}"
            echo "  Path: $SCRIPT_DIR"
        else
            echo -e "${YELLOW}⚠ trip.md exists but path doesn't match current directory${NC}"
            echo "  Expected: $SCRIPT_DIR"
            CURRENT_PATH=$(grep -o 'npx -y tsx [^"]*' "$TRIP_COMMAND_FILE" 2>/dev/null | head -1)
            echo "  Found: $CURRENT_PATH"
        fi
    else
        echo -e "${RED}✗ trip.md not found at $TRIP_COMMAND_FILE${NC}"
        echo "  Run: ./install.sh to create it"
        VALIDATION_PASSED=false
    fi

    # Check settings.json
    if [ -f "$SETTINGS_FILE" ]; then
        if grep -q '"statusLine"' "$SETTINGS_FILE" 2>/dev/null; then
            if grep -q "$SCRIPT_DIR" "$SETTINGS_FILE" 2>/dev/null; then
                echo -e "${GREEN}✓ settings.json statusLine configured correctly${NC}"
            else
                echo -e "${YELLOW}⚠ settings.json statusLine exists but path may differ${NC}"
                echo "  Expected path: $SCRIPT_DIR"
            fi
        else
            echo -e "${RED}✗ settings.json missing statusLine configuration${NC}"
            VALIDATION_PASSED=false
        fi
    else
        echo -e "${RED}✗ settings.json not found at $SETTINGS_FILE${NC}"
        VALIDATION_PASSED=false
    fi

    # Check billing config
    CONFIG_FILE=~/.claude/hooks/.stats-config
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}✓ Billing config exists${NC}"
        BILLING_MODE=$(grep 'BILLING_MODE' "$CONFIG_FILE" 2>/dev/null | cut -d'"' -f2)
        echo "  Mode: $BILLING_MODE"
    else
        echo -e "${YELLOW}⚠ Billing config not found (will use defaults)${NC}"
    fi

    echo ""

    # Test execution
    echo -e "${BLUE}Testing execution...${NC}"
    echo ""

    TEST_OUTPUT=$(npx -y tsx "$SCRIPT_DIR/src/index.ts" 2>&1)
    # Note: Empty output or "0 msgs" is valid when running outside Claude Code (no stdin)
    if [[ $TEST_OUTPUT == *"msgs"* ]] || [[ -z "$TEST_OUTPUT" ]]; then
        echo -e "${GREEN}✓ Status line command works${NC}"
        if [[ -z "$TEST_OUTPUT" ]]; then
            echo "  (Empty output expected - no active Claude Code session)"
        fi
    else
        echo -e "${RED}✗ Status line command failed${NC}"
        echo "  Output: $TEST_OUTPUT"
        VALIDATION_PASSED=false
    fi

    TEST_TRIP=$(npx -y tsx "$SCRIPT_DIR/src/index.ts" --trip-computer 2>&1)
    if [[ $TEST_TRIP == *"TRIP COMPUTER"* ]]; then
        echo -e "${GREEN}✓ Trip computer command works${NC}"
    else
        echo -e "${RED}✗ Trip computer command failed${NC}"
        VALIDATION_PASSED=false
    fi

    echo ""
    echo "================================================"
    if [ "$VALIDATION_PASSED" = true ]; then
        echo -e "${GREEN}All validations passed!${NC}"
    else
        echo -e "${RED}Some validations failed. See above for fixes.${NC}"
    fi
    echo "================================================"
    exit 0
fi

# Clean up old bash-based installation (non-interactive)
echo -e "${BLUE}Checking for previous installations...${NC}"

CLEANUP_NEEDED=false

# Check for old bash scripts
OLD_SCRIPTS=(
    ~/.claude/hooks/brief-stats.sh
    ~/.claude/hooks/show-session-stats.sh
    ~/.claude/hooks/session-end-stats.sh
    ~/.claude/hooks/session-cache-lib.sh
    ~/.claude/hooks/rate-limit-lib.sh
)

for script in "${OLD_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        CLEANUP_NEEDED=true
        break
    fi
done

# Check for old lib directory
if [ -d ~/.claude/lib ]; then
    CLEANUP_NEEDED=true
fi

# Check for old trip-computer.md (different from trip.md)
if [ -f ~/.claude/commands/trip-computer.md ]; then
    CLEANUP_NEEDED=true
fi

if [ "$CLEANUP_NEEDED" = true ]; then
    echo -e "${YELLOW}⚠ Found old bash-based installation - cleaning up${NC}"

    # Remove old scripts
    for script in "${OLD_SCRIPTS[@]}"; do
        if [ -f "$script" ]; then
            rm -f "$script"
            echo "  Removed: $script"
        fi
    done

    # Remove old lib directory
    if [ -d ~/.claude/lib ]; then
        rm -rf ~/.claude/lib
        echo "  Removed: ~/.claude/lib/"
    fi

    # Remove old command file
    if [ -f ~/.claude/commands/trip-computer.md ]; then
        rm -f ~/.claude/commands/trip-computer.md
        echo "  Removed: ~/.claude/commands/trip-computer.md"
    fi

    # Clear old cache files (different format from v0.11.0)
    if [ -d ~/.claude/session-stats ]; then
        rm -f ~/.claude/session-stats/*.json 2>/dev/null
        rm -f ~/.claude/session-stats/.usage-cache.json 2>/dev/null
        echo "  Cleared old cache files"
    fi

    # Clean up settings.json if it references old bash scripts
    if [ -f ~/.claude/settings.json ]; then
        if grep -q "\.sh" ~/.claude/settings.json 2>/dev/null; then
            echo "  Found old bash references in settings.json - will be replaced"
        fi

        # Remove SessionEnd hook if present (old bash version)
        if grep -q "SessionEnd" ~/.claude/settings.json 2>/dev/null; then
            echo "  Found old SessionEnd hook - will be removed"
            # We'll handle this in the settings.json update section
        fi
    fi

    echo -e "${GREEN}✓ Cleanup completed${NC}"
else
    echo -e "${GREEN}✓ No previous installation found${NC}"
fi
echo ""

# Interactive billing mode selection
echo -e "${BLUE}Configure billing mode:${NC}"
echo ""
echo "Select your Claude Code billing type:"
echo "  1) API (Pay-as-you-go)"
echo "  2) Subscription (Pro/Max)"
echo ""
read -p "Enter choice [1-2]: " BILLING_CHOICE

case $BILLING_CHOICE in
    1)
        BILLING_MODE="API"
        BILLING_ICON="💳"
        SAFETY_MARGIN="1.00"
        echo -e "${GREEN}✓ API billing mode selected${NC}"
        ;;
    2)
        BILLING_MODE="Sub"
        BILLING_ICON="📅"
        SAFETY_MARGIN="1.10"
        echo -e "${GREEN}✓ Subscription billing mode selected${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac
echo ""

# Create .claude directory structure
echo -e "${BLUE}Setting up Claude Code configuration...${NC}"
mkdir -p ~/.claude/hooks
mkdir -p ~/.claude/commands
mkdir -p ~/.claude/session-stats

# Create billing config
CONFIG_FILE=~/.claude/hooks/.stats-config
cat > "$CONFIG_FILE" << EOF
# Claude Trip Computer Configuration
# Generated: $(date)
BILLING_MODE="$BILLING_MODE"
BILLING_ICON="$BILLING_ICON"
SAFETY_MARGIN="$SAFETY_MARGIN"
EOF

echo -e "${GREEN}✓ Created billing config: ~/.claude/hooks/.stats-config${NC}"

# Create trip command
TRIP_COMMAND_FILE=~/.claude/commands/trip.md
cat > "$TRIP_COMMAND_FILE" << 'EOF'
---
description: Advanced analytics dashboard with cost tracking and optimization recommendations
command: npx -y tsx SCRIPT_PATH_PLACEHOLDER/src/index.ts --trip-computer
---

# Trip Computer - Advanced Analytics Dashboard

**CRITICAL INSTRUCTIONS FOR ASSISTANT:**

When this skill is invoked, you MUST:
1. Execute the command using Bash tool
2. Immediately output the COMPLETE command result in your text response as a code block
3. Display ONLY the raw output - NO additional text, commentary, or analysis
4. The output is self-contained and needs no explanation

**DO NOT:**
- Leave the output in the collapsed Bash tool result
- Add any text before or after the output
- Provide summaries or interpretations
- The user should see the full dashboard immediately without expanding anything

**Correct format:**
```
[Full trip computer output here in code block]
```

## Output Sections

The trip computer displays:
- **📊 Quick Summary**: Health status, message/tool/token counts
- **📈 Session Health**: 5-star rating with component breakdown (0-100 score)
- **🤖 Model Mix**: Per-model usage with cost percentages
- **📊 Token Distribution** (API) or **💵 Cost Drivers** (Subscription): Breakdown of token usage
- **⚡ Efficiency Metrics**: Tool intensity, response verbosity, cache performance
- **📊 Session Metrics/Usage**: Complete session overview
- **🎯 Top Optimization Actions**: Prioritized recommendations (max 3)
- **📊 Session Insights** (API) or **📈 Trajectory** (Subscription): Context/tool/cache patterns or cost projections
EOF

# Replace placeholder with actual path
sed -i.bak "s|SCRIPT_PATH_PLACEHOLDER|$SCRIPT_DIR|g" "$TRIP_COMMAND_FILE"
rm -f "${TRIP_COMMAND_FILE}.bak"

echo -e "${GREEN}✓ Created /trip command: ~/.claude/commands/trip.md${NC}"
echo ""

# Check if settings.json exists
SETTINGS_FILE=~/.claude/settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
    echo -e "${YELLOW}⚠ settings.json not found, creating new file${NC}"
    echo '{}' > "$SETTINGS_FILE"
fi

# Update settings.json
echo -e "${BLUE}Updating Claude Code settings...${NC}"

# Use jq if available, otherwise use Node.js fallback
if command -v jq &> /dev/null; then
    # Backup settings
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup"

    # Remove old SessionEnd hook and update statusLine
    jq --arg cmd "npx -y tsx $SCRIPT_DIR/src/index.ts" \
        'del(.hooks.SessionEnd) | .statusLine = {type: "command", command: $cmd}' \
        "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"

    echo -e "${GREEN}✓ Updated settings.json using jq (backup saved)${NC}"
else
    # Node.js fallback - works on all platforms without jq
    echo -e "${YELLOW}⚠ jq not found - using Node.js fallback${NC}"
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup"

    node -e "
        const fs = require('fs');
        const path = '${SETTINGS_FILE}'.replace('~', process.env.HOME);
        let config = {};
        try { config = JSON.parse(fs.readFileSync(path, 'utf8')); } catch(e) {}
        delete config.hooks?.SessionEnd;
        config.statusLine = { type: 'command', command: 'npx -y tsx $SCRIPT_DIR/src/index.ts' };
        fs.writeFileSync(path, JSON.stringify(config, null, 2));
        console.log('Updated settings.json using Node.js');
    " 2>/dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Updated settings.json using Node.js (backup saved)${NC}"
    else
        echo -e "${RED}✗ Failed to update settings.json${NC}"
        echo ""
        echo "Please manually add this to ~/.claude/settings.json:"
        echo ""
        echo '{'
        echo '  "statusLine": {'
        echo '    "type": "command",'
        echo "    \"command\": \"npx -y tsx $SCRIPT_DIR/src/index.ts\""
        echo '  }'
        echo '}'
        echo ""
    fi
fi

echo ""
echo -e "${BLUE}Testing installation...${NC}"

# Test status line
TEST_OUTPUT=$(npx -y tsx "$SCRIPT_DIR/src/index.ts" 2>&1)
if [[ $TEST_OUTPUT == *"msgs"* ]]; then
    echo -e "${GREEN}✓ Status line test passed${NC}"
else
    echo -e "${YELLOW}⚠ Status line test produced unexpected output${NC}"
    echo "Output: $TEST_OUTPUT"
fi

# Test trip computer
TEST_TRIP=$(npx -y tsx "$SCRIPT_DIR/src/index.ts" --trip-computer 2>&1)
if [[ $TEST_TRIP == *"TRIP COMPUTER"* ]]; then
    echo -e "${GREEN}✓ Trip computer test passed${NC}"
else
    echo -e "${YELLOW}⚠ Trip computer test produced unexpected output${NC}"
fi

echo ""
echo -e "${BLUE}Validating installation...${NC}"

# Validate trip.md - check placeholder was replaced
VALIDATION_PASSED=true
if grep -q "SCRIPT_PATH_PLACEHOLDER" "$TRIP_COMMAND_FILE" 2>/dev/null; then
    echo -e "${RED}✗ trip.md still contains placeholder - path substitution failed${NC}"
    echo "  Fix: sed -i '' \"s|SCRIPT_PATH_PLACEHOLDER|$SCRIPT_DIR|g\" $TRIP_COMMAND_FILE"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}✓ trip.md path configured correctly${NC}"
fi

# Validate settings.json - check statusLine exists
if grep -q '"statusLine"' "$SETTINGS_FILE" 2>/dev/null; then
    if grep -q "$SCRIPT_DIR" "$SETTINGS_FILE" 2>/dev/null; then
        echo -e "${GREEN}✓ settings.json statusLine configured correctly${NC}"
    else
        echo -e "${YELLOW}⚠ settings.json statusLine exists but path may be incorrect${NC}"
        echo "  Expected path: $SCRIPT_DIR"
    fi
else
    echo -e "${RED}✗ settings.json missing statusLine configuration${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = false ]; then
    echo ""
    echo -e "${YELLOW}⚠ Some validations failed. Run './install.sh --verify' after fixing.${NC}"
fi

echo ""
echo "================================================"
echo -e "${GREEN}Installation complete!${NC}"
echo "================================================"
echo ""
echo "Configuration:"
echo "  Billing mode: $BILLING_MODE"
echo "  Project path: $SCRIPT_DIR"
echo "  Config file:  ~/.claude/hooks/.stats-config"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code to activate status line"
echo "  2. Test with: /trip"
echo ""
echo "Documentation:"
echo "  README:     README.md"
echo "  Technical:  CLAUDE.md"
echo "  Help:       TROUBLESHOOTING.md"
echo ""

if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Note: Please manually update ~/.claude/settings.json (see above)${NC}"
    echo ""
fi
