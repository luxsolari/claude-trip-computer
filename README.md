# Claude Code Session Stats Tracking

**Version 0.9.1** | [Changelog](CHANGELOG.md)

Real-time session optimization with complete billing-mode differentiation: actionable efficiency insights for API users, value awareness for subscription users.

## Quick Install

### Windows Users
**Double-click installer:**
```
install-claude-stats.bat
```
- Automatically detects and installs prerequisites (jq, bc)
- Requires Git for Windows

**Or use bash:**
```bash
./install-claude-stats.sh
```

### Linux/macOS Users
```bash
./install-claude-stats.sh
```
- Automatically detects and installs prerequisites if missing
- Supports apt-get, dnf, pacman (Linux) and Homebrew (macOS)

**Time:** ~2 minutes | Auto-detects OS, installs prerequisites, configures everything

### Need Help?
- **Troubleshooting** → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Manual Installation** → See troubleshooting guide (advanced users only)
- **Technical Docs** → [CLAUDE.md](CLAUDE.md)

## What You Get

### Status Line
**Real-time session efficiency metrics:**

**API Users:**
```
💬 28 msgs | 🔧 185 tools (6.6 tools/msg) | ⚡ 91% cached | 📝 1.8K tok/msg | 📈 /trip-computer
```

**Subscription Users:**
```
💬 28 msgs | 🔧 185 tools (6.6 tools/msg) | ⚡ 91% cached | 📝 1.8K tok/msg | 📅 ~$11.39 value | 📈 /trip-computer
```

**What You See:**
- **🔧 185 tools (6.6 tools/msg)** - Tool usage intensity showing task complexity (≥15: very intensive, ≥5: moderate, >0: light)
- **⚡ 91% cached** - Cache efficiency showing how well prompt caching is working
- **📝 1.8K tok/msg** - Response verbosity (avg output tokens per message)
- **📅 ~$11.39 value** (Sub users only) - API-equivalent value with 10% safety margin
- **📈 /trip-computer** - Access detailed optimization analytics

Or when agents are working:
```
🤖 Sub-agents running, stand by...
```

### Trip Computer (`/trip-computer`)
**Session optimization dashboard with complete billing-mode differentiation (NEW v0.9.0):**

**For API Users** - Optimization-First Experience:
- 📈 **Session Health Score** (0-100) with 5-star rating
- 🤖 **Model Mix Analysis** - See which models you used and when to switch
- 📊 **Token Distribution** - Visual breakdown showing input/output/cache patterns (percentages only)
- ⚡ **Efficiency Metrics** - Tool usage intensity, response verbosity, cache hit rate
- 🎯 **Top 3 Optimization Actions** - Ranked by efficiency gains (no dollar amounts)
- 📊 **Session Insights** - Context growth rate, tool patterns, cache performance trends
- **NO COST DISPLAY** - Use `/cost` for official billing (accurate, authoritative)
- **Purpose**: Actionable session optimization without cost distraction

**For Subscription Users** - Value + Optimization:
- 📈 **Session Health Score** (0-100) with 5-star rating
- 🤖 **Model Mix Analysis** - See which models you used and when to switch
- 💵 **Cost Drivers Breakdown** - Visual breakdown with dollar amounts (10% safety margin)
- ⚡ **Efficiency Metrics** - Tool usage intensity, response verbosity, cache hit rate
- 🎯 **Top 3 Optimization Actions** - Ranked by dollar savings potential
- 📈 **Cost Trajectory** - Projected costs for next 10 messages, hourly rate
- **API-Equivalent Estimates** - Understand subscription value with conservative buffer
- **Purpose**: Value awareness + session optimization guidance

### Session End Statistics (NEW v0.7.0)
**Automatic final analytics when sessions end:**

When you exit Claude Code, use `/clear`, or log out, you'll automatically see:
```
╔══════════════════════════════════════════════════════════════════════════════╗
║                          SESSION ENDED - FINAL STATS                         ║
╚══════════════════════════════════════════════════════════════════════════════╝

Session ID: abc123
Exit Reason: exit

[Complete Trip Computer Analytics Display]
```

**Benefits:**
- **Zero effort** - Statistics appear automatically, no command needed
- **Perfect timing** - Review costs right when you finish working
- **Complete picture** - Full trip computer analytics, not just brief stats
- **Session awareness** - Understand what each work session cost
- **Learning tool** - See which workflows are most/least expensive over time

**Triggers on:**
- Claude Code exit
- `/clear` command (session reset)
- Logout
- Any other session termination event

## Features

✅ **Automatic session-end statistics** (NEW v0.7.0) - Full trip computer analytics displayed automatically when sessions end (exit, `/clear`, logout)
✅ **Prompt quality analysis** (v0.6.0) - Detects 4 inefficient prompting patterns (vague questions, large pastes, repeated questions, missing constraints) with estimated savings
✅ **Session health scoring** (v0.5.0) - 0-100 automated assessment with 5-star rating
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
