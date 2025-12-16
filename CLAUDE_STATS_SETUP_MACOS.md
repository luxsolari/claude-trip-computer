# Claude Code Stats Tracking Setup for macOS

This guide provides step-by-step instructions to set up session statistics tracking functionality (custom slash command and status line) for Claude Code on macOS.

## Overview

The stats tracking system consists of:
1. **Status Line Hook**: Displays real-time stats in the Claude Code status bar (messages, tools, tokens, cost, billing mode)
2. **Custom Slash Command**: `/trip-computer` command to display detailed session statistics
3. **Two Bash Scripts**: `brief-stats.sh` (for status line) and `show-session-stats.sh` (for detailed stats)
4. **Agent Detection**: Automatically shows "🤖 Sub-agents running, stand by..." when background agents are active

### Billing Mode Configuration

During installation, you'll select your billing mode:
- **API Billing** (💳 API): Pay-per-token billing via Anthropic API
- **Subscription Plan** (📅 Sub): Claude Pro or Max subscription with included usage and rate limits

Configuration method: Your selection is saved to `~/.claude/hooks/.stats-config` and used by both scripts to display the appropriate billing mode and disclaimer. You can change this later by re-running the installer or manually editing the config file.

## Prerequisites

- `bash` - Shell (pre-installed on macOS)
- `jq` - JSON processor
- `bc` - Command-line calculator (pre-installed on macOS)
- Homebrew (recommended for installing `jq`)

## Installation Steps

### Step 1: Install Prerequisites

**Install Homebrew (if not already installed):**
```bash
# Check if Homebrew is installed
which brew

# If not installed, install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Install jq:**
```bash
# Using Homebrew (recommended)
brew install jq

# Verify installation
jq --version
```

**Verify bc is available:**
```bash
# bc is pre-installed on macOS
bc --version
```

**Note:** macOS comes with bash pre-installed. However, it may be an older version. You can optionally upgrade to bash 5.x:
```bash
# Optional: Install latest bash
brew install bash

# Check bash version
bash --version

# The scripts work with both the default macOS bash (3.2+) and newer versions
```

### Step 2: Create Claude Hooks Directory

```bash
# Create the directory structure
mkdir -p ~/.claude/hooks
mkdir -p ~/.claude/commands

# Verify directories were created
ls -la ~/.claude/
```

### Step 3: Create the Brief Stats Script (Status Line)

Create the file `~/.claude/hooks/brief-stats.sh`:

```bash
cat > ~/.claude/hooks/brief-stats.sh << 'EOF'
# Brief session statistics displayed in the status line
# Claude Code Session Stats - Version 0.4.2

# Force C locale for consistent number formatting
export LC_NUMERIC=C

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
PROJECT_DIR=$(pwd | sed 's/\//-/g' | sed 's/_/-/g')
TRANSCRIPT_DIR="$HOME/.claude/projects/$PROJECT_DIR"

# Check for active sub-agents with robust detection
if [ -d "$TRANSCRIPT_DIR" ]; then
  NOW=$(date +%s)
  ACTIVE_AGENTS=0

  # Iterate through agent files if they exist
  for agent_file in "$TRANSCRIPT_DIR"/agent-*.jsonl; do
    # Check if file exists (glob may not match anything)
    if [ -f "$agent_file" ]; then
      # Get file modification time (macOS uses -f, Linux uses -c)
      FILE_MTIME=$(stat -f %m "$agent_file" 2>/dev/null || stat -c %Y "$agent_file" 2>/dev/null || echo 0)
      AGE=$((NOW - FILE_MTIME))

      # Multi-criteria check for active agents:
      # 1. File modified in last 3 seconds (stricter window to avoid false positives from old sessions)
      # 2. File size > 100 bytes (not just init/empty file)
      # 3. File is actively growing (check size twice with small delay)
      if [ "$AGE" -lt 3 ]; then
        # Get file size (macOS uses -f %z, Linux uses -c %s)
        FILE_SIZE_1=$(stat -f %z "$agent_file" 2>/dev/null || stat -c %s "$agent_file" 2>/dev/null || echo 0)

        # Check if file has meaningful content (> 100 bytes)
        if [ "$FILE_SIZE_1" -gt 100 ]; then
          # Wait briefly and check if file is still growing (active write)
          sleep 0.1
          FILE_SIZE_2=$(stat -f %z "$agent_file" 2>/dev/null || stat -c %s "$agent_file" 2>/dev/null || echo 0)

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

# If we have an active session ID, use it directly
if [ -n "$ACTIVE_SESSION_ID" ]; then
  TRANSCRIPT_PATH="$TRANSCRIPT_DIR/${ACTIVE_SESSION_ID}.jsonl"

  # If the transcript doesn't exist yet (new session), show zeroed stats
  if [ ! -f "$TRANSCRIPT_PATH" ]; then
    echo "💬 0 msgs | 🔧 0 tools | 🎯 0 tok | 💰 \$0.0000"
    exit 0
  fi
else
  # No active session - check if there's a recent transcript
  if [ -d "$TRANSCRIPT_DIR" ]; then
    TRANSCRIPT_PATH=$(ls -t "$TRANSCRIPT_DIR"/*.jsonl 2>/dev/null | head -1)
    if [ -z "$TRANSCRIPT_PATH" ]; then
      # No transcripts exist - show zeroed stats
      echo "💬 0 msgs | 🔧 0 tools | 🎯 0 tok | 💰 \$0.0000"
      exit 0
    fi
  else
    # New directory - show zeroed stats
    echo "💬 0 msgs | 🔧 0 tools | 🎯 0 tok | 💰 \$0.0000"
    exit 0
  fi
fi

# Calculate statistics from current session only
# Count messages and tool calls from current transcript
# Count only direct user prompts (exclude tool results, meta messages, and command messages)
USER_MESSAGES=$(jq -s '[.[] | select(.type == "user" and (.isMeta != true) and (.message.content | if type == "array" then all(.[]; .type != "tool_result") else (test("<command-name>|<command-args>|<local-command-stdout>|<command-message>") | not) end))] | length' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")

# Count tool uses - they are nested inside message.content arrays
TOOL_CALLS=$(jq -s '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")] | length' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")

# Parse current transcript and group by requestId + model
PER_MODEL_DATA=$(jq -s '
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
' "$TRANSCRIPT_PATH" 2>/dev/null || echo '[]')

# Calculate totals across all models
INPUT_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].input] | add // 0')
OUTPUT_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].output] | add // 0')
CACHE_CREATION_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].cache_creation] | add // 0')
CACHE_READ_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].cache_read] | add // 0')

# Calculate total tokens
TOTAL_TOKENS=$((INPUT_TOKENS + OUTPUT_TOKENS + CACHE_CREATION_TOKENS + CACHE_READ_TOKENS))

# Format tokens in industry standard abbreviation (K for thousands, M for millions)
if [ $TOTAL_TOKENS -ge 1000000 ]; then
  # Millions
  FORMATTED_TOKENS=$(echo "scale=1; $TOTAL_TOKENS / 1000000" | bc 2>/dev/null || echo "0")
  # Handle bc output starting with .
  if [[ "$FORMATTED_TOKENS" == .* ]]; then
    FORMATTED_TOKENS="0$FORMATTED_TOKENS"
  fi
  FORMATTED_TOKENS="${FORMATTED_TOKENS}M"
elif [ $TOTAL_TOKENS -ge 1000 ]; then
  # Thousands
  FORMATTED_TOKENS=$(echo "scale=1; $TOTAL_TOKENS / 1000" | bc 2>/dev/null || echo "0")
  if [[ "$FORMATTED_TOKENS" == .* ]]; then
    FORMATTED_TOKENS="0$FORMATTED_TOKENS"
  fi
  FORMATTED_TOKENS="${FORMATTED_TOKENS}K"
else
  # Less than 1000
  FORMATTED_TOKENS="$TOTAL_TOKENS"
fi

# Load billing mode from config file
CONFIG_FILE="$HOME/.claude/hooks/.stats-config"
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
else
  # Fallback to defaults if config doesn't exist
  BILLING_MODE="API"
  BILLING_ICON="💳"
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

# Format cost - handle bc output that starts with . (like .8809 -> 0.8809)
if [[ "$TOTAL_COST" == .* ]]; then
  TOTAL_COST="0$TOTAL_COST"
fi
FORMATTED_COST=$(printf "%.4f" "$TOTAL_COST" 2>/dev/null || echo "0.0000")

# Calculate cost per message for trajectory indicator
COST_PER_MESSAGE="0.00"
if [ "$USER_MESSAGES" -gt 0 ]; then
  COST_PER_MESSAGE=$(echo "scale=2; $TOTAL_COST / $USER_MESSAGES" | bc 2>/dev/null || echo "0.00")
  [[ "$COST_PER_MESSAGE" == .* ]] && COST_PER_MESSAGE="0$COST_PER_MESSAGE"
fi

# Output brief stats (single line for status bar) with billing mode indicator and cost per message
# Add "~" prefix to indicate estimate
echo "💬 $USER_MESSAGES msgs | 🔧 $TOOL_CALLS tools | 🎯 ${FORMATTED_TOKENS} tok | $BILLING_ICON $BILLING_MODE ~\$$FORMATTED_COST (\$$COST_PER_MESSAGE/msg)"

exit 0
EOF

# Make it executable
chmod +x ~/.claude/hooks/brief-stats.sh
```

### Step 4: Create the Detailed Stats Script

Create the file `~/.claude/hooks/show-session-stats.sh`:

```bash
cat > ~/.claude/hooks/show-session-stats.sh << 'EOF'
#!/bin/bash
set -e

# Helper script to display session statistics for current or specified session
# Claude Code Session Stats - Version 0.4.2
# Usage: ./show-session-stats.sh [session_id]

# If session_id provided, use it; otherwise find the most recent session
if [ -n "$1" ]; then
  SESSION_ID="$1"
else
  # Find the most recent transcript file for this project
  PROJECT_DIR=$(pwd | sed 's/\//-/g' | sed 's/_/-/g')
  TRANSCRIPT_DIR="$HOME/.claude/projects/$PROJECT_DIR"

  if [ -d "$TRANSCRIPT_DIR" ]; then
    TRANSCRIPT_PATH=$(ls -t "$TRANSCRIPT_DIR"/*.jsonl 2>/dev/null | head -1)
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
PROJECT_DIR=$(pwd | sed 's/\//-/g' | sed 's/_/-/g')
TRANSCRIPT_PATH="$HOME/.claude/projects/$PROJECT_DIR/${SESSION_ID}.jsonl"

if [ ! -f "$TRANSCRIPT_PATH" ]; then
  echo "❌ Transcript file not found: $TRANSCRIPT_PATH"
  exit 1
fi

# Calculate statistics from current session only
# Count messages and tool calls from current transcript
# Count only direct user prompts (exclude tool results, meta messages, and command messages)
USER_MESSAGES=$(jq -s '[.[] | select(.type == "user" and (.isMeta != true) and (.message.content | if type == "array" then all(.[]; .type != "tool_result") else (test("<command-name>|<command-args>|<local-command-stdout>|<command-message>") | not) end))] | length' "$TRANSCRIPT_PATH")

# Count tool uses - they are nested inside message.content arrays
TOOL_CALLS=$(jq -s '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")] | length' "$TRANSCRIPT_PATH")

# Parse current transcript and group by requestId + model to avoid double-counting
PER_MODEL_DATA=$(jq -s '
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
' "$TRANSCRIPT_PATH" 2>/dev/null || echo '[]')

# Calculate totals across all models
INPUT_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].input] | add // 0')
OUTPUT_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].output] | add // 0')
CACHE_CREATION_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].cache_creation] | add // 0')
CACHE_READ_TOKENS=$(echo "$PER_MODEL_DATA" | jq '[.[].cache_read] | add // 0')
TOTAL_TOKENS=$((INPUT_TOKENS + OUTPUT_TOKENS + CACHE_CREATION_TOKENS + CACHE_READ_TOKENS))

# Load billing mode from config file
CONFIG_FILE="$HOME/.claude/hooks/.stats-config"
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
  # Set display mode and note based on config
  if [ "$BILLING_MODE" = "API" ]; then
    BILLING_MODE_DISPLAY="API Billing"
    BILLING_NOTE="These estimates are for reference only and may not be representative of actual consumption as measured by your organization. Differences may occur due to background operations, timing variations, and API measurement methods."
  else
    BILLING_MODE_DISPLAY="Subscription Plan"
    BILLING_NOTE="These estimates are for reference only and may not be representative of actual consumption as measured by Anthropic. Your actual usage is included in your subscription plan. Differences may occur due to background operations, timing variations, and API measurement methods."
  fi
else
  # Fallback to defaults if config doesn't exist
  BILLING_MODE_DISPLAY="API Billing"
  BILLING_NOTE="These estimates are for reference only and may not be representative of actual consumption as measured by your organization. Differences may occur due to background operations, timing variations, and API measurement methods."
fi

# Helper function to get pricing for a model
get_model_pricing() {
  local model_name="$1"
  local input_rate output_rate cache_write_mult cache_read_mult

  # Detect model family and version
  if [[ "$model_name" == *"opus-4-5"* ]] || [[ "$model_name" == *"opus-4.5"* ]]; then
    input_rate=5
    output_rate=25
    cache_write_mult=1.25
    cache_read_mult=0.10
  elif [[ "$model_name" == *"opus-4"* ]] || [[ "$model_name" == *"opus-3"* ]] || [[ "$model_name" == *"opus"* ]]; then
    input_rate=15
    output_rate=75
    cache_write_mult=1.25
    cache_read_mult=0.10
  elif [[ "$model_name" == *"haiku-4-5"* ]] || [[ "$model_name" == *"haiku-4.5"* ]]; then
    input_rate=1
    output_rate=5
    cache_write_mult=1.25
    cache_read_mult=0.10
  elif [[ "$model_name" == *"haiku-3-5"* ]] || [[ "$model_name" == *"haiku-3.5"* ]]; then
    input_rate=0.80
    output_rate=4
    cache_write_mult=1.25
    cache_read_mult=0.10
  elif [[ "$model_name" == *"haiku-3"* ]] || [[ "$model_name" == *"haiku"* ]]; then
    input_rate=0.25
    output_rate=1.25
    cache_write_mult=1.20
    cache_read_mult=0.12
  else
    # Default to Sonnet 4.5 pricing
    input_rate=3
    output_rate=15
    cache_write_mult=1.25
    cache_read_mult=0.10
  fi

  echo "$input_rate $output_rate $cache_write_mult $cache_read_mult"
}

# Calculate costs per model
TOTAL_COST=0
MODEL_BREAKDOWN=""

# Iterate through each model in the data
MODEL_COUNT=$(echo "$PER_MODEL_DATA" | jq 'length')
for ((i=0; i<MODEL_COUNT; i++)); do
  MODEL_NAME=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].model")
  MODEL_INPUT=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].input")
  MODEL_OUTPUT=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].output")
  MODEL_CACHE_WRITE=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].cache_creation")
  MODEL_CACHE_READ=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].cache_read")

  # Get pricing for this model
  read INPUT_RATE OUTPUT_RATE CACHE_WRITE_MULT CACHE_READ_MULT < <(get_model_pricing "$MODEL_NAME")

  # Calculate costs for this model
  MODEL_COST=$(echo "scale=4; \
    ($MODEL_INPUT * $INPUT_RATE / 1000000) + \
    ($MODEL_OUTPUT * $OUTPUT_RATE / 1000000) + \
    ($MODEL_CACHE_WRITE * $INPUT_RATE * $CACHE_WRITE_MULT / 1000000) + \
    ($MODEL_CACHE_READ * $INPUT_RATE * $CACHE_READ_MULT / 1000000)" | bc)

  # Handle bc output starting with .
  if [[ "$MODEL_COST" == .* ]]; then
    MODEL_COST="0$MODEL_COST"
  fi

  # Add to total
  TOTAL_COST=$(echo "scale=4; $TOTAL_COST + $MODEL_COST" | bc)
  if [[ "$TOTAL_COST" == .* ]]; then
    TOTAL_COST="0$TOTAL_COST"
  fi

  # Detect model display name
  if [[ "$MODEL_NAME" == *"opus"* ]]; then
    MODEL_DISPLAY_NAME="Claude Opus"
  elif [[ "$MODEL_NAME" == *"haiku"* ]]; then
    MODEL_DISPLAY_NAME="Claude Haiku"
  else
    MODEL_DISPLAY_NAME="Claude Sonnet"
  fi

  # Calculate individual cost components for display
  INPUT_COST_DISPLAY=$(echo "scale=4; $MODEL_INPUT * $INPUT_RATE / 1000000" | bc)
  OUTPUT_COST_DISPLAY=$(echo "scale=4; $MODEL_OUTPUT * $OUTPUT_RATE / 1000000" | bc)
  CACHE_WRITE_COST_DISPLAY=$(echo "scale=4; $MODEL_CACHE_WRITE * $INPUT_RATE * $CACHE_WRITE_MULT / 1000000" | bc)
  CACHE_READ_COST_DISPLAY=$(echo "scale=4; $MODEL_CACHE_READ * $INPUT_RATE * $CACHE_READ_MULT / 1000000" | bc)

  # Handle bc output starting with .
  [[ "$INPUT_COST_DISPLAY" == .* ]] && INPUT_COST_DISPLAY="0$INPUT_COST_DISPLAY"
  [[ "$OUTPUT_COST_DISPLAY" == .* ]] && OUTPUT_COST_DISPLAY="0$OUTPUT_COST_DISPLAY"
  [[ "$CACHE_WRITE_COST_DISPLAY" == .* ]] && CACHE_WRITE_COST_DISPLAY="0$CACHE_WRITE_COST_DISPLAY"
  [[ "$CACHE_READ_COST_DISPLAY" == .* ]] && CACHE_READ_COST_DISPLAY="0$CACHE_READ_COST_DISPLAY"

  # Build breakdown string
  MODEL_BREAKDOWN="$MODEL_BREAKDOWN
  **${MODEL_DISPLAY_NAME}** ($MODEL_NAME):
    • Input: ${MODEL_INPUT} tokens (\$$INPUT_COST_DISPLAY)
    • Output: ${MODEL_OUTPUT} tokens (\$$OUTPUT_COST_DISPLAY)
    • Cache writes: ${MODEL_CACHE_WRITE} tokens (\$$CACHE_WRITE_COST_DISPLAY)
    • Cache reads: ${MODEL_CACHE_READ} tokens (\$$CACHE_READ_COST_DISPLAY)
    • Subtotal: \$$MODEL_COST
"
done

# ============================================================================
# ENHANCED ANALYTICS - "Trip Computer" Features
# ============================================================================

# Calculate additional metrics for enhanced display
COST_PER_MESSAGE=0
COST_PER_TOOL=0
if [ "$USER_MESSAGES" -gt 0 ]; then
  COST_PER_MESSAGE=$(echo "scale=4; $TOTAL_COST / $USER_MESSAGES" | bc)
  [[ "$COST_PER_MESSAGE" == .* ]] && COST_PER_MESSAGE="0$COST_PER_MESSAGE"
fi
if [ "$TOOL_CALLS" -gt 0 ]; then
  COST_PER_TOOL=$(echo "scale=4; $TOTAL_COST / $TOOL_CALLS" | bc)
  [[ "$COST_PER_TOOL" == .* ]] && COST_PER_TOOL="0$COST_PER_TOOL"
fi

# Calculate cache efficiency (percentage of reads vs total cached tokens)
TOTAL_CACHE_TOKENS=$((CACHE_CREATION_TOKENS + CACHE_READ_TOKENS))
CACHE_EFFICIENCY=0
if [ "$TOTAL_CACHE_TOKENS" -gt 0 ]; then
  CACHE_EFFICIENCY=$(echo "scale=1; 100 * $CACHE_READ_TOKENS / $TOTAL_CACHE_TOKENS" | bc)
  [[ "$CACHE_EFFICIENCY" == .* ]] && CACHE_EFFICIENCY="0$CACHE_EFFICIENCY"
fi

# Calculate output/input ratio (excluding cache)
OUTPUT_INPUT_RATIO="N/A"
if [ "$INPUT_TOKENS" -gt 0 ]; then
  OUTPUT_INPUT_RATIO=$(echo "scale=2; $OUTPUT_TOKENS / $INPUT_TOKENS" | bc)
  [[ "$OUTPUT_INPUT_RATIO" == .* ]] && OUTPUT_INPUT_RATIO="0$OUTPUT_INPUT_RATIO"
fi

# Calculate cost savings from cache
CACHE_READ_COST_SAVED=0
for ((i=0; i<MODEL_COUNT; i++)); do
  MODEL_NAME=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].model")
  MODEL_CACHE_READ=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].cache_read")
  read INPUT_RATE OUTPUT_RATE CACHE_WRITE_MULT CACHE_READ_MULT < <(get_model_pricing "$MODEL_NAME")

  # Saved cost = (full input rate - cache read rate) * tokens
  SAVED=$(echo "scale=4; ($MODEL_CACHE_READ * $INPUT_RATE * (1 - $CACHE_READ_MULT)) / 1000000" | bc)
  [[ "$SAVED" == .* ]] && SAVED="0$SAVED"
  CACHE_READ_COST_SAVED=$(echo "scale=4; $CACHE_READ_COST_SAVED + $SAVED" | bc)
  [[ "$CACHE_READ_COST_SAVED" == .* ]] && CACHE_READ_COST_SAVED="0$CACHE_READ_COST_SAVED"
done

# Calculate spending trajectory (project next 10 messages)
PROJECTED_NEXT_10="N/A"
if [ "$USER_MESSAGES" -gt 0 ]; then
  PROJECTED=$(echo "scale=2; $COST_PER_MESSAGE * 10" | bc)
  [[ "$PROJECTED" == .* ]] && PROJECTED="0$PROJECTED"
  PROJECTED_NEXT_10="\$$PROJECTED"
fi

# Calculate model usage mix (percentage breakdown)
MODEL_USAGE_MIX=""
for ((i=0; i<MODEL_COUNT; i++)); do
  MODEL_NAME=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].model")
  MODEL_TOTAL_TOKENS=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].input + .[$i].output + .[$i].cache_creation + .[$i].cache_read")

  if [ "$TOTAL_TOKENS" -gt 0 ]; then
    MODEL_PERCENTAGE=$(echo "scale=1; 100 * $MODEL_TOTAL_TOKENS / $TOTAL_TOKENS" | bc)
    [[ "$MODEL_PERCENTAGE" == .* ]] && MODEL_PERCENTAGE="0$MODEL_PERCENTAGE"
  else
    MODEL_PERCENTAGE="0"
  fi

  # Detect model display name
  if [[ "$MODEL_NAME" == *"opus"* ]]; then
    MODEL_SHORT="Opus"
  elif [[ "$MODEL_NAME" == *"haiku"* ]]; then
    MODEL_SHORT="Haiku"
  else
    MODEL_SHORT="Sonnet"
  fi

  if [ -n "$MODEL_USAGE_MIX" ]; then
    MODEL_USAGE_MIX="${MODEL_USAGE_MIX}, ${MODEL_SHORT} ${MODEL_PERCENTAGE}%"
  else
    MODEL_USAGE_MIX="${MODEL_SHORT} ${MODEL_PERCENTAGE}%"
  fi
done

# Calculate cost breakdown by category
INPUT_COST_TOTAL=0
OUTPUT_COST_TOTAL=0
CACHE_WRITE_COST_TOTAL=0
CACHE_READ_COST_TOTAL=0

for ((i=0; i<MODEL_COUNT; i++)); do
  MODEL_NAME=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].model")
  MODEL_INPUT=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].input")
  MODEL_OUTPUT=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].output")
  MODEL_CACHE_WRITE=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].cache_creation")
  MODEL_CACHE_READ=$(echo "$PER_MODEL_DATA" | jq -r ".[$i].cache_read")

  read INPUT_RATE OUTPUT_RATE CACHE_WRITE_MULT CACHE_READ_MULT < <(get_model_pricing "$MODEL_NAME")

  INPUT_COST=$(echo "scale=4; $MODEL_INPUT * $INPUT_RATE / 1000000" | bc)
  OUTPUT_COST=$(echo "scale=4; $MODEL_OUTPUT * $OUTPUT_RATE / 1000000" | bc)
  CACHE_WRITE_COST=$(echo "scale=4; $MODEL_CACHE_WRITE * $INPUT_RATE * $CACHE_WRITE_MULT / 1000000" | bc)
  CACHE_READ_COST=$(echo "scale=4; $MODEL_CACHE_READ * $INPUT_RATE * $CACHE_READ_MULT / 1000000" | bc)

  [[ "$INPUT_COST" == .* ]] && INPUT_COST="0$INPUT_COST"
  [[ "$OUTPUT_COST" == .* ]] && OUTPUT_COST="0$OUTPUT_COST"
  [[ "$CACHE_WRITE_COST" == .* ]] && CACHE_WRITE_COST="0$CACHE_WRITE_COST"
  [[ "$CACHE_READ_COST" == .* ]] && CACHE_READ_COST="0$CACHE_READ_COST"

  INPUT_COST_TOTAL=$(echo "scale=4; $INPUT_COST_TOTAL + $INPUT_COST" | bc)
  OUTPUT_COST_TOTAL=$(echo "scale=4; $OUTPUT_COST_TOTAL + $OUTPUT_COST" | bc)
  CACHE_WRITE_COST_TOTAL=$(echo "scale=4; $CACHE_WRITE_COST_TOTAL + $CACHE_WRITE_COST" | bc)
  CACHE_READ_COST_TOTAL=$(echo "scale=4; $CACHE_READ_COST_TOTAL + $CACHE_READ_COST" | bc)
done

[[ "$INPUT_COST_TOTAL" == .* ]] && INPUT_COST_TOTAL="0$INPUT_COST_TOTAL"
[[ "$OUTPUT_COST_TOTAL" == .* ]] && OUTPUT_COST_TOTAL="0$OUTPUT_COST_TOTAL"
[[ "$CACHE_WRITE_COST_TOTAL" == .* ]] && CACHE_WRITE_COST_TOTAL="0$CACHE_WRITE_COST_TOTAL"
[[ "$CACHE_READ_COST_TOTAL" == .* ]] && CACHE_READ_COST_TOTAL="0$CACHE_READ_COST_TOTAL"

# Calculate percentages for cost drivers
if (( $(echo "$TOTAL_COST > 0" | bc -l) )); then
  INPUT_PCT=$(echo "scale=0; 100 * $INPUT_COST_TOTAL / $TOTAL_COST" | bc)
  OUTPUT_PCT=$(echo "scale=0; 100 * $OUTPUT_COST_TOTAL / $TOTAL_COST" | bc)
  CACHE_WRITE_PCT=$(echo "scale=0; 100 * $CACHE_WRITE_COST_TOTAL / $TOTAL_COST" | bc)
  CACHE_READ_PCT=$(echo "scale=0; 100 * $CACHE_READ_COST_TOTAL / $TOTAL_COST" | bc)

  [[ "$INPUT_PCT" == .* ]] && INPUT_PCT="0$INPUT_PCT"
  [[ "$OUTPUT_PCT" == .* ]] && OUTPUT_PCT="0$OUTPUT_PCT"
  [[ "$CACHE_WRITE_PCT" == .* ]] && CACHE_WRITE_PCT="0$CACHE_WRITE_PCT"
  [[ "$CACHE_READ_PCT" == .* ]] && CACHE_READ_PCT="0$CACHE_READ_PCT"
else
  INPUT_PCT=0
  OUTPUT_PCT=0
  CACHE_WRITE_PCT=0
  CACHE_READ_PCT=0
fi

# Generate context growth insight (first message vs current)
FIRST_INPUT=$(jq -s '[.[] | select(.message.usage.input_tokens)] | .[0].message.usage.input_tokens // 0' "$TRANSCRIPT_PATH")
LATEST_INPUT=$(jq -s '[.[] | select(.message.usage.input_tokens)] | .[-1].message.usage.input_tokens // 0' "$TRANSCRIPT_PATH")
CONTEXT_GROWTH="N/A"
CONTEXT_GROWTH_PCT="N/A"
if [ "$FIRST_INPUT" -gt 0 ] && [ "$LATEST_INPUT" -gt 0 ]; then
  GROWTH=$(echo "scale=0; (($LATEST_INPUT - $FIRST_INPUT) * 100) / $FIRST_INPUT" | bc)
  [[ "$GROWTH" == .* ]] && GROWTH="0$GROWTH"
  CONTEXT_GROWTH="${FIRST_INPUT} → ${LATEST_INPUT} tokens"
  CONTEXT_GROWTH_PCT="+${GROWTH}%"
fi

# Generate smart recommendations
RECOMMENDATIONS=""

# Recommendation: Cache efficiency
if [ "$TOTAL_CACHE_TOKENS" -gt 0 ]; then
  if (( $(echo "$CACHE_EFFICIENCY < 50" | bc -l) )); then
    RECOMMENDATIONS="${RECOMMENDATIONS}  • Low cache reuse (${CACHE_EFFICIENCY}%) - consider starting fresh session for better efficiency\n"
  elif (( $(echo "$CACHE_EFFICIENCY >= 80" | bc -l) )); then
    RECOMMENDATIONS="${RECOMMENDATIONS}  • Excellent cache reuse (${CACHE_EFFICIENCY}%) - caching is working well!\n"
  fi
fi

# Recommendation: Output driving cost
if (( $(echo "$OUTPUT_PCT >= 50" | bc -l) )); then
  RECOMMENDATIONS="${RECOMMENDATIONS}  • Output tokens driving cost (${OUTPUT_PCT}%) - consider more focused prompts or smaller tasks\n"
fi

# Recommendation: Context growth
if [ "$FIRST_INPUT" -gt 0 ] && [ "$LATEST_INPUT" -gt 0 ]; then
  GROWTH_RATIO=$(echo "scale=2; $LATEST_INPUT / $FIRST_INPUT" | bc)
  [[ "$GROWTH_RATIO" == .* ]] && GROWTH_RATIO="0$GROWTH_RATIO"

  if (( $(echo "$GROWTH_RATIO >= 5" | bc -l) )); then
    RECOMMENDATIONS="${RECOMMENDATIONS}  • Context grew ${CONTEXT_GROWTH_PCT} - /clear might improve performance and reduce costs\n"
  fi
fi

# Recommendation: High cost per message
if [ "$USER_MESSAGES" -gt 5 ] && (( $(echo "$COST_PER_MESSAGE > 0.10" | bc -l) )); then
  RECOMMENDATIONS="${RECOMMENDATIONS}  • High cost/message (\$${COST_PER_MESSAGE}) - consider using Haiku for simpler tasks\n"
fi

# If no recommendations, provide positive feedback
if [ -z "$RECOMMENDATIONS" ]; then
  RECOMMENDATIONS="  • Session efficiency looks good! No optimization suggestions at this time.\n"
fi

# ============================================================================
# OUTPUT - Enhanced "Trip Computer" Display
# ============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "🚗 **SESSION TRIP COMPUTER** - Real-time Analytics & Insights"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "📊 **Quick Overview**"
echo "  Billing Mode: $BILLING_MODE_DISPLAY"
echo "  Messages: $USER_MESSAGES | Tool Calls: $TOOL_CALLS | Models: $MODEL_COUNT"
echo "  Total Cost: **~\$$TOTAL_COST**"
echo ""
echo "───────────────────────────────────────────────────────────────────────"
echo "💸 **RATE & TRAJECTORY**"
echo "───────────────────────────────────────────────────────────────────────"
echo "  Average Cost per Message: \$$COST_PER_MESSAGE"
echo "  Average Cost per Tool Call: \$$COST_PER_TOOL"
echo "  Projected Next 10 Messages: ~$PROJECTED_NEXT_10"
echo ""
echo "───────────────────────────────────────────────────────────────────────"
echo "⚡ **EFFICIENCY METRICS**"
echo "───────────────────────────────────────────────────────────────────────"
echo "  Cache Efficiency: ${CACHE_EFFICIENCY}% reads (saving ~\$$CACHE_READ_COST_SAVED)"
echo "  Output/Input Ratio: ${OUTPUT_INPUT_RATIO}:1"
echo "  Token Efficiency: $(echo "scale=0; $TOTAL_TOKENS / $USER_MESSAGES" | bc) tokens/message"
echo ""
echo "───────────────────────────────────────────────────────────────────────"
echo "📊 **SESSION INSIGHTS**"
echo "───────────────────────────────────────────────────────────────────────"
echo "  Model Mix: $MODEL_USAGE_MIX"
echo "  Context Growth: $CONTEXT_GROWTH ($CONTEXT_GROWTH_PCT)"
echo ""
echo "  💡 Recommendations:"
echo -e "$RECOMMENDATIONS"
echo "───────────────────────────────────────────────────────────────────────"
echo "💰 **WHAT'S DRIVING COST**"
echo "───────────────────────────────────────────────────────────────────────"
echo "  Output Tokens:  ${OUTPUT_PCT}% (\$$OUTPUT_COST_TOTAL)"
echo "  Cache Writes:   ${CACHE_WRITE_PCT}% (\$$CACHE_WRITE_COST_TOTAL)"
echo "  Input Tokens:   ${INPUT_PCT}% (\$$INPUT_COST_TOTAL)"
echo "  Cache Reads:    ${CACHE_READ_PCT}% (\$$CACHE_READ_COST_TOTAL)"
echo ""
echo "───────────────────────────────────────────────────────────────────────"
echo "📋 **TOKEN USAGE DETAILS**"
echo "───────────────────────────────────────────────────────────────────────"
echo "  Input: $(printf "%'d" $INPUT_TOKENS) | Output: $(printf "%'d" $OUTPUT_TOKENS)"
echo "  Cache Writes: $(printf "%'d" $CACHE_CREATION_TOKENS) | Cache Reads: $(printf "%'d" $CACHE_READ_TOKENS)"
echo "  Total: $(printf "%'d" $TOTAL_TOKENS) tokens"
echo ""
echo "───────────────────────────────────────────────────────────────────────"
echo "🔧 **MODEL BREAKDOWN**"
echo "───────────────────────────────────────────────────────────────────────"
echo "$MODEL_BREAKDOWN"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "ℹ️  **Note**: $BILLING_NOTE"
echo ""
echo "📁 Session: $SESSION_ID"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""

exit 0
EOF

# Make it executable
chmod +x ~/.claude/hooks/show-session-stats.sh
```

### Step 5: Create the Custom Slash Command

Create the file `~/.claude/commands/trip-computer.md`:

```bash
cat > ~/.claude/commands/trip-computer.md << 'EOF'
---
description: Display statistics for the current session (messages, tool calls, estimated costs)
---

Execute the session statistics script to display current session metrics:

```bash
~/.claude/hooks/show-session-stats.sh
```

Display the output to the user.
EOF
```

### Step 6: Configure the Status Line

**Option A: Create new settings file (if it doesn't exist)**

```bash
cat > ~/.claude/settings.json << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/hooks/brief-stats.sh"
  }
}
EOF
```

**Option B: Update existing settings file (if it exists)**

```bash
# Backup existing settings
cp ~/.claude/settings.json ~/.claude/settings.json.backup

# Add statusLine configuration using jq
jq '.statusLine = {"type": "command", "command": "~/.claude/hooks/brief-stats.sh"}' \
  ~/.claude/settings.json.backup > ~/.claude/settings.json
```

**Option C: Manual configuration**

Edit `~/.claude/settings.json` and add/modify the `statusLine` section:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/hooks/brief-stats.sh"
  }
}
```

### Step 7: Verify File Permissions

```bash
# Ensure all scripts are executable
chmod +x ~/.claude/hooks/brief-stats.sh
chmod +x ~/.claude/hooks/show-session-stats.sh

# Verify the files exist and are executable
ls -lh ~/.claude/hooks/
ls -lh ~/.claude/commands/

# Expected output should show -rwxr-xr-x for the .sh files
```

### Step 8: Test the Setup

**Test 1: Test the brief stats script directly**
```bash
cd ~  # or any project directory
~/.claude/hooks/brief-stats.sh
```

Expected output (if no sessions): `💬 0 msgs | 🔧 0 tools | 🎯 0 tok | 💰 $0.0000`

**Test 2: Test the detailed stats script**
```bash
~/.claude/hooks/show-session-stats.sh
```

Expected output: Session statistics or error message if no sessions found.

**Test 3: Test the slash command**
- Start Claude Code in a project directory
- Type `/trip-computer` and press Enter
- Should display detailed session statistics

**Test 4: Check the status line**
- Start Claude Code
- Look at the status bar at the bottom
- Should see: `💬 X msgs | 🔧 X tools | 🎯 XK tok | 📅 Sub ~$X.XXXX` (subscription) or `💳 API ~$X.XXXX` (API billing)

## Troubleshooting

### Issue: Scripts not executable
```bash
# Solution: Set execute permissions
chmod +x ~/.claude/hooks/brief-stats.sh
chmod +x ~/.claude/hooks/show-session-stats.sh
```

### Issue: `jq: command not found`
```bash
# Install using Homebrew
brew install jq

# Verify installation
which jq
jq --version
```

### Issue: Status line not updating
1. Restart Claude Code completely (quit and reopen)
2. Verify the script path in `settings.json` is correct
3. Test the script manually: `~/.claude/hooks/brief-stats.sh`
4. Check script has execute permissions: `ls -l ~/.claude/hooks/brief-stats.sh`
5. Run with debug mode: `bash -x ~/.claude/hooks/brief-stats.sh`

### Issue: Transcript files not found
- Claude Code stores transcripts in `~/.claude/projects/PROJECT_DIR/SESSION_ID.jsonl`
- The project directory name is derived from the working directory path
- Example: `/Users/john/Code/my_project` → `~/.claude/projects/-Users-john-Code-my-project/`
- Check if the directory exists: `ls -la ~/.claude/projects/`

### Issue: Permission denied errors
```bash
# Ensure scripts are executable and readable
chmod +x ~/.claude/hooks/*.sh
chmod 644 ~/.claude/commands/*.md
chmod 644 ~/.claude/settings.json

# Check ownership
ls -la ~/.claude/
# Should be owned by your user account
```

### Issue: sed behaves differently (BSD sed on macOS)
- macOS uses BSD sed by default (not GNU sed)
- The scripts are compatible with both versions
- If you encounter issues, you can install GNU sed:
  ```bash
  brew install gnu-sed
  # GNU sed will be available as 'gsed'
  ```

### Issue: Older bash version (macOS default bash 3.2)
```bash
# Check bash version
bash --version

# macOS ships with bash 3.2 (due to licensing)
# The scripts are compatible with bash 3.2+
# For bash 5.x features, install via Homebrew:
brew install bash

# To use the new bash as default (optional):
sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'
chsh -s /usr/local/bin/bash
```

### Issue: Homebrew not found
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Follow the installation instructions
# Add Homebrew to your PATH (as instructed during installation)
```

### Issue: Terminal not displaying emoji correctly
- Most macOS terminals (Terminal.app, iTerm2) support emoji by default
- Ensure your terminal font supports emoji
- Try using iTerm2 if Terminal.app has issues
- Check your terminal preferences for Unicode/UTF-8 support

## macOS-Specific Notes

### Terminal Applications
- **Terminal.app**: Built-in macOS terminal, works well with the scripts
- **iTerm2**: Popular third-party terminal with excellent UTF-8/emoji support
- Both terminals support the scripts without modification

### Shell Configuration
- macOS uses bash by default (version 3.2.57 on older systems)
- macOS Catalina+ uses zsh as the default shell
- The scripts work with both bash and zsh

### Apple Silicon (M1/M2/M3) vs Intel
- Scripts work identically on both architectures
- Homebrew installation path differs:
  - Intel: `/usr/local/bin/`
  - Apple Silicon: `/opt/homebrew/bin/`
- Homebrew handles this automatically

### File System Considerations
- macOS uses case-insensitive (but case-preserving) file system by default
- The scripts handle this correctly
- No special considerations needed

## Billing Modes Explained

### Subscription Plan (📅 Sub)
- **When shown**: When `ANTHROPIC_API_KEY` environment variable is NOT set
- **Plans**: Claude Pro ($20/month), Max 5x ($100/month), Max 20x ($200/month)
- **Cost display**: Shows estimated API-equivalent cost for reference
- **Important**: Actual usage is included in your subscription; no additional charges apply
- **Limits**: Usage limits reset every 5 hours and are shared across Claude web/desktop/mobile and Claude Code

### API Billing (💳 API)
- **When shown**: When `ANTHROPIC_API_KEY` environment variable IS set
- **Billing**: Pay-per-token usage via Anthropic API prepaid credits
- **Cost display**: Shows actual API costs based on token usage
- **Important**: You are charged for actual usage; monitor costs carefully

### Switching Between Modes
To switch from API to subscription:
```bash
unset ANTHROPIC_API_KEY
# Then use /login in Claude Code to authenticate with your subscription
```

To switch from subscription to API:
```bash
export ANTHROPIC_API_KEY="your-api-key-here"
# Restart Claude Code
```

## Cost Calculation Details

The scripts automatically detect which model you're using and apply the correct pricing:

| Model | Input ($/MTok) | Output ($/MTok) | Cache Write ($/MTok) | Cache Read ($/MTok) |
|-------|----------------|-----------------|----------------------|--------------------|
| **Opus 4.5** | $5.00 | $25.00 | $6.25 (1.25x input) | $0.50 (0.10x input) |
| **Opus 3/4/4.1** | $15.00 | $75.00 | $18.75 (1.25x input) | $1.50 (0.10x input) |
| **Sonnet 3.7/4/4.5** | $3.00 | $15.00 | $3.75 (1.25x input) | $0.30 (0.10x input) |
| **Haiku 4.5** | $1.00 | $5.00 | $1.25 (1.25x input) | $0.10 (0.10x input) |
| **Haiku 3.5** | $0.80 | $4.00 | $1.00 (1.25x input) | $0.08 (0.10x input) |
| **Haiku 3** | $0.25 | $1.25 | $0.30 (1.20x input) | $0.03 (0.12x input) |

**Model Detection**: The scripts automatically read the model name from your session transcript and apply the appropriate pricing rates.

**Cache Token Pricing**:
- Most models: Cache writes cost 1.25x the regular input rate, and cache reads cost 0.10x the regular input rate
- Haiku 3 exception: Cache writes are 1.20x input rate ($0.30), cache reads are 0.12x input rate ($0.03)

## Understanding Session-Level vs Billing-Level Costs

### What `/trip-computer` Shows (Session-Level)
- **Scope**: THIS specific Claude Code session only
- **Source**: Session transcript file (real-time, accurate for the session)
- **Purpose**: Understand per-session costs and make real-time decisions
- **Benefits**:
  - Immediate feedback on session expenses
  - Track cost per coding task
  - Make model-switching decisions mid-session
  - Identify expensive workflows

### What `/cost` Shows (Billing-Level)
- **Scope**: Finalized billing data from Anthropic's API
- **Source**: Anthropic's billing system
- **Purpose**: Show what you'll actually be charged
- **Includes**: May include agent sessions, background tasks, different time windows

### Why They Differ
These tools measure at different levels of granularity:
- **`/trip-computer`** = "Speedometer" - how much is THIS session costing?
- **`/cost`** = "Odometer" - what's my total billing?

Both are accurate for their purpose. Session-level tracking provides **more immediate, actionable insights** for development work.

**Note on Estimates**:
- **For subscription users**: Session costs show estimated API-equivalent value. Your actual usage is included in your subscription with no additional charges.
- **For API users**: Session costs show estimated usage for this session. Your final bill (via `/cost`) may differ due to billing system aggregation and timing.

To update pricing, edit the cost calculation sections in both scripts.

## Additional Notes

- The status line updates automatically on each Claude Code interaction
- The `/trip-computer` command can be run anytime to see detailed statistics
- Session transcripts are stored in `~/.claude/projects/` organized by project directory
- Each session has a unique ID and corresponding `.jsonl` file
- Stats are calculated from the transcript file in real-time
- Scripts are compatible with both default macOS bash (3.2+) and newer bash versions
- Emoji display works natively in macOS terminals

## File Locations Reference

```
~/.claude/
├── hooks/
│   ├── brief-stats.sh          # Status line script
│   └── show-session-stats.sh   # Detailed stats script
├── commands/
│   └── trip-computer.md        # Slash command definition
├── settings.json               # Global Claude Code settings
└── projects/
    └── -Users-username-Code-project/
        └── SESSION_ID.jsonl    # Session transcripts
```

## Support

If you encounter issues:
1. Verify all prerequisites are installed (`jq`, `bc`)
2. Check file permissions (scripts must be executable)
3. Test scripts manually before using in Claude Code
4. Check Claude Code documentation for statusLine and custom commands
5. Ensure Homebrew is properly installed and in PATH
6. Verify bash version compatibility (3.2+ required)
7. Check terminal UTF-8/emoji support
8. Review Console.app logs for any system-level errors
