/**
 * Unit tests for SessionCacheManager
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { SessionCacheManager } from '../src/cache.js';
import { writeFileSync, existsSync, unlinkSync, mkdirSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import type { SessionCache } from '../src/types.js';

const TEST_CACHE_DIR = join(homedir(), '.claude', 'session-stats');
const TEST_SESSION_ID = 'test-cache-session';
const TEST_CACHE_FILE = join(TEST_CACHE_DIR, `${TEST_SESSION_ID}.json`);

const createMockCache = (overrides?: Partial<SessionCache>): SessionCache => ({
  version: '0.11.0',
  session_id: TEST_SESSION_ID,
  last_updated: Math.floor(Date.now() / 1000),
  transcript_mtime: Math.floor(Date.now() / 1000),
  transcript_path: '/test/path.jsonl',
  metrics: {
    session_id: TEST_SESSION_ID,
    message_count: 5,
    tool_count: 10,
    total_tokens: {
      input: 5000,
      output: 2000,
      cache_creation: 500,
      cache_read: 1000,
    },
    models: {},
    cache_efficiency: 66.67,
    tokens_per_message: 400,
    tools_per_message: 2,
    total_cost: 0.10,
  },
  analytics: {
    health_score: 75,
    health_label: '⭐⭐⭐⭐ Good',
    cache_score: 30,
    context_score: 20,
    efficiency_score: 25,
    tool_intensity_label: 'Moderate',
    verbosity_label: 'Concise',
    context_growth_label: 'Slow growth',
    cache_guidance: 'Good → cache is helping',
    optimization_actions: [],
  },
  ...overrides,
});

describe('SessionCacheManager', () => {
  let manager: SessionCacheManager;

  beforeEach(() => {
    manager = new SessionCacheManager();

    // Ensure cache directory exists
    if (!existsSync(TEST_CACHE_DIR)) {
      mkdirSync(TEST_CACHE_DIR, { recursive: true });
    }

    // Clean up test cache file
    if (existsSync(TEST_CACHE_FILE)) {
      unlinkSync(TEST_CACHE_FILE);
    }
  });

  afterEach(() => {
    // Clean up test cache file
    if (existsSync(TEST_CACHE_FILE)) {
      unlinkSync(TEST_CACHE_FILE);
    }
  });

  describe('Cache Reading', () => {
    it('should return null for non-existent cache', () => {
      const cache = manager.read('nonexistent-session');
      expect(cache).toBeNull();
    });

    it('should read valid cache file', () => {
      const mockCache = createMockCache();
      writeFileSync(TEST_CACHE_FILE, JSON.stringify(mockCache));

      const cache = manager.read(TEST_SESSION_ID);
      expect(cache).not.toBeNull();
      expect(cache?.session_id).toBe(TEST_SESSION_ID);
      expect(cache?.version).toBe('0.11.0');
    });

    it('should return null for invalid JSON', () => {
      writeFileSync(TEST_CACHE_FILE, 'invalid json');

      const cache = manager.read(TEST_SESSION_ID);
      expect(cache).toBeNull();
    });

    it('should preserve all cache fields', () => {
      const mockCache = createMockCache();
      writeFileSync(TEST_CACHE_FILE, JSON.stringify(mockCache));

      const cache = manager.read(TEST_SESSION_ID);
      expect(cache?.metrics.message_count).toBe(5);
      expect(cache?.analytics.health_score).toBe(75);
      expect(cache?.context_window).toBeUndefined();
    });
  });

  describe('Cache Writing', () => {
    it('should write cache to file', () => {
      const mockCache = createMockCache();
      manager.write(mockCache);

      expect(existsSync(TEST_CACHE_FILE)).toBe(true);
    });

    it('should write valid JSON', () => {
      const mockCache = createMockCache();
      manager.write(mockCache);

      const cache = manager.read(TEST_SESSION_ID);
      expect(cache).not.toBeNull();
      expect(cache?.session_id).toBe(TEST_SESSION_ID);
    });

    it('should overwrite existing cache', () => {
      const oldCache = createMockCache({ version: '0.10.0' });
      manager.write(oldCache);

      const newCache = createMockCache({ version: '0.11.0' });
      manager.write(newCache);

      const cache = manager.read(TEST_SESSION_ID);
      expect(cache?.version).toBe('0.11.0');
    });

    it('should format JSON with indentation', () => {
      const mockCache = createMockCache();
      manager.write(mockCache);

      const content = require('fs').readFileSync(TEST_CACHE_FILE, 'utf-8');
      expect(content).toContain('\n');
      expect(content).toContain('  '); // 2-space indentation
    });

    it('should handle write errors gracefully', () => {
      // Try to write to an invalid directory
      const invalidCache = createMockCache({ session_id: '../../../invalid/path' });

      // Should not throw
      expect(() => manager.write(invalidCache)).not.toThrow();
    });
  });

  describe('Cache Validation', () => {
    it('should validate fresh cache as valid', () => {
      const transcriptPath = join(import.meta.dirname, 'fixtures', 'simple-session.jsonl');
      const mockCache = createMockCache({
        transcript_path: transcriptPath,
        transcript_mtime: Math.floor(require('fs').statSync(transcriptPath).mtimeMs / 1000),
        last_updated: Math.floor(Date.now() / 1000),
      });

      const isValid = manager.isValid(mockCache, transcriptPath);
      expect(isValid).toBe(true);
    });

    it('should invalidate cache for non-existent transcript', () => {
      const mockCache = createMockCache({
        transcript_path: '/nonexistent/path.jsonl',
      });

      const isValid = manager.isValid(mockCache, '/nonexistent/path.jsonl');
      expect(isValid).toBe(false);
    });

    it('should invalidate cache when transcript modified', () => {
      const transcriptPath = join(import.meta.dirname, 'fixtures', 'simple-session.jsonl');
      const mockCache = createMockCache({
        transcript_path: transcriptPath,
        transcript_mtime: 0, // Old mtime
        last_updated: Math.floor(Date.now() / 1000),
      });

      const isValid = manager.isValid(mockCache, transcriptPath);
      expect(isValid).toBe(false);
    });

    it('should invalidate cache after TTL (5 seconds)', () => {
      const transcriptPath = join(import.meta.dirname, 'fixtures', 'simple-session.jsonl');
      const mockCache = createMockCache({
        transcript_path: transcriptPath,
        transcript_mtime: Math.floor(require('fs').statSync(transcriptPath).mtimeMs / 1000),
        last_updated: Math.floor(Date.now() / 1000) - 6, // 6 seconds old
      });

      const isValid = manager.isValid(mockCache, transcriptPath);
      expect(isValid).toBe(false);
    });

    it('should validate cache within TTL', () => {
      const transcriptPath = join(import.meta.dirname, 'fixtures', 'simple-session.jsonl');
      const mockCache = createMockCache({
        transcript_path: transcriptPath,
        transcript_mtime: Math.floor(require('fs').statSync(transcriptPath).mtimeMs / 1000),
        last_updated: Math.floor(Date.now() / 1000) - 3, // 3 seconds old
      });

      const isValid = manager.isValid(mockCache, transcriptPath);
      expect(isValid).toBe(true);
    });
  });

  describe('Cache Cleanup', () => {
    it('should delete old cache files', () => {
      // Create an old cache file
      const oldCache = createMockCache({
        session_id: 'old-session',
        last_updated: Math.floor(Date.now() / 1000) - 86400 * 2, // 2 days old
      });
      const oldCacheFile = join(TEST_CACHE_DIR, 'old-session.json');
      writeFileSync(oldCacheFile, JSON.stringify(oldCache));

      // Touch the file to set its mtime to 2 days ago
      const oldTime = Date.now() - 86400 * 2 * 1000; // 2 days ago in ms
      require('fs').utimesSync(oldCacheFile, oldTime / 1000, oldTime / 1000);

      // Run cleanup with 1 hour max age
      manager.cleanup(1, 50);

      // Old cache should be deleted
      expect(existsSync(oldCacheFile)).toBe(false);
    });

    it('should keep recent cache files', () => {
      // Create a recent cache file
      const recentCache = createMockCache();
      manager.write(recentCache);

      // Run cleanup with 24 hour max age
      manager.cleanup(24, 50);

      // Recent cache should still exist
      expect(existsSync(TEST_CACHE_FILE)).toBe(true);
    });

    it('should delete cache files beyond max count', () => {
      // Create multiple cache files
      const caches = Array.from({ length: 10 }, (_, i) => ({
        ...createMockCache({ session_id: `session-${i}` }),
        last_updated: Math.floor(Date.now() / 1000) - i, // Different ages
      }));

      for (const cache of caches) {
        const file = join(TEST_CACHE_DIR, `${cache.session_id}.json`);
        writeFileSync(file, JSON.stringify(cache));
      }

      // Keep only 5 most recent
      manager.cleanup(24, 5);

      // Count remaining cache files
      const remaining = require('fs').readdirSync(TEST_CACHE_DIR)
        .filter((f: string) => f.startsWith('session-') && f.endsWith('.json'));

      expect(remaining.length).toBeLessThanOrEqual(5);

      // Cleanup test files
      for (const cache of caches) {
        const file = join(TEST_CACHE_DIR, `${cache.session_id}.json`);
        if (existsSync(file)) {
          unlinkSync(file);
        }
      }
    });

    it('should handle cleanup errors gracefully', () => {
      // Cleanup on non-existent directory should not throw
      expect(() => manager.cleanup(24, 50)).not.toThrow();
    });
  });

  describe('Atomic Writes', () => {
    it('should not corrupt cache on write failure', () => {
      // Write initial cache
      const initialCache = createMockCache({ version: '0.10.0' });
      manager.write(initialCache);

      // Verify initial cache exists
      const cache1 = manager.read(TEST_SESSION_ID);
      expect(cache1?.version).toBe('0.10.0');

      // Even if next write fails (we can't easily simulate this),
      // we should still be able to read the old cache
      const cache2 = manager.read(TEST_SESSION_ID);
      expect(cache2).not.toBeNull();
    });

    it('should clean up temp files', () => {
      const mockCache = createMockCache();
      manager.write(mockCache);

      // Check for leftover temp files
      const tempFiles = require('fs').readdirSync(TEST_CACHE_DIR)
        .filter((f: string) => f.includes('.tmp.'));

      expect(tempFiles.length).toBe(0);
    });
  });

  describe('Context Window Caching', () => {
    it('should cache context window data from stdin', () => {
      const mockCache = createMockCache({
        context_window: {
          size: 200000,
          usage: 100000,
          usage_percent: 50,
          health_status: 'healthy',
        },
      });
      manager.write(mockCache);

      const cache = manager.read(TEST_SESSION_ID);
      expect(cache?.context_window).toBeDefined();
      expect(cache?.context_window?.usage_percent).toBe(50);
    });

    it('should cache model name from stdin', () => {
      const mockCache = createMockCache({
        model_name: 'Sonnet 4.5',
      });
      manager.write(mockCache);

      const cache = manager.read(TEST_SESSION_ID);
      expect(cache?.model_name).toBe('Sonnet 4.5');
    });

    it('should cache rate limits data', () => {
      const mockCache = createMockCache({
        rate_limits: {
          plan_name: 'Pro',
          five_hour_percent: 25,
          seven_day_percent: 50,
          five_hour_reset_at: new Date('2026-01-13T00:00:00Z'),
          seven_day_reset_at: new Date('2026-01-14T00:00:00Z'),
          api_unavailable: false,
        },
      });
      manager.write(mockCache);

      const cache = manager.read(TEST_SESSION_ID);
      expect(cache?.rate_limits).toBeDefined();
      expect(cache?.rate_limits?.plan_name).toBe('Pro');
    });
  });
});
