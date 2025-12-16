# Claude Code Session Stats Tracking

**Version 0.5.1** | [Changelog](CHANGELOG.md)

Real-time cost tracking and advanced analytics for your Claude Code sessions.

## Quick Install

### Automated (Recommended)
```bash
./install-claude-stats.sh
```
**Time:** ~2 minutes | Auto-detects OS, installs everything, tests it

### Manual Setup
Choose your platform guide:
- **Linux** → `CLAUDE_STATS_SETUP_LINUX.md`
- **macOS** → `CLAUDE_STATS_SETUP_MACOS.md`
- **Windows** → `CLAUDE_STATS_SETUP_WINDOWS.md`

**Time:** ~10 minutes | Step-by-step instructions with full explanations

## What You Get

### Status Line
**Real-time efficiency and cost tracking:**
```
💬 28 msgs | 🔧 185 tools | 🎯 13.5M tok | ⚡ 91% eff | 💳 ~$11.39 ($0.41/msg) | 📊 /trip-computer
```
- **⚡ 91% eff** - Cache efficiency showing how well prompt caching is working
- **($0.41/msg)** - Cost per message for immediate spending awareness and trajectory tracking
- **📊 /trip-computer** - Quick reminder to check detailed analytics

Or when agents are working:
```
🤖 Sub-agents running, stand by...
```

### Trip Computer (`/trip-computer`)
**Advanced analytics dashboard with health scoring and optimization:**

**What You Get:**
- 📈 **Session Health Score** (0-100) - Automated health assessment with 5-star rating
- 🤖 **Model Mix Breakdown** - See which models you used and their cost contribution
- 💵 **Cost Drivers Analysis** - Visual breakdown showing what's expensive (input/output/cache)
- ⚡ **Efficiency Metrics** - Output/input ratio, cache hit rate, cost per token
- 🎯 **Prioritized Recommendations** - Top 3 actions ranked by potential savings (e.g., "Save $0.60/10 msgs")
- 📊 **Best-effort cost estimates** from session transcript (typically within 10% of actual)
- 📈 **Trajectory Projections** - Next 10 messages, hourly rate estimates
- ⚠️ **Context Growth Warnings** - When to use `/clear` for better performance

**For API Users:**
- Reminds you to run `/cost` separately for official billing comparison
- Estimates help with real-time decision making between interactions

**For Subscription Users:**
- Shows API-equivalent estimates to understand rate limit impact
- No actual charges (usage included in subscription)

## Features

✅ **Session health scoring** (NEW v0.5.0) - 0-100 automated assessment with 5-star rating
✅ **Cost drivers breakdown** (NEW v0.5.0) - Visual analysis of what's driving costs (input/output/cache)
✅ **Model mix visibility** (NEW v0.5.0) - See which models used and switching suggestions
✅ **Efficiency metrics** (NEW v0.5.0) - Output/input ratio, cache hit rate, cost per token
✅ **Prioritized recommendations** (NEW v0.5.0) - Top 3 actions ranked by dollar savings
✅ **Billing mode detection** - Adapts messaging for API (💳) or Subscription (📅) users
✅ **Cache efficiency tracking** - Real-time cache performance indicator (⚡ X% eff)
✅ **Best-effort estimates** - Transcript-based calculations typically within 10% of actual costs
✅ **Model-aware pricing** - All versions: Opus 3/4/4.5, Sonnet 3.7/4/4.5, Haiku 3/3.5/4.5
✅ **Accurate cache pricing** - Model-specific multipliers (including Haiku 3 exception)
✅ **Agent activity indicator** - Shows when sub-agents are running
✅ **Session-level tracking** - Know what each coding session costs
✅ **Real-time updates** - Status line refreshes automatically

## Why This is Valuable

**Speedometer vs. Odometer:**
- **Trip Computer** = Speedometer (real-time insights for decision making)
- **/cost command** = Odometer (authoritative billing from Anthropic)
- Both are valuable: Use trip computer for session optimization, `/cost` for billing verification

**Immediate Decision Making:**
- "This is getting expensive, let me switch to Haiku"
- "Cache reads are high, maybe start a fresh session"
- "This task cost $15 - worth it for the result"

**Cost Awareness:**
- Track expenses per session
- Understand which workflows are expensive
- Learn to use appropriate models
- Improve cost efficiency over time

**Session vs Billing:**
- `/session-stats` = Speedometer (real-time, per-session)
- `/cost` = Odometer (final billing)
- Both are valuable for complete cost awareness

## Installation

**Time required:** ~10 minutes

**Prerequisites:**
- `jq` (JSON processor)
- `bc` (calculator, usually pre-installed)
- `bash` (usually pre-installed)

See platform-specific guides for detailed instructions.

## How It Works

**Billing Configuration:** User selects API or Subscription during installation, stored in `~/.claude/hooks/.stats-config`
**Model Detection:** Reads model name from transcript, detects specific versions (e.g., opus-4-5, haiku-3)
**Token Deduplication:** Groups by `requestId`, takes MAX per request to avoid inflation
**Agent Detection:** Checks for recently modified agent files (<10 seconds)
**Cache Pricing:** Applies model-specific multipliers (standard: 1.25x/0.10x, Haiku 3: 1.20x/0.12x)

## Known Limitations

### Session Stats Reset with `/clear` Command

**Current Behavior:** When you use the `/clear` command in Claude Code, it creates a new session with a new transcript file. This means the session stats will reset to zero, showing stats only for the new session.

**Why:** Each session has its own transcript file, and stats are calculated from the current session's transcript. This is by design to keep session tracking simple, predictable, and isolated per session.

**Desired Future Behavior:** Ideally, stats would be cumulative across `/clear` commands within the same Claude Code instance, but reset when Claude Code is closed and restarted.

**Workaround:** Note the costs before using `/clear` if you need to track total spending across multiple cleared sessions within the same work period.

**Status:** Documented as a known limitation. See "Future Enhancements" section for planned improvements.

## Pricing Reference (2025)

| Model | Input | Output | Cache Write (5m) | Cache Read |
|-------|-------|--------|------------------|------------|
| **Opus 4.5** | $5/MTok | $25/MTok | $6.25/MTok | $0.50/MTok |
| **Opus 3/4/4.1** | $15/MTok | $75/MTok | $18.75/MTok | $1.50/MTok |
| **Sonnet 3.7/4/4.5** | $3/MTok | $15/MTok | $3.75/MTok | $0.30/MTok |
| **Haiku 4.5** | $1/MTok | $5/MTok | $1.25/MTok | $0.10/MTok |
| **Haiku 3.5** | $0.80/MTok | $4/MTok | $1/MTok | $0.08/MTok |
| **Haiku 3** | $0.25/MTok | $1.25/MTok | $0.30/MTok* | $0.03/MTok* |

*Haiku 3 uses different cache multipliers: 1.20x for writes, 0.12x for reads

**Subscriptions:** Pro ($20/mo), Max 5x ($100/mo), Max 20x ($200/mo)

## Disclaimer

These are session-level estimates from transcript data, typically accurate within 10% of the `/cost` command. Differences occur due to background operations, timing variations, and API measurement methods. For official billing amounts, use the `/cost` command. For subscription users, these show API-equivalent costs - your actual usage is included in your plan.

## Distribution

**What to share:**
- Minimum: `install-claude-stats.sh` + `README.md`
- Complete: All 5 files (installer + README + 3 platform guides)

**Via email/Slack:**
```
"Hey team! Real-time Claude Code cost tracking - 2 min setup.
Run: ./install-claude-stats.sh
See: README.md for details"
```

**Installation success:** Users see stats in their status bar and can run `/session-stats`

## Technical Details

- **Deduplication:** Groups by `requestId` to avoid counting duplicates (3-4x inflation without this)
- **Cross-platform:** Works on Linux, macOS, Windows (WSL/Git Bash)
- **Agent detection:** Shows indicator when sub-agents active (files modified <10 seconds)
- **Model-aware:** Automatically detects and applies correct pricing rates
- **Session-scoped:** Tracks THIS session only, not total billing

## Future Enhancements

Potential improvements for future versions:

- [ ] **Cumulative stats across `/clear` sessions** - Track cumulative costs within the same Claude Code instance even when using `/clear`, but reset when Claude Code is closed and restarted
  - Possible approaches: PID-based session detection, persistent marker file with inactivity timeout, or user-controlled reset command
  - Trade-off: Added complexity (50-60 lines) and edge cases vs. convenience
- [ ] Support for multiple sessions comparison
- [ ] Cost history tracking over time
- [ ] Budget alerts/warnings
- [ ] Export stats to CSV/JSON
- [ ] Integration with time tracking tools
- [ ] Team/project-level aggregation
- [ ] Custom pricing profiles
- [ ] Model performance metrics

## Support

**Installation issues?** Check troubleshooting section in your platform guide
**Questions?** Review the detailed setup guide for your OS
**Need help?** Verify prerequisites are installed (`jq`, `bc`)

---

**Ready to install? Run `./install-claude-stats.sh` or follow your platform guide!**
