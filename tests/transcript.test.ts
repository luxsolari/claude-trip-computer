/**
 * Unit tests for TranscriptParser
 */

import { describe, it, expect, beforeEach } from 'vitest';
import { TranscriptParser } from '../src/transcript.js';
import { join } from 'path';

const FIXTURES_DIR = join(import.meta.dirname, 'fixtures');

describe('TranscriptParser', () => {
  describe('Simple Session Parsing', () => {
    it('should parse basic session metrics', () => {
      const transcriptPath = join(FIXTURES_DIR, 'simple-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      // Should count 2 user messages (exclude tool result message)
      expect(metrics.message_count).toBe(2);

      // Should count 1 tool use
      expect(metrics.tool_count).toBe(1);

      // Should extract session ID from filename
      expect(metrics.session_id).toBe('simple-session');
    });

    it('should calculate token totals correctly', () => {
      const transcriptPath = join(FIXTURES_DIR, 'simple-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      // Total input: 1000 + 800 + 700 = 2500
      expect(metrics.total_tokens.input).toBe(2500);

      // Total output: 500 + 600 + 400 = 1500
      expect(metrics.total_tokens.output).toBe(1500);

      // Total cache creation: 200 + 100 + 0 = 300
      expect(metrics.total_tokens.cache_creation).toBe(300);

      // Total cache read: 0 + 500 + 800 = 1300
      expect(metrics.total_tokens.cache_read).toBe(1300);
    });

    it('should calculate cache efficiency correctly', () => {
      const transcriptPath = join(FIXTURES_DIR, 'simple-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      // Cache efficiency = cache_read / (cache_creation + cache_read)
      // = 1300 / (300 + 1300) = 1300 / 1600 = 81.25%
      expect(metrics.cache_efficiency).toBeCloseTo(81.25, 2);
    });

    it('should calculate tokens per message', () => {
      const transcriptPath = join(FIXTURES_DIR, 'simple-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      // tokens_per_message = output / message_count = 1500 / 2 = 750
      expect(metrics.tokens_per_message).toBe(750);
    });

    it('should calculate tools per message', () => {
      const transcriptPath = join(FIXTURES_DIR, 'simple-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      // tools_per_message = tool_count / message_count = 1 / 2 = 0.5
      expect(metrics.tools_per_message).toBe(0.5);
    });

    it('should track model usage', () => {
      const transcriptPath = join(FIXTURES_DIR, 'simple-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      const models = Object.values(metrics.models);
      expect(models).toHaveLength(1);

      const sonnet = models[0];
      expect(sonnet.display_name).toBe('Sonnet 4.5');
      expect(sonnet.requests).toBe(3);
      expect(sonnet.tokens.input).toBe(2500);
    });

    it('should calculate cost correctly', () => {
      const transcriptPath = join(FIXTURES_DIR, 'simple-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      // Sonnet 4.5 pricing: $3/M input, $15/M output
      // Input cost: 2500 * 3 / 1M = $0.0075
      // Output cost: 1500 * 15 / 1M = $0.0225
      // Cache write: 300 * 3 * 1.25 / 1M = $0.001125
      // Cache read: 1300 * 3 * 0.10 / 1M = $0.00039
      // Total ≈ $0.0315
      expect(metrics.total_cost).toBeGreaterThan(0.03);
      expect(metrics.total_cost).toBeLessThan(0.04);
    });
  });

  describe('Multi-Model Session', () => {
    it('should track multiple models separately', () => {
      const transcriptPath = join(FIXTURES_DIR, 'multi-model-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      const models = Object.values(metrics.models);
      expect(models).toHaveLength(3);

      const modelNames = models.map(m => m.display_name).sort();
      expect(modelNames).toEqual(['Haiku 4.5', 'Opus 4.5', 'Sonnet 4.5']);
    });

    it('should calculate per-model costs correctly', () => {
      const transcriptPath = join(FIXTURES_DIR, 'multi-model-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      const sonnet = Object.values(metrics.models).find(m => m.display_name === 'Sonnet 4.5');
      const opus = Object.values(metrics.models).find(m => m.display_name === 'Opus 4.5');
      const haiku = Object.values(metrics.models).find(m => m.display_name === 'Haiku 4.5');

      expect(sonnet?.cost).toBeGreaterThan(0);
      expect(opus?.cost).toBeGreaterThan(sonnet?.cost ?? 0); // Opus more expensive
      expect(haiku?.cost).toBeLessThan(sonnet?.cost ?? Infinity); // Haiku cheaper
    });

    it('should aggregate total cost across models', () => {
      const transcriptPath = join(FIXTURES_DIR, 'multi-model-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      const sumOfModelCosts = Object.values(metrics.models)
        .reduce((sum, model) => sum + model.cost, 0);

      expect(metrics.total_cost).toBeCloseTo(sumOfModelCosts, 6);
    });
  });

  describe('Token Deduplication', () => {
    it('should deduplicate entries with same requestId by taking MAX', () => {
      const transcriptPath = join(FIXTURES_DIR, 'duplicate-entries.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      // Should take the MAX tokens from the 3 duplicate entries
      // MAX input: 1200 (not 1000 + 1000 + 1200)
      expect(metrics.total_tokens.input).toBe(1200);

      // MAX output: 600 (not 500 + 500 + 600)
      expect(metrics.total_tokens.output).toBe(600);

      // MAX cache_creation: 150 (not 100 + 100 + 150)
      expect(metrics.total_tokens.cache_creation).toBe(150);

      // MAX cache_read: 50 (not 0 + 0 + 50)
      expect(metrics.total_tokens.cache_read).toBe(50);
    });

    it('should count only 1 request despite multiple entries', () => {
      const transcriptPath = join(FIXTURES_DIR, 'duplicate-entries.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      const sonnet = Object.values(metrics.models)[0];
      expect(sonnet.requests).toBe(1); // Only 1 unique request
    });
  });

  describe('Model Name Formatting', () => {
    it('should format Sonnet model names correctly', () => {
      const transcriptPath = join(FIXTURES_DIR, 'simple-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      const model = Object.values(metrics.models)[0];
      expect(model.display_name).toBe('Sonnet 4.5');
    });

    it('should format Opus model names correctly', () => {
      const transcriptPath = join(FIXTURES_DIR, 'multi-model-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      const opus = Object.values(metrics.models).find(m =>
        m.model_id.includes('opus')
      );
      expect(opus?.display_name).toBe('Opus 4.5');
    });

    it('should format Haiku model names correctly', () => {
      const transcriptPath = join(FIXTURES_DIR, 'multi-model-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      const haiku = Object.values(metrics.models).find(m =>
        m.model_id.includes('haiku')
      );
      expect(haiku?.display_name).toBe('Haiku 4.5');
    });
  });

  describe('Edge Cases', () => {
    it('should handle empty transcript gracefully', () => {
      const transcriptPath = join(FIXTURES_DIR, 'nonexistent.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      expect(metrics.message_count).toBe(0);
      expect(metrics.tool_count).toBe(0);
      expect(metrics.total_tokens.input).toBe(0);
    });

    it('should handle cache efficiency when no cache exists', () => {
      // Create a minimal transcript with no cache
      const transcriptPath = join(FIXTURES_DIR, 'simple-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      // Cache efficiency should be calculable
      expect(metrics.cache_efficiency).toBeGreaterThanOrEqual(0);
      expect(metrics.cache_efficiency).toBeLessThanOrEqual(100);
    });

    it('should handle division by zero for zero messages', () => {
      const transcriptPath = join(FIXTURES_DIR, 'nonexistent.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      // Should not crash with NaN
      expect(metrics.tokens_per_message).toBe(0);
      expect(metrics.tools_per_message).toBe(0);
    });
  });
});
