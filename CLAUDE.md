# CLAUDE.md - Project Context for Claude Code

## Project Overview

**Name:** Claude Code Session Stats Tracking
**Version:** 0.4.2 (see [CHANGELOG.md](CHANGELOG.md) for version history)
**Purpose:** Real-time cost tracking and analytics system for Claude Code sessions
**Type:** CLI utility / Developer tool
**Status:** Development phase (0.x.x versions) - Insight-focused analytics with billing mode detection

## What This Project Does

This project provides comprehensive session statistics tracking for Claude Code, enabling developers to:

1. **Monitor costs in real-time** via status line display with trajectory tracking
2. **Track session metrics** including messages, tool calls, tokens, and costs
3. **View detailed analytics** via `/trip-computer` command with actionable insights
4. **Configure billing mode** via interactive setup (API vs Subscription)
5. **Apply model-specific pricing** (Opus 4.5, Sonnet 4.5, Haiku)
6. **Show agent activity** when sub-agents are running
7. **Deduplicate token counts** to avoid 3-4x inflation

## Project Structure

```
claude-session-stats/
├── install-claude-stats.sh           # Automated installer (recommended)
├── VERSION                           # Current version number (semver)
├── CHANGELOG.md                      # Version history and changes
├── README.md                          # Main documentation
├── CLAUDE.md                          # Project context (this file)
├── CLAUDE_STATS_SETUP_MACOS.md       # macOS manual setup guide
├── CLAUDE_STATS_SETUP_LINUX.md       # Linux manual setup guide
├── CLAUDE_STATS_SETUP_WINDOWS.md     # Windows manual setup guide
└── .git/                             # Git repository
```

### Installation Targets (created by installer)

```
~/.claude/
├── hooks/
│   ├── brief-stats.sh              # Status line script (real-time brief stats)
│   ├── show-session-stats.sh       # Detailed stats script (full breakdown)
│   └── .stats-config               # Billing mode configuration
├── commands/
│   └── trip-computer.md            # /trip-computer slash command
└── settings.json                   # Claude Code configuration
```

## Key Components

### 1. brief-stats.sh (Status Line Script)

**Location:** `~/.claude/hooks/brief-stats.sh`
**Purpose:** Displays real-time stats in Claude Code status bar
**Output Format:** `💬 X msgs | 🔧 X tools | 🎯 XM tok | ⚡ X% eff | 💳 ~$X.XX ($X.XX/msg) | 📊 /trip-computer`
**Version:** 0.4.2 - Fixed status line update issue; added cache efficiency and trip computer pointer

**New in 0.4.2:**
- **Fixed:** Status line now correctly updates with real session data when Claude Code doesn't pass session ID via stdin

**Features from 0.4.0:**
- **⚡ X% eff** - Cache efficiency percentage for immediate performance visibility
- **($X.XX/msg)** - Cost per message for trajectory awareness (retained from v0.2.0)
- **📊 /trip-computer** - Subtle reminder that detailed analytics are available

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
**Purpose:** Insight-focused analytics dashboard based on transcript data
**Triggered by:** `/trip-computer` slash command
**Version:** 0.4.2 - Enhanced with cache efficiency and insights

**Core Functionality:**
- Analyzes session transcript to calculate best-effort cost estimates
- Typically within 10% of actual costs (validated against `/cost` command)
- Provides actionable insights and recommendations for optimization
- Adapts messaging based on billing mode (API vs Subscription)

**Output Includes:**

**📊 Usage Estimates:**
- Message count, tool count, total cost estimate
- Cache efficiency percentage
- Complete token breakdown (input, output, cache writes, cache reads)
- For API users: Reminder to run `/cost` for official billing
- For Subscription users: Notes usage is included in subscription

**💡 Insights & Recommendations:**
- Cache performance analysis (excellent/good/low with specific percentages)
- Context growth warnings (when to use `/clear`)
- Cost per message optimization suggestions
- Tool usage pattern analysis
- Smart, context-aware actionable recommendations

**📈 Trajectory:**
- Cost per message rate
- Projected cost for next 10 messages
- Hourly rate projection at current pace

**Key Features:**
- Best-effort calculations from transcript data (deduplication by requestId)
- Emphasizes "what should I do?" over "what are the numbers?"
- Clear disclaimers about estimate accuracy
- Actionable insights always provided regardless of billing mode

### 3. trip-computer.md (Slash Command)

**Location:** `~/.claude/commands/trip-computer.md`
**Purpose:** Defines the `/trip-computer` custom slash command
**Action:** Executes `show-session-stats.sh` and displays output

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
**Solution:** Group by `requestId`, take MAX value for each token type per request, then sum

```bash
# Deduplication JQ query
jq -s '[.[] | select(.isSidechain == false)] |
  group_by(.requestId) |
  map(select(.[0].message.usage) | {
    input: (map(.message.usage.input_tokens // 0) | max),
    output: (map(.message.usage.output_tokens // 0) | max),
    cache_creation: (map(.message.usage.cache_creation_input_tokens // 0) | max),
    cache_read: (map(.message.usage.cache_read_input_tokens // 0) | max)
  }) | {
    input: (map(.input) | add // 0),
    output: (map(.output) | add // 0),
    cache_creation: (map(.cache_creation) | add // 0),
    cache_read: (map(.cache_read) | add // 0)
  }'
```

### Billing Mode Configuration

**Method:** User-configured during installation via interactive prompt
**Storage:** `~/.claude/hooks/.stats-config`
**Logic:**
- User selects billing mode during install (API or Subscription)
- Configuration saved to `.stats-config` file
- Scripts read from config file at runtime
- API Billing → 💳 icon
- Subscription Plan → 📅 icon

**Config File Format:**
```bash
# Claude Code Session Stats Configuration
BILLING_MODE="API"  # or "Sub"
BILLING_ICON="💳"   # or "📅"
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

**Pricing Source:** [Anthropic Official Pricing](https://platform.claude.com/docs/en/about-claude/pricing) (verified 2025-12-15)

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

1. **jq** - JSON processor
   - Linux: `sudo apt-get install jq` or `sudo dnf install jq`
   - macOS: `brew install jq`
   - Windows: Git Bash includes it, or download from stedolan.github.io/jq/

2. **bc** - Calculator
   - Usually pre-installed on Linux/macOS
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

**Linux:**
- GNU tools standard
- Works on Ubuntu, Debian, RHEL, Fedora, Arch

**Windows:**
- Requires WSL or Git Bash
- Git Bash recommended

## How to Use

### Installation

**Automated (Recommended):**
```bash
./install-claude-stats.sh
```
Time: ~2 minutes

**Manual:**
Follow platform-specific guide:
- macOS: `CLAUDE_STATS_SETUP_MACOS.md`
- Linux: `CLAUDE_STATS_SETUP_LINUX.md`
- Windows: `CLAUDE_STATS_SETUP_WINDOWS.md`

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

### Expected Variance: Up to 10%

Session stats are **estimates** derived from local transcript files and are typically **accurate within 10%** of the `/cost` command. Minor differences occur due to:

1. **Background Operations** - Claude Code uses ~$0.04/session for summarization and internal operations not always logged in transcripts
2. **Timing Differences** - Transcripts write asynchronously; `/cost` queries API in real-time
3. **Measurement Methods** - Anthropic's API uses official token counters; our scripts estimate from transcript logs
4. **Deduplication Approach** - While we avoid 3-4x inflation by deduplicating by `requestId`, edge cases remain

### For Subscription Users
- Costs shown are **API-equivalent estimates** for reference
- **Actual usage is included in your subscription** with no additional charges
- Useful for understanding value and managing rate limits
- Typically accurate within 10% of actual usage shown in `/cost`

### For API Users
- Costs shown are **session-level estimates** from transcript data
- **Typically accurate within 10%** of official billing measurements
- **Use `/cost` command for official billing amounts** and financial accounting
- Session stats are for real-time awareness and optimization decisions

### When to Use Each Tool
- **Use `/trip-computer`** - Real-time cost awareness, deciding which model to use, understanding session impact
- **Use `/cost`** - Official billing verification, expense reporting, financial accounting

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
8. ✅ **CLAUDE_STATS_SETUP_MACOS.md** - macOS manual installation guide
9. ✅ **CLAUDE_STATS_SETUP_LINUX.md** - Linux manual installation guide
10. ✅ **CLAUDE_STATS_SETUP_WINDOWS.md** - Windows manual installation guide

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
- `install-claude-stats.sh`
- `README.md`

### Complete Package
- All 5 files (installer + README + 3 platform guides)

### Sharing Instructions
```
"Hey team! Real-time Claude Code cost tracking - 2 min setup.
Run: ./install-claude-stats.sh
See: README.md for details"
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

## Contact & Support

For questions or issues with this tracking system, refer to:
- README.md for overview
- Platform-specific setup guides for detailed instructions
- Script comments for implementation details

---

**Last Updated:** 2025-12-16 (v0.4.2 - Fixed status line update issue)
**Claude Code Version Compatibility:** v1.0+
**Status:** Stable, production-ready
- all changes proposed in this project should be applied both on the status line and the custom command, along with updating installer script and relevant documentation / guides.
- always remember to use semantic versioning, major for breaking changes, minor for when working with adding backwards compatible features, and patch for when fixing bugs.