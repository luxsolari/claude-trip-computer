# Testing Guide

## Overview

Claude Trip Computer has a comprehensive test suite built with Vitest covering unit tests, integration tests, and edge cases.

**Test Coverage:**
- ✅ 73 tests across 4 test files
- ✅ 100% pass rate
- ✅ Zero npm dependencies (pure Node.js stdlib)

## Test Structure

```
tests/
├── fixtures/              # Sample transcript data
│   ├── simple-session.jsonl          # Basic session with cache
│   ├── multi-model-session.jsonl     # Session using 3 models
│   └── duplicate-entries.jsonl       # Tests deduplication logic
├── transcript.test.ts     # TranscriptParser unit tests (18 tests)
├── analytics.test.ts      # AnalyticsComputer unit tests (22 tests)
├── cache.test.ts          # SessionCacheManager unit tests (23 tests)
└── integration.test.ts    # End-to-end integration tests (10 tests)
```

## Running Tests

### Run All Tests
```bash
npm test
```

### Watch Mode
```bash
npm test -- --watch
```

### Run Specific Test File
```bash
npm test tests/transcript.test.ts
```

### Coverage Report
```bash
npm test -- --coverage
```

## Test Categories

### 1. Transcript Parsing Tests (`transcript.test.ts`)

Tests the core parsing logic with token deduplication:

- ✅ Simple session parsing
- ✅ Token totals calculation
- ✅ Cache efficiency calculation
- ✅ Tokens/tools per message
- ✅ Multi-model tracking
- ✅ Per-model cost calculation
- ✅ Token deduplication (MAX aggregation)
- ✅ Model name formatting (Opus/Sonnet/Haiku)
- ✅ Edge cases (empty transcripts, division by zero)

**Key Tests:**
- **Deduplication**: Verifies that duplicate entries with same `requestId + model` use MAX values, not SUM
- **Cost Accuracy**: Ensures pricing calculations match Anthropic's rates
- **Model Detection**: Tests all 9 model formats (Opus 3/4/4.5, Sonnet 3.7/4/4.5, Haiku 3/3.5/4.5)

### 2. Analytics Tests (`analytics.test.ts`)

Tests the health scoring and optimization recommendation engine:

- ✅ Health score calculation (0-100 scale)
- ✅ Cache score (0-40 points)
- ✅ Context score (0-30 points)
- ✅ Efficiency score (0-30 points)
- ✅ Health labels (⭐ to ⭐⭐⭐⭐⭐)
- ✅ Optimization action generation
- ✅ Action priority sorting
- ✅ Billing mode differentiation (API vs Subscription)
- ✅ Safety margin application
- ✅ Tool intensity/verbosity/context guidance

**Key Tests:**
- **Health Boundaries**: Tests all 5 health tiers (Excellent, Good, Fair, Poor, Critical)
- **Billing Modes**: Verifies API users see efficiency metrics, Subscription users see cost savings
- **Recommendations**: Ensures actions are prioritized correctly (25 = high, 20 = moderate, 15 = low)

### 3. Cache Tests (`cache.test.ts`)

Tests the 5-second TTL caching system:

- ✅ Cache reading (valid/invalid/missing)
- ✅ Cache writing (atomic operations)
- ✅ Cache validation (TTL, mtime, transcript changes)
- ✅ Cache cleanup (age-based, count-based)
- ✅ Atomic writes (temp file → rename)
- ✅ Context window caching
- ✅ Model name caching
- ✅ Rate limits caching
- ✅ Error handling (corrupt JSON, missing files)

**Key Tests:**
- **TTL Validation**: Ensures cache expires after 5 seconds
- **Mtime Tracking**: Invalidates cache when transcript changes
- **Atomic Writes**: Verifies no corruption on concurrent writes
- **Cleanup**: Tests both time-based (24h) and count-based (50 max) cleanup

### 4. Integration Tests (`integration.test.ts`)

Tests the complete pipeline from transcript → analytics → cache:

- ✅ End-to-end session processing
- ✅ Multi-model session flow
- ✅ Cache round-trip (write → read → validate)
- ✅ Cost calculation accuracy
- ✅ Health scoring consistency
- ✅ Optimization action generation
- ✅ Error resilience (missing files)
- ✅ Deduplication effectiveness

**Key Tests:**
- **Pipeline Integrity**: Verifies transcript parsing → analytics computation → cache storage
- **Cost Realism**: Ensures calculated costs are in expected ranges (e.g., $0.03-0.04 for simple session)
- **Deduplication Impact**: Confirms 3x inflation prevention works end-to-end

## Test Fixtures

### `simple-session.jsonl`
- 2 user messages
- 1 tool use
- 3 API requests (Sonnet 4.5)
- Cache efficiency: 81.25%
- Total cost: ~$0.03

### `multi-model-session.jsonl`
- 3 models: Sonnet 4.5, Opus 4.5, Haiku 4.5
- 2 tool uses
- Tests per-model cost tracking

### `duplicate-entries.jsonl`
- 3 duplicate entries with same `requestId`
- Different token counts
- Tests MAX aggregation (not SUM)

## Writing New Tests

### Test Template

```typescript
import { describe, it, expect } from 'vitest';
import { YourClass } from '../src/your-module.js';

describe('YourClass', () => {
  describe('Feature Category', () => {
    it('should do something specific', () => {
      // Arrange
      const instance = new YourClass();

      // Act
      const result = instance.method();

      // Assert
      expect(result).toBe(expectedValue);
    });
  });
});
```

### Best Practices

1. **Use descriptive test names**: `should calculate cache efficiency correctly` (✅) vs. `test cache` (❌)
2. **Test one thing per test**: Each `it()` should verify a single behavior
3. **Use AAA pattern**: Arrange → Act → Assert
4. **Test edge cases**: Empty inputs, null values, division by zero
5. **Mock external dependencies**: File I/O, API calls, timestamps
6. **Keep tests fast**: Use fixtures instead of generating large datasets

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm test
      - run: npm run lint
```

## Test-Driven Development (TDD)

When adding new features:

1. **Write test first**: Define expected behavior in a test
2. **Run test**: Verify it fails (red)
3. **Implement feature**: Write minimal code to pass test
4. **Run test**: Verify it passes (green)
5. **Refactor**: Clean up code while keeping tests green

### Example: Adding New Health Metric

```typescript
// 1. Write test first
it('should calculate context growth rate', () => {
  const computer = new AnalyticsComputer(API_CONFIG);
  const metrics = createMockMetrics({
    tokens_per_message: 50000
  });
  const analytics = computer.compute(metrics, null);

  expect(analytics.context_growth_rate).toBeGreaterThan(1.0);
});

// 2. Run test → fails (red)
// 3. Implement in analytics.ts
// 4. Run test → passes (green)
// 5. Refactor if needed
```

## Debugging Tests

### Run Single Test
```bash
npm test -- -t "should calculate cache efficiency"
```

### Debug Mode (Node Inspector)
```bash
node --inspect-brk node_modules/.bin/vitest
```

### Verbose Output
```bash
npm test -- --reporter=verbose
```

## Known Limitations

1. **Agent transcript discovery**: Requires actual files in `~/.claude/projects/` (not easily mockable)
2. **Stdin reading**: Tests use fixture files, not actual Claude Code stdin
3. **OAuth API**: Not tested (would require auth tokens)

## Test Maintenance

- **Update fixtures** when transcript format changes
- **Update pricing tests** when Anthropic changes rates
- **Keep test count visible** in CI status badges
- **Review coverage reports** to identify untested code paths

---

**Last Updated:** 2026-01-12
**Test Framework:** Vitest 1.2.0
**Node.js Requirement:** 18+
**Pass Rate:** 100% (73/73 tests)
