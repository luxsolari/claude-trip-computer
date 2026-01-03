# Changelog

All notable changes to the Claude Code Session Stats project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.3] - 2026-01-03

### Fixed - Status Line Working Directory
- **Status line showing zeroes**: Fixed brief-stats.sh to read working directory from Claude Code JSON input instead of using `pwd`
  - **Root cause**: When Claude Code invokes the status line script, `pwd` returns the hooks directory, not the project directory
  - **Impact**: Script couldn't find transcript files, always showing 0 msgs, 0 tools, 0 tokens in status line
  - **Fix**: Script now reads `workspace.current_dir` from JSON input provided by Claude Code, with fallback to `pwd`
- **Files updated**:
  - `brief-stats.sh`: Lines 22-28 - Added JSON parsing to extract working directory from Claude Code input
  - `install-claude-stats.sh`: Line 163 - Same fix applied to installer's embedded script

### Technical
- Claude Code passes JSON via stdin including `workspace.current_dir` and `workspace.project_dir`
- Updated logic:
  1. Try to read directory from JSON: `workspace.current_dir // workspace.project_dir // cwd`
  2. Fallback to `pwd` if JSON not available or parsing fails
  3. Apply Windows drive letter transformation to the detected directory
- This allows the script to work correctly regardless of where Claude Code executes it from

## [0.6.2] - 2026-01-03

### Fixed - Windows Path Mapping
- **Project directory mapping on Windows Git Bash**: Fixed incorrect directory name calculation that caused metrics to always show zero
  - **Root cause**: Script converted `/c/Dev/project` to `-c-Dev-project` but Claude Code creates directories as `C--Dev-project`
  - **Impact**: Status line and `/trip-computer` could not find transcript files, always showing 0 msgs, 0 tools, 0 tokens
  - **Fix**: Added Windows drive letter detection and proper transformation (`/c/` → `C--`)
- **Files updated**:
  - `brief-stats.sh`: Added regex pattern matching `[[ "$PWD_PATH" =~ ^/([a-z])/ ]]` with BASH_REMATCH for drive letter uppercasing
  - `show-session-stats.sh`: Uses sed transformation `sed 's|^/\([a-z]\)/|\U\1--|'` to uppercase drive letter and add double dash
  - `install-claude-stats.sh`: Both approaches embedded in installer to generate correct scripts
- **Cross-platform compatibility**: Works correctly on Linux, macOS (Unix paths), and Windows Git Bash (drive letter paths)

### Technical
Two equivalent approaches used across scripts:

**Approach 1 (brief-stats.sh, installer):**
- Detection: `[[ "$PWD_PATH" =~ ^/([a-z])/ ]]` matches Windows paths like `/c/Dev/project`
- Transformation: Extract drive letter via `${BASH_REMATCH[1]}`, uppercase with `tr`, combine with `--` prefix
- Result: `C--Dev-claude-trip-computer`

**Approach 2 (show-session-stats.sh):**
- Single sed pipeline: `sed 's|^/\([a-z]\)/|\U\1--|'` captures drive letter and uppercases it inline
- Simpler but requires GNU sed `\U` (uppercase) flag support
- Result: `C--Dev-claude-trip-computer` (identical output)

Both fallback to Unix transformation (`s/\//-/g`) for non-Windows paths.


## [0.6.1] - 2026-01-03

### Fixed - Windows Compatibility
- **Spaces in username handling**: Fixed installer to detect and handle Windows usernames containing spaces (e.g., "Lux Solari")
  - Installer now checks if `$HOME/.claude/hooks/brief-stats.sh` path contains spaces
  - Automatically wraps command with `bash "path"` when spaces detected
  - Uses simple `~/.claude/hooks/brief-stats.sh` path when no spaces present
  - Prevents "command not found" errors on Windows systems with space-containing usernames
- **Root cause**: Tilde expansion (`~`) to paths with spaces caused shell to split arguments incorrectly
  - Example: `/c/Users/Lux Solari/.claude/` split into `/c/Users/Lux` and `Solari/.claude/`
  - Fixed by using explicit bash invocation with properly quoted paths
- **Impact**: Status line now works correctly for all Windows users regardless of username format

### Changed
- **Installer logic**: Enhanced settings.json generation to handle edge cases
  - Detects path spaces before writing configuration
  - Uses `jq --arg` for safe command string handling
  - Provides user feedback when spaces detected ("✓ Detected spaces in path, using bash wrapper")

### Technical
- Modified `install-claude-stats.sh` lines 1218-1244 to add space detection and conditional bash wrapper
- Changed from hardcoded `~/.claude/hooks/brief-stats.sh` to dynamic `SCRIPT_PATH` variable with conditional formatting
- Updated jq invocation to use `--arg cmd` parameter for safe string interpolation
- Cross-platform compatible: Works on Linux, macOS, and Windows (WSL/Git Bash)

## [0.6.0] - 2026-01-03

### Added - Prompt Quality Analysis
- **Automatic prompt pattern detection**: Identifies 4 common inefficient prompting patterns to help reduce session costs
  - **Vague/broad questions**: Detects questions with keywords like "explain/describe" without constraints like "brief" or "in N points" (>30% threshold, ≥2 occurrences)
    - Estimated savings: ~25% reduction in output costs per 10 messages
  - **Large context pastes**: Detects prompts containing >200 lines of pasted code/text (>20% threshold, ≥1 occurrence)
    - Estimated savings: ~20% reduction in input + cache write costs per 10 messages
  - **Repeated similar questions**: Detects low keyword diversity indicating unclear responses or iterative refinement (≥3 messages, avg <15 unique words)
    - Estimated savings: ~15% reduction by asking complete questions upfront per 10 messages
  - **Missing task constraints**: Detects coding tasks ("write/create/implement") without format/length specs (>40% threshold, ≥2 occurrences)
    - Estimated savings: ~20% reduction in output costs per 10 messages
- **Smart savings calculations**: Each pattern shows estimated dollar savings per 10 messages for actionable decision-making
- **Integrated recommendations**: Prompt quality tips automatically prioritized with existing recommendations via bubble sort
- **Pure bash implementation**: No API calls required - fast analysis using jq regex pattern matching
- **Always-on by default**: Runs automatically in `/trip-computer` with no configuration needed

### Changed
- **Recommendation capacity**: Can now show up to 8 recommendations (was 4), accommodating new prompt analysis patterns
- **Trip computer analytics**: Added prompt pattern analysis section before recommendations generation
- **Savings estimates**: More granular with 4 new pattern-specific calculations based on actual session costs

### Technical
- Added 182 lines to show-session-stats.sh (now 810 lines, up from 677 lines)
- Implemented regex-based pattern detection using jq with case-insensitive matching
- Added keyword diversity analysis for repeated question detection (unique word counting)
- Enhanced recommendation system to handle prompt quality insights alongside existing model/cache/context rules
- Updated installer script to embed new version with prompt analysis features

### Developer Value
Developers can now:
- **Identify prompting habits** that increase costs (vague questions without constraints, large code pastes)
- **Get specific guidance** on improving prompt efficiency with concrete examples
- **See estimated savings** from better prompting practices (dollar amounts per 10 messages)
- **Understand cost drivers** at the prompt level, not just token/model level
- **Optimize iteratively** by seeing which prompt patterns are detected in their sessions

### Notes
- Prompt analysis runs on every `/trip-computer` invocation with ~100-200ms overhead (negligible)
- Pattern thresholds (30%, 40%, etc.) are calibrated to minimize false positives while catching real issues
- Recommendations show actual dollar savings based on current session's cost structure
- Works across all platforms (Linux, macOS, Windows Git Bash) using standard bash/jq features

## [0.5.1] - 2025-12-16

### Fixed
- **Locale warning**: Removed `en_US.UTF-8` locale requirement that caused warnings on systems without it installed
  - Changed from `LC_NUMERIC=en_US.UTF-8` to `LC_NUMERIC=C` (universally available)
  - Prevents "setlocale: LC_NUMERIC: cannot change locale" warning on WSL and minimal Linux installations
  - No functional impact - number formatting still works correctly

## [0.5.0] - 2025-12-16

### Added - Major Trip Computer Enhancements
- **Session Health Score** (0-100): Automated health assessment based on cache efficiency, cost per message, and context growth
  - 5-star rating system with clear health status (Excellent/Good/Fair/Poor/Critical)
  - Detailed breakdown showing which factors contribute to score
- **Model Mix Visibility**: Shows which models were used and their cost contribution
  - Visual percentage bars for each model
  - Request count per model
  - Smart model switching suggestions (e.g., "Switching Sonnet → Haiku could save $X (67% reduction)")
- **Cost Drivers Breakdown**: Shows exactly where costs come from with percentages and visual bars
  - Input tokens, output tokens, cache writes, cache reads
  - Context-aware insights (e.g., "Output tokens are your biggest cost driver")
- **Efficiency Metrics Section**: Advanced performance analytics
  - Output/Input ratio with verbosity assessment
  - Cache hit rate with savings amount
  - Cost per token for transparency
- **Smart Prioritized Recommendations**: Top 3 optimization actions ranked by potential savings
  - Calculates actual dollar savings for next 10 messages
  - Shows percentage reduction for each recommendation
  - Examples: "Switch to Haiku for simple tasks → Save ~$0.60/10 msgs (75% reduction)"
- **Enhanced Visual Hierarchy**: Improved readability and scannability
  - Quick summary bar showing health, trend, and action
  - Cost trend indicator (Rising ➚ / Stable ➡️ / Falling ➘)
  - Clear section headers with visual separators

### Changed
- **Trip Computer Layout**: Reorganized for better information flow
  - Quick Summary → Health Score → Model Mix → Cost Drivers → Efficiency → Usage → Recommendations → Trajectory
  - Emphasis on actionable insights over raw numbers
- **Recommendation System**: Complete rewrite from generic to data-driven
  - Recommendations now sorted by potential savings (highest impact first)
  - Each recommendation shows specific dollar savings and percentage reduction
  - Based on actual session patterns (output verbosity, model usage, cache performance, context growth)
- **Version Display**: Trip computer header now shows version number for troubleshooting

### Technical
- Increased script size from 310 to 677 lines to add advanced analytics
- Added bubble sort algorithm for recommendation prioritization
- Implemented session health scoring algorithm (40 pts cache + 30 pts cost + 30 pts context)
- Added trend analysis by comparing early vs late message costs
- Enhanced model detection with friendly names (e.g., "Sonnet 4.5" instead of full model ID)
- Added cost component breakdown tracking (input/output/cache write/cache read)

### Developer Value
This release transforms `/trip-computer` from a data display into an actionable analytics dashboard. Developers can now:
- Instantly assess session health with a single score
- Identify which models and token types are driving costs
- Get specific, prioritized recommendations with dollar savings
- Understand efficiency trends without manual calculation

## [0.4.2] - 2025-12-16

### Fixed
- **Status line not updating**: Fixed issue where status line showed zeros instead of real session data
  - Root cause: Script fallback logic was removed, causing it to exit early when Claude Code didn't pass session ID via stdin
  - Solution: Restored fallback logic to find most recent transcript when no session ID provided
  - Status line now correctly displays real-time stats from the current session

## [0.4.1] - 2025-12-16

### Fixed
- **Installer script**: Fixed duplicate SCRIPT_EOF marker and code causing "command not found" error at line 695
  - Removed duplicate heredoc terminator that was being interpreted as a bash command
  - Removed duplicate chmod and echo statements

## [0.4.0] - 2025-12-15

### Added
- **Status line cache efficiency**: Added `⚡ X% eff` indicator showing cache performance in real-time
- **Status line trip computer pointer**: Added `📊 /trip-computer` reminder for better discoverability
- **Trip computer billing mode awareness**: Adapts messaging based on API vs Subscription billing
  - API users: Reminds to run `/cost` separately for official billing comparison
  - Subscription users: Shows API-equivalent estimates with rate limit context
- **Insights-focused analytics**: Trip computer emphasizes actionable recommendations
  - Smart recommendations based on cache efficiency, context growth, and cost patterns
  - Trajectory projections (next 10 messages, hourly rate estimates)
  - Best-effort transcript-based estimates (typically within 10% of actual costs)

### Changed
- **Status line format** (v0.2.0 → v0.4.0):
  - Old: `💬 X msgs | 🔧 X tools | 🎯 XM tok | 💳 API ~$X.XX ($X.XX/msg)`
  - New: `💬 X msgs | 🔧 X tools | 🎯 XM tok | ⚡ X% eff | 💳 ~$X.XX ($X.XX/msg) | 📊 /trip-computer`
  - Added cache efficiency indicator and trip computer pointer for better discoverability
- **Trip computer redesign**: Completely rewritten for insight-focused output
  - Always shows transcript-based estimates with clear disclaimers
  - Emphasizes cache savings, context growth warnings, and cost optimization tips
  - API users reminded to run `/cost` separately for official billing
- **Script efficiency**: Reduced trip computer from 457 to 350 lines while adding features

### Technical
- Added cache efficiency calculation: `(cache_read_tokens / (cache_write_tokens + cache_read_tokens)) * 100`
- Enhanced insights generation with context-aware recommendations
- Simplified approach: Always use transcript data (best-effort estimates)
- Clear disclaimers for each billing mode (API vs Subscription)

## [0.3.1] - 2025-12-15

### Fixed
- **Token display formatting**: Fixed locale-based number formatting inconsistency in `/trip-computer` output
  - Numbers were displaying with dots as thousand separators (European locale: "6.634") instead of commas (English locale: "6,634")
  - This made large numbers appear confusing (e.g., "497.779 tokens" looked like ~500 instead of ~500,000)
  - Solution: Added `export LC_NUMERIC=en_US.UTF-8` to `show-session-stats.sh` for consistent comma formatting
  - Now aligns with status line's K/M notation approach for clarity

## [0.3.0] - 2025-12-15

### Changed
- **BREAKING: Renamed slash command** from `/session-stats` to `/trip-computer`
  - Better reflects the "Trip Computer" branding and analytics focus
  - Existing users will need to use new command name after updating
  - Command file: `~/.claude/commands/trip-computer.md` (was `session-stats.md`)
  - Updated all documentation and guides with new command name

### Migration
- After updating, use `/trip-computer` instead of `/session-stats`
- The underlying script (`show-session-stats.sh`) remains unchanged
- All functionality is identical, only the command name changed

## [0.2.1] - 2025-12-15

### Fixed
- **Agent detection false positives**: Fixed issue where status line incorrectly showed "🤖 Sub-agents running, stand by..." in new sessions
  - Reduced detection time window from 10 seconds to 3 seconds
  - Added file growth check (compares file size twice with 0.1s delay)
  - Now only triggers when agent files are actively being written to
  - Prevents false positives from old agent files in directory

## [0.2.0] - 2025-12-15

### Added
- **Enhanced Status Line** with cost per message trajectory indicator:
  - **Cost per Message** (`$0.81/msg`): Shows spending rate per interaction for immediate trajectory awareness
  - Helps users make real-time decisions about model selection and task complexity

### Changed
- Status line format updated from:
  - Old: `💬 X msgs | 🔧 X tools | 🎯 XM tok | 💳 API ~$X.XX`
  - New: `💬 X msgs | 🔧 X tools | 🎯 XM tok | 💳 API ~$X.XX ($X.XX/msg)`

### Technical
- Added cost per message calculation for trajectory indicator
- Updated `brief-stats.sh` with trajectory metric
- Updated installer script with enhanced status line

### Removed
- **Context Fill % indicator** - Removed due to technical limitation: transcript files don't store accumulated context size (only incremental per-message data). The `/context` command gets this from Claude Code's internal state, which isn't accessible to our scripts.

## [0.1.0] - 2025-12-15

### Added
- **Enhanced "Trip Computer" Analytics** for `/session-stats` command:
  - **💸 Rate & Trajectory**: Average cost per message, average cost per tool call, projected cost for next 10 messages
  - **⚡ Efficiency Metrics**: Cache efficiency percentage, cost savings from cache, output/input ratio, tokens per message
  - **📊 Session Insights**: Model usage mix (percentage breakdown), context growth tracking with percentage increase
  - **💡 Smart Recommendations**: Context-aware suggestions for optimization (cache efficiency, cost per message, context growth, output token usage)
  - **💰 Cost Drivers**: Percentage breakdown showing what's driving costs (output tokens, cache writes, input tokens, cache reads)
  - **📋 Enhanced Token Display**: Thousand-separator formatting for token counts
  - **🔧 Multi-Model Support**: Per-model breakdown in detailed stats
  - **🚗 New Visual Design**: Beautiful bordered sections with clear hierarchy and visual separators

### Changed
- Renamed `/session-stats` output title from "Session Statistics" to "SESSION TRIP COMPUTER - Real-time Analytics & Insights"
- Reorganized output layout to prioritize actionable insights over raw numbers
- Enhanced visual formatting with Unicode box-drawing characters for better readability
- Moved raw token counts lower in the output (after insights and recommendations)
- Model breakdown now shows per-model costs in addition to token counts

### Technical
- Added 16 new analytical calculations to `show-session-stats.sh`
- Implemented smart recommendation engine with 4 different recommendation types
- Added cost savings calculation for cache efficiency
- Added context growth tracking (first input vs latest input tokens)
- Added spending trajectory projection based on current session rate
- Updated installer script to include new enhanced version

## [0.0.1] - 2025-12-15

### Added
- Created CHANGELOG.md to track version history
- Added VERSION file for semantic versioning
- Version display in installer script

### Added
- Initial production-ready release
- Real-time cost tracking via status line display
- Interactive billing mode configuration (API vs Subscription)
- Multi-model support with automatic pricing detection (Opus 4.5, Opus 3/4/4.1, Sonnet 3.7/4/4.5, Haiku 3/3.5/4.5)
- Token deduplication by `requestId` to prevent 3-4x inflation
- Sub-agent activity detection and status display
- `/session-stats` slash command for detailed statistics
- Automated installation script with platform detection (Linux, macOS, Windows)
- Manual installation guides for all platforms
- Comprehensive project documentation (CLAUDE.md)
- User-facing README with quick start guide
- Billing mode persistence via `.stats-config` file
- Model-specific cache pricing with correct multipliers
- Token formatting in K/M notation
- Error handling and graceful fallbacks

### Fixed
- **Message counting bug after `/clear` command**: Fixed issue where command-related messages (containing `<command-name>`, `<command-args>`, `<local-command-stdout>`, `<command-message>` XML tags) were being counted as user messages, causing the count to show 2 messages after `/clear` instead of 0.
  - Updated message counting filter in `brief-stats.sh` to exclude command messages
  - Updated message counting filter in `show-session-stats.sh` to exclude command messages
  - Updated message counting filter in `install-claude-stats.sh` (both brief and detailed stats sections)
  - Message counts now correctly show only actual user prompts

### Technical Details
- Bash 3.2+ compatibility (macOS default shell)
- Cross-platform `stat` command handling (BSD/GNU)
- Safe numeric handling for `bc` output
- Session ID detection from stdin
- Project directory path mapping
- Transcript file parsing with jq

### Documentation
- CLAUDE.md - Complete project context and technical documentation
- README.md - User-facing quick start guide
- CLAUDE_STATS_SETUP_MACOS.md - macOS manual installation
- CLAUDE_STATS_SETUP_LINUX.md - Linux manual installation
- CLAUDE_STATS_SETUP_WINDOWS.md - Windows manual installation

### Known Limitations
- Stats reset when using `/clear` command (by design for session isolation)
- Estimates typically accurate within 10% of official `/cost` command
- Long context window pricing (>200K tokens) uses simplified aggregate pricing

---

## Version History

- **0.3.0** (2025-12-15) - Renamed slash command from /session-stats to /trip-computer (breaking change)
- **0.2.1** (2025-12-15) - Fixed agent detection false positives
- **0.2.0** (2025-12-15) - Enhanced status line with cost per message trajectory indicator
- **0.1.0** (2025-12-15) - Enhanced "Trip Computer" analytics with rate tracking, efficiency metrics, smart recommendations, and cost drivers
- **0.0.1** (2025-12-15) - Initial versioned release with command message counting fix

---

## Semantic Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version (X.0.0) - Incompatible API changes or major functionality changes
- **MINOR** version (0.X.0) - New features added in a backwards-compatible manner
- **PATCH** version (0.0.X) - Backwards-compatible bug fixes

### When to bump versions:

**MAJOR (X.0.0)**:
- Breaking changes to installation process
- Incompatible changes to `.stats-config` format
- Major rewrites requiring user action
- Changes to script locations or names

**MINOR (0.X.0)**:
- New features (e.g., new pricing models, additional stats)
- New slash commands or hooks
- Enhanced functionality (e.g., cumulative stats across `/clear`)
- New configuration options

**PATCH (0.0.X)**:
- Bug fixes
- Documentation improvements
- Pricing updates
- Performance improvements
- Minor UI/formatting tweaks
