# Changelog

All notable changes to the Claude Code Session Stats project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
