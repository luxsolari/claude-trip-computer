# Contributing to Claude Trip Computer

Thank you for your interest in contributing! This project maintains strict conventions for consistency and quality.

## Development Setup

### Prerequisites

- **Node.js 18+** - Check: `node --version`
- **TypeScript knowledge** - Familiarity with TypeScript syntax and types
- **Git** - For version control

### Initial Setup

1. **Clone repository:**
   ```bash
   git clone <repository-url> claude-trip-computer
   cd claude-trip-computer
   ```

2. **Test the application:**
   ```bash
   # Status line mode
   npx tsx src/index.ts

   # Trip computer mode
   npx tsx src/index.ts --trip-computer
   ```

3. **Configure for testing:**
   - Edit `~/.claude/settings.json` to point to your local copy
   - Create test config in `~/.claude/hooks/.stats-config`

## Development Conventions

### 1. Semantic Versioning (SemVer)

**REQUIRED:** All version numbers MUST follow [Semantic Versioning 2.0.0](https://semver.org/)

**Format:** `MAJOR.MINOR.PATCH`

**Rules:**
- **MAJOR (X.0.0):** Breaking changes to config format, API, or installation
  - Example: v1.0.0 → v2.0.0 (incompatible config file format)
- **MINOR (0.X.0):** New backward-compatible features
  - Example: v0.12.0 → v0.13.0 (added multi-line status)
- **PATCH (0.0.X):** Backward-compatible bug fixes
  - Example: v0.13.0 → v0.13.2 (fixed cost calculation bug)

**Files to Update:**
1. `VERSION` - Single source of truth
2. `CHANGELOG.md` - Document the version with details
3. `CLAUDE.md` - Update version references (header, last updated)
4. `README.md` - Update version badge
5. `src/index.ts` - Update version in header comment
6. `install.sh` - Update version in header (if changed)
7. `install.bat` - Update version in header (if changed)

### 2. Conventional Commits

**REQUIRED:** All commit messages MUST follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/)

**Format:**
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Allowed Types:**
- `feat`: New feature (MINOR version bump)
- `fix`: Bug fix (PATCH version bump)
- `docs`: Documentation only
- `style`: Code formatting (no functional changes)
- `refactor`: Code restructuring (no behavior changes)
- `perf`: Performance improvement
- `test`: Adding/updating tests
- `chore`: Build process, dependencies, etc.

**Examples:**
```bash
feat(analytics): add rate limit tracking to status line

fix(transcript): correct per-model token aggregation

docs(readme): update TypeScript setup instructions

refactor(cache): extract session cache to separate module
```

**Breaking Changes:**
```bash
feat!: migrate from bash to TypeScript

BREAKING CHANGE: All bash scripts removed. Users must reconfigure settings.json.
```

### 3. TypeScript Conventions

**Style:**
- Use strict TypeScript (`strict: true` in tsconfig.json)
- Define interfaces in `types.ts`
- Export types alongside implementations
- Use ES2022 module syntax (`import/export`)

**File Organization:**
```
src/
├── index.ts              # Entry point (mode detection, orchestration)
├── transcript.ts         # Domain logic (parsing, deduplication)
├── analytics.ts          # Business logic (health, recommendations)
├── cache.ts              # Infrastructure (persistence)
├── usage-api.ts          # External services (OAuth API)
├── stdin.ts              # Infrastructure (Claude Code integration)
├── types.ts              # Type definitions (shared interfaces)
├── constants.ts          # Configuration (pricing, constants)
├── render/               # Presentation layer
│   ├── status-line.ts    # Brief output formatter
│   └── trip-computer.ts  # Detailed output formatter
└── utils/                # Utilities
    └── config.ts         # Config file reading
```

**Naming Conventions:**
- **Classes:** PascalCase (e.g., `TranscriptParser`, `SessionCacheManager`)
- **Functions:** camelCase (e.g., `readStdin`, `calculateCost`)
- **Interfaces:** PascalCase (e.g., `SessionMetrics`, `TokenUsage`)
- **Constants:** SCREAMING_SNAKE_CASE (e.g., `MODEL_PRICING`, `CACHE_TTL_SECONDS`)
- **Files:** kebab-case (e.g., `trip-computer.ts`, `status-line.ts`)

**Example Interface:**
```typescript
export interface SessionMetrics {
  session_id: string;
  message_count: number;
  tool_count: number;
  total_tokens: TokenUsage;
  models: Record<string, ModelUsage>;
  cache_efficiency: number;
  tokens_per_message: number;
  tools_per_message: number;
  total_cost: number;
}
```

### 4. Code Patterns

**Error Handling:**
```typescript
try {
  // ... operation
} catch (error) {
  console.error('[claude-trip-computer] Error:',
    error instanceof Error ? error.message : 'Unknown error'
  );
  console.log('💬 Error | 📈 /trip');
}
```

**Safe Optional Access:**
```typescript
const modelName = getModelName(stdinData);  // Returns 'Unknown' if missing
const context = getContextWindow(stdinData);  // Returns null if missing

if (context) {
  // Use context data
}
```

**Token Formatting:**
```typescript
function formatTokens(count: number): string {
  if (count >= 1_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
  if (count >= 1_000) return `${(count / 1_000).toFixed(1)}K`;
  return `${Math.round(count)}`;
}
```

## Testing Checklist

Before submitting a pull request:

- [ ] Test status line: `npx tsx src/index.ts`
- [ ] Test trip computer: `npx tsx src/index.ts --trip-computer`
- [ ] Verify per-model cost calculations are accurate
- [ ] Test both API and Subscription billing modes
- [ ] Test with multiple model types (Opus, Sonnet, Haiku)
- [ ] Verify token deduplication works correctly
- [ ] Check that cache system functions properly
- [ ] Update version numbers in all required files
- [ ] Update CHANGELOG.md with your changes
- [ ] Run TypeScript compiler: `npx tsc --noEmit` (no errors)
- [ ] Test on your platform (macOS/Linux/Windows)

## Pull Request Process

1. **Create a feature branch:**
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. **Make your changes:**
   - Follow conventions above
   - Update documentation
   - Add entries to CHANGELOG.md

3. **Commit with conventional commits:**
   ```bash
   git add .
   git commit -m "feat(scope): description"
   ```

4. **Test thoroughly:**
   - Run through testing checklist
   - Verify no TypeScript errors

5. **Submit pull request:**
   - Clear description of changes
   - Reference any related issues
   - Include testing notes

## Code Review Criteria

Contributions will be reviewed for:

1. **Correctness:** Does it work as intended?
2. **Type Safety:** Proper TypeScript types?
3. **Performance:** No unnecessary parsing/computation?
4. **Maintainability:** Clear, readable code?
5. **Documentation:** Updated README/CLAUDE.md?
6. **Conventions:** Follows all required conventions?
7. **Testing:** Tested on target platforms?

## Common Contribution Areas

### Adding New Metrics

1. **Update `SessionMetrics` interface** in `types.ts`
2. **Calculate metric** in `transcript.ts` or `analytics.ts`
3. **Render metric** in `status-line.ts` or `trip-computer.ts`
4. **Update documentation** in README.md
5. **Bump MINOR version** (new feature)

### Fixing Bugs

1. **Identify root cause** (add comments explaining fix)
2. **Make minimal changes** (don't refactor unrelated code)
3. **Test fix thoroughly** (prevent regressions)
4. **Update CHANGELOG.md** with fix description
5. **Bump PATCH version** (bug fix)

### Improving Documentation

1. **Update relevant .md files**
2. **Ensure examples are current** (test all code blocks)
3. **Commit with `docs:` prefix**
4. **No version bump needed** (unless major doc rewrite)

### Adding Model Support

1. **Add pricing to `MODEL_PRICING`** in `constants.ts`
2. **Add detection pattern** in `formatModelName()` method
3. **Test with transcripts** using new model
4. **Update pricing table** in README.md and CLAUDE.md
5. **Bump MINOR version** (new feature)

## Questions?

- **Technical questions?** Review [CLAUDE.md](CLAUDE.md) for architecture details
- **Setup issues?** Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Usage questions?** See [README.md](README.md)

---

**Thank you for contributing!** Your improvements help make Claude Trip Computer better for everyone.

**Last Updated:** 2026-01-12 (v0.13.2)
