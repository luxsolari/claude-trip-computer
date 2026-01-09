#!/bin/bash
set -e

# Claude Code Session Stats Tracking - Automated Installer
# Supports: Linux, macOS, Windows (WSL/Git Bash)

# Read version from VERSION file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="0.0.1"
if [ -f "$SCRIPT_DIR/VERSION" ]; then
  VERSION=$(cat "$SCRIPT_DIR/VERSION" | tr -d '[:space:]')
fi

echo "================================================================"
echo "   Claude Code Session Stats Tracking - *NIX Installer"
echo "   Version: $VERSION"
echo "================================================================"
echo ""

# Detect operating system
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
  OS="windows"
else
  # Check for WSL
  if grep -qi microsoft /proc/version 2>/dev/null; then
    OS="linux"
  fi
fi

echo "✓ Detected OS: $OS"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
echo ""

MISSING_PREREQS=()

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "⚠ jq is not installed"
  MISSING_PREREQS+=("jq")
else
  echo "✓ jq is installed ($(jq --version))"
fi

# Check for bc
if ! command -v bc &> /dev/null; then
  echo "⚠ bc is not installed"
  MISSING_PREREQS+=("bc")
else
  echo "✓ bc is installed"
fi

# If prerequisites are missing, offer to install them
if [ ${#MISSING_PREREQS[@]} -gt 0 ]; then
  echo ""
  echo "----------------------------------------------------------------"
  echo "Missing prerequisites: ${MISSING_PREREQS[*]}"
  echo "----------------------------------------------------------------"
  echo ""
  echo "Would you like to install them automatically? (Y/n)"
  echo ""
  
  read -p "Install prerequisites? [Y/n]: " INSTALL_CHOICE
  INSTALL_CHOICE=${INSTALL_CHOICE:-Y}  # Default to Y if empty
  
  if [[ "$INSTALL_CHOICE" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Installing prerequisites..."
    echo ""
    
    case "$OS" in
      linux)
        # Detect package manager
        if command -v apt-get &> /dev/null; then
          echo "Using apt-get package manager..."
          for pkg in "${MISSING_PREREQS[@]}"; do
            echo "Installing $pkg..."
            sudo apt-get update -qq && sudo apt-get install -y "$pkg"
            if [ $? -ne 0 ]; then
              echo "❌ Failed to install $pkg"
              echo "Please install manually: sudo apt-get install -y $pkg"
              exit 1
            fi
          done
        elif command -v dnf &> /dev/null; then
          echo "Using dnf package manager..."
          for pkg in "${MISSING_PREREQS[@]}"; do
            echo "Installing $pkg..."
            sudo dnf install -y "$pkg"
            if [ $? -ne 0 ]; then
              echo "❌ Failed to install $pkg"
              echo "Please install manually: sudo dnf install -y $pkg"
              exit 1
            fi
          done
        elif command -v pacman &> /dev/null; then
          echo "Using pacman package manager..."
          for pkg in "${MISSING_PREREQS[@]}"; do
            echo "Installing $pkg..."
            sudo pacman -S --noconfirm "$pkg"
            if [ $? -ne 0 ]; then
              echo "❌ Failed to install $pkg"
              echo "Please install manually: sudo pacman -S $pkg"
              exit 1
            fi
          done
        else
          echo "❌ Could not detect package manager"
          echo "Please install manually: ${MISSING_PREREQS[*]}"
          exit 1
        fi
        ;;
        
      macos)
        # Check for Homebrew
        if command -v brew &> /dev/null; then
          echo "Using Homebrew package manager..."
          for pkg in "${MISSING_PREREQS[@]}"; do
            # bc is pre-installed on macOS
            if [ "$pkg" == "bc" ]; then
              echo "⚠ bc should be pre-installed on macOS"
              echo "If missing, please reinstall Xcode Command Line Tools"
              continue
            fi
            echo "Installing $pkg..."
            brew install "$pkg"
            if [ $? -ne 0 ]; then
              echo "❌ Failed to install $pkg"
              echo "Please install manually: brew install $pkg"
              exit 1
            fi
          done
        else
          echo "❌ Homebrew not found"
          echo ""
          echo "Please install Homebrew first:"
          echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
          echo ""
          echo "Then run this installer again."
          exit 1
        fi
        ;;
        
      windows)
        echo "❌ Cannot auto-install on Windows via bash"
        echo ""
        echo "Please use the Windows batch installer instead:"
        echo "  install-claude-stats.bat"
        echo ""
        echo "Or install manually:"
        echo "  - Install Chocolatey: https://chocolatey.org/install"
        echo "  - Run: choco install jq"
        echo "  - bc: Usually included with Git Bash"
        echo "  - bc manual install: https://stackoverflow.com/a/57787863/32131291"
        exit 1
        ;;
    esac
    
    echo ""
    echo "✓ Prerequisites installed successfully"
    echo ""
    
    # Verify installation
    for pkg in "${MISSING_PREREQS[@]}"; do
      if ! command -v "$pkg" &> /dev/null; then
        echo "❌ $pkg installation failed or not in PATH"
        echo "Please install manually and run installer again"
        exit 1
      fi
      echo "✓ $pkg is now available"
    done
  else
    echo ""
    echo "Installation cancelled."
    echo ""
    echo "Please install prerequisites manually:"
    case "$OS" in
      linux)
        echo "  Ubuntu/Debian: sudo apt-get install -y ${MISSING_PREREQS[*]}"
        echo "  RHEL/Fedora:   sudo dnf install -y ${MISSING_PREREQS[*]}"
        echo "  Arch:          sudo pacman -S ${MISSING_PREREQS[*]}"
        ;;
      macos)
        echo "  macOS:         brew install ${MISSING_PREREQS[*]}"
        ;;
      windows)
        echo "  Windows:       Use install-claude-stats.bat"
        echo "  Or manually:   choco install jq"
        echo "  bc manual:     https://stackoverflow.com/a/57787863/32131291"
        ;;
    esac
    exit 1
  fi
fi

echo ""
echo "Configuring billing mode..."
echo ""
echo "Which billing mode are you using?"
echo "  1) API Billing (pay-per-use, charged per API call)"
echo "  2) Subscription Plan (monthly subscription with included usage)"
echo ""

# Read user input with validation
while true; do
  read -p "Enter your choice (1 or 2): " BILLING_CHOICE
  case "$BILLING_CHOICE" in
    1)
      BILLING_MODE="API"
      BILLING_ICON="💳"
      echo "✓ Selected: API Billing"
      break
      ;;
    2)
      BILLING_MODE="Sub"
      BILLING_ICON="📅"
      echo "✓ Selected: Subscription Plan"
      break
      ;;
    *)
      echo "❌ Invalid choice. Please enter 1 or 2."
      ;;
  esac
done

echo ""
echo "Creating directories..."

# Create directories
mkdir -p ~/.claude/hooks
mkdir -p ~/.claude/commands

echo "✓ Created ~/.claude/hooks"
echo "✓ Created ~/.claude/commands"

# Save billing mode configuration
# Set safety margin based on billing mode
if [ "$BILLING_MODE" = "Sub" ]; then
  SAFETY_MARGIN_VALUE="1.10"
else
  SAFETY_MARGIN_VALUE="1.00"
fi

cat > ~/.claude/hooks/.stats-config << CONFIG_EOF
# Claude Code Session Stats Configuration
# Generated by install-claude-stats.sh
BILLING_MODE="$BILLING_MODE"
BILLING_ICON="$BILLING_ICON"

# Cost Estimate Safety Margin
# For Subscription users: 1.10 (10% buffer for conservative API-equivalent estimates)
# For API users: 1.00 (no margin - use /cost for actual billing)
SAFETY_MARGIN="$SAFETY_MARGIN_VALUE"
CONFIG_EOF

echo "✓ Saved billing configuration to ~/.claude/hooks/.stats-config"
echo ""


echo "Installing scripts..."

# Create brief-stats.sh (status line)
cat > ~/.claude/hooks/brief-stats.sh << 'SCRIPT_EOF'
#!/bin/bash
# Brief session statistics displayed in the status line
# Claude Code Session Stats - Version 0.9.4

# Force C locale for consistent number formatting
export LC_NUMERIC=C

# FIX: On Windows Git Bash, HOME might be /home/USERNAME but Claude stores files in /c/Users/username
# Normalize HOME to use Git Bash style path
if [[ "$HOME" == /home/* ]] && [[ -d "/c/Users" ]]; then
  # Extract username from /home/Username
  USERNAME=$(basename "$HOME")
  # Try to find matching user directory in /c/Users/ (case-insensitive)
  for user_dir in "/c/Users"/*; do
    if [[ "$(basename "$user_dir" | tr '[:upper:]' '[:lower:]')" == "$(echo "$USERNAME" | tr '[:upper:]' '[:lower:]')" ]]; then
      HOME="$user_dir"
      break
    fi
  done
fi

# Try to read session info from stdin (provided by Claude Code in statusLine context)
# Read with a 1 second timeout - if nothing arrives, assume no session
if IFS= read -t 1 -r INPUT; then
  # If we got one line, try to read the rest (for multi-line JSON)
  while IFS= read -t 1 -r line; do
    INPUT="${INPUT}${line}"
  done
else
  INPUT=""
fi

# Extract session ID from JSON input if available
ACTIVE_SESSION_ID=$(echo "$INPUT" | jq -r '.sessionId // empty' 2>/dev/null)

# Find the project directory
# Find the project directory - handle Windows drive letters specially
# Get working directory from Claude Code JSON input, fallback to pwd
if [ -n "$INPUT" ]; then
  PWD_PATH=$(echo "$INPUT" | jq -r '.workspace.current_dir // .workspace.project_dir // .cwd // empty' 2>/dev/null)
fi
if [ -z "$PWD_PATH" ]; then
  PWD_PATH=$(pwd)
fi
if [[ "$PWD_PATH" =~ ^/([a-z])/ ]]; then
  # Windows Git Bash path like /c/Dev/project -> C--Dev-project
  DRIVE_LETTER=$(echo "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')
  REST_PATH=$(echo "$PWD_PATH" | sed 's|^/[a-z]/||' | sed 's/\//-/g' | sed 's/_/-/g')
  PROJECT_DIR="${DRIVE_LETTER}--${REST_PATH}"
else
  # Unix path - replace / and _ with -
  PROJECT_DIR=$(echo "$PWD_PATH" | sed 's/\//-/g' | sed 's/_/-/g')
fi
TRANSCRIPT_DIR="$HOME/.claude/projects/$PROJECT_DIR"

# Check for active sub-agents with robust detection
if [ -d "$TRANSCRIPT_DIR" ]; then
  NOW=$(date +%s)
  ACTIVE_AGENTS=0

  # Iterate through agent files if they exist
  for agent_file in "$TRANSCRIPT_DIR"/agent-*.jsonl; do
    # Check if file exists (glob may not match anything)
    if [ -f "$agent_file" ]; then
      # Get file modification time (Linux uses -c, macOS uses -f)
      FILE_MTIME=$(stat -c %Y "$agent_file" 2>/dev/null || stat -f %m "$agent_file" 2>/dev/null || echo 0)
      AGE=$((NOW - FILE_MTIME))

      # Multi-criteria check for active agents:
      # 1. File modified in last 3 seconds (stricter window to avoid false positives from old sessions)
      # 2. File size > 100 bytes (not just init/empty file)
      # 3. File is actively growing (check size twice with small delay)
      if [ "$AGE" -lt 3 ]; then
        # Get file size (Linux uses -c %s, macOS uses -f %z)
        FILE_SIZE_1=$(stat -c %s "$agent_file" 2>/dev/null || stat -f %z "$agent_file" 2>/dev/null || echo 0)

        # Check if file has meaningful content (> 100 bytes)
        if [ "$FILE_SIZE_1" -gt 100 ]; then
          # Wait briefly and check if file is still growing (active write)
          sleep 0.1
          FILE_SIZE_2=$(stat -c %s "$agent_file" 2>/dev/null || stat -f %z "$agent_file" 2>/dev/null || echo 0)

          # If file grew, it's actively being written to
          if [ "$FILE_SIZE_2" -gt "$FILE_SIZE_1" ]; then
            ACTIVE_AGENTS=1
            break
          fi
        fi
      fi
    fi
  done

  if [ "$ACTIVE_AGENTS" -eq 1 ]; then
    echo "🤖 Sub-agents running, stand by..."
    exit 0
  fi
fi

# Load billing mode from config file
CONFIG_FILE="$HOME/.claude/hooks/.stats-config"
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
else
  # Fallback to defaults if config doesn't exist
  BILLING_MODE="API"
  BILLING_ICON="💳"
  SAFETY_MARGIN="1.10"
fi

# Ensure SAFETY_MARGIN is set (for older configs without it)
if [ -z "$SAFETY_MARGIN" ]; then
  SAFETY_MARGIN="1.10"
fi

# If we have an active session ID, use it directly
if [ -n "$ACTIVE_SESSION_ID" ]; then
  TRANSCRIPT_PATH="$TRANSCRIPT_DIR/${ACTIVE_SESSION_ID}.jsonl"

  # If the transcript doesn't exist yet (new session), show zeroed stats
  if [ ! -f "$TRANSCRIPT_PATH" ]; then
    echo "💬 0 msgs | 🔧 0 tools (0.0 tools/msg) | 🎯 0 tok | ⚡ 0% cached | 📝 0 tok/msg | 📈 /trip-computer"
    exit 0
  fi
else
  # No active session ID - fall back to most recent transcript
  if [ -d "$TRANSCRIPT_DIR" ]; then
    TRANSCRIPT_PATH=$(ls -t "$TRANSCRIPT_DIR"/*.jsonl 2>/dev/null | grep -v agent | head -1)
    if [ -z "$TRANSCRIPT_PATH" ]; then
      # No transcripts exist - show zeroed stats
      echo "💬 0 msgs | 🔧 0 tools (0.0 tools/msg) | 🎯 0 tok | ⚡ 0% cached | 📝 0 tok/msg | 📈 /trip-computer"
      exit 0
    fi
  else
    # New directory - show zeroed stats
    echo "💬 0 msgs | 🔧 0 tools (0.0 tools/msg) | 🎯 0 tok | ⚡ 0% cached | 📝 0 tok/msg | 📈 /trip-computer"
    exit 0
  fi
fi

# Calculate statistics from current session including sub-agents
# Build list of ALL transcript files for this session (main + agents)
ALL_TRANSCRIPTS=()
if [ -f "$TRANSCRIPT_PATH" ]; then
  ALL_TRANSCRIPTS+=("$TRANSCRIPT_PATH")
fi
# Add agent transcript files referenced in main session (search across all project directories)
# This handles cases where agents are in different project directories (e.g., cross-project agent usage)
if [ -f "$TRANSCRIPT_PATH" ]; then
  # Extract agent IDs referenced in main session transcript
  REFERENCED_AGENTS=$(grep -o 'agent-[a-z0-9]\+' "$TRANSCRIPT_PATH" 2>/dev/null | sort -u || echo "")

  # Search for those agent files across all project directories
  if [ -n "$REFERENCED_AGENTS" ]; then
    for agent_id in $REFERENCED_AGENTS; do
      # Find agent file across all ~/.claude/projects/* directories
      AGENT_FILE=$(find "$HOME/.claude/projects" -name "${agent_id}.jsonl" 2>/dev/null | head -1)
      if [ -n "$AGENT_FILE" ] && [ -f "$AGENT_FILE" ]; then
        ALL_TRANSCRIPTS+=("$AGENT_FILE")
      fi
    done
  fi
fi

# Exit if no transcripts found
if [ ${#ALL_TRANSCRIPTS[@]} -eq 0 ]; then
  echo "💬 0 msgs | 🔧 0 tools (0.0 tools/msg) | 🎯 0 tok | ⚡ 0% cached | 📝 0 tok/msg | 📈 /trip-computer"
  exit 0
fi

# Count messages and tool calls from current transcript (main session only, not agents)
# Count direct user prompts (string-type messages, excluding command messages)
DIRECT_USER_MESSAGES=$(jq -s '[.[] | select(.type == "user" and (.isMeta == false or .isMeta == null) and (.message.content | if type == "array" then all(.[]; .type == "tool_result") | not else (test("<command-name>|<command-args>|<local-command-stdout>|<command-message>") | not) end))] | length' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")

# Count "btw" queued messages (system reminders where message starts with "btw")
BTW_MESSAGES=$(grep -c 'The user sent the following message:\\nbtw' "$TRANSCRIPT_PATH" 2>/dev/null) || BTW_MESSAGES=0

# Total user messages = direct messages + btw messages
USER_MESSAGES=$((DIRECT_USER_MESSAGES + BTW_MESSAGES))

# Count tool uses - they are nested inside message.content arrays
TOOL_CALLS=$(jq -s '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")] | length' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")

# Parse ALL transcripts (main + agents) and group by requestId + model
# This ensures we capture sub-agent activity (like web searches using Haiku)
PER_MODEL_DATA=$(cat "${ALL_TRANSCRIPTS[@]}" | jq -s '
[.[] | select(.message.usage and .message.model)] |
group_by(.requestId + "|" + .message.model) |
map({
  requestId: .[0].requestId,
  model: .[0].message.model,
  input: (map(.message.usage.input_tokens // 0) | max),
  output: (map(.message.usage.output_tokens // 0) | max),
  cache_creation: (map(.message.usage.cache_creation_input_tokens // 0) | max),
  cache_read: (map(.message.usage.cache_read_input_tokens // 0) | max)
}) |
group_by(.model) |
map({
  model: .[0].model,
  input: (map(.input) | add),
  output: (map(.output) | add),
  cache_creation: (map(.cache_creation) | add),
  cache_read: (map(.cache_read) | add)
})
' 2>/dev/null || echo '[]')

# Calculate totals across all models
INPUT_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].input] | add // 0')
OUTPUT_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].output] | add // 0')
CACHE_CREATION_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].cache_creation] | add // 0')
CACHE_READ_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].cache_read] | add // 0')

# Calculate total tokens across all types
TOTAL_TOKENS=$((INPUT_TOKENS + OUTPUT_TOKENS + CACHE_CREATION_TOKENS + CACHE_READ_TOKENS))

# Format total tokens in K/M notation
if [ "$TOTAL_TOKENS" -ge 1000000 ]; then
  FORMATTED_TOTAL=$(echo "scale=1; $TOTAL_TOKENS / 1000000" | bc 2>/dev/null || echo "0")
  [[ "$FORMATTED_TOTAL" == .* ]] && FORMATTED_TOTAL="0$FORMATTED_TOTAL"
  FORMATTED_TOTAL="${FORMATTED_TOTAL}M"
elif [ "$TOTAL_TOKENS" -ge 1000 ]; then
  FORMATTED_TOTAL=$(echo "scale=1; $TOTAL_TOKENS / 1000" | bc 2>/dev/null || echo "0")
  [[ "$FORMATTED_TOTAL" == .* ]] && FORMATTED_TOTAL="0$FORMATTED_TOTAL"
  FORMATTED_TOTAL="${FORMATTED_TOTAL}K"
else
  FORMATTED_TOTAL="$TOTAL_TOKENS"
fi

# Calculate tool intensity (tools per message)
TOOL_INTENSITY="0.0"
if [ "$USER_MESSAGES" -gt 0 ] && [ "$TOOL_CALLS" -gt 0 ]; then
  TOOL_INTENSITY=$(echo "scale=1; $TOOL_CALLS / $USER_MESSAGES" | bc 2>/dev/null || echo "0.0")
  [[ "$TOOL_INTENSITY" == .* ]] && TOOL_INTENSITY="0$TOOL_INTENSITY"
fi

# Calculate response verbosity (avg output tokens per user message)
VERBOSITY=0
FORMATTED_VERBOSITY="0"
if [ "$USER_MESSAGES" -gt 0 ] && [ "$OUTPUT_TOKENS" -gt 0 ]; then
  VERBOSITY=$(echo "scale=0; $OUTPUT_TOKENS / $USER_MESSAGES" | bc 2>/dev/null || echo "0")
  [[ "$VERBOSITY" == .* ]] && VERBOSITY="0"

  # Format verbosity in K notation if >= 1000
  if [ "$VERBOSITY" -ge 1000 ]; then
    FORMATTED_VERBOSITY=$(echo "scale=1; $VERBOSITY / 1000" | bc 2>/dev/null || echo "0")
    [[ "$FORMATTED_VERBOSITY" == .* ]] && FORMATTED_VERBOSITY="0$FORMATTED_VERBOSITY"
    FORMATTED_VERBOSITY="${FORMATTED_VERBOSITY}K"
  else
    FORMATTED_VERBOSITY="$VERBOSITY"
  fi
fi

# Calculate cache efficiency percentage
TOTAL_CACHE_TOKENS=$((CACHE_CREATION_TOKENS + CACHE_READ_TOKENS))
CACHE_EFFICIENCY="0"
if [ "$TOTAL_CACHE_TOKENS" -gt 0 ]; then
  CACHE_EFFICIENCY=$(echo "scale=0; 100 * $CACHE_READ_TOKENS / $TOTAL_CACHE_TOKENS" | bc 2>/dev/null || echo "0")
  [[ "$CACHE_EFFICIENCY" == .* ]] && CACHE_EFFICIENCY="0"
fi

# Helper function to get pricing for a model
get_model_pricing() {
  local model_name="$1"
  local input_rate output_rate cache_write_mult cache_read_mult

  if [[ "$model_name" == *"opus-4-5"* ]] || [[ "$model_name" == *"opus-4.5"* ]]; then
    input_rate=5; output_rate=25; cache_write_mult=1.25; cache_read_mult=0.10
  elif [[ "$model_name" == *"opus-4"* ]] || [[ "$model_name" == *"opus-3"* ]] || [[ "$model_name" == *"opus"* ]]; then
    input_rate=15; output_rate=75; cache_write_mult=1.25; cache_read_mult=0.10
  elif [[ "$model_name" == *"haiku-4-5"* ]] || [[ "$model_name" == *"haiku-4.5"* ]]; then
    input_rate=1; output_rate=5; cache_write_mult=1.25; cache_read_mult=0.10
  elif [[ "$model_name" == *"haiku-3-5"* ]] || [[ "$model_name" == *"haiku-3.5"* ]]; then
    input_rate=0.80; output_rate=4; cache_write_mult=1.25; cache_read_mult=0.10
  elif [[ "$model_name" == *"haiku-3"* ]] || [[ "$model_name" == *"haiku"* ]]; then
    input_rate=0.25; output_rate=1.25; cache_write_mult=1.20; cache_read_mult=0.12
  else
    input_rate=3; output_rate=15; cache_write_mult=1.25; cache_read_mult=0.10
  fi

  echo "$input_rate $output_rate $cache_write_mult $cache_read_mult"
}

# Build status line based on billing mode
if [ "$BILLING_MODE" = "Sub" ]; then
  # For Subscription users: Show cost estimation with 10% safety margin
  # Calculate costs per model and sum
  TOTAL_COST=0
  MODEL_COUNT=$(echo "$PER_MODEL_DATA" | jq 'length')
  for ((i=0; i<MODEL_COUNT; i++)); do
    MODEL_NAME=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].model")
    MODEL_INPUT=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].input")
    MODEL_OUTPUT=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].output")
    MODEL_CACHE_WRITE=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].cache_creation")
    MODEL_CACHE_READ=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].cache_read")

    read INPUT_RATE OUTPUT_RATE CACHE_WRITE_MULT CACHE_READ_MULT < <(get_model_pricing "$MODEL_NAME")

    MODEL_COST=$(echo "scale=4; \
      ($MODEL_INPUT * $INPUT_RATE / 1000000) + \
      ($MODEL_OUTPUT * $OUTPUT_RATE / 1000000) + \
      ($MODEL_CACHE_WRITE * $INPUT_RATE * $CACHE_WRITE_MULT / 1000000) + \
      ($MODEL_CACHE_READ * $INPUT_RATE * $CACHE_READ_MULT / 1000000)" | bc 2>/dev/null || echo "0")

    [[ "$MODEL_COST" == .* ]] && MODEL_COST="0$MODEL_COST"
    TOTAL_COST=$(echo "scale=4; $TOTAL_COST + $MODEL_COST" | bc 2>/dev/null || echo "0")
    [[ "$TOTAL_COST" == .* ]] && TOTAL_COST="0$TOTAL_COST"
  done

  # Apply 10% safety margin for Subscription users
  TOTAL_COST=$(echo "scale=4; $TOTAL_COST * $SAFETY_MARGIN" | bc 2>/dev/null || echo "$TOTAL_COST")
  [[ "$TOTAL_COST" == .* ]] && TOTAL_COST="0$TOTAL_COST"

  FORMATTED_COST=$(printf "%.2f" "$TOTAL_COST" 2>/dev/null || echo "0.00")

  # Subscription user status line (with cost)
  echo "💬 $USER_MESSAGES msgs | 🔧 $TOOL_CALLS tools ($TOOL_INTENSITY tools/msg) | 🎯 $FORMATTED_TOTAL tok | ⚡ ${CACHE_EFFICIENCY}% cached | 📝 ${FORMATTED_VERBOSITY} tok/msg | $BILLING_ICON ~\$$FORMATTED_COST value | 📈 /trip-computer"
else
  # API user status line (no cost)
  echo "💬 $USER_MESSAGES msgs | 🔧 $TOOL_CALLS tools ($TOOL_INTENSITY tools/msg) | 🎯 $FORMATTED_TOTAL tok | ⚡ ${CACHE_EFFICIENCY}% cached | 📝 ${FORMATTED_VERBOSITY} tok/msg | 📈 /trip-computer"
fi

exit 0
SCRIPT_EOF

# Create show-session-stats.sh (detailed stats - enhanced "trip computer" version)
cat > ~/.claude/hooks/show-session-stats.sh << 'SCRIPT_EOF'
#!/bin/bash
set -e

# Helper script to display session statistics for current or specified session
# Claude Code Session Stats - Version 0.9.4
# Usage: ./show-session-stats.sh [session_id]

# Force C locale for consistent number formatting (avoids locale warnings on systems without en_US.UTF-8)
export LC_NUMERIC=C

# If session_id provided, use it; otherwise find the most recent session
if [ -n "$1" ]; then
  SESSION_ID="$1"
else
  # Find the most recent transcript file for this project
  PROJECT_DIR=$(pwd | sed 's|^/\([a-z]\)/|\U\1--|' | sed 's/\//-/g' | sed 's/_/-/g')
  TRANSCRIPT_DIR="$HOME/.claude/projects/$PROJECT_DIR"

  if [ -d "$TRANSCRIPT_DIR" ]; then
    TRANSCRIPT_PATH=$(ls -t "$TRANSCRIPT_DIR"/*.jsonl 2>/dev/null | grep -v agent | head -1)
    if [ -z "$TRANSCRIPT_PATH" ]; then
      echo "❌ No session transcripts found in $TRANSCRIPT_DIR"
      exit 1
    fi
    SESSION_ID=$(basename "$TRANSCRIPT_PATH" .jsonl)
  else
    echo "❌ No transcript directory found for this project"
    exit 1
  fi
fi

# Construct transcript path
PROJECT_DIR=$(pwd | sed 's|^/\([a-z]\)/|\U\1--|' | sed 's/\//-/g' | sed 's/_/-/g')
TRANSCRIPT_PATH="$HOME/.claude/projects/$PROJECT_DIR/${SESSION_ID}.jsonl"

if [ ! -f "$TRANSCRIPT_PATH" ]; then
  echo "❌ Transcript file not found: $TRANSCRIPT_PATH"
  exit 1
fi

# Load billing mode from config file
CONFIG_FILE="$HOME/.claude/hooks/.stats-config"
BILLING_MODE="API"
BILLING_ICON="💳"
SAFETY_MARGIN_CONFIG="1.10"
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
  SAFETY_MARGIN_CONFIG="${SAFETY_MARGIN:-1.10}"
fi

# Apply safety margin only for Subscription users
# API users should use /cost for actual billing - this is just for reference
if [ "$BILLING_MODE" = "Sub" ]; then
  SAFETY_MARGIN="$SAFETY_MARGIN_CONFIG"
else
  SAFETY_MARGIN="1.00"  # No margin for API users - they use /cost for billing
fi

# Build list of ALL transcript files for this session (main + agents)
ALL_TRANSCRIPTS=()
if [ -f "$TRANSCRIPT_PATH" ]; then
  ALL_TRANSCRIPTS+=("$TRANSCRIPT_PATH")
fi
# Add agent transcript files referenced in main session (search across all project directories)
# This handles cases where agents are in different project directories (e.g., cross-project agent usage)
if [ -f "$TRANSCRIPT_PATH" ]; then
  # Extract agent IDs referenced in main session transcript
  REFERENCED_AGENTS=$(grep -o 'agent-[a-z0-9]\+' "$TRANSCRIPT_PATH" 2>/dev/null | sort -u || echo "")

  # Search for those agent files across all project directories
  if [ -n "$REFERENCED_AGENTS" ]; then
    for agent_id in $REFERENCED_AGENTS; do
      # Find agent file across all ~/.claude/projects/* directories
      AGENT_FILE=$(find "$HOME/.claude/projects" -name "${agent_id}.jsonl" 2>/dev/null | head -1)
      if [ -n "$AGENT_FILE" ] && [ -f "$AGENT_FILE" ]; then
        ALL_TRANSCRIPTS+=("$AGENT_FILE")
      fi
    done
  fi
fi

# ============================================================================
# TRANSCRIPT ANALYSIS - Calculate estimates from session transcript
# ============================================================================

# Count messages and tool calls from current transcript (main session only, not agents)
USER_MESSAGES=$(jq -s '[.[] | select(.type == "user" and (.isMeta == false or .isMeta == null) and (.message.content | if type == "array" then all(.[]; .type == "tool_result") | not else (test("<command-name>|<command-args>|<local-command-stdout>|<command-message>") | not) end))] | length' "$TRANSCRIPT_PATH")

TOOL_CALLS=$(jq -s '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")] | length' "$TRANSCRIPT_PATH")

# Parse ALL transcripts (main + agents) and group by requestId + model to avoid double-counting
# This ensures we capture sub-agent activity (like web searches using Haiku)
PER_MODEL_DATA=$(cat "${ALL_TRANSCRIPTS[@]}" | jq -s '
[.[] | select(.message.usage and .message.model)] |
group_by(.requestId + "|" + .message.model) |
map({
  requestId: .[0].requestId,
  model: .[0].message.model,
  input: (map(.message.usage.input_tokens // 0) | max),
  output: (map(.message.usage.output_tokens // 0) | max),
  cache_creation: (map(.message.usage.cache_creation_input_tokens // 0) | max),
  cache_read: (map(.message.usage.cache_read_input_tokens // 0) | max)
}) |
group_by(.model) |
map({
  model: .[0].model,
  requests: length,
  input: (map(.input) | add),
  output: (map(.output) | add),
  cache_creation: (map(.cache_creation) | add),
  cache_read: (map(.cache_read) | add)
})
' 2>/dev/null || echo '[]')

# Calculate totals
INPUT_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].input] | add // 0')
OUTPUT_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].output] | add // 0')
CACHE_CREATION_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].cache_creation] | add // 0')
CACHE_READ_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].cache_read] | add // 0')
TOTAL_TOKENS=$((INPUT_TOKENS + OUTPUT_TOKENS + CACHE_CREATION_TOKENS + CACHE_READ_TOKENS))

# Helper function to get pricing for a model
get_model_pricing() {
  local model_name="$1"
  local input_rate output_rate cache_write_mult cache_read_mult

  if [[ "$model_name" == *"opus-4-5"* ]] || [[ "$model_name" == *"opus-4.5"* ]]; then
    input_rate=5; output_rate=25; cache_write_mult=1.25; cache_read_mult=0.10
  elif [[ "$model_name" == *"opus-4"* ]] || [[ "$model_name" == *"opus-3"* ]] || [[ "$model_name" == *"opus"* ]]; then
    input_rate=15; output_rate=75; cache_write_mult=1.25; cache_read_mult=0.10
  elif [[ "$model_name" == *"haiku-4-5"* ]] || [[ "$model_name" == *"haiku-4.5"* ]]; then
    input_rate=1; output_rate=5; cache_write_mult=1.25; cache_read_mult=0.10
  elif [[ "$model_name" == *"haiku-3-5"* ]] || [[ "$model_name" == *"haiku-3.5"* ]]; then
    input_rate=0.80; output_rate=4; cache_write_mult=1.25; cache_read_mult=0.10
  elif [[ "$model_name" == *"haiku-3"* ]] || [[ "$model_name" == *"haiku"* ]]; then
    input_rate=0.25; output_rate=1.25; cache_write_mult=1.20; cache_read_mult=0.12
  else
    input_rate=3; output_rate=15; cache_write_mult=1.25; cache_read_mult=0.10
  fi

  echo "$input_rate $output_rate $cache_write_mult $cache_read_mult"
}

# Helper function to get friendly model name
get_friendly_model_name() {
  local model_name="$1"
  if [[ "$model_name" == *"opus-4-5"* ]] || [[ "$model_name" == *"opus-4.5"* ]]; then
    echo "Opus 4.5"
  elif [[ "$model_name" == *"opus-4"* ]]; then
    echo "Opus 4"
  elif [[ "$model_name" == *"opus-3"* ]]; then
    echo "Opus 3"
  elif [[ "$model_name" == *"haiku-4-5"* ]] || [[ "$model_name" == *"haiku-4.5"* ]]; then
    echo "Haiku 4.5"
  elif [[ "$model_name" == *"haiku-3-5"* ]] || [[ "$model_name" == *"haiku-3.5"* ]]; then
    echo "Haiku 3.5"
  elif [[ "$model_name" == *"haiku-3"* ]]; then
    echo "Haiku 3"
  elif [[ "$model_name" == *"sonnet"* ]]; then
    echo "Sonnet 4.5"
  else
    echo "Unknown"
  fi
}

# Calculate estimated costs per model and per cost driver
ESTIMATE_TOTAL_COST=0
TOTAL_INPUT_COST=0
TOTAL_OUTPUT_COST=0
TOTAL_CACHE_WRITE_COST=0
TOTAL_CACHE_READ_COST=0

declare -a MODEL_NAMES
declare -a MODEL_COSTS
declare -a MODEL_REQUESTS

MODEL_COUNT=$(echo "$PER_MODEL_DATA" | jq 'length')
for ((i=0; i<MODEL_COUNT; i++)); do
  MODEL_NAME=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].model")
  MODEL_INPUT=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].input")
  MODEL_OUTPUT=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].output")
  MODEL_CACHE_WRITE=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].cache_creation")
  MODEL_CACHE_READ=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].cache_read")
  MODEL_REQUEST_COUNT=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].requests")

  read INPUT_RATE OUTPUT_RATE CACHE_WRITE_MULT CACHE_READ_MULT < <(get_model_pricing "$MODEL_NAME")

  # Calculate individual cost components
  INPUT_COST=$(echo "scale=4; $MODEL_INPUT * $INPUT_RATE / 1000000" | bc)
  OUTPUT_COST=$(echo "scale=4; $MODEL_OUTPUT * $OUTPUT_RATE / 1000000" | bc)
  CACHE_WRITE_COST=$(echo "scale=4; $MODEL_CACHE_WRITE * $INPUT_RATE * $CACHE_WRITE_MULT / 1000000" | bc)
  CACHE_READ_COST=$(echo "scale=4; $MODEL_CACHE_READ * $INPUT_RATE * $CACHE_READ_MULT / 1000000" | bc)

  # Fix leading dot
  [[ "$INPUT_COST" == .* ]] && INPUT_COST="0$INPUT_COST"
  [[ "$OUTPUT_COST" == .* ]] && OUTPUT_COST="0$OUTPUT_COST"
  [[ "$CACHE_WRITE_COST" == .* ]] && CACHE_WRITE_COST="0$CACHE_WRITE_COST"
  [[ "$CACHE_READ_COST" == .* ]] && CACHE_READ_COST="0$CACHE_READ_COST"

  # Accumulate totals
  TOTAL_INPUT_COST=$(echo "scale=4; $TOTAL_INPUT_COST + $INPUT_COST" | bc)
  TOTAL_OUTPUT_COST=$(echo "scale=4; $TOTAL_OUTPUT_COST + $OUTPUT_COST" | bc)
  TOTAL_CACHE_WRITE_COST=$(echo "scale=4; $TOTAL_CACHE_WRITE_COST + $CACHE_WRITE_COST" | bc)
  TOTAL_CACHE_READ_COST=$(echo "scale=4; $TOTAL_CACHE_READ_COST + $CACHE_READ_COST" | bc)

  [[ "$TOTAL_INPUT_COST" == .* ]] && TOTAL_INPUT_COST="0$TOTAL_INPUT_COST"
  [[ "$TOTAL_OUTPUT_COST" == .* ]] && TOTAL_OUTPUT_COST="0$TOTAL_OUTPUT_COST"
  [[ "$TOTAL_CACHE_WRITE_COST" == .* ]] && TOTAL_CACHE_WRITE_COST="0$TOTAL_CACHE_WRITE_COST"
  [[ "$TOTAL_CACHE_READ_COST" == .* ]] && TOTAL_CACHE_READ_COST="0$TOTAL_CACHE_READ_COST"

  MODEL_COST=$(echo "scale=4; $INPUT_COST + $OUTPUT_COST + $CACHE_WRITE_COST + $CACHE_READ_COST" | bc)
  [[ "$MODEL_COST" == .* ]] && MODEL_COST="0$MODEL_COST"

  ESTIMATE_TOTAL_COST=$(echo "scale=4; $ESTIMATE_TOTAL_COST + $MODEL_COST" | bc)
  [[ "$ESTIMATE_TOTAL_COST" == .* ]] && ESTIMATE_TOTAL_COST="0$ESTIMATE_TOTAL_COST"

  # Store for model mix section
  MODEL_NAMES[$i]=$(get_friendly_model_name "$MODEL_NAME")
  MODEL_COSTS[$i]=$MODEL_COST
  MODEL_REQUESTS[$i]=$MODEL_REQUEST_COUNT
done

# Apply conservative safety margin (helps avoid underestimation)
# Philosophy: Better to overestimate slightly than underestimate significantly
ESTIMATE_TOTAL_COST=$(echo "scale=4; $ESTIMATE_TOTAL_COST * $SAFETY_MARGIN" | bc)
[[ "$ESTIMATE_TOTAL_COST" == .* ]] && ESTIMATE_TOTAL_COST="0$ESTIMATE_TOTAL_COST"

# Calculate cache efficiency
TOTAL_CACHE_TOKENS=$((CACHE_CREATION_TOKENS + CACHE_READ_TOKENS))
CACHE_EFFICIENCY=0
if [ "$TOTAL_CACHE_TOKENS" -gt 0 ]; then
  CACHE_EFFICIENCY=$(echo "scale=1; 100 * $CACHE_READ_TOKENS / $TOTAL_CACHE_TOKENS" | bc)
  [[ "$CACHE_EFFICIENCY" == .* ]] && CACHE_EFFICIENCY="0$CACHE_EFFICIENCY"
fi

# Calculate cost per message
COST_PER_MESSAGE=0
if [ "$USER_MESSAGES" -gt 0 ]; then
  COST_PER_MESSAGE=$(echo "scale=2; $ESTIMATE_TOTAL_COST / $USER_MESSAGES" | bc)
  [[ "$COST_PER_MESSAGE" == .* ]] && COST_PER_MESSAGE="0$COST_PER_MESSAGE"
fi

# Calculate cache savings
CACHE_READ_COST_SAVED=0
for ((i=0; i<MODEL_COUNT; i++)); do
  MODEL_NAME=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].model")
  MODEL_CACHE_READ=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].cache_read")
  read INPUT_RATE OUTPUT_RATE CACHE_WRITE_MULT CACHE_READ_MULT < <(get_model_pricing "$MODEL_NAME")

  SAVED=$(echo "scale=2; ($MODEL_CACHE_READ * $INPUT_RATE * (1 - $CACHE_READ_MULT)) / 1000000" | bc)
  [[ "$SAVED" == .* ]] && SAVED="0$SAVED"
  CACHE_READ_COST_SAVED=$(echo "scale=2; $CACHE_READ_COST_SAVED + $SAVED" | bc)
  [[ "$CACHE_READ_COST_SAVED" == .* ]] && CACHE_READ_COST_SAVED="0$CACHE_READ_COST_SAVED"
done

# Get context growth
FIRST_INPUT=$(jq -s '[.[] | select(.message.usage.input_tokens)] | .[0].message.usage.input_tokens // 0' "$TRANSCRIPT_PATH")
LATEST_INPUT=$(jq -s '[.[] | select(.message.usage.input_tokens)] | .[-1].message.usage.input_tokens // 0' "$TRANSCRIPT_PATH")

# Calculate efficiency metrics
OUTPUT_INPUT_RATIO=0
COST_PER_TOKEN=0
if [ "$INPUT_TOKENS" -gt 0 ]; then
  OUTPUT_INPUT_RATIO=$(echo "scale=1; $OUTPUT_TOKENS / $INPUT_TOKENS" | bc)
  [[ "$OUTPUT_INPUT_RATIO" == .* ]] && OUTPUT_INPUT_RATIO="0$OUTPUT_INPUT_RATIO"
fi
if [ "$TOTAL_TOKENS" -gt 0 ]; then
  COST_PER_TOKEN=$(echo "scale=8; $ESTIMATE_TOTAL_COST / $TOTAL_TOKENS" | bc)
  [[ "$COST_PER_TOKEN" == .* ]] && COST_PER_TOKEN="0$COST_PER_TOKEN"
fi

# ============================================================================
# SESSION HEALTH SCORE CALCULATION (0-100)
# ============================================================================

HEALTH_SCORE=0
HEALTH_REASONS=()

# Cache efficiency component (0-40 points)
if [ "$TOTAL_CACHE_TOKENS" -gt 0 ]; then
  if (( $(echo "$CACHE_EFFICIENCY >= 80" | bc -l) )); then
    HEALTH_SCORE=$((HEALTH_SCORE + 40))
    HEALTH_REASONS+=("✅ Excellent cache efficiency")
  elif (( $(echo "$CACHE_EFFICIENCY >= 50" | bc -l) )); then
    HEALTH_SCORE=$((HEALTH_SCORE + 30))
    HEALTH_REASONS+=("✅ Good cache efficiency")
  elif (( $(echo "$CACHE_EFFICIENCY >= 20" | bc -l) )); then
    HEALTH_SCORE=$((HEALTH_SCORE + 15))
    HEALTH_REASONS+=("⚠️  Moderate cache efficiency")
  else
    HEALTH_SCORE=$((HEALTH_SCORE + 5))
    HEALTH_REASONS+=("⚠️  Low cache efficiency")
  fi
else
  HEALTH_SCORE=$((HEALTH_SCORE + 20))
  HEALTH_REASONS+=("➡️  No cache usage yet")
fi

# Cost per message component (0-30 points)
if [ "$USER_MESSAGES" -gt 0 ]; then
  if (( $(echo "$COST_PER_MESSAGE <= 0.10" | bc -l) )); then
    HEALTH_SCORE=$((HEALTH_SCORE + 30))
    HEALTH_REASONS+=("✅ Efficient cost per message")
  elif (( $(echo "$COST_PER_MESSAGE <= 0.30" | bc -l) )); then
    HEALTH_SCORE=$((HEALTH_SCORE + 20))
    HEALTH_REASONS+=("✅ Reasonable cost per message")
  elif (( $(echo "$COST_PER_MESSAGE <= 0.50" | bc -l) )); then
    HEALTH_SCORE=$((HEALTH_SCORE + 10))
    HEALTH_REASONS+=("⚠️  Moderate cost per message")
  else
    HEALTH_SCORE=$((HEALTH_SCORE + 5))
    HEALTH_REASONS+=("⚠️  High cost per message")
  fi
else
  HEALTH_SCORE=$((HEALTH_SCORE + 15))
fi

# Context growth component (0-30 points)
if [ "$FIRST_INPUT" -gt 0 ] && [ "$LATEST_INPUT" -gt 0 ]; then
  GROWTH_RATIO=$(echo "scale=1; $LATEST_INPUT / $FIRST_INPUT" | bc)
  [[ "$GROWTH_RATIO" == .* ]] && GROWTH_RATIO="0$GROWTH_RATIO"

  if (( $(echo "$GROWTH_RATIO < 3" | bc -l) )); then
    HEALTH_SCORE=$((HEALTH_SCORE + 30))
    HEALTH_REASONS+=("✅ Healthy context size")
  elif (( $(echo "$GROWTH_RATIO < 5" | bc -l) )); then
    HEALTH_SCORE=$((HEALTH_SCORE + 20))
    HEALTH_REASONS+=("✅ Moderate context growth")
  elif (( $(echo "$GROWTH_RATIO < 8" | bc -l) )); then
    HEALTH_SCORE=$((HEALTH_SCORE + 10))
    HEALTH_REASONS+=("⚠️  Context growing significantly")
  else
    HEALTH_SCORE=$((HEALTH_SCORE + 5))
    HEALTH_REASONS+=("⚠️  Context bloat detected")
  fi
else
  HEALTH_SCORE=$((HEALTH_SCORE + 15))
fi

# Determine health rating
if [ "$HEALTH_SCORE" -ge 90 ]; then
  HEALTH_RATING="⭐⭐⭐⭐⭐"
  HEALTH_STATUS="Excellent"
elif [ "$HEALTH_SCORE" -ge 75 ]; then
  HEALTH_RATING="⭐⭐⭐⭐"
  HEALTH_STATUS="Good"
elif [ "$HEALTH_SCORE" -ge 60 ]; then
  HEALTH_RATING="⭐⭐⭐"
  HEALTH_STATUS="Fair"
elif [ "$HEALTH_SCORE" -ge 40 ]; then
  HEALTH_RATING="⭐⭐"
  HEALTH_STATUS="Poor"
else
  HEALTH_RATING="⭐"
  HEALTH_STATUS="Critical"
fi

# ============================================================================
# PROMPT PATTERN ANALYSIS - Detect inefficient prompting patterns
# ============================================================================

# Extract user prompts for analysis
USER_PROMPT_ANALYSIS=$(jq -s '[.[] |
  select(.type == "user" and
         (.isMeta == false or .isMeta == null) and
         (.message.content | type == "string"))]' "$TRANSCRIPT_PATH")

# Pattern 1: Vague/broad questions
# Detect questions with broad keywords but no constraints
VAGUE_PROMPTS=$(echo "$USER_PROMPT_ANALYSIS" | jq '[.[] |
  select(.message.content |
    test("(?i)(explain|describe|tell me|how does|what is|show me)") and
    test("(?i)(brief|concise|summary|in \\\\d+ (points|words|lines)|limit|short)") | not
  )] | length')

VAGUE_PCT=0
if [ "$USER_MESSAGES" -gt 0 ]; then
  VAGUE_PCT=$(echo "scale=0; 100 * $VAGUE_PROMPTS / $USER_MESSAGES" | bc)
  [[ "$VAGUE_PCT" == .* ]] && VAGUE_PCT="0"
fi

VAGUE_DETECTED=false
VAGUE_SAVING=0
if [ "$VAGUE_PCT" -gt 30 ] && [ "$VAGUE_PROMPTS" -ge 2 ]; then
  VAGUE_DETECTED=true
  if [ "$USER_MESSAGES" -gt 0 ] && [ $(echo "$TOTAL_OUTPUT_COST > 0" | bc) -eq 1 ]; then
    VAGUE_SAVING=$(echo "scale=2; $TOTAL_OUTPUT_COST / $USER_MESSAGES * 0.25 * 10" | bc)
    [[ "$VAGUE_SAVING" == .* ]] && VAGUE_SAVING="0$VAGUE_SAVING"
  fi
fi

# Pattern 2: Large context pastes (>200 lines)
# Detect when users paste large blocks of code/text
LARGE_PASTE_COUNT=$(echo "$USER_PROMPT_ANALYSIS" | jq '[.[] |
  select((.message.content | split("\n") | length) > 200)] | length')

LARGE_PASTE_PCT=0
if [ "$USER_MESSAGES" -gt 0 ]; then
  LARGE_PASTE_PCT=$(echo "scale=0; 100 * $LARGE_PASTE_COUNT / $USER_MESSAGES" | bc)
  [[ "$LARGE_PASTE_PCT" == .* ]] && LARGE_PASTE_PCT="0"
fi

LARGE_PASTE_DETECTED=false
LARGE_PASTE_SAVING=0
if [ "$LARGE_PASTE_PCT" -gt 20 ] && [ "$LARGE_PASTE_COUNT" -ge 1 ]; then
  LARGE_PASTE_DETECTED=true
  if [ "$USER_MESSAGES" -gt 0 ]; then
    COMBINED_INPUT_COST=$(echo "scale=4; $TOTAL_INPUT_COST + $TOTAL_CACHE_WRITE_COST" | bc)
    [[ "$COMBINED_INPUT_COST" == .* ]] && COMBINED_INPUT_COST="0$COMBINED_INPUT_COST"
    if [ $(echo "$COMBINED_INPUT_COST > 0" | bc) -eq 1 ]; then
      LARGE_PASTE_SAVING=$(echo "scale=2; $COMBINED_INPUT_COST / $USER_MESSAGES * 0.20 * 10" | bc)
      [[ "$LARGE_PASTE_SAVING" == .* ]] && LARGE_PASTE_SAVING="0$LARGE_PASTE_SAVING"
    fi
  fi
fi

# Pattern 3: Repeated similar questions (low unique word diversity)
# Detect when user asks similar questions repeatedly (indicates unclear initial response)
AVG_UNIQUE_WORDS=$(echo "$USER_PROMPT_ANALYSIS" | jq '
  if length == 0 then 0 else
    (map(.message.content |
         ascii_downcase |
         gsub("[^a-z0-9 ]"; "") |
         split(" ") |
         unique |
         length) | add) / length
  end | floor')

REPEATED_DETECTED=false
REPEATED_SAVING=0
if [ "$USER_MESSAGES" -ge 3 ] && [ "$AVG_UNIQUE_WORDS" -lt 15 ] && [ "$AVG_UNIQUE_WORDS" -gt 0 ]; then
  REPEATED_DETECTED=true
  if [ $(echo "$COST_PER_MESSAGE > 0" | bc) -eq 1 ]; then
    REPEATED_SAVING=$(echo "scale=2; $COST_PER_MESSAGE * 0.15 * 10" | bc)
    [[ "$REPEATED_SAVING" == .* ]] && REPEATED_SAVING="0$REPEATED_SAVING"
  fi
fi

# Pattern 4: Missing task constraints
# Detect coding/task requests without format/length specifications
UNCONSTRAINED_TASKS=$(echo "$USER_PROMPT_ANALYSIS" | jq '[.[] |
  select(
    (.message.content | test("(?i)(write|create|build|implement|add|fix|refactor|generate)")) and
    (.message.content | test("(?i)(max|maximum|limit|under|less than|no more than|exactly|in \\\\d+|brief|concise|short|simple)") | not)
  )] | length')

UNCONSTRAINED_PCT=0
if [ "$USER_MESSAGES" -gt 0 ]; then
  UNCONSTRAINED_PCT=$(echo "scale=0; 100 * $UNCONSTRAINED_TASKS / $USER_MESSAGES" | bc)
  [[ "$UNCONSTRAINED_PCT" == .* ]] && UNCONSTRAINED_PCT="0"
fi

UNCONSTRAINED_DETECTED=false
UNCONSTRAINED_SAVING=0
if [ "$UNCONSTRAINED_PCT" -gt 40 ] && [ "$UNCONSTRAINED_TASKS" -ge 2 ]; then
  UNCONSTRAINED_DETECTED=true
  if [ "$USER_MESSAGES" -gt 0 ] && [ $(echo "$TOTAL_OUTPUT_COST > 0" | bc) -eq 1 ]; then
    UNCONSTRAINED_SAVING=$(echo "scale=2; $TOTAL_OUTPUT_COST / $USER_MESSAGES * 0.20 * 10" | bc)
    [[ "$UNCONSTRAINED_SAVING" == .* ]] && UNCONSTRAINED_SAVING="0$UNCONSTRAINED_SAVING"
  fi
fi

# ============================================================================
# GENERATE SMART RECOMMENDATIONS (Prioritized by savings)
# ============================================================================

declare -a RECOMMENDATIONS
declare -a REC_SAVINGS

# Recommendation 1: Model switching
if [ "$MODEL_COUNT" -gt 0 ]; then
  PRIMARY_MODEL="${MODEL_NAMES[0]}"
  if [[ "$PRIMARY_MODEL" == *"Opus"* ]] || [[ "$PRIMARY_MODEL" == *"Sonnet"* ]]; then
    POTENTIAL_SAVING=$(echo "scale=2; $COST_PER_MESSAGE * 0.75 * 10" | bc)
    [[ "$POTENTIAL_SAVING" == .* ]] && POTENTIAL_SAVING="0$POTENTIAL_SAVING"
    RECOMMENDATIONS+=("Switch to Haiku for simple tasks")
    REC_SAVINGS+=("$POTENTIAL_SAVING")
  fi
fi

# Recommendation 2: Output verbosity
if [ "$OUTPUT_TOKENS" -gt 0 ] && [ "$INPUT_TOKENS" -gt 0 ]; then
  if (( $(echo "$OUTPUT_INPUT_RATIO > 2.5" | bc -l) )); then
    POTENTIAL_SAVING=$(echo "scale=2; $COST_PER_MESSAGE * 0.25 * 10" | bc)
    [[ "$POTENTIAL_SAVING" == .* ]] && POTENTIAL_SAVING="0$POTENTIAL_SAVING"
    RECOMMENDATIONS+=("Ask for more concise responses")
    REC_SAVINGS+=("$POTENTIAL_SAVING")
  fi
fi

# Recommendation 3: Cache optimization
if [ "$TOTAL_CACHE_TOKENS" -gt 0 ]; then
  if (( $(echo "$CACHE_EFFICIENCY >= 70" | bc -l) )); then
    POTENTIAL_SAVING=$(echo "scale=2; $CACHE_READ_COST_SAVED / $USER_MESSAGES * 10" | bc)
    [[ "$POTENTIAL_SAVING" == .* ]] && POTENTIAL_SAVING="0$POTENTIAL_SAVING"
    RECOMMENDATIONS+=("Continue in session (cache working well)")
    REC_SAVINGS+=("$POTENTIAL_SAVING")
  elif (( $(echo "$CACHE_EFFICIENCY < 30" | bc -l) )); then
    POTENTIAL_SAVING=$(echo "scale=2; $COST_PER_MESSAGE * 0.15 * 10" | bc)
    [[ "$POTENTIAL_SAVING" == .* ]] && POTENTIAL_SAVING="0$POTENTIAL_SAVING"
    RECOMMENDATIONS+=("Use /clear to start fresh (cache inefficient)")
    REC_SAVINGS+=("$POTENTIAL_SAVING")
  fi
fi

# Recommendation 4: Context reset
if [ "$FIRST_INPUT" -gt 0 ] && [ "$LATEST_INPUT" -gt 0 ]; then
  GROWTH_RATIO=$(echo "scale=1; $LATEST_INPUT / $FIRST_INPUT" | bc)
  [[ "$GROWTH_RATIO" == .* ]] && GROWTH_RATIO="0$GROWTH_RATIO"

  if (( $(echo "$GROWTH_RATIO >= 5" | bc -l) )); then
    POTENTIAL_SAVING=$(echo "scale=2; $COST_PER_MESSAGE * 0.20 * 10" | bc)
    [[ "$POTENTIAL_SAVING" == .* ]] && POTENTIAL_SAVING="0$POTENTIAL_SAVING"
    RECOMMENDATIONS+=("Use /clear to reduce context size")
    REC_SAVINGS+=("$POTENTIAL_SAVING")
  fi
fi

# Recommendation 5: Vague prompts
if [ "$VAGUE_DETECTED" = true ]; then
  POTENTIAL_SAVING="$VAGUE_SAVING"
  RECOMMENDATIONS+=("Add constraints to questions (brief, in N points)")
  REC_SAVINGS+=("$POTENTIAL_SAVING")
fi

# Recommendation 6: Large pastes
if [ "$LARGE_PASTE_DETECTED" = true ]; then
  POTENTIAL_SAVING="$LARGE_PASTE_SAVING"
  RECOMMENDATIONS+=("Use file references instead of pasting large code")
  REC_SAVINGS+=("$POTENTIAL_SAVING")
fi

# Recommendation 7: Repeated questions
if [ "$REPEATED_DETECTED" = true ]; then
  POTENTIAL_SAVING="$REPEATED_SAVING"
  RECOMMENDATIONS+=("Ask complete questions upfront (avoid iterations)")
  REC_SAVINGS+=("$POTENTIAL_SAVING")
fi

# Recommendation 8: Unconstrained tasks
if [ "$UNCONSTRAINED_DETECTED" = true ]; then
  POTENTIAL_SAVING="$UNCONSTRAINED_SAVING"
  RECOMMENDATIONS+=("Specify format/length constraints for tasks")
  REC_SAVINGS+=("$POTENTIAL_SAVING")
fi

# Sort recommendations by savings (bubble sort for bash compatibility)
REC_COUNT=${#RECOMMENDATIONS[@]}
for ((i=0; i<REC_COUNT-1; i++)); do
  for ((j=0; j<REC_COUNT-i-1; j++)); do
    if (( $(echo "${REC_SAVINGS[j]} < ${REC_SAVINGS[j+1]}" | bc -l) )); then
      # Swap
      temp_rec="${RECOMMENDATIONS[j]}"
      temp_sav="${REC_SAVINGS[j]}"
      RECOMMENDATIONS[j]="${RECOMMENDATIONS[j+1]}"
      REC_SAVINGS[j]="${REC_SAVINGS[j+1]}"
      RECOMMENDATIONS[j+1]="$temp_rec"
      REC_SAVINGS[j+1]="$temp_sav"
    fi
  done
done

# ============================================================================
# OUTPUT DISPLAY - Enhanced visual hierarchy
# ============================================================================

# Quick summary line
TREND_INDICATOR="--"
TREND_TEXT="Stable"
if [ "$USER_MESSAGES" -gt 2 ]; then
  EARLY_MSGS=2
  LATE_START=$((USER_MESSAGES - 2))
  if [ "$LATE_START" -gt "$EARLY_MSGS" ]; then
    EARLY_COST=$(echo "scale=4; $ESTIMATE_TOTAL_COST / $USER_MESSAGES * $EARLY_MSGS" | bc)
    LATE_COST=$(echo "scale=4; $ESTIMATE_TOTAL_COST - ($ESTIMATE_TOTAL_COST / $USER_MESSAGES * $LATE_START)" | bc)
    EARLY_AVG=$(echo "scale=4; $EARLY_COST / $EARLY_MSGS" | bc)
    LATE_AVG=$(echo "scale=4; $LATE_COST / 2" | bc)

    [[ "$EARLY_AVG" == .* ]] && EARLY_AVG="0$EARLY_AVG"
    [[ "$LATE_AVG" == .* ]] && LATE_AVG="0$LATE_AVG"

    if (( $(echo "$LATE_AVG > $EARLY_AVG * 1.2" | bc -l) )); then
      TREND_INDICATOR="/\\"
      TREND_TEXT="Rising"
    elif (( $(echo "$LATE_AVG < $EARLY_AVG * 0.8" | bc -l) )); then
      TREND_INDICATOR="\\/"
      TREND_TEXT="Falling"
    fi
  fi
fi

ACTION_TEXT="Review insights below"
if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
  ACTION_TEXT="See top ${#RECOMMENDATIONS[@]} optimization tips"
fi

echo ""
echo "================================================================================"
echo "  🚗 TRIP COMPUTER v0.9.4  |  ${CACHE_EFFICIENCY}% cache efficiency  |  $USER_MESSAGES messages"
echo "================================================================================"
echo ""
echo "📊 QUICK SUMMARY"
echo "  Status: $HEALTH_STATUS ($HEALTH_SCORE/100)  |  Trend: $TREND_INDICATOR $TREND_TEXT  |  Action: $ACTION_TEXT"
echo ""
echo "--------------------------------------------------------------------------------"
echo ""

# ============================================================================
# SESSION HEALTH SCORE
# ============================================================================

echo "📈 SESSION HEALTH: $HEALTH_SCORE/100  $HEALTH_RATING"
echo "--------------------------------------------------------------------------------"
for reason in "${HEALTH_REASONS[@]}"; do
  echo "  $reason"
done
echo ""

# ============================================================================
# MODEL MIX
# ============================================================================

if [ "$MODEL_COUNT" -gt 0 ]; then
  echo "🤖 MODEL MIX"
  echo "--------------------------------------------------------------------------------"

  for ((i=0; i<MODEL_COUNT; i++)); do
    MODEL_NAME="${MODEL_NAMES[i]}"
    MODEL_COST="${MODEL_COSTS[i]}"
    MODEL_REQ="${MODEL_REQUESTS[i]}"

    # Calculate percentage
    if (( $(echo "$ESTIMATE_TOTAL_COST > 0" | bc -l) )); then
      MODEL_PCT=$(echo "scale=0; 100 * $MODEL_COST / $ESTIMATE_TOTAL_COST" | bc)
      [[ "$MODEL_PCT" == .* ]] && MODEL_PCT="0"
    else
      MODEL_PCT=0
    fi

    # Create visual bar (20 chars max)
    BAR_LENGTH=$(echo "scale=0; $MODEL_PCT / 5" | bc)
    [[ "$BAR_LENGTH" == .* ]] && BAR_LENGTH="0"
    BAR=$(printf '#%.0s' $(seq 1 $BAR_LENGTH))
    BAR="${BAR}$(printf -- '-%.0s' $(seq 1 $((20 - BAR_LENGTH))))"

    printf "  %-12s %2d calls -> \$%-8s (%3d%%)  %s\n" "$MODEL_NAME:" "$MODEL_REQ" "$MODEL_COST" "$MODEL_PCT" "$BAR"
  done

  # Model switching suggestion
  if [ "$MODEL_COUNT" -eq 1 ]; then
    PRIMARY_MODEL="${MODEL_NAMES[0]}"
    if [[ "$PRIMARY_MODEL" == *"Opus"* ]]; then
      HAIKU_COST=$(echo "scale=2; $ESTIMATE_TOTAL_COST * 0.20" | bc)
      [[ "$HAIKU_COST" == .* ]] && HAIKU_COST="0$HAIKU_COST"
      echo ""
      echo "  💡 Switching Opus -> Haiku could save ~\$$(echo "scale=2; $ESTIMATE_TOTAL_COST - $HAIKU_COST" | bc) (80% reduction)"
    elif [[ "$PRIMARY_MODEL" == *"Sonnet"* ]]; then
      HAIKU_COST=$(echo "scale=2; $ESTIMATE_TOTAL_COST * 0.33" | bc)
      [[ "$HAIKU_COST" == .* ]] && HAIKU_COST="0$HAIKU_COST"
      echo ""
      echo "  💡 Switching Sonnet -> Haiku could save ~\$$(echo "scale=2; $ESTIMATE_TOTAL_COST - $HAIKU_COST" | bc) (67% reduction)"
    fi
  fi
  echo ""
fi

# ============================================================================
# TOKEN DISTRIBUTION / COST DRIVERS (billing-mode aware)
# ============================================================================

if [ "$BILLING_MODE" = "Sub" ]; then
  echo "💵 COST DRIVERS"
else
  echo "📊 TOKEN DISTRIBUTION"
fi
echo "--------------------------------------------------------------------------------"

# Calculate percentages
if (( $(echo "$ESTIMATE_TOTAL_COST > 0" | bc -l) )); then
  INPUT_PCT=$(echo "scale=0; 100 * $TOTAL_INPUT_COST / $ESTIMATE_TOTAL_COST" | bc)
  OUTPUT_PCT=$(echo "scale=0; 100 * $TOTAL_OUTPUT_COST / $ESTIMATE_TOTAL_COST" | bc)
  CACHE_WRITE_PCT=$(echo "scale=0; 100 * $TOTAL_CACHE_WRITE_COST / $ESTIMATE_TOTAL_COST" | bc)
  CACHE_READ_PCT=$(echo "scale=0; 100 * $TOTAL_CACHE_READ_COST / $ESTIMATE_TOTAL_COST" | bc)

  [[ "$INPUT_PCT" == .* ]] && INPUT_PCT="0"
  [[ "$OUTPUT_PCT" == .* ]] && OUTPUT_PCT="0"
  [[ "$CACHE_WRITE_PCT" == .* ]] && CACHE_WRITE_PCT="0"
  [[ "$CACHE_READ_PCT" == .* ]] && CACHE_READ_PCT="0"
else
  INPUT_PCT=0
  OUTPUT_PCT=0
  CACHE_WRITE_PCT=0
  CACHE_READ_PCT=0
fi

# Create visual bars
INPUT_BAR_LEN=$(echo "scale=0; $INPUT_PCT / 5" | bc)
OUTPUT_BAR_LEN=$(echo "scale=0; $OUTPUT_PCT / 5" | bc)
CACHE_W_BAR_LEN=$(echo "scale=0; $CACHE_WRITE_PCT / 5" | bc)
CACHE_R_BAR_LEN=$(echo "scale=0; $CACHE_READ_PCT / 5" | bc)

[[ "$INPUT_BAR_LEN" == .* ]] && INPUT_BAR_LEN="0"
[[ "$OUTPUT_BAR_LEN" == .* ]] && OUTPUT_BAR_LEN="0"
[[ "$CACHE_W_BAR_LEN" == .* ]] && CACHE_W_BAR_LEN="0"
[[ "$CACHE_R_BAR_LEN" == .* ]] && CACHE_R_BAR_LEN="0"

INPUT_BAR=$(printf '#%.0s' $(seq 1 $INPUT_BAR_LEN))$(printf -- '-%.0s' $(seq 1 $((20 - INPUT_BAR_LEN))))
OUTPUT_BAR=$(printf '#%.0s' $(seq 1 $OUTPUT_BAR_LEN))$(printf -- '-%.0s' $(seq 1 $((20 - OUTPUT_BAR_LEN))))
CACHE_W_BAR=$(printf '#%.0s' $(seq 1 $CACHE_W_BAR_LEN))$(printf -- '-%.0s' $(seq 1 $((20 - CACHE_W_BAR_LEN))))
CACHE_R_BAR=$(printf '#%.0s' $(seq 1 $CACHE_R_BAR_LEN))$(printf -- '-%.0s' $(seq 1 $((20 - CACHE_R_BAR_LEN))))

if [ "$BILLING_MODE" = "Sub" ]; then
  # Subscription users: show costs
  printf "  %-18s \$%-8s (%3d%%)  %s\n" "Input tokens:" "$TOTAL_INPUT_COST" "$INPUT_PCT" "$INPUT_BAR"
  printf "  %-18s \$%-8s (%3d%%)  %s\n" "Output tokens:" "$TOTAL_OUTPUT_COST" "$OUTPUT_PCT" "$OUTPUT_BAR"
  printf "  %-18s \$%-8s (%3d%%)  %s\n" "Cache writes:" "$TOTAL_CACHE_WRITE_COST" "$CACHE_WRITE_PCT" "$CACHE_W_BAR"
  printf "  %-18s \$%-8s (%3d%%)  %s\n" "Cache reads:" "$TOTAL_CACHE_READ_COST" "$CACHE_READ_PCT" "$CACHE_R_BAR"
else
  # API users: show percentages only (focus on patterns)
  printf "  %-18s (%3d%%)  %s\n" "Input tokens:" "$INPUT_PCT" "$INPUT_BAR"
  printf "  %-18s (%3d%%)  %s\n" "Output tokens:" "$OUTPUT_PCT" "$OUTPUT_BAR"
  printf "  %-18s (%3d%%)  %s\n" "Cache writes:" "$CACHE_WRITE_PCT" "$CACHE_W_BAR"
  printf "  %-18s (%3d%%)  %s\n" "Cache reads:" "$CACHE_READ_PCT" "$CACHE_R_BAR"
fi

# Token distribution insights (adapt messaging to billing mode)
echo ""
if [ "$BILLING_MODE" = "Sub" ]; then
  # Sub users: cost-focused insights
  if [ "$OUTPUT_PCT" -gt 60 ]; then
    echo "  ⚠️  Output tokens are your biggest cost driver (${OUTPUT_PCT}%) - consider asking for brevity"
  elif [ "$INPUT_PCT" -gt 60 ]; then
    echo "  ⚠️  Input tokens are your biggest cost driver (${INPUT_PCT}%) - context may be large"
  elif [ "$CACHE_WRITE_PCT" -gt 40 ]; then
    echo "  ⚠️  Cache writes are expensive (${CACHE_WRITE_PCT}%) - consider using /clear if cache not helping"
  else
    echo "  ✓ Balanced cost distribution across token types"
  fi
else
  # API users: pattern-focused insights
  if [ "$OUTPUT_PCT" -gt 60 ]; then
    echo "  💡 Output-heavy session (${OUTPUT_PCT}%) - responses are verbose"
    echo "     -> Actionable: Add brevity constraints to prompts"
  elif [ "$INPUT_PCT" -gt 60 ]; then
    echo "  💡 Input-heavy session (${INPUT_PCT}%) - large context or many tool results"
    echo "     -> Actionable: Consider using /clear to reset context"
  elif [ "$CACHE_WRITE_PCT" -gt 40 ]; then
    echo "  💡 High cache write activity (${CACHE_WRITE_PCT}%) - building up context"
    echo "     -> Actionable: Continue in session to benefit from cache reads"
  else
    echo "  ✓ Balanced token distribution - healthy session pattern"
  fi
fi
echo ""

# ============================================================================
# EFFICIENCY METRICS
# ============================================================================

echo "⚡ EFFICIENCY METRICS"
echo "--------------------------------------------------------------------------------"

# Calculate tool usage intensity (tools per message)
TOOL_INTENSITY=0
if [ "$USER_MESSAGES" -gt 0 ] && [ "$TOOL_CALLS" -gt 0 ]; then
  TOOL_INTENSITY=$(echo "scale=1; $TOOL_CALLS / $USER_MESSAGES" | bc)
  [[ "$TOOL_INTENSITY" == .* ]] && TOOL_INTENSITY="0$TOOL_INTENSITY"
fi

echo "  Tool Intensity:     ${TOOL_CALLS} tools (${TOOL_INTENSITY} tools/msg) across $USER_MESSAGES msgs"

# Determine intensity based on absolute count + rate + message count
INTENSITY_LABEL=""
if [ "$TOOL_CALLS" -ge 250 ]; then
  # High absolute count - check if it's concentrated or spread out
  if (( $(echo "$TOOL_INTENSITY >= 15.0" | bc -l) )); then
    INTENSITY_LABEL="Very intensive - heavy implementation with high tool rate"
  else
    INTENSITY_LABEL="Intensive - substantial work across longer session"
  fi
elif [ "$TOOL_CALLS" -ge 100 ]; then
  # Moderate absolute count - check concentration
  if (( $(echo "$TOOL_INTENSITY >= 15.0" | bc -l) )); then
    INTENSITY_LABEL="Intensive - focused implementation burst"
  elif [ "$USER_MESSAGES" -ge 20 ]; then
    INTENSITY_LABEL="Moderate - steady workflow over extended session"
  else
    INTENSITY_LABEL="Moderate - standard coding workflow"
  fi
elif [ "$TOOL_CALLS" -ge 25 ]; then
  # Light absolute count
  if (( $(echo "$TOOL_INTENSITY >= 10.0" | bc -l) )); then
    INTENSITY_LABEL="Light - short but focused work session"
  else
    INTENSITY_LABEL="Light - planning/exploration phase"
  fi
elif [ "$TOOL_CALLS" -gt 0 ]; then
  INTENSITY_LABEL="Minimal - mostly conversational with some tool use"
else
  INTENSITY_LABEL="No tools used yet"
fi

echo "                      ->$INTENSITY_LABEL"
echo ""

# Calculate response verbosity (avg output tokens per message)
RESPONSE_VERBOSITY=0
if [ "$USER_MESSAGES" -gt 0 ] && [ "$OUTPUT_TOKENS" -gt 0 ]; then
  RESPONSE_VERBOSITY=$(echo "scale=0; $OUTPUT_TOKENS / $USER_MESSAGES" | bc)
  [[ "$RESPONSE_VERBOSITY" == .* ]] && RESPONSE_VERBOSITY="0"
fi

echo "  Response Verbosity: $(printf "%'d" $RESPONSE_VERBOSITY) tokens/msg"
if [ "$RESPONSE_VERBOSITY" -gt 3000 ]; then
  # Check if high verbosity + high tool intensity = detailed implementation
  if [ "$TOOL_CALLS" -ge 100 ] && (( $(echo "$TOOL_INTENSITY >= 10.0" | bc -l) )); then
    echo "                      ->Very verbose - detailed implementation explanations"
  else
    echo "                      ->Very verbose - consider brevity constraints"
  fi
elif [ "$RESPONSE_VERBOSITY" -gt 1500 ]; then
  echo "                      ->Moderately verbose - typical for detailed work"
elif [ "$RESPONSE_VERBOSITY" -gt 0 ]; then
  echo "                      ->Concise responses - good efficiency"
else
  echo "                      ->No messages yet"
fi
echo ""
echo "  Output/Input Ratio: ${OUTPUT_INPUT_RATIO}x"
if (( $(echo "$OUTPUT_INPUT_RATIO > 3.0" | bc -l) )); then
  echo "                      ->AI is verbose - consider asking for brevity"
elif (( $(echo "$OUTPUT_INPUT_RATIO < 1.0" | bc -l) )); then
  echo "                      ->AI is concise - good efficiency"
else
  echo "                      ->Typical verbosity level"
fi
echo ""
echo "  Cache Hit Rate:     ${CACHE_EFFICIENCY}%"
if (( $(echo "$CACHE_EFFICIENCY >= 70" | bc -l) )); then
  echo "                      ->Excellent - stay in session (saved ~\$$CACHE_READ_COST_SAVED)"
elif (( $(echo "$CACHE_EFFICIENCY >= 40" | bc -l) )); then
  echo "                      ->Moderate - session working OK"
elif [ "$TOTAL_CACHE_TOKENS" -gt 0 ]; then
  echo "                      ->Low - consider /clear to refresh"
else
  echo "                      ->No cache data yet"
fi
echo ""
printf "  Cost per Token:     \$%.8f\n" "$COST_PER_TOKEN"
echo ""

# ============================================================================
# USAGE SECTION - Different for API vs Subscription
# ============================================================================

if [ "$BILLING_MODE" = "Sub" ]; then
  USAGE_HEADER="📊 SESSION USAGE ESTIMATE"
  USAGE_NOTE="  📌 Your usage is included in subscription - no additional charges."
  USAGE_NOTE2="     These API-equivalent estimates (with 10% safety margin) show value extraction."
else
  USAGE_HEADER="📊 SESSION METRICS"
  USAGE_NOTE="  💡 For actual billing costs, use the /cost command."
  USAGE_NOTE2="     These metrics help optimize session efficiency and context usage."
fi

echo "$USAGE_HEADER"
echo "--------------------------------------------------------------------------------"
if [ "$BILLING_MODE" = "Sub" ]; then
  echo "  Messages: $USER_MESSAGES | Tools: $TOOL_CALLS | Cost: ~\$$ESTIMATE_TOTAL_COST"
  echo "  Cache Efficiency: ${CACHE_EFFICIENCY}% | Tokens: $(printf "%'d" $TOTAL_TOKENS)"
else
  echo "  Messages: $USER_MESSAGES | Tools: $TOOL_CALLS | Cache Efficiency: ${CACHE_EFFICIENCY}%"
  echo "  Total Tokens: $(printf "%'d" $TOTAL_TOKENS)"
fi
echo ""
echo "  Token Breakdown:"
echo "    Input: $(printf "%'d" $INPUT_TOKENS) | Output: $(printf "%'d" $OUTPUT_TOKENS)"
echo "    Cache Writes: $(printf "%'d" $CACHE_CREATION_TOKENS) | Cache Reads: $(printf "%'d" $CACHE_READ_TOKENS)"
echo ""
echo "$USAGE_NOTE"
if [ -n "$USAGE_NOTE2" ]; then
  echo "$USAGE_NOTE2"
fi

echo ""

# ============================================================================
# SMART RECOMMENDATIONS (Prioritized by savings)
# ============================================================================

if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
  echo "🎯 TOP OPTIMIZATION ACTIONS (by potential savings)"
  echo "--------------------------------------------------------------------------------"

  DISPLAY_COUNT=$((${#RECOMMENDATIONS[@]} < 4 ? ${#RECOMMENDATIONS[@]} : 4))
  for ((i=0; i<DISPLAY_COUNT; i++)); do
    REC_NUM=$((i + 1))
    REC_TEXT="${RECOMMENDATIONS[i]}"
    REC_SAVE="${REC_SAVINGS[i]}"

    if [ "$BILLING_MODE" = "Sub" ]; then
      # Sub users: show dollar savings
      if (( $(echo "$REC_SAVE > 0.01" | bc -l) )); then
        SAVINGS_TEXT="Save ~\$$REC_SAVE/10 msgs"
        REDUCTION_PCT=$(echo "scale=0; 100 * $REC_SAVE / ($COST_PER_MESSAGE * 10)" | bc)
        [[ "$REDUCTION_PCT" == .* ]] && REDUCTION_PCT="0"
        if [ "$REDUCTION_PCT" -gt 0 ]; then
          SAVINGS_TEXT="$SAVINGS_TEXT (${REDUCTION_PCT}% reduction)"
        fi
      else
        SAVINGS_TEXT="Optimize session health"
      fi
    else
      # API users: show efficiency benefits (no dollar amounts)
      if (( $(echo "$REC_SAVE > 0.01" | bc -l) )); then
        REDUCTION_PCT=$(echo "scale=0; 100 * $REC_SAVE / ($COST_PER_MESSAGE * 10)" | bc)
        [[ "$REDUCTION_PCT" == .* ]] && REDUCTION_PCT="0"
        if [ "$REDUCTION_PCT" -gt 50 ]; then
          SAVINGS_TEXT="High efficiency gain (${REDUCTION_PCT}% improvement)"
        elif [ "$REDUCTION_PCT" -gt 20 ]; then
          SAVINGS_TEXT="Moderate efficiency gain (${REDUCTION_PCT}% improvement)"
        else
          SAVINGS_TEXT="Incremental efficiency gain (${REDUCTION_PCT}% improvement)"
        fi
      else
        SAVINGS_TEXT="Optimize session health"
      fi
    fi

    echo "  $REC_NUM. $REC_TEXT"
    echo "     -> $SAVINGS_TEXT"
  done
  echo ""
else
  echo "💡 INSIGHTS"
  echo "--------------------------------------------------------------------------------"
  echo "  ✓ Session efficiency looks good - continue with current workflow"
  echo ""
fi

# ============================================================================
# TRAJECTORY (billing-mode aware)
# ============================================================================

if [ "$BILLING_MODE" = "Sub" ]; then
  # Subscription users: cost trajectory
  echo "📈 TRAJECTORY"
  echo "--------------------------------------------------------------------------------"
  echo "  At current rate (\$${COST_PER_MESSAGE}/msg):"
  if [ "$USER_MESSAGES" -gt 0 ]; then
    PROJECTED_10=$(echo "scale=2; $COST_PER_MESSAGE * 10" | bc)
    [[ "$PROJECTED_10" == .* ]] && PROJECTED_10="0$PROJECTED_10"
    echo "    • Next 10 messages: ~\$$PROJECTED_10"

    HOURLY_MSGS=$(echo "scale=0; 60 / ($USER_MESSAGES / 1)" | bc 2>/dev/null || echo "N/A")
    if [ "$HOURLY_MSGS" != "N/A" ] && [ "$HOURLY_MSGS" -gt 0 ]; then
      HOURLY_COST=$(echo "scale=2; $COST_PER_MESSAGE * $HOURLY_MSGS" | bc)
      [[ "$HOURLY_COST" == .* ]] && HOURLY_COST="0$HOURLY_COST"
      echo "    • Projected hourly rate: ~\$$HOURLY_COST at current pace"
    fi
  else
    echo "    • Next 10 messages: N/A (no messages yet)"
  fi
  echo ""
else
  # API users: efficiency trends
  echo "📊 SESSION INSIGHTS"
  echo "--------------------------------------------------------------------------------"

  # Context growth rate
  if [ "$USER_MESSAGES" -gt 1 ]; then
    AVG_CONTEXT_GROWTH=$(echo "scale=0; ($INPUT_TOKENS + $CACHE_CREATION_TOKENS) / $USER_MESSAGES" | bc)
    [[ "$AVG_CONTEXT_GROWTH" == .* ]] && AVG_CONTEXT_GROWTH="0"
    echo "  Context Growth:     $(printf "%'d" $AVG_CONTEXT_GROWTH) tokens/msg average"
    if [ "$AVG_CONTEXT_GROWTH" -gt 50000 ]; then
      echo "                      ->Fast growth - consider /clear soon"
    elif [ "$AVG_CONTEXT_GROWTH" -gt 20000 ]; then
      echo "                      ->Moderate growth - monitor context size"
    else
      echo "                      ->Slow growth - healthy pace"
    fi
    echo ""
  fi

  # Tool usage pattern
  echo "  Tool Pattern:       ${TOOL_CALLS} tools (${TOOL_INTENSITY} tools/msg) across $USER_MESSAGES msgs"

  # Same intensity logic as main section
  if [ "$TOOL_CALLS" -ge 250 ]; then
    if (( $(echo "$TOOL_INTENSITY >= 15.0" | bc -l) )); then
      echo "                      ->Very intensive - heavy implementation with high tool rate"
    else
      echo "                      ->Intensive - substantial work across longer session"
    fi
  elif [ "$TOOL_CALLS" -ge 100 ]; then
    if (( $(echo "$TOOL_INTENSITY >= 15.0" | bc -l) )); then
      echo "                      ->Intensive - focused implementation burst"
    elif [ "$USER_MESSAGES" -ge 20 ]; then
      echo "                      ->Moderate - steady workflow over extended session"
    else
      echo "                      ->Moderate - standard coding workflow"
    fi
  elif [ "$TOOL_CALLS" -ge 25 ]; then
    if (( $(echo "$TOOL_INTENSITY >= 10.0" | bc -l) )); then
      echo "                      ->Light - short but focused work session"
    else
      echo "                      ->Light - planning/exploration phase"
    fi
  elif [ "$TOOL_CALLS" -gt 0 ]; then
    echo "                      ->Minimal - mostly conversational with some tool use"
  else
    echo "                      ->No tools used yet"
  fi
  echo ""

  # Cache performance trend
  echo "  Cache Performance:  ${CACHE_EFFICIENCY}% hit rate"
  if (( $(echo "$CACHE_EFFICIENCY > 90" | bc -l) )); then
    echo "                      ->Excellent - stay in session"
  elif (( $(echo "$CACHE_EFFICIENCY > 70" | bc -l) )); then
    echo "                      ->Good - cache is helping"
  elif (( $(echo "$CACHE_EFFICIENCY > 50" | bc -l) )); then
    echo "                      ->Moderate - some benefit"
  else
    echo "                      ->Low - consider /clear to rebuild cache"
  fi
  echo ""
fi

echo "--------------------------------------------------------------------------------"
echo ""
echo "📁 Session: $SESSION_ID"
echo ""

exit 0
  echo "  Cache Efficiency: ${CACHE_EFFICIENCY}% | Tokens: $(printf "%'d" $TOTAL_TOKENS)"
else
  echo "  Messages: $USER_MESSAGES | Tools: $TOOL_CALLS | Cache Efficiency: ${CACHE_EFFICIENCY}%"
  echo "  Total Tokens: $(printf "%'d" $TOTAL_TOKENS)"
fi
echo ""
echo "  Token Breakdown:"
echo "    Input: $(printf "%'d" $INPUT_TOKENS) | Output: $(printf "%'d" $OUTPUT_TOKENS)"
echo "    Cache Writes: $(printf "%'d" $CACHE_CREATION_TOKENS) | Cache Reads: $(printf "%'d" $CACHE_READ_TOKENS)"
echo ""
echo "$USAGE_NOTE"
if [ -n "$USAGE_NOTE2" ]; then
  echo "$USAGE_NOTE2"
fi

echo ""

# ============================================================================
# SMART RECOMMENDATIONS (Prioritized by savings)
# ============================================================================

if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
  echo "🎯 TOP OPTIMIZATION ACTIONS (by potential savings)"
  echo "--------------------------------------------------------------------------------"

  DISPLAY_COUNT=$((${#RECOMMENDATIONS[@]} < 4 ? ${#RECOMMENDATIONS[@]} : 4))
  for ((i=0; i<DISPLAY_COUNT; i++)); do
    REC_NUM=$((i + 1))
    REC_TEXT="${RECOMMENDATIONS[i]}"
    REC_SAVE="${REC_SAVINGS[i]}"

    if [ "$BILLING_MODE" = "Sub" ]; then
      # Sub users: show dollar savings
      if (( $(echo "$REC_SAVE > 0.01" | bc -l) )); then
        SAVINGS_TEXT="Save ~\$$REC_SAVE/10 msgs"
        REDUCTION_PCT=$(echo "scale=0; 100 * $REC_SAVE / ($COST_PER_MESSAGE * 10)" | bc)
        [[ "$REDUCTION_PCT" == .* ]] && REDUCTION_PCT="0"
        if [ "$REDUCTION_PCT" -gt 0 ]; then
          SAVINGS_TEXT="$SAVINGS_TEXT (${REDUCTION_PCT}% reduction)"
        fi
      else
        SAVINGS_TEXT="Optimize session health"
      fi
    else
      # API users: show efficiency benefits (no dollar amounts)
      if (( $(echo "$REC_SAVE > 0.01" | bc -l) )); then
        REDUCTION_PCT=$(echo "scale=0; 100 * $REC_SAVE / ($COST_PER_MESSAGE * 10)" | bc)
        [[ "$REDUCTION_PCT" == .* ]] && REDUCTION_PCT="0"
        if [ "$REDUCTION_PCT" -gt 50 ]; then
          SAVINGS_TEXT="High efficiency gain (${REDUCTION_PCT}% improvement)"
        elif [ "$REDUCTION_PCT" -gt 20 ]; then
          SAVINGS_TEXT="Moderate efficiency gain (${REDUCTION_PCT}% improvement)"
        else
          SAVINGS_TEXT="Incremental efficiency gain (${REDUCTION_PCT}% improvement)"
        fi
      else
        SAVINGS_TEXT="Optimize session health"
      fi
    fi

    echo "  $REC_NUM. $REC_TEXT"
    echo "     -> $SAVINGS_TEXT"
  done
  echo ""
else
  echo "💡 INSIGHTS"
  echo "--------------------------------------------------------------------------------"
  echo "  ✓ Session efficiency looks good - continue with current workflow"
  echo ""
fi

# ============================================================================
# TRAJECTORY (billing-mode aware)
# ============================================================================

if [ "$BILLING_MODE" = "Sub" ]; then
  # Subscription users: cost trajectory
  echo "📈 TRAJECTORY"
  echo "--------------------------------------------------------------------------------"
  echo "  At current rate (\$${COST_PER_MESSAGE}/msg):"
  if [ "$USER_MESSAGES" -gt 0 ]; then
    PROJECTED_10=$(echo "scale=2; $COST_PER_MESSAGE * 10" | bc)
    [[ "$PROJECTED_10" == .* ]] && PROJECTED_10="0$PROJECTED_10"
    echo "    • Next 10 messages: ~\$$PROJECTED_10"

    HOURLY_MSGS=$(echo "scale=0; 60 / ($USER_MESSAGES / 1)" | bc 2>/dev/null || echo "N/A")
    if [ "$HOURLY_MSGS" != "N/A" ] && [ "$HOURLY_MSGS" -gt 0 ]; then
      HOURLY_COST=$(echo "scale=2; $COST_PER_MESSAGE * $HOURLY_MSGS" | bc)
      [[ "$HOURLY_COST" == .* ]] && HOURLY_COST="0$HOURLY_COST"
      echo "    • Projected hourly rate: ~\$$HOURLY_COST at current pace"
    fi
  else
    echo "    • Next 10 messages: N/A (no messages yet)"
  fi
  echo ""
else
  # API users: efficiency trends
  echo "📊 SESSION INSIGHTS"
  echo "--------------------------------------------------------------------------------"

  # Context growth rate
  if [ "$USER_MESSAGES" -gt 1 ]; then
    AVG_CONTEXT_GROWTH=$(echo "scale=0; ($INPUT_TOKENS + $CACHE_CREATION_TOKENS) / $USER_MESSAGES" | bc)
    [[ "$AVG_CONTEXT_GROWTH" == .* ]] && AVG_CONTEXT_GROWTH="0"
    echo "  Context Growth:     $(printf "%'d" $AVG_CONTEXT_GROWTH) tokens/msg average"
    if [ "$AVG_CONTEXT_GROWTH" -gt 50000 ]; then
      echo "                      ->Fast growth - consider /clear soon"
    elif [ "$AVG_CONTEXT_GROWTH" -gt 20000 ]; then
      echo "                      ->Moderate growth - monitor context size"
    else
      echo "                      ->Slow growth - healthy pace"
    fi
    echo ""
  fi

  # Tool usage pattern
  echo "  Tool Pattern:       ${TOOL_CALLS} tools (${TOOL_INTENSITY} tools/msg) across $USER_MESSAGES msgs"

  # Same intensity logic as main section
  if [ "$TOOL_CALLS" -ge 250 ]; then
    if (( $(echo "$TOOL_INTENSITY >= 15.0" | bc -l) )); then
      echo "                      ->Very intensive - heavy implementation with high tool rate"
    else
      echo "                      ->Intensive - substantial work across longer session"
    fi
  elif [ "$TOOL_CALLS" -ge 100 ]; then
    if (( $(echo "$TOOL_INTENSITY >= 15.0" | bc -l) )); then
      echo "                      ->Intensive - focused implementation burst"
    elif [ "$USER_MESSAGES" -ge 20 ]; then
      echo "                      ->Moderate - steady workflow over extended session"
    else
      echo "                      ->Moderate - standard coding workflow"
    fi
  elif [ "$TOOL_CALLS" -ge 25 ]; then
    if (( $(echo "$TOOL_INTENSITY >= 10.0" | bc -l) )); then
      echo "                      ->Light - short but focused work session"
    else
      echo "                      ->Light - planning/exploration phase"
    fi
  elif [ "$TOOL_CALLS" -gt 0 ]; then
    echo "                      ->Minimal - mostly conversational with some tool use"
  else
    echo "                      ->No tools used yet"
  fi
  echo ""

  # Cache performance trend
  echo "  Cache Performance:  ${CACHE_EFFICIENCY}% hit rate"
  if (( $(echo "$CACHE_EFFICIENCY > 90" | bc -l) )); then
    echo "                      ->Excellent - stay in session"
  elif (( $(echo "$CACHE_EFFICIENCY > 70" | bc -l) )); then
    echo "                      ->Good - cache is helping"
  elif (( $(echo "$CACHE_EFFICIENCY > 50" | bc -l) )); then
    echo "                      ->Moderate - some benefit"
  else
    echo "                      ->Low - consider /clear to rebuild cache"
  fi
  echo ""
fi

echo "--------------------------------------------------------------------------------"
echo ""
echo "📁 Session: $SESSION_ID"
echo ""

exit 0
    REC_SAVE="${REC_SAVINGS[i]}"

    if [ "$BILLING_MODE" = "Sub" ]; then
      # Sub users: show dollar savings
      if (( $(echo "$REC_SAVE > 0.01" | bc -l) )); then
        SAVINGS_TEXT="Save ~\$$REC_SAVE/10 msgs"
        REDUCTION_PCT=$(echo "scale=0; 100 * $REC_SAVE / ($COST_PER_MESSAGE * 10)" | bc)
        [[ "$REDUCTION_PCT" == .* ]] && REDUCTION_PCT="0"
        if [ "$REDUCTION_PCT" -gt 0 ]; then
          SAVINGS_TEXT="$SAVINGS_TEXT (${REDUCTION_PCT}% reduction)"
        fi
      else
        SAVINGS_TEXT="Optimize session health"
      fi
    else
      # API users: show efficiency benefits (no dollar amounts)
      if (( $(echo "$REC_SAVE > 0.01" | bc -l) )); then
        REDUCTION_PCT=$(echo "scale=0; 100 * $REC_SAVE / ($COST_PER_MESSAGE * 10)" | bc)
        [[ "$REDUCTION_PCT" == .* ]] && REDUCTION_PCT="0"
        if [ "$REDUCTION_PCT" -gt 50 ]; then
          SAVINGS_TEXT="High efficiency gain (${REDUCTION_PCT}% improvement)"
        elif [ "$REDUCTION_PCT" -gt 20 ]; then
          SAVINGS_TEXT="Moderate efficiency gain (${REDUCTION_PCT}% improvement)"
        else
          SAVINGS_TEXT="Incremental efficiency gain (${REDUCTION_PCT}% improvement)"
        fi
      else
        SAVINGS_TEXT="Optimize session health"
      fi
    fi

    echo "  $REC_NUM. $REC_TEXT"
    echo "     -> $SAVINGS_TEXT"
  done
  echo ""
else
  echo "💡 INSIGHTS"
  echo "--------------------------------------------------------------------------------"
  echo "  ✓ Session efficiency looks good - continue with current workflow"
  echo ""
fi

# ============================================================================
# TRAJECTORY (billing-mode aware)
# ============================================================================

if [ "$BILLING_MODE" = "Sub" ]; then
  # Subscription users: cost trajectory
  echo "📈 TRAJECTORY"
  echo "--------------------------------------------------------------------------------"
  echo "  At current rate (\$${COST_PER_MESSAGE}/msg):"
  if [ "$USER_MESSAGES" -gt 0 ]; then
    PROJECTED_10=$(echo "scale=2; $COST_PER_MESSAGE * 10" | bc)
    [[ "$PROJECTED_10" == .* ]] && PROJECTED_10="0$PROJECTED_10"
    echo "    • Next 10 messages: ~\$$PROJECTED_10"

    HOURLY_MSGS=$(echo "scale=0; 60 / ($USER_MESSAGES / 1)" | bc 2>/dev/null || echo "N/A")
    if [ "$HOURLY_MSGS" != "N/A" ] && [ "$HOURLY_MSGS" -gt 0 ]; then
      HOURLY_COST=$(echo "scale=2; $COST_PER_MESSAGE * $HOURLY_MSGS" | bc)
      [[ "$HOURLY_COST" == .* ]] && HOURLY_COST="0$HOURLY_COST"
      echo "    • Projected hourly rate: ~\$$HOURLY_COST at current pace"
    fi
  else
    echo "    • Next 10 messages: N/A (no messages yet)"
  fi
  echo ""
else
  # API users: efficiency trends
  echo "📊 SESSION INSIGHTS"
  echo "--------------------------------------------------------------------------------"

  # Context growth rate
  if [ "$USER_MESSAGES" -gt 1 ]; then
    AVG_CONTEXT_GROWTH=$(echo "scale=0; ($INPUT_TOKENS + $CACHE_CREATION_TOKENS) / $USER_MESSAGES" | bc)
    [[ "$AVG_CONTEXT_GROWTH" == .* ]] && AVG_CONTEXT_GROWTH="0"
    echo "  Context Growth:     $(printf "%'d" $AVG_CONTEXT_GROWTH) tokens/msg average"
    if [ "$AVG_CONTEXT_GROWTH" -gt 50000 ]; then
      echo "                      ->Fast growth - consider /clear soon"
    elif [ "$AVG_CONTEXT_GROWTH" -gt 20000 ]; then
      echo "                      ->Moderate growth - monitor context size"
    else
      echo "                      ->Slow growth - healthy pace"
    fi
    echo ""
  fi

  # Tool usage pattern
  echo "  Tool Pattern:       ${TOOL_INTENSITY} tools/msg"
  if (( $(echo "$TOOL_INTENSITY >= 15.0" | bc -l) )); then
    echo "                      ->Heavy implementation work (complex changes)"
  elif (( $(echo "$TOOL_INTENSITY >= 5.0" | bc -l) )); then
    echo "                      ->Standard coding workflow"
  elif (( $(echo "$TOOL_INTENSITY > 0" | bc -l) )); then
    echo "                      ->Planning/discussion phase"
  else
    echo "                      ->Conversational session"
  fi
  echo ""

  # Cache performance trend
  echo "  Cache Performance:  ${CACHE_EFFICIENCY}% hit rate"
  if (( $(echo "$CACHE_EFFICIENCY > 90" | bc -l) )); then
    echo "                      ->Excellent - stay in session"
  elif (( $(echo "$CACHE_EFFICIENCY > 70" | bc -l) )); then
    echo "                      ->Good - cache is helping"
  elif (( $(echo "$CACHE_EFFICIENCY > 50" | bc -l) )); then
    echo "                      ->Moderate - some benefit"
  else
    echo "                      ->Low - consider /clear to rebuild cache"
  fi
  echo ""
fi

echo "--------------------------------------------------------------------------------"
echo ""
echo "📁 Session: $SESSION_ID"
echo ""

exit 0
SCRIPT_EOF

chmod +x ~/.claude/hooks/show-session-stats.sh
echo "✓ Installed show-session-stats.sh (detailed stats)"


# Create slash command
cat > ~/.claude/commands/trip-computer.md << 'COMMAND_EOF'
---
description: Display trip computer analytics for the current session (rate, efficiency, cost drivers, recommendations)
---

Execute the session statistics script and display its output directly in your message text (not in a code block) so it's immediately visible without requiring expansion:

1. Run: ~/.claude/hooks/show-session-stats.sh
2. Capture the output
3. Display the full output as plain text in your response
4. Do not add any commentary, analysis, or interpretation - just show the trip computer output
COMMAND_EOF

echo "✓ Created /trip-computer command"

# Create session-end-stats.sh (session end hook)
cat > ~/.claude/hooks/session-end-stats.sh << 'HOOK_EOF'
#!/bin/bash
# Session end hook - Display final session statistics when Claude Code session ends
# Claude Code Session Stats - Version 0.9.4

# Read input from stdin (Claude Code provides JSON with session info)
INPUT=""
while IFS= read -r -t 1 line; do
  INPUT="${INPUT}${line}"
done

# Parse session information from JSON input
if [ -n "$INPUT" ]; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
  TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
  EXIT_REASON=$(echo "$INPUT" | jq -r '.reason // "unknown"' 2>/dev/null)
  CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
else
  # No input provided - cannot proceed
  echo "⚠️  SessionEnd hook: No session information provided" >&2
  exit 0
fi

# Validate required fields
if [ -z "$SESSION_ID" ] || [ -z "$TRANSCRIPT_PATH" ]; then
  echo "⚠️  SessionEnd hook: Missing session_id or transcript_path" >&2
  exit 0
fi

# Check if transcript file exists
if [ ! -f "$TRANSCRIPT_PATH" ]; then
  echo "⚠️  SessionEnd hook: Transcript file not found: $TRANSCRIPT_PATH" >&2
  exit 0
fi

# Change to the working directory where the session was active
if [ -n "$CWD" ] && [ -d "$CWD" ]; then
  cd "$CWD" || exit 0
fi

# Display session end banner
echo ""
echo "================================================================================"
echo "                          SESSION ENDED - FINAL STATS"
echo "================================================================================"
echo ""
echo "Session ID: $SESSION_ID"
echo "Exit Reason: $EXIT_REASON"
echo ""

# Run the trip computer to display final statistics
if [ -f "$HOME/.claude/hooks/show-session-stats.sh" ]; then
  # Execute show-session-stats.sh with the session ID
  "$HOME/.claude/hooks/show-session-stats.sh" "$SESSION_ID"
else
  echo "❌ Trip computer script not found at: $HOME/.claude/hooks/show-session-stats.sh"
  exit 1
fi

# Optional: Save session summary to a log file
# Uncomment the section below to enable session logging

# LOG_DIR="$HOME/.claude/session-logs"
# mkdir -p "$LOG_DIR"
# LOG_FILE="$LOG_DIR/sessions.log"
#
# # Extract key metrics from transcript
# USER_MESSAGES=$(jq -s '[.[] | select(.type == "user" and (.isMeta != true) and (.message.content | if type == "array" then all(.[]; .type != "tool_result") else (test("<command-name>|<command-args>|<local-command-stdout>|<command-message>") | not) end))] | length' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")
#
# # Log session end event
# echo "[$(date '+%Y-%m-%d %H:%M:%S')] Session $SESSION_ID ended ($EXIT_REASON) - $USER_MESSAGES messages" >> "$LOG_FILE"

echo ""
echo "--------------------------------------------------------------------------------"
echo ""

exit 0
HOOK_EOF

chmod +x ~/.claude/hooks/session-end-stats.sh
echo "✓ Installed session-end-stats.sh (session end hook)"
echo ""

echo "Configuring status line and hooks..."

# Configure settings.json
SETTINGS_FILE="$HOME/.claude/settings.json"

# Get absolute path to script and check for spaces
SCRIPT_PATH="$HOME/.claude/hooks/brief-stats.sh"

# Check if path contains spaces - if so, wrap with bash command
if [[ "$SCRIPT_PATH" == *" "* ]]; then
  # Path has spaces - use bash wrapper (jq will handle JSON escaping)
  STATUS_COMMAND="bash \"$SCRIPT_PATH\""
  echo "✓ Detected spaces in path, using bash wrapper"
else
  # No spaces - use simple path
  STATUS_COMMAND="$HOME/.claude/hooks/brief-stats.sh"
fi

if [ -f "$SETTINGS_FILE" ]; then
  # Backup existing settings
  cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup"
  echo "✓ Backed up existing settings to settings.json.backup"

  # Update statusLine and add SessionEnd hook using jq
  jq --arg cmd "$STATUS_COMMAND" \
     '.statusLine = {"type": "command", "command": $cmd} |
      .hooks.SessionEnd = [{"hooks": [{"type": "command", "command": ($ENV.HOME + "/.claude/hooks/session-end-stats.sh")}]}]' \
    "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
  echo "✓ Updated $HOME/.claude/settings.json (status line + SessionEnd hook)"
else
  # Create new settings file with both statusLine and SessionEnd hook
  jq -n --arg cmd "$STATUS_COMMAND" \
     '{statusLine: {type: "command", command: $cmd},
       hooks: {SessionEnd: [{hooks: [{type: "command", command: ($ENV.HOME + "/.claude/hooks/session-end-stats.sh")}]}]}}' \
    > "$SETTINGS_FILE"
  echo "✓ Created ~/.claude/settings.json (status line + SessionEnd hook)"
fi

echo ""
echo "Testing installation..."

# Test brief-stats.sh
BRIEF_OUTPUT=$(~/.claude/hooks/brief-stats.sh 2>&1)
if [ $? -eq 0 ]; then
  echo "✓ Status line script works: $BRIEF_OUTPUT"
else
  echo "⚠️  Status line script error (may be normal if no sessions exist yet)"
fi

# Test show-session-stats.sh (output not displayed, just checking exit code)
if ~/.claude/hooks/show-session-stats.sh >/dev/null 2>&1; then
  echo "✓ Detailed stats script works"
else
  echo "⚠️  Detailed stats script error (may be normal if no sessions exist yet)"
fi

echo ""
echo "================================================================"
echo "                  Installation Complete! ✓"
echo "================================================================"
echo ""
echo "What's installed:"
echo "  • Status line hook:  ~/.claude/hooks/brief-stats.sh"
echo "  • Detailed stats:    ~/.claude/hooks/show-session-stats.sh"
echo "  • Session end hook:  ~/.claude/hooks/session-end-stats.sh"
echo "  • Slash command:     /trip-computer"
echo "  • Configuration:     ~/.claude/settings.json"
echo "  • Billing config:    ~/.claude/hooks/.stats-config"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code to see the status line"
echo "  2. Type /trip-computer to view detailed analytics"
echo "  3. Check the status bar at the bottom of Claude Code"
echo ""
echo "What you'll see in the status line:"
echo "  💬 X msgs | 🔧 X tools | 🎯 XK tok | 💳 API ~\$X.XX"
echo "  or"
echo "  💬 X msgs | 🔧 X tools | 🎯 XK tok | 📅 Sub ~\$X.XX"
echo ""
echo "Features:"
echo "  ✓ User-configured billing mode ($BILLING_MODE)"
echo "  ✓ Model-specific pricing (Opus, Sonnet, Haiku)"
echo "  ✓ Agent activity indicator"
echo "  ✓ Accurate token deduplication"
echo "  ✓ Session-level cost tracking"
echo "  ✓ Automatic session end statistics display"
echo ""
echo "Enjoy your new stats tracking! 🚀"
