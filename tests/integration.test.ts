/**
 * Integration tests for the full transcript → analytics pipeline
 */

import { describe, it, expect } from 'vitest';
import { TranscriptParser } from '../src/transcript.js';
import { AnalyticsComputer } from '../src/analytics.js';
import { SessionCacheManager } from '../src/cache.js';
import { join } from 'path';
import type { BillingConfig, ContextWindow } from '../src/types.js';

const FIXTURES_DIR = join(import.meta.dirname, 'fixtures');

const API_CONFIG: BillingConfig = {
  billing_mode: 'API',
  billing_icon: '💳',
  safety_margin: 1.0,
};

describe('Integration Tests', () => {
  describe('Full Pipeline: Transcript → Metrics → Analytics', () => {
    it('should process simple session end-to-end', () => {
      // 1. Parse transcript
      const transcriptPath = join(FIXTURES_DIR, 'simple-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      // 2. Compute analytics
      const computer = new AnalyticsComputer(API_CONFIG);
      const context: ContextWindow = {
        size: 200000,
        usage: 100000,
        usage_percent: 50,
        health_status: 'healthy',
      };
      const analytics = computer.compute(metrics, context);

      // 3. Verify end-to-end results
      expect(metrics.session_id).toBe('simple-session');
      expect(metrics.message_count).toBe(2);
      expect(analytics.health_score).toBeGreaterThan(0);
      expect(analytics.health_score).toBeLessThanOrEqual(100);
      expect(analytics.health_label).toContain('⭐');
    });

    it('should process multi-model session end-to-end', () => {
      // 1. Parse transcript
      const transcriptPath = join(FIXTURES_DIR, 'multi-model-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      // 2. Verify multi-model parsing
      expect(Object.keys(metrics.models)).toHaveLength(3);

      // 3. Compute analytics
      const computer = new AnalyticsComputer(API_CONFIG);
      const analytics = computer.compute(metrics, null);

      // 4. Verify analytics computed correctly
      expect(analytics.health_score).toBeGreaterThan(0);
      expect(analytics.optimization_actions).toBeDefined();
    });
  });

  describe('Caching Integration', () => {
    it('should cache and retrieve session data', () => {
      // 1. Parse transcript
      const transcriptPath = join(FIXTURES_DIR, 'simple-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      // 2. Compute analytics
      const computer = new AnalyticsComputer(API_CONFIG);
      const analytics = computer.compute(metrics, null);

      // 3. Create cache with actual transcript mtime
      const cacheManager = new SessionCacheManager();
      const transcriptMtime = Math.floor(require('fs').statSync(transcriptPath).mtimeMs / 1000);
      const cache = {
        version: '0.11.0',
        session_id: 'integration-test-session',
        last_updated: Math.floor(Date.now() / 1000),
        transcript_mtime: transcriptMtime,
        transcript_path: transcriptPath,
        metrics,
        analytics,
      };

      // 4. Write and read cache
      cacheManager.write(cache);
      const retrieved = cacheManager.read('integration-test-session');

      // 5. Verify cached data
      expect(retrieved).not.toBeNull();
      expect(retrieved?.session_id).toBe('integration-test-session');
      expect(retrieved?.metrics.message_count).toBe(metrics.message_count);
      expect(retrieved?.analytics.health_score).toBe(analytics.health_score);

      // 6. Verify cache is valid
      const isValid = cacheManager.isValid(retrieved!, transcriptPath);
      expect(isValid).toBe(true);
    });
  });

  describe('Cost Calculation Accuracy', () => {
    it('should calculate realistic costs for Sonnet 4.5', () => {
      const transcriptPath = join(FIXTURES_DIR, 'simple-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      // Simple session has ~2500 input, 1500 output, 300 cache write, 1300 cache read
      // Sonnet 4.5: $3/M input, $15/M output
      // Expected cost ≈ $0.03-0.04
      expect(metrics.total_cost).toBeGreaterThan(0.02);
      expect(metrics.total_cost).toBeLessThan(0.05);
    });

    it('should calculate different costs for different models', () => {
      const transcriptPath = join(FIXTURES_DIR, 'multi-model-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      const sonnet = Object.values(metrics.models).find(m => m.display_name === 'Sonnet 4.5');
      const opus = Object.values(metrics.models).find(m => m.display_name === 'Opus 4.5');
      const haiku = Object.values(metrics.models).find(m => m.display_name === 'Haiku 4.5');

      // Opus should be most expensive
      expect(opus?.cost).toBeGreaterThan(sonnet?.cost ?? 0);

      // Haiku should be cheapest
      expect(haiku?.cost).toBeLessThan(sonnet?.cost ?? Infinity);
    });
  });

  describe('Health Scoring Integration', () => {
    it('should produce consistent health scores', () => {
      const transcriptPath = join(FIXTURES_DIR, 'simple-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      const computer = new AnalyticsComputer(API_CONFIG);
      const analytics = computer.compute(metrics, null);

      // Health score should be sum of cache + context + efficiency
      const totalScore = analytics.cache_score + analytics.context_score + analytics.efficiency_score;
      expect(analytics.health_score).toBe(totalScore);
    });

    it('should generate appropriate optimization actions based on metrics', () => {
      const transcriptPath = join(FIXTURES_DIR, 'simple-session.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      const computer = new AnalyticsComputer(API_CONFIG);
      const analytics = computer.compute(metrics, null);

      // Simple session has good cache efficiency (81%), so no cache rebuild recommendation
      const cacheAction = analytics.optimization_actions.find(a =>
        a.action.includes('cache')
      );

      // May or may not have cache action depending on threshold (70%)
      // At 81% efficiency, it's above 70% threshold so no cache action
      expect(cacheAction).toBeUndefined();
    });
  });

  describe('Error Handling Integration', () => {
    it('should handle missing transcript gracefully', () => {
      const parser = new TranscriptParser('/nonexistent/path.jsonl');
      const metrics = parser.parse();

      expect(metrics.message_count).toBe(0);
      expect(metrics.total_cost).toBe(0);

      const computer = new AnalyticsComputer(API_CONFIG);
      const analytics = computer.compute(metrics, null);

      // Should still produce valid analytics even with empty metrics
      expect(analytics.health_score).toBeGreaterThanOrEqual(0);
      expect(analytics.health_label).toBeDefined();
    });

    it('should handle invalid cache gracefully', () => {
      const cacheManager = new SessionCacheManager();
      const cache = cacheManager.read('nonexistent-session');

      expect(cache).toBeNull();
    });
  });

  describe('Deduplication Integration', () => {
    it('should prevent token inflation in duplicate-heavy transcripts', () => {
      const transcriptPath = join(FIXTURES_DIR, 'duplicate-entries.jsonl');
      const parser = new TranscriptParser(transcriptPath);
      const metrics = parser.parse();

      // Should take MAX values, not sum
      // MAX input: 1200, not 1000 + 1000 + 1200 = 3200
      expect(metrics.total_tokens.input).toBe(1200);

      // Without deduplication, this would be inflated by 3x
      const inflatedInput = 1000 + 1000 + 1200;
      expect(metrics.total_tokens.input).toBeLessThan(inflatedInput);
    });
  });
});
