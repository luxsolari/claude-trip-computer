# Claude Trip Computer

**Version 0.13.2** | [Changelog](CHANGELOG.md) 

Real-time session analytics and optimization insights for Claude Code. TypeScript-powered with multi-line status display, git integration, tool activity tracking, and efficiency metrics.

![License](https://img.shields.io/github/license/luxsolari/claude-trip-computer)

## Quick Setup

### Prerequisites

- **Node.js 18+** - Check: `node --version` ([Download](https://nodejs.org/))
- **Claude Code** - Latest version recommended

### Automated Installation (Recommended)

**Windows:**
```cmd
# Double-click or run:
install.bat
```

**Linux/macOS:**
```bash
./install.sh
```

The installer will:
- ✓ Check Node.js version (18+ required)
- ✓ Detect and remove old bash-based installations automatically
- ✓ Prompt for billing mode (API or Subscription)
- ✓ Create configuration files
- ✓ Update Claude Code settings
- ✓ Create `/trip` command
- ✓ Test the installation

**Time:** ~2 minutes | **Then restart Claude Code**

> **Upgrading from bash version?** The installer automatically detects and removes old bash scripts, hooks, and cache files. No manual cleanup needed!

### Manual Installation

<details>
<summary>Click to expand manual setup instructions</summary>

1. **Clone repository:**
   ```bash
   cd ~/Code  # or your preferred location
   git clone <repository-url> claude-trip-computer
   ```

2. **Configure billing mode:**

   Create `~/.claude/hooks/.stats-config`:
   ```bash
   # Claude Code Session Stats Configuration
   BILLING_MODE="API"  # or "Sub" for subscription
   BILLING_ICON="💳"   # or "📅" for subscription
   SAFETY_MARGIN="1.00"  # 1.10 for subscription (10% buffer)
   ```

3. **Configure Claude Code status line:**

   Edit `~/.claude/settings.json`:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "npx -y tsx /full/path/to/claude-trip-computer/src/index.ts"
     }
   }
   ```

   Replace `/full/path/to/` with your actual path.

4. **Restart Claude Code**

**Time:** ~5 minutes

</details>

### Need Help?
- **Troubleshooting** → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Technical Docs** → [CLAUDE.md](CLAUDE.md)

## What You Get

### Status Line
**Real-time session efficiency metrics in your Claude Code status bar:**

**Multi-Line Status (v0.13.2):**
```
💬 5 msgs (Opus 4.5) | 🔧 12 tools (2.4/msg) | 🎯 15.3K tok | 🌿 main* | ████░░░░░░ 35% | ⚡ 78% cached | 📝 3.1K/msg | ⏱️ 31m | 📈 /trip
✓ Edit ×55 | ✓ Bash ×41 | ✓ Read ×23 | ✓ Write ×8
✓ Explore: Explore codebase structure (52s)
▸ Fix authentication bug (2/5)
```

**Line 1 - Session Metrics:**
- **💬 5 msgs (Opus 4.5)** - Message count with current model
- **🔧 12 tools (2.4/msg)** - Tool usage with intensity ratio
- **🎯 15.3K tok** - Total tokens (deduplicated)
- **🌿 main*** - Git branch with dirty indicator (NEW)
- **████░░░░░░ 35%** - Context window usage bar
- **⚡ 78% cached** - Cache efficiency
- **📝 3.1K/msg** - Response verbosity
- **⏱️ 31m** - Session duration (NEW)
- **📈 /trip** - Trip computer link
- **📅 ~$X.XX value** (Sub users only) - API-equivalent value

**Line 2 - Tool Activity (NEW):**
- Top 5 tools by frequency with accurate session-wide counts
- Running tools: `◐ Bash: command...`

**Lines 3+ - Agent Status (NEW, when agents exist):**
- Shows running/completed agents with duration

**Final Line - Todo Progress (NEW, when todos exist):**
- In progress: `▸ Task name (2/5)`
- Complete: `✓ All todos complete (5/5)`

**Or when analyzing:**
```
🤖 Sub-agents running, stand by...
```

### Trip Computer

Ask Claude to show trip computer stats, or run directly:
```bash
npx tsx /path/to/claude-trip-computer/src/index.ts --trip-computer
```

**Session optimization dashboard with complete billing-mode differentiation:**

**For API Users** - Optimization-First Experience:
```
═══════════════════════════════════════════════════════════════
  📊 TRIP COMPUTER - Session Analytics Dashboard
═══════════════════════════════════════════════════════════════

📊 QUICK SUMMARY
───────────────────────────────────────────────────────────────
  Health: ⭐⭐⭐⭐⭐ Excellent (85/100)
  Messages: 3 | Tools: 46 | Tokens: 3.8M

📈 SESSION HEALTH (0-100)
───────────────────────────────────────────────────────────────
  Overall: ⭐⭐⭐⭐⭐ 85/100

  ⚡ Cache Efficiency: ✅ 40/40 points
     90% cache hit rate

  ⚙️  Context Management: ➡️ 15/30 points
     Context tracking unavailable

  🎯 Efficiency: ✅ 30/30 points
     15.3 tools/msg, 4.4K tok/msg

🤖 MODEL MIX
───────────────────────────────────────────────────────────────
  Sonnet 4.5
  █████████░ 92.7% of cost
  Tokens: 3.5M

  Haiku 4.5
  ░░░░░░░░░░ 7.3% of cost
  Tokens: 336.7K

📊 TOKEN DISTRIBUTION
───────────────────────────────────────────────────────────────
  Input: 0.1% ░░░░░░░░░░
  Output: 0.3% ░░░░░░░░░░
  Cache writes: 9.6% ░░░░░░░░░░
  Cache reads: 90.0% █████████░

⚡ EFFICIENCY METRICS
───────────────────────────────────────────────────────────────
  Tool Intensity: Minimal - early session or simple tasks
    46 tools (15.3 tools/msg) across 3 msgs

  Response Verbosity: Concise - brief responses
    4.4K tokens/msg average

  Output/Input Ratio: 3.13x

  Cache Hit Rate: 90.4%
    Excellent → stay in session

📊 SESSION METRICS
───────────────────────────────────────────────────────────────
  Messages: 3 | Tools: 46
  Cache Efficiency: 90.4%
  Total Tokens: 3,815,792

  ℹ️  Use /cost for official billing amounts

🎯 TOP OPTIMIZATION ACTIONS
───────────────────────────────────────────────────────────────
  ✅ Session looks well-optimized! Keep up the good work.

📊 SESSION INSIGHTS
───────────────────────────────────────────────────────────────
  Context Growth: Slow growth → healthy pace
    4.4K tokens/msg average

  Tool Pattern: Minimal - early session or simple tasks
    46 tools (15.3 tools/msg)

  Cache Performance: Excellent → stay in session
    90.4% hit rate
```

**For Subscription Users** - Value + Optimization:
- Same dashboard with **💵 Cost Drivers** (dollar amounts)
- **📈 Trajectory** section with projected costs
- **Dollar savings** in optimization recommendations
- API-equivalent estimates with 10% safety margin

## How It Works

### Technical Implementation

**Architecture:** TypeScript executed via `npx tsx` (no compilation needed)

**Claude Code Features Used:**

1. **Status Line Command** (`~/.claude/settings.json`)
   - Not a hook - direct command execution by Claude Code
   - Invoked automatically on every interaction
   - Receives JSON stdin: `{session_id, model, context_window, ...}`
   - Returns formatted string to status bar

2. **Custom Slash Command** (`~/.claude/commands/trip.md`)
   - User-invocable skill via `/trip`
   - Assistant executes command with `--trip-computer` flag
   - Assistant displays output in code block (instructed by skill docs)
   - No hooks involved - pure command execution

3. **No Hooks Used** (v0.11.0+)
   - Old bash version (<0.11.0) used SessionEnd hooks for automatic session-end stats
   - v0.11.0 removed all hooks - uses only status line command + slash command
   - Installer automatically removes old SessionEnd hooks from settings.json

**Status Line Flow:**
```
User interaction → Claude Code invokes status line command
→ Script reads stdin (session_id, model, context)
→ Parses transcript: ~/.claude/projects/<project>/<session>.jsonl
→ Deduplicates tokens by requestId + model
→ Aggregates per-model, calculates costs
→ Returns: "💬 X msgs (Model) | 🔧 X tools | ..."
```

**Trip Computer Flow:**
```
User types /trip → Assistant invokes skill
→ Skill executes: npx tsx src/index.ts --trip-computer
→ Same parsing + deduplication + analytics computation
→ Outputs dashboard to stdout
→ Assistant copies output to response (per skill instructions)
```

**Session Caching:**
- 5-second TTL cache in `~/.claude/session-stats/<session_id>.json`
- Cache invalidated when transcript mtime changes
- ~10ms cache hits vs ~200ms misses (90% hit rate typical)

**Transcript Deduplication Algorithm:**
```typescript
// Group by requestId + model, take MAX tokens per request
const dedupKey = `${requestId}|${modelId}`;
requestUsage.input = Math.max(requestUsage.input, usage.input_tokens);
// Then aggregate into per-model totals
```

**Cross-Project Agent Discovery:**
- Extracts agent IDs from main transcript: `/agent-[a-z0-9]+/g`
- Searches all `~/.claude/projects/*/agent-*.jsonl` files
- Includes agent usage in cost calculation (agents are billable)

**Zero Dependencies:** Uses only Node.js stdlib (no `npm install` needed)

## Features

### ✨ New in v0.13.0 (Multi-Line Status)
✅ **Multi-line status display** - Session metrics + tool activity + agents + todos
✅ **Git branch integration** - Shows branch name with dirty indicator (`🌿 main*`)
✅ **Session duration** - Time since session started (`⏱️ 31m`)
✅ **Tool activity tracking** - Top 5 tools by frequency with accurate counts
✅ **Agent status display** - Running and completed agents with duration
✅ **Todo progress** - Current task and completion status
✅ **Accurate tool counts** - Aggregates ALL tools (improvement over claude-hud's last 20)

### Session Analytics
✅ **Session health scoring** - 0-100 automated assessment with 5-star rating
✅ **Model mix visibility** - See which models used with cost breakdown
✅ **Cost drivers breakdown** - Visual analysis of input/output/cache patterns
✅ **Efficiency metrics** - Tool intensity, response verbosity, cache hit rate
✅ **Prioritized recommendations** - Top 3 actions ranked by impact
✅ **Billing mode differentiation** - Adapts for API (💳) or Subscription (📅) users

### Technical
✅ **Best-effort estimates** - Transcript-based calculations typically within 5-15% of `/cost`
✅ **Model-aware pricing** - All versions: Opus 3/4/4.5, Sonnet 3.7/4/4.5, Haiku 3/3.5/4.5
✅ **Accurate cache pricing** - Model-specific multipliers (including Haiku 3 exception)
✅ **Token deduplication** - Groups by requestId to avoid inflation
✅ **Cross-project agent tracking** - Finds agent transcripts across all projects
✅ **Real-time updates** - Status line refreshes automatically

## Why This is Valuable

**Speedometer vs. Odometer:**
- **Trip Computer** = Speedometer (real-time insights for decision making)
- **/cost command** = Odometer (authoritative billing from Anthropic)
- Both are valuable: Use trip computer for session optimization, `/cost` for billing verification

**Immediate Decision Making:**
- "This is getting expensive, let me switch to Haiku"
- "Cache efficiency is great, stay in this session"
- "This task used 3.8M tokens - worth tracking"

**Cost Awareness:**
- Track session efficiency in real-time
- Understand which workflows are expensive
- Learn to use appropriate models
- Improve cost efficiency over time

**Session vs Billing:**
- Trip Computer = Real-time session insights
- `/cost` = Final billing verification
- Both are valuable for complete awareness

## How It Works

**Model Detection:** Reads model name from Claude Code stdin (real-time) or transcript fallback
**Token Deduplication:** Groups by `requestId` + `model`, takes MAX per request to avoid inflation
**Per-Model Tracking:** Aggregates tokens and calculates costs separately for each model used
**Agent Detection:** Finds agent transcripts across all project directories for complete session view
**Context Tracking:** Receives context window data from Claude Code stdin (Node.js/Bun only)
**Cache Pricing:** Applies model-specific multipliers (standard: 1.25x/0.10x, Haiku 3: 1.20x/0.12x)
**Billing Configuration:** Reads mode from `~/.claude/hooks/.stats-config` (API vs Subscription)

## Pricing Reference (2026)

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

## Known Limitations

### Context Tracking
**Limitation:** Context tracking is only available when running as a status line command. Direct execution via bash doesn't receive stdin from Claude Code.

**Why:** Claude Code only provides stdin data (context_window, model) to processes invoked as status line commands.

**Workaround:** Use `/context` command for accurate context information.

### Stats Reset with `/clear` Command

**Current Behavior:** When you use `/clear`, stats reset to zero (new session, new transcript).

**Why:** Each session has its own transcript file for isolation and simplicity.

**Desired Future:** Cumulative stats across `/clear` within same Claude Code instance.

**Workaround:** Note costs before `/clear` if tracking total spending across resets.

## Disclaimer

These are session-level estimates from transcript data, typically accurate within 5-15% of the `/cost` command. Differences occur due to:
- Web search costs (may not appear in transcript usage)
- Background operations
- Timing variations (transcript lag)
- API measurement methods

**For official billing amounts, always use the `/cost` command.** For subscription users, these show API-equivalent costs - your actual usage is included in your plan.

## Technical Architecture

**Language:** TypeScript with ES2022 modules
**Runtime:** Node.js 18+ (via tsx for direct TS execution)
**Dependencies:** Zero npm packages (stdlib only)
**Entry Point:** `src/index.ts`
**Modules:** Transcript parser, analytics computer, renderers, cache manager, usage API client
**Data Flow:** stdin → transcript parse → analytics compute → cache → render

## Future Enhancements

Potential improvements for future versions:

- [ ] **Rate limit display** - Show OAuth rate limits in status line (library implemented)
- [ ] **Cumulative stats across `/clear`** - Track within same instance, reset on close
- [ ] **Cost history tracking** - Session-over-session trends
- [ ] **Budget alerts** - Configurable spending warnings
- [ ] **Export stats** - CSV/JSON for analysis
- [ ] **Time tracking integration** - Link sessions to work periods
- [ ] **Team analytics** - Aggregate across multiple users
- [ ] **Custom pricing profiles** - User-defined rates

## Support

**Installation issues?** Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

**Questions?** Review [CLAUDE.md](CLAUDE.md) for technical details

**Need help?** Verify Node.js 18+ is installed: `node --version`

---

**Ready to use?** Add to `~/.claude/settings.json` and restart Claude Code!
