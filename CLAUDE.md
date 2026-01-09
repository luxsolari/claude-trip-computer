# CLAUDE.md - Project Context for Claude Code

## Project Overview

**Name:** Claude Code Session Stats Tracking
**Version:** 0.9.3 (see [CHANGELOG.md](CHANGELOG.md) for version history)
**Purpose:** Real-time session optimization and analytics system for Claude Code
**Type:** CLI utility / Developer tool
**Status:** Development phase (0.x.x versions) - Optimization-first analytics with billing-mode differentiation, tool usage tracking, health scoring, and actionable insights

## What This Project Does

This project provides comprehensive session analytics for Claude Code, enabling developers to:

1. **Monitor session efficiency** via status line with tool usage intensity, cache efficiency, and response verbosity
2. **Track optimization metrics** including tool call patterns, cache hit rates, and token distribution
3. **View detailed analytics** via `/trip-computer` command with actionable optimization insights
4. **Automatic session-end statistics** - Full trip computer analytics displayed when sessions end
5. **Configure billing mode** via interactive setup (API vs Subscription)
   - **API users**: Focus on session optimization, use `/cost` for actual billing
   - **Sub users**: Show API-equivalent value with 10% safety margin
6. **Apply model-specific analysis** (Opus 4.5, Sonnet 4.5, Haiku)
7. **Show agent activity** when sub-agents are running
8. **Deduplicate token counts** to avoid 3-4x inflation

## Project Structure

```
claude-session-stats/
├── install-claude-stats.sh           # Automated installer (Linux/macOS/WSL)
├── install-claude-stats.bat          # Windows batch wrapper (double-click)
├── VERSION                           # Current version number (semver)
├── CHANGELOG.md                      # Version history and changes
├── README.md                          # Main documentation
├── CLAUDE.md                          # Project context (this file)
├── TROUBLESHOOTING.md                # Troubleshooting & manual setup guide
└── .git/                             # Git repository
```

### Installation Targets (created by installer)

```
~/.claude/
├── hooks/
│   ├── brief-stats.sh              # Status line script (real-time brief stats)
│   ├── show-session-stats.sh       # Detailed stats script (full breakdown)
│   ├── session-end-stats.sh        # Session end hook (automatic final stats)
│   └── .stats-config               # Billing mode configuration
├── commands/
│   └── trip-computer.md            # /trip-computer slash command
└── settings.json                   # Claude Code configuration
```

## Key Components

### 1. brief-stats.sh (Status Line Script)

**Location:** `~/.claude/hooks/brief-stats.sh`
**Purpose:** Displays real-time session efficiency metrics in Claude Code status bar
**Current Version:** 0.9.3 - Fixed message counting failure due to jq syntax error

**Output Format (API users):**
```
💬 X msgs | 🔧 X tools (X.X tools/msg) | 🎯 XM tok | ⚡ X% cached | 📝 XK tok/msg | 📈 /trip-computer
```

**Output Format (Subscription users):**
```
💬 X msgs | 🔧 X tools (X.X tools/msg) | 🎯 XM tok | ⚡ X% cached | 📝 XK tok/msg | 📅 ~$X.XX value | 📈 /trip-computer
```

**Key Features (from v0.8.1):**
- **🔧 X tools (X.X tools/msg)** - Tool usage intensity showing complexity of tasks
- **📝 XK tok/msg** - Response verbosity (avg output tokens per message)
- **Fixed in v0.8.1**: Removed buggy context budget metric (redundant with `/context` command)
- **API users**: Cost display removed (use `/cost` for billing)
- **Sub users**: Cost estimation with 10% safety margin retained

**Key Features:**
- Detects active sub-agents (shows "🤖 Sub-agents running, stand by...")
- Reads session ID from stdin (provided by Claude Code)
- Calculates cost per message for spending rate visibility
- Finds transcript files in `~/.claude/projects/PROJECT_DIR/SESSION_ID.jsonl`
- Deduplicates tokens by `requestId` to avoid counting same API call multiple times
- Reads billing mode from `.stats-config` (configured during installation)
- Detects model from transcript to apply correct pricing
- Formats tokens in K/M notation (1.5K, 13.5M)
- Shows billing icon: 💳 for API, 📅 for Subscription

### 2. show-session-stats.sh (Detailed Stats Script / Trip Computer)

**Location:** `~/.claude/hooks/show-session-stats.sh`
**Purpose:** Session optimization dashboard with efficiency metrics, health scoring, and actionable recommendations
**Triggered by:** `/trip-computer` slash command
**Current Version:** 0.9.3 - Fixed message counting failure due to jq syntax error

**Core Functionality:**
- Analyzes session transcript for efficiency optimization opportunities
- **Billing-mode aware display**: Complete output differentiation for API vs Sub users
- **API users**: Optimization-focused (no cost display, use `/cost` for billing)
- **Sub users**: Value awareness + optimization (cost estimates with 10% safety margin)
- Provides actionable recommendations prioritized by impact
- Automated session health assessment (0-100 score)
- Real-time session insights (context growth, tool patterns, cache performance)

**Output Sections:**

**📊 Quick Summary:**
- Health status (Excellent/Good/Fair/Poor/Critical) with score (X/100)
- Cost trend indicator (Rising ➚ / Stable ➡️ / Falling ➘)
- Action recommendation count

**📈 Session Health (0-100):**
- 5-star rating system (⭐⭐⭐⭐⭐)
- Component breakdown:
  - Cache efficiency contribution (0-40 points)
  - Cost per message contribution (0-30 points)
  - Context growth contribution (0-30 points)
- Clear indicators (✅ positive, ⚠️ warning, ➡️ neutral)

**🤖 Model Mix:**
- Per-model usage breakdown with visual bars
- Request count per model
- Cost percentage per model
- Smart switching suggestions (e.g., "Switching Sonnet → Haiku could save $X (67% reduction)")

**📊 Token Distribution / 💵 Cost Drivers (v0.9.0):**
- **API users**: "📊 TOKEN DISTRIBUTION" - Percentages only with actionable insights
  - `Input tokens: (0%) ███░░░` (no dollar amounts)
  - Actionable insights: "💡 Output-heavy session → Add brevity constraints"
- **Sub users**: "💵 COST DRIVERS" - Dollar amounts + percentages
  - `Input tokens: $0.0033 (0%) ███░░░` (full cost breakdown)
  - Cost-focused insights: "⚠️ Output tokens are your biggest cost driver"

**⚡ Efficiency Metrics:**
- Tool Intensity - Multi-dimensional assessment combining:
  - **Absolute tool count**: Total tools used (≥250 very intensive, ≥100 moderate, ≥25 light)
  - **Tool rate**: Tools per message (intensity concentration)
  - **Message count**: Session length context
  - **Assessment examples**:
    - `Very intensive - heavy implementation with high tool rate` (≥250 tools + ≥15 tools/msg)
    - `Intensive - focused implementation burst` (≥100 tools + ≥15 tools/msg, <20 msgs)
    - `Moderate - steady workflow over extended session` (≥100 tools, ≥20 msgs, lower rate)
    - `Light - planning/exploration phase` (25-99 tools, <10 tools/msg)
- Response verbosity (avg tokens per message) - Context-aware:
  - High verbosity + high tool intensity = legitimate detailed implementation
  - High verbosity + low tool intensity = consider brevity constraints
- Output/Input ratio with verbosity assessment
- Cache hit rate with efficiency insights
- Cost per token (8 decimal precision, reference only)
- Contextual guidance for each metric

**📊 Session Metrics / Usage Estimate (v0.9.0):**
- **API users**: "📊 SESSION METRICS" - No cost display, optimization focus only
  - `Messages: X | Tools: Y | Cache Efficiency: Z%`
  - `Total Tokens: X,XXX,XXX`
  - Disclaimer: "Use /cost for official billing amounts"
- **Sub users**: "📊 SESSION USAGE ESTIMATE" - API-equivalent value with 10% safety margin
  - `Messages: X | Tools: Y | Cost: ~$X.XX`
  - `Cache Efficiency: Z% | Tokens: X,XXX,XXX`
  - Complete token breakdown (input, output, cache writes, cache reads)
  - Disclaimer: "API-equivalent estimates for reference (10% conservative buffer)"

**🎯 Top Optimization Actions (v0.9.0):**
- **API users**: Efficiency gains displayed (no dollar amounts)
  - `High efficiency gain (75% improvement)` - Major optimization potential
  - `Moderate efficiency gain (25% improvement)` - Incremental improvement
  - `Incremental efficiency gain (10% improvement)` - Minor optimization
  - Example: "Switch to Haiku for simple tasks → High efficiency gain (75% improvement)"
- **Sub users**: Dollar savings displayed (traditional cost-focused)
  - `Save ~$0.60/10 msgs (75% reduction)` - Financial impact clear
  - Example: "Switch to Haiku for simple tasks → Save ~$0.60/10 msgs (75% reduction)"
- Top 3 recommendations always shown, prioritized by potential impact
- Examples: Model switching, brevity constraints, cache optimization, prompt patterns

**📊 Session Insights / 📈 Trajectory (v0.9.0):**
- **API users**: "📊 SESSION INSIGHTS" - Real-time efficiency trends (replaces cost trajectory)
  - **Context Growth**: Average tokens/msg with growth rate assessment
    - `Fast growth → consider /clear soon` (>50K tokens/msg)
    - `Moderate growth → monitor context size` (20K-50K tokens/msg)
    - `Slow growth → healthy pace` (<20K tokens/msg)
  - **Tool Pattern**: Multi-dimensional intensity assessment
    - Shows: `X tools (Y tools/msg) across Z msgs`
    - `Very intensive - heavy implementation with high tool rate` (≥250 tools + ≥15 tools/msg)
    - `Intensive - focused implementation burst` (≥100 tools + ≥15 tools/msg)
    - `Moderate - steady workflow over extended session` (≥100 tools, ≥20 msgs)
    - `Light - planning/exploration phase` (25-99 tools, <10 tools/msg)
  - **Cache Performance**: Hit rate guidance
    - `Excellent → stay in session` (>90% hit rate)
    - `Good → cache is helping` (70-90% hit rate)
    - `Low → consider /clear to rebuild cache` (<50% hit rate)
- **Sub users**: "📈 TRAJECTORY" - Cost projection at current rate (traditional view)
  - Cost per message rate
  - Projected cost for next 10 messages
  - Hourly rate projection at current pace

**Key Features:**
- Best-effort calculations from transcript data (deduplication by requestId)
- Health scoring algorithm (40 pts cache + 30 pts cost + 30 pts context)
- Bubble sort for recommendation prioritization
- Emphasizes "what should I do?" over "what are the numbers?"
- Clear disclaimers about estimate accuracy
- Actionable insights always provided regardless of billing mode

### 2.5. Prompt Pattern Analysis (v0.6.0)

**Location:** Integrated into `show-session-stats.sh`
**Purpose:** Detect inefficient prompting patterns and recommend improvements to reduce costs
**Version:** 0.6.0 - Automatic prompt quality analysis

**Analysis Approach:**
- Pure bash pattern matching using jq regex
- No API calls required (free and instant)
- Always-on by default in `/trip-computer`
- Analyzes actual user prompts from session transcript

**Patterns Detected:**

**1. Vague/Broad Questions**
- **Detects:** Questions with "explain/describe/tell me/how does/what is/show me" WITHOUT "brief/concise/summary/in N points/limit/short"
- **Threshold:** >30% of prompts lacking constraints AND ≥2 vague prompts
- **Example:** "Explain how authentication works" vs "Briefly explain authentication in 3 points"
- **Estimated Savings:** ~25% reduction in output costs (~$0.25 per 10 messages)
- **Rationale:** Unconstrained questions lead to verbose responses, increasing output tokens

**2. Large Context Pastes**
- **Detects:** Prompts containing >200 lines of text (counted by newlines)
- **Threshold:** >20% of prompts with large pastes AND ≥1 occurrence
- **Example:** Pasting 300 lines of code vs using file references or breaking into chunks
- **Estimated Savings:** ~20% reduction in input + cache write costs (~$0.20 per 10 messages)
- **Rationale:** Large pastes increase input tokens and cache write costs (1.25x multiplier)

**3. Repeated Similar Questions**
- **Detects:** Low keyword diversity (average <15 unique words per prompt) across ≥3 messages
- **Method:** Counts unique words in each prompt after removing stop words and special characters
- **Example:** Asking "how do I fix X", "can you fix X", "fix X please" repeatedly
- **Estimated Savings:** ~15% reduction by asking complete questions upfront (~$0.15 per 10 messages)
- **Rationale:** Repetitive prompts indicate unclear initial responses or iterative refinement

**4. Missing Task Constraints**
- **Detects:** Coding tasks ("write/create/build/implement/add/fix/refactor/generate") without constraints ("max/limit/brief/under/less than/in N")
- **Threshold:** >40% of task prompts unconstrained AND ≥2 occurrences
- **Example:** "Write a function to sort users" vs "Write a short function (max 20 lines) to sort users by name"
- **Estimated Savings:** ~20% reduction in output costs (~$0.20 per 10 messages)
- **Rationale:** Unconstrained tasks generate over-engineered or verbose solutions

**Key Features:**
- **Regex-based detection:** Case-insensitive pattern matching for trigger keywords
- **Configurable thresholds:** Calibrated to minimize false positives (30%, 40% thresholds)
- **Savings calculations:** Based on actual session costs (TOTAL_OUTPUT_COST, TOTAL_INPUT_COST, etc.)
- **Integrated recommendations:** Automatically added to recommendation array and prioritized by bubble sort
- **High-level insights:** Shows aggregate patterns, not message-by-message critique
- **Cross-platform:** Works on Linux, macOS, Windows Git Bash using standard bash/jq

**Output Integration:**
Prompt analysis recommendations appear in the "🎯 TOP OPTIMIZATION ACTIONS" section alongside existing recommendations, prioritized by potential dollar savings.

Example:
```
🎯 TOP OPTIMIZATION ACTIONS (by potential savings)
  1. Add constraints to questions (brief, in N points)
     → Save ~$0.45/10 msgs (25% reduction)

  2. Specify format/length constraints for tasks
     → Save ~$0.36/10 msgs (20% reduction)

  3. Use file references instead of pasting large code
     → Save ~$0.28/10 msgs (15% reduction)
```

**Performance:**
- ~100-200ms additional processing time per `/trip-computer` invocation (negligible)
- No impact on status line (brief-stats.sh unchanged)
- No new dependencies or configuration required

### 3. trip-computer.md (Slash Command)

**Location:** `~/.claude/commands/trip-computer.md`
**Purpose:** Defines the `/trip-computer` custom slash command
**Action:** Executes `show-session-stats.sh` and displays output

### 3.5. session-end-stats.sh (Session End Hook)

**Location:** `~/.claude/hooks/session-end-stats.sh`
**Purpose:** Automatically display final session statistics when Claude Code sessions end
**Triggered by:** SessionEnd hook event (session exit, `/clear`, logout, etc.)
**Version:** 0.7.0 - Automatic session-end statistics display

**Core Functionality:**
- Receives session metadata from Claude Code via stdin (JSON format)
- Extracts session ID, transcript path, exit reason, and working directory
- Validates session information and transcript file existence
- Changes to session's working directory for accurate project detection
- Displays formatted "SESSION ENDED - FINAL STATS" banner
- Executes complete trip computer analytics for final session summary

**Input Format (from Claude Code):**
```json
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../session.jsonl",
  "cwd": "/Users/.../project",
  "permission_mode": "default",
  "hook_event_name": "SessionEnd",
  "reason": "exit"  // or "clear", "logout", "prompt_input_exit", "other"
}
```

**Output Sections:**
- Session ID and exit reason
- Complete trip computer analytics:
  - Quick summary with health score
  - Session health breakdown
  - Model mix analysis
  - Cost drivers breakdown
  - Efficiency metrics
  - Usage estimate
  - Top optimization actions
  - Trajectory projections

**Key Features:**
- **Automatic trigger** - No user action required, runs on session end
- **Context-aware** - Changes to session's working directory for accurate stats
- **Graceful error handling** - Validates all inputs, exits cleanly on errors
- **Zero-config** - Works immediately after installation
- **Optional logging** - Commented-out code for session history tracking
- **Perfect timing** - Statistics appear right when you finish a session

**Hook Configuration (in settings.json):**
```json
{
  "hooks": {
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/session-end-stats.sh"
          }
        ]
      }
    ]
  }
}
```

**Use Cases:**
- Review session costs after long coding sessions
- Understand efficiency trends over multiple sessions
- Validate optimization strategies (e.g., model switching)
- Budget awareness when ending work for the day
- Compare costs across different types of tasks
- Learn which workflows are most/least expensive

**Optional Session Logging:**
The script includes commented-out code to save session summaries to a log file:
```bash
LOG_DIR="$HOME/.claude/session-logs"
LOG_FILE="$LOG_DIR/sessions.log"
# Format: [timestamp] Session ID ended (reason) - N messages
```

Uncomment the logging section to enable historical session tracking.

### 4. install-claude-stats.sh (Automated Installer)

**Purpose:** One-command installation for all platforms
**Features:**
- Auto-detects OS (Linux, macOS, Windows WSL/Git Bash)
- Checks prerequisites (jq, bc)
- Interactive billing mode selection (API vs Subscription)
- Creates directory structure
- Installs all scripts
- Saves billing configuration to `.stats-config`
- Configures settings.json
- Tests installation
- Provides clear success message

## Technical Implementation Details

### Token Deduplication Algorithm

**Problem:** Session transcripts contain multiple entries per API call, causing 3-4x inflation
**Solution:** Group by `requestId` + `model`, take MAX value for each token type per request, then aggregate by model

**Key Insight:** We include ALL usage entries regardless of `isSidechain` status because:
- Sub-agent activities (web search, etc.) are billed
- Web searches typically cost $10 per 1,000 searches plus tokens
- All billable events must be aggregated for accurate cost tracking

```bash
# Deduplication JQ query (per-model aggregation)
jq -s '
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
'
```

**Note:** Web search costs appear in `/cost` output but may not have explicit `usage` entries in transcripts. This contributes to the typical 5-15% variance between our estimates and `/cost`.

### Cross-Project Agent Discovery (v0.7.1)

**Problem:** Agent transcript files (sub-agents for web search, complex tasks) may exist in different project directories when context is shared between sessions. Original implementation only searched the current project directory, missing cross-project agents and causing 14-16% systematic underestimation.

**Solution:** Extract agent IDs referenced in main transcript, search across ALL project directories to find agent files regardless of location.

**Implementation:**
```bash
# Build list of ALL transcript files for this session (main + agents)
ALL_TRANSCRIPTS=()
if [ -f "$TRANSCRIPT_PATH" ]; then
  ALL_TRANSCRIPTS+=("$TRANSCRIPT_PATH")
fi

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

# Parse ALL transcripts (main + agents) together
PER_MODEL_DATA=$(cat "${ALL_TRANSCRIPTS[@]}" | jq -s '...')
```

**Key Benefits:**
- Captures all billable agent activity regardless of project location
- Fixes systematic underestimation (from 14% under to 10.4% over with 5% safety margin)
- Handles cross-project context sharing correctly
- No performance impact (~100-200ms additional processing for `find` command)

**Why Cross-Project?**
When Claude Code shares context between sessions in different projects, agent files may be written to different project directories. The main session transcript still references these agents, and their usage is billed to your account, so we must include them for accurate cost tracking.

### Billing Mode Configuration

**Method:** User-configured during installation via interactive prompt
**Storage:** `~/.claude/hooks/.stats-config`
**Logic:**
- User selects billing mode during install (API or Subscription)
- Configuration saved to `.stats-config` file
- Scripts read from config file at runtime
- **API Billing** → 💳 icon, no cost display in status line, optimization focus
- **Subscription Plan** → 📅 icon, shows API-equivalent value with 10% safety margin

**Config File Format:**
```bash
# Claude Code Session Stats Configuration
BILLING_MODE="API"  # or "Sub"
BILLING_ICON="💳"   # or "📅"

# Cost Estimate Safety Margin
# For Subscription users: 1.10 (10% buffer)
# For API users: 1.00 (no margin - use /cost)
SAFETY_MARGIN="1.10"  # or "1.00"
```

### Model Detection & Pricing

**Detection:** Read `message.model` field from transcript and match against version patterns
**Pricing Tables (per million tokens):**

| Model | Input | Output | Cache Write (5m) | Cache Read | Multipliers |
|-------|-------|--------|------------------|------------|-------------|
| **Opus 4.5** | $5 | $25 | $6.25 | $0.50 | 1.25x / 0.10x |
| **Opus 3/4/4.1** | $15 | $75 | $18.75 | $1.50 | 1.25x / 0.10x |
| **Sonnet 3.7/4/4.5** | $3 | $15 | $3.75 | $0.30 | 1.25x / 0.10x |
| **Haiku 4.5** | $1 | $5 | $1.25 | $0.10 | 1.25x / 0.10x |
| **Haiku 3.5** | $0.80 | $4 | $1 | $0.08 | 1.25x / 0.10x |
| **Haiku 3** | $0.25 | $1.25 | $0.30 | $0.03 | **1.20x / 0.12x** ⚠️ |

**Cache Pricing Formulas:**
- **Standard models:** Cache writes = 1.25x input rate, Cache reads = 0.10x input rate
- **Haiku 3 exception:** Cache writes = 1.20x input rate, Cache reads = 0.12x input rate

**Long Context Window Pricing (Sonnet 4/4.5 only):**
When a request's input tokens (input + cache_creation + cache_read) exceed 200,000:
- **Input rate:** $6/MTok (2x standard rate of $3)
- **Output rate:** $22.50/MTok (1.5x standard rate of $15)
- Cache multipliers still apply on top of premium rates
- **Limitation:** Current scripts use simplified aggregate pricing and do not detect per-request long context pricing
- **Manual Check:** Use `/context` command to check current context window size
- **Impact:** If your session regularly exceeds 200K context, actual costs may be higher than estimates shown

**Model Version Detection Logic:**
1. Checks for specific version strings (e.g., "opus-4-5", "haiku-3.5")
2. Falls back to model family detection if version unclear
3. Defaults to newest model pricing in each family
4. Uses model-specific multipliers for cache cost calculations
5. Detects long context threshold (>200K input) for Sonnet 4/4.5

**Pricing Source:** [Anthropic Official Pricing](https://platform.claude.com/docs/en/about-claude/pricing) (verified 2026-01-03)

### Agent Detection

**Method:** Check if agent files were modified in last 10 seconds
**Files checked:** `~/.claude/projects/PROJECT_DIR/agent-*.jsonl`
**Purpose:** Show "🤖 Sub-agents running, stand by..." in status line

### Project Directory Mapping

**Formula:** Convert working directory path to project directory name
**Example:** `/Users/john/Code/my_project` → `-Users-john-Code-my-project`
**Transformations:**
1. Replace `/` with `-`
2. Replace `_` with `-`

## Prerequisites

### Required Tools

**The installers automatically detect and install missing prerequisites.**

1. **jq** - JSON processor
   - Auto-installed by installer on Linux (apt-get/dnf/pacman) and macOS (brew)
   - Windows: Auto-installed via Chocolatey by batch installer
   - Manual: See TROUBLESHOOTING.md

2. **bc** - Calculator
   - Auto-installed by installer on Linux
   - Usually pre-installed on macOS
   - Included with Git Bash on Windows

3. **bash** - Shell
   - Pre-installed on all platforms
   - macOS: Works with default bash 3.2+
   - Scripts compatible with bash 3.2+

### Platform-Specific Notes

**macOS:**
- Uses BSD sed (not GNU sed) - scripts are compatible
- Default bash 3.2.57 - scripts work fine
- Supports emoji natively in Terminal.app and iTerm2
- Requires Homebrew for auto-installing jq

**Linux:**
- GNU tools standard
- Works on Ubuntu, Debian, RHEL, Fedora, Arch
- Auto-installs prerequisites via native package manager

**Windows:**
- Requires Git Bash (installer checks for it)
- Use `install-claude-stats.bat` for best experience
- Requires Chocolatey for auto-installing jq (installer provides instructions)

## How to Use

### Installation

**Automated (Recommended):**

**Windows:**
```
# Double-click:
install-claude-stats.bat

# Or use bash:
./install-claude-stats.sh
```

**Linux/macOS:**
```bash
./install-claude-stats.sh
```

Time: ~2 minutes | Auto-installs prerequisites (jq, bc) if needed

**Manual:**
See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Manual Installation section

Time: ~10 minutes

### Using the Features

1. **Status Line** - Automatically displays at bottom of Claude Code
2. **Trip Computer** - Run `/trip-computer` command anytime
3. **Real-time Updates** - Status line refreshes on each interaction

## Value Proposition

### Immediate Decision Making
- "This is getting expensive, let me switch to Haiku"
- "Cache reads are high, maybe start a fresh session"
- "This task cost $15 - worth it for the result"

### Cost Awareness
- Track expenses per session
- Understand which workflows are expensive
- Learn to use appropriate models
- Improve cost efficiency over time

### Session vs Billing
- `/trip-computer` = Speedometer (real-time session estimates, transcript-based)
- `/cost` = Odometer (authoritative billing from Anthropic API)
- Both valuable for complete cost awareness

## Known Limitations

### Stats Reset with `/clear` Command

**Current Behavior:**
When you use the `/clear` command in Claude Code, it creates a new session with a new transcript file. This causes the session stats to reset to zero, displaying only stats for the new session.

**Why This Happens:**
- Each Claude Code session has its own transcript file (identified by a unique session ID)
- Session stats are calculated by reading the current session's transcript file
- The `/clear` command starts a fresh session with a new transcript file
- This is by design to keep session tracking simple, predictable, and isolated per session

**Desired Future Behavior:**
Ideally, stats would be cumulative across `/clear` commands within the same Claude Code instance, but reset when Claude Code is closed and restarted. This would require detecting the difference between:
- Same Claude Code process + `/clear` → Keep cumulative stats
- Close and restart Claude Code → Reset stats (new work session)

**Workaround:**
If you need to track cumulative costs across multiple `/clear` sessions:
1. Note the session stats before using `/clear`
2. Manually add costs from different sessions if needed
3. Consider using `/clear` less frequently if you want longer cumulative tracking

**Status:** Documented as a known limitation. See "Future Enhancement Ideas" for planned improvements.

### Fixed: Command Messages No Longer Counted (2025-12-15)

**Issue:** After running `/clear`, the message count would incorrectly show 2 messages instead of 0 because command-related messages were being counted as user messages.

**Root Cause:** The message counting logic was counting command invocation messages (containing XML tags like `<command-name>`, `<command-args>`, `<local-command-stdout>`, `<command-message>`) as regular user messages.

**Fix:** Updated message counting filter in all three scripts (brief-stats.sh, show-session-stats.sh, and installer) to exclude messages containing command-related XML tags:
```jq
select(.type == "user" and
       (.isMeta != true) and
       (.message.content |
         if type == "array"
         then all(.[]; .type != "tool_result")
         else (test("<command-name>|<command-args>|<local-command-stdout>|<command-message>") | not)
         end))
```

**Result:** Message counts now correctly exclude command invocation and output messages, showing only actual user prompts.

## Important Disclaimers

### Design Philosophy: Optimization Over Cost Tracking

**v0.8.0 Major Shift**: This tool has evolved from cost tracking to **session optimization**.

**Why the change?**
- API users already have `/cost` for accurate billing - duplicating this created confusion
- The 5-15% variance between estimates and `/cost` was inherently confusing
- Our unique value is in **optimization insights** not available elsewhere:
  - Context window budget tracking
  - Cache efficiency analysis
  - Response verbosity metrics
  - Prompt pattern detection
  - Session health scoring

**What this means for different users:**

**API Users (v0.8.0+):**
- **Status line**: Context budget, cache efficiency, verbosity (NO cost display)
- **Trip computer**: Optimization insights, session health, actionable recommendations
- **For billing**: Use `/cost` command (official, accurate, authoritative)
- **Safety margin**: 1.00 (no adjustment - costs for reference only)

**Subscription Users:**
- **Status line**: Context + efficiency metrics + API-equivalent value estimate
- **Trip computer**: Same optimization insights + value awareness
- **Safety margin**: 1.10 (10% buffer for conservative estimates)
- **Purpose**: Understand value extraction from subscription

### For Subscription Users (v0.8.0)
- **Status line**: Shows context, efficiency, verbosity + API-equivalent value
- **Trip computer**: Full optimization insights + value awareness
- **Value estimates**: API-equivalent with 10% safety margin (conservative)
- **Purpose**: Understand value extraction and optimize session efficiency
- **No billing concern**: Usage included in subscription

### For API Users (v0.8.0)
- **Status line**: Shows context, efficiency, verbosity (NO cost)
- **Trip computer**: Full optimization insights focused on efficiency
- **Cost reference**: Trip computer shows cost for context only (no safety margin)
- **For billing**: **Always use `/cost` command** (official, accurate, authoritative)
- **Purpose**: Optimize session efficiency, manage context budget

### When to Use Each Tool (v0.8.0)
- **Use status line** - Quick glance at session efficiency (context budget, cache, verbosity)
- **Use `/trip-computer`** - Deep session health analysis, optimization recommendations, efficiency patterns
- **Use `/cost`** (API users only) - Official billing amounts, financial accounting, expense reporting
- **Focus shift**: Session optimization first, cost awareness second

## Development Guidelines

### ⚠️ CRITICAL: Always Update All Documentation When Making Changes

**MANDATORY UPDATE CHECKLIST** - When modifying pricing, billing logic, or functionality:

1. ✅ **VERSION** - Bump version number following semver guidelines
2. ✅ **CHANGELOG.md** - Document changes in appropriate version section
3. ✅ **install-claude-stats.sh** - Automated installer script (update version if changed)
4. ✅ **~/.claude/hooks/brief-stats.sh** - Status line script (if already installed, update version)
5. ✅ **~/.claude/hooks/show-session-stats.sh** - Detailed stats script (if already installed, update version)
6. ✅ **CLAUDE.md** - Project context and technical documentation (update version reference)
7. ✅ **README.md** - Quick start guide and overview (update version badge)
8. ✅ **TROUBLESHOOTING.md** - Troubleshooting guide (update version if referenced)

**Common Changes That Require Updates:**
- Pricing rates or cache multipliers
- Model detection logic
- Billing mode detection
- New features or functionality
- Disclaimer wording
- File structure or paths
- Configuration options

**Testing After Updates:**
1. Test automated installer on clean environment
2. Verify status line displays correctly
3. Run `/trip-computer` and verify output
4. Compare with `/cost` command for accuracy
5. Test on multiple model types if possible

### When Modifying Scripts

**Testing Checklist:**
1. Test on clean session (no transcript)
2. Test with existing session
3. Test with agent activity
4. Test billing mode configuration (API and Subscription modes)
5. Test all model types (Opus, Sonnet, Haiku)
6. Test token formatting (K, M notation)
7. Verify cross-platform compatibility

**Key Functions to Preserve:**
- Token deduplication by requestId
- Billing mode reading from `.stats-config`
- Model detection and pricing application
- Agent activity detection
- Error handling for missing files

### Code Patterns

**Session ID Detection:**
```bash
# Try to read from stdin first (Claude Code provides it)
ACTIVE_SESSION_ID=$(echo "$INPUT" | jq -r '.sessionId // empty' 2>/dev/null)

# Fall back to most recent transcript if not provided
TRANSCRIPT_PATH=$(ls -t "$TRANSCRIPT_DIR"/*.jsonl 2>/dev/null | head -1)
```

**Safe Numeric Handling:**
```bash
# Handle bc output starting with . (like .8809 -> 0.8809)
if [[ "$TOTAL_COST" == .* ]]; then
  TOTAL_COST="0$TOTAL_COST"
fi
```

**Cross-Platform stat Command:**
```bash
# macOS uses -f, Linux uses -c
FILE_MTIME=$(stat -f %m "$agent_file" 2>/dev/null || stat -c %Y "$agent_file" 2>/dev/null || echo 0)
```

## Distribution

### Minimum Package
- `install-claude-stats.sh` (Linux/macOS/WSL)
- `install-claude-stats.bat` (Windows)
- `README.md`
- `TROUBLESHOOTING.md`

### Complete Package
- All core files (installers + README + TROUBLESHOOTING + CLAUDE.md + CHANGELOG)

### Sharing Instructions
```
"Hey team! Real-time Claude Code cost tracking - 2 min setup.
Run: ./install-claude-stats.sh
Troubleshooting: TROUBLESHOOTING.md
Docs: README.md"
```

## Future Enhancement Ideas

- [ ] **Cumulative stats across `/clear` sessions** - Track cumulative costs within the same Claude Code instance even when using `/clear`, but reset when Claude Code is closed and restarted
  - Possible approaches: PID-based session detection, persistent marker file with inactivity timeout, or user-controlled reset command
  - Trade-off: Added complexity (50-60 lines) and edge cases vs. convenience
  - Status: Documented as known limitation in "Known Limitations" section, awaiting user feedback on priority
- [ ] Support for multiple sessions comparison
- [ ] Cost history tracking over time
- [ ] Budget alerts/warnings
- [ ] Export stats to CSV/JSON
- [ ] Integration with time tracking tools
- [ ] Team/project-level aggregation
- [ ] Custom pricing profiles
- [ ] Model performance metrics

## Troubleshooting Common Issues

### Status line not updating
1. Restart Claude Code completely
2. Check `~/.claude/settings.json` configuration
3. Test script manually: `~/.claude/hooks/brief-stats.sh`
4. Check execute permissions
5. Check for errors: `bash -x ~/.claude/hooks/brief-stats.sh`

**Windows-specific: Username with spaces**
If your Windows username contains spaces (e.g., "Lux Solari"), older versions (< 0.6.1) may fail because the path splits incorrectly. Solutions:
- **Recommended:** Reinstall using `install-claude-stats.sh` (v0.6.1+ auto-detects spaces)
- **Manual fix:** Edit `~/.claude/settings.json` to wrap command with bash:
  ```json
  {
    "statusLine": {
      "type": "command",
      "command": "bash \"/c/Users/Your Name/.claude/hooks/brief-stats.sh\""
    }
  }
  ```
- **Verify:** Run `bash "/c/Users/Your Name/.claude/hooks/brief-stats.sh"` to test

### Transcript files not found
- Check `~/.claude/projects/` directory exists
- Verify project directory name mapping
- Ensure you're in a project directory when testing

### Wrong costs displayed
- Verify model detection is working
- Check pricing rates in scripts
- Ensure token deduplication is functioning

## Git Information

**Repository:** Local git repository initialized
**Branch:** master
**Status:** Clean working directory
**Recent commit:** Initial commit with all setup files

## External Documentation References

This section provides links to official Anthropic documentation relevant to this project. All URLs were verified as of 2026-01-03.

### Claude Code Official Documentation

#### Core Features
- **Status Line Configuration**: https://code.claude.com/docs/en/statusline
  - How the status line works, JSON input structure, update frequency
  - Example implementations in bash, Python, Node.js
  - Context window usage tracking
  - Essential for understanding how `brief-stats.sh` integrates with Claude Code
  - Last verified: 2026-01-03

- **Hooks Guide**: https://code.claude.com/docs/en/hooks-guide
  - Comprehensive guide to Claude Code hooks system
  - Hook types, execution context, and lifecycle
  - Best practices for creating custom hooks
  - Error handling and debugging hooks
  - Relevant for both `brief-stats.sh` and `show-session-stats.sh` implementation
  - Last verified: 2026-01-03

- **Sub-agents**: https://code.claude.com/docs/en/sub-agents
  - How sub-agents work in Claude Code
  - When Claude spawns sub-agents (web search, complex tasks)
  - Sub-agent lifecycle and session tracking
  - Understanding `isSidechain` property in transcripts
  - Critical for accurate cost calculation (sub-agent usage is billed)
  - Last verified: 2026-01-03

- **Cost Tracking**: https://docs.anthropic.com/en/docs/claude-code/costs
  - Official `/cost` command documentation
  - How Anthropic tracks and bills Claude Code usage
  - Average costs per developer ($6/day typical, <$12/day for 90% of users)
  - Historical usage tracking via Anthropic Console
  - Setting workspace spend limits
  - Authoritative source for validating our cost estimates
  - Last verified: 2026-01-03

#### Commands
- **Slash Commands**: https://code.claude.com/docs/en/commands
  - Creating custom slash commands (like `/trip-computer`)
  - Command structure and markdown format
  - Passing parameters to commands
  - Integration with hooks and scripts
  - Last verified: 2026-01-03

### Anthropic Pricing Documentation

- **Official API Pricing**: https://www.anthropic.com/pricing
  - Consumer plans (Free, Pro, Max)
  - Team and Enterprise plans
  - API pricing by model
  - Subscription vs API billing differences
  - Last verified: 2026-01-03

- **Claude.com Pricing Page**: https://claude.com/pricing#api
  - Detailed API pricing tables with all token costs
  - Prompt caching pricing (write/read rates)
  - Service tiers (Priority, Standard, Batch)
  - Tools pricing (web search, code execution)
  - Long context window pricing (>200K tokens)
  - Last verified: 2026-01-03

- **Platform Pricing Documentation**: https://platform.claude.com/docs/en/about-claude/pricing
  - Technical pricing details for API developers
  - Token counting methodology
  - Cache multipliers and TTL information
  - Extended prompt caching options
  - Batch processing (50% discount)
  - Model-specific pricing tables
  - Source of truth for our pricing implementation
  - Last verified: 2026-01-03

### Model Documentation

- **Models Overview**: https://docs.anthropic.com/en/docs/about-claude/models/overview
  - Complete model family comparison
  - Capabilities and use cases per model
  - Context window sizes
  - Model version history
  - Deprecation timelines
  - Helps users understand when to use Opus vs Sonnet vs Haiku
  - Last verified: 2026-01-03

### API Documentation

- **API Reference**: https://docs.anthropic.com/en/api/getting-started
  - Complete API documentation
  - Token usage response structure
  - Understanding `usage` object in API responses
  - Relevant for understanding transcript file structure
  - Last verified: 2026-01-03

- **Prompt Caching**: https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching
  - How prompt caching works
  - 5-minute TTL (standard) vs extended caching
  - Cache write vs cache read costs
  - Strategies to maximize cache efficiency
  - Explains why we track `cache_creation_input_tokens` and `cache_read_input_tokens`
  - Last verified: 2026-01-03

### Console & Account Management

- **Anthropic Console**: https://console.anthropic.com
  - Account management dashboard
  - Historical usage tracking
  - Workspace spend limits
  - Billing and payment settings
  - API key management
  - Last verified: 2026-01-03

### Support Resources

- **Support Center**: https://support.anthropic.com
  - Official support articles
  - Troubleshooting guides
  - FAQs about billing, usage, and features
  - Contact information for billing questions
  - Last verified: 2026-01-03

### Version History & Updates

- **Anthropic News**: https://www.anthropic.com/news
  - Product announcements
  - Pricing changes
  - New model releases
  - Feature updates
  - Important for staying current on pricing changes
  - Last verified: 2026-01-03

### Key Integration Points

This project relies on the following documentation areas:

1. **Status Line Hook** (`brief-stats.sh`):
   - Status Line Configuration docs for JSON input format
   - Hooks Guide for execution context and lifecycle
   - Cost Tracking docs for validation against `/cost`

2. **Trip Computer Command** (`show-session-stats.sh`):
   - Slash Commands docs for command structure
   - Hooks Guide for script execution
   - Sub-agents docs for `isSidechain` handling

3. **Pricing Calculations**:
   - Platform Pricing Documentation for token costs
   - Prompt Caching docs for multipliers
   - Models Overview for model detection patterns

4. **Cost Validation**:
   - Cost Tracking docs for `/cost` command behavior
   - API Reference for `usage` object structure
   - Console docs for historical usage comparison

## Contact & Support

For questions or issues with this tracking system, refer to:
- README.md for overview
- Platform-specific setup guides for detailed instructions
- Script comments for implementation details

---

**Last Updated:** 2026-01-08 (v0.9.3 - Fixed message counting failure due to jq syntax error)
**Claude Code Version Compatibility:** v1.0+
**Status:** Stable, production-ready
- all changes proposed in this project should be applied both on the status line and the custom command, along with updating installer script and relevant documentation / guides.
- always remember to use semantic versioning, major for breaking changes, minor for when working with adding backwards compatible features, and patch for when fixing bugs.