# CLAUDE.md - Project Context for Claude Code

## Project Overview

**Name:** Claude Trip Computer
**Version:** 0.13.0 (see [CHANGELOG.md](CHANGELOG.md))
**Purpose:** Real-time session analytics and optimization system for Claude Code
**Type:** TypeScript CLI utility
**Status:** Production-ready - Complete TypeScript rewrite with accurate context tracking and per-model cost breakdown

## What This Project Does

Provides comprehensive session analytics for Claude Code:

1. **Status line** - Real-time efficiency metrics (model, tools, cache, verbosity)
2. **Context tracking** - Accurate usage from Claude Code stdin (Node.js only)
3. **Trip computer** - Detailed analytics dashboard with optimization insights
4. **Per-model tracking** - Token counts and cost percentages for each model used
5. **Billing mode differentiation** - API users (optimization) vs Subscription users (value awareness)
6. **Token deduplication** - Groups by requestId + model to avoid 3-4x inflation

## Project Structure

```
claude-trip-computer/
├── src/
│   ├── index.ts              # Entry point, mode detection, caching
│   ├── transcript.ts         # Parser with deduplication logic
│   ├── analytics.ts          # Health scoring, recommendations
│   ├── cache.ts              # 5-second session cache
│   ├── usage-api.ts          # OAuth rate limit API (future)
│   ├── stdin.ts              # Claude Code stdin reader
│   ├── types.ts              # TypeScript interfaces
│   ├── constants.ts          # Pricing tables
│   ├── render/
│   │   ├── status-line.ts    # Brief status renderer
│   │   └── trip-computer.ts  # Full dashboard renderer
│   └── utils/
│       └── config.ts         # Billing config reader
├── package.json              # Node.js metadata (zero deps)
├── tsconfig.json             # TypeScript config
├── VERSION                   # 0.13.0
├── CHANGELOG.md              # Version history
├── README.md                 # User documentation
└── TROUBLESHOOTING.md        # Setup help
```

## Installation

### Automated (Recommended)

Run the installation script:
```bash
# Linux/macOS
./install.sh

# Windows
install.bat
```

The script will:
- Check Node.js 18+ requirement
- Prompt for billing mode (API/Subscription)
- Create configuration files
- Update settings.json
- Test the installation

### Manual Configuration

Users can manually configure `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "npx -y tsx /full/path/to/claude-trip-computer/src/index.ts"
  }
}
```

And create `~/.claude/hooks/.stats-config`:

```bash
BILLING_MODE="API"  # or "Sub"
BILLING_ICON="💳"   # or "📅"
SAFETY_MARGIN="1.00"  # 1.10 for subscription
```

## Usage Instructions for Assistant

**Skill Configuration:**

The trip computer is available as a Skill at `~/.claude/skills/trip/SKILL.md`. It can be invoked by:
- User typing `/trip` explicitly
- User asking for session analytics, cost breakdown, or performance insights
- Automatic discovery when session analysis is relevant

**Critical Behavioral Requirement:**

When the `/trip` Skill is invoked:
1. Execute: `npx -y tsx /Users/llaje/Code/claude-trip-computer/src/index.ts --trip-computer` using Bash tool
2. **Immediately copy the COMPLETE output into your text response as a code block**
3. Display ONLY the raw output - NO additional text, commentary, or analysis before/after
4. Do NOT leave output in collapsed Bash tool result - user must see it immediately

**Required Output Format:**
```
[Complete trip computer dashboard output in code block]
```

**DO NOT:**
- Add summaries or interpretations
- Leave output collapsed in tool result
- Add any text before or after the code block
- Modify or reformat the output
- The output is self-contained and complete

The trip computer output already includes all necessary context, health assessment, recommendations, and insights. The Skill file at `~/.claude/skills/trip/SKILL.md` contains these same instructions to ensure deterministic formatting.

## Key Technical Concepts

### Token Deduplication

**Problem:** Session transcripts contain multiple entries per API call (3-4x inflation).

**Solution:** Group by `requestId + model`, take MAX value per token type, then aggregate:

```typescript
// Per-request deduplication
const seenRequests = new Map<string, TokenUsage>();
const dedupKey = `${requestId}|${modelId}`;

if (!seenRequests.has(dedupKey)) {
  seenRequests.set(dedupKey, { input: 0, output: 0, cache_creation: 0, cache_read: 0 });
}

const reqUsage = seenRequests.get(dedupKey)!;
reqUsage.input = Math.max(reqUsage.input, usage.input_tokens ?? 0);
// ... same for other token types

// Then aggregate into per-model totals
for (const [dedupKey, usage] of seenRequests) {
  const modelId = dedupKey.split('|')[1];
  metrics.models[modelId].tokens.input += usage.input;
  // ... etc
}
```

### Model Detection & Pricing

**Detection:**
- Primary: Read from Claude Code stdin (`stdin.model.display_name`)
- Fallback: Parse from transcript `message.model` field

**Pricing Application:**

```typescript
// constants.ts - Prices per million tokens
const MODEL_PRICING: Record<string, ModelPricing> = {
  'opus-4-5': { input_rate: 5, output_rate: 25, cache_write_mult: 1.25, cache_read_mult: 0.10 },
  'sonnet-4-5': { input_rate: 3, output_rate: 15, cache_write_mult: 1.25, cache_read_mult: 0.10 },
  'haiku-4-5': { input_rate: 1, output_rate: 5, cache_write_mult: 1.25, cache_read_mult: 0.10 },
  // ... Haiku 3 has different multipliers: 1.20x / 0.12x
};

// Cost calculation
const inputCost = (tokens.input * pricing.input_rate) / 1_000_000;
const cacheWriteCost = (tokens.cache_creation * pricing.input_rate * pricing.cache_write_mult) / 1_000_000;
```

### Context Tracking (v0.13.0+)

**Source:** Claude Code provides context window data via stdin (Node.js/Bun processes only).

**Structure:**
```typescript
interface StdinData {
  context_window?: {
    context_window_size?: number;
    current_usage?: {
      input_tokens?: number;
      output_tokens?: number;
      cache_creation_input_tokens?: number;
      cache_read_input_tokens?: number;
    };
  };
}
```

**Limitation:** Only available when running as status line command. Direct bash execution doesn't receive stdin.

### Agent Discovery (Cross-Project)

**Problem:** Agent transcripts may be in different project directories when context is shared.

**Solution:** Extract agent IDs from main transcript, search across all `~/.claude/projects/` directories:

```typescript
// Extract agent IDs from transcript
const agentIds = new Set<string>();
const matches = content.matchAll(/agent-[a-z0-9]+/g);
for (const match of matches) {
  agentIds.add(match[0]);
}

// Find across all projects (use execSync + find)
const result = execSync(
  `find "${projectsDir}" -name "${agentId}.jsonl" 2>/dev/null | head -1`,
  { encoding: 'utf-8' }
);
```

### Session Caching (5-second TTL)

**Purpose:** Fast status line rendering (~10ms cache hits vs ~200ms misses).

**Cache Structure:**
```typescript
interface SessionCache {
  version: string;
  session_id: string;
  last_updated: number;
  transcript_mtime: number;
  transcript_path: string;
  metrics: SessionMetrics;           // Parsed transcript data
  context_window?: ContextWindow;    // From stdin
  model_name?: string;               // From stdin
  analytics: SessionAnalytics;       // Pre-computed insights
  rate_limits?: RateLimits;          // Cached API response
}
```

**Validation:** Cache is valid if `last_updated` is within 5 seconds AND `transcript_mtime` matches file.

### Analytics Computer

**Health Scoring (0-100):**
- Cache efficiency: 0-40 points (>90% = 40, 70-90% = 30, 50-70% = 20, <50% = 0-10)
- Context management: 0-30 points (context < 70% = 30, 70-85% = 20, >85% = 0-10)
- Efficiency: 0-30 points (tools/msg and tok/msg ratios)

**Optimization Actions:** Generated based on thresholds:
- High cache efficiency (>90%) → "Stay in session"
- Low cache efficiency (<50%) → "Consider /clear to rebuild cache"
- High verbosity (>3K tok/msg) → "Add brevity constraints"
- Model switching suggestions based on usage patterns

## Billing Mode Differentiation

### API Users (BILLING_MODE="API")
- **Status line:** No cost display (use `/cost` for billing)
- **Trip computer:** Optimization-focused output
  - "📊 TOKEN DISTRIBUTION" (percentages only)
  - "📊 SESSION METRICS" (no cost)
  - "High efficiency gain" recommendations
  - "📊 SESSION INSIGHTS" (context/tool/cache patterns)

### Subscription Users (BILLING_MODE="Sub")
- **Status line:** Shows API-equivalent value (~$X.XX)
- **Trip computer:** Value awareness + optimization
  - "💵 COST DRIVERS" (with dollar amounts)
  - "📊 SESSION USAGE ESTIMATE" (with cost)
  - "Save ~$X.XX/10 msgs" recommendations
  - "📈 TRAJECTORY" (cost projections)

**Safety Margin:** 1.00 for API (reference only), 1.10 for Sub (10% conservative buffer)

## Model Pricing (2026)

| Model | Input | Output | Cache Write | Cache Read |
|-------|-------|--------|-------------|------------|
| Opus 4.5 | $5 | $25 | $6.25 (1.25x) | $0.50 (0.10x) |
| Opus 3/4/4.1 | $15 | $75 | $18.75 (1.25x) | $1.50 (0.10x) |
| Sonnet 3.7/4/4.5 | $3 | $15 | $3.75 (1.25x) | $0.30 (0.10x) |
| Haiku 4.5 | $1 | $5 | $1.25 (1.25x) | $0.10 (0.10x) |
| Haiku 3.5 | $0.80 | $4 | $1.00 (1.25x) | $0.08 (0.10x) |
| Haiku 3 | $0.25 | $1.25 | $0.30 (1.20x)* | $0.03 (0.12x)* |

*Haiku 3 exception: Different multipliers

**Source:** https://www.anthropic.com/pricing (verified 2026-01-12)

## Known Limitations

1. **Context tracking** - Only available when running as status line (stdin access)
2. **Stats reset with `/clear`** - New session = new transcript = reset stats (by design)
3. **5-15% variance from `/cost`** - Due to web search costs, transcript lag, background ops
4. **Long context pricing** - Doesn't detect per-request >200K threshold (Sonnet 4/4.5 premium rates)

## Development Guidelines

### Version Bumping (Semantic Versioning)

**MAJOR (X.0.0):** Breaking changes to config format, installation process, or file structure
**MINOR (0.X.0):** New features, new metrics, backwards-compatible enhancements
**PATCH (0.0.X):** Bug fixes, documentation updates, pricing updates

### Files to Update When Making Changes

**Always update:**
1. `VERSION` - Bump version number
2. `CHANGELOG.md` - Document changes in appropriate section
3. Relevant `src/*.ts` files - Code changes
4. `README.md` - If user-facing functionality changes
5. `CLAUDE.md` - If architecture or concepts change (this file)

**Test checklist:**
- Run with `--trip-computer` flag and verify output
- Test status line: `npx tsx src/index.ts` (no flag)
- Verify per-model cost calculations
- Check both API and Sub billing modes
- Test with various model types

### Code Patterns

**Safe stdin reading:**
```typescript
const stdinData = await readStdin();
if (stdinData) {
  // Use stdin data
} else {
  // Fallback to file discovery
}
```

**Error handling:**
```typescript
try {
  // ... operation
} catch (error) {
  console.error('[claude-trip-computer] Error:', error instanceof Error ? error.message : 'Unknown');
  console.log('💬 Error | 📈 /trip');
}
```

**Token formatting:**
```typescript
if (count >= 1_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
if (count >= 1_000) return `${(count / 1_000).toFixed(1)}K`;
return `${Math.round(count)}`;
```

## External Documentation References

**Essential Links:**
- **Status Line API:** https://code.claude.com/docs/en/statusline
- **Hooks Guide:** https://code.claude.com/docs/en/hooks-guide
- **Cost Tracking:** https://docs.anthropic.com/en/docs/claude-code/costs
- **API Pricing:** https://www.anthropic.com/pricing
- **Model Docs:** https://docs.anthropic.com/en/docs/about-claude/models/overview
- **Prompt Caching:** https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching

## Support

**Issues?** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
**Questions?** Check [README.md](README.md)
**Bugs?** Review code in `src/` directory

---

**Last Updated:** 2026-01-12 (v0.13.0 - TypeScript rewrite)
**Compatibility:** Node.js 18+, Claude Code latest
