#!/usr/bin/env node
/**
 * Claude Trip Computer - Session Analytics for Claude Code
 * Version: 0.13.4
 */

import { readStdin, getContextWindow, getModelName, getSessionId, getTranscriptPath } from './stdin.js';
import { TranscriptParser } from './transcript.js';
import { UsageAPI } from './usage-api.js';
import { StatusLineRenderer } from './render/status-line.js';
import { TripComputerRenderer } from './render/trip-computer.js';
import { readBillingConfig } from './utils/config.js';
import { SessionCacheManager } from './cache.js';
import { AnalyticsComputer } from './analytics.js';
import { getGitStatus } from './git.js';
import { parseActivity } from './activity.js';
import { homedir } from 'os';
import { join } from 'path';
import { existsSync, readdirSync, statSync } from 'fs';
import type { SessionMetrics, ContextWindow, SessionAnalytics, GitStatus, ActivityData } from './types.js';

async function findCurrentSession(): Promise<{ sessionId: string; transcriptPath: string } | null> {
  // Find current working directory's project
  const cwd = process.cwd();

  // Normalize path for Windows compatibility
  // Handles both Git Bash (/c/Dev/...) and Windows (C:\Dev\...) formats
  let normalizedPath = cwd;

  // Convert Git Bash format (/c/Dev/...) to Windows format (C:/Dev/...)
  if (normalizedPath.match(/^\/[a-z]\//)) {
    const drive = normalizedPath.charAt(1).toUpperCase();
    normalizedPath = drive + ':' + normalizedPath.slice(2);
  }

  // Replace backslashes with forward slashes for consistent handling
  normalizedPath = normalizedPath.replace(/\\/g, '/');

  // Convert to project directory name format: C:/Dev/project -> C--Dev-project
  // Replace colons and slashes with dashes, replace underscores with dashes
  const projectDir = normalizedPath.replace(/:/g, '-').replace(/\//g, '-').replace(/_/g, '-');
  const transcriptDir = join(homedir(), '.claude', 'projects', projectDir);

  if (!existsSync(transcriptDir)) {
    return null;
  }

  // Find most recent non-agent transcript
  // Sort by mtime descending, then by name descending for determinism when mtimes match
  const files = readdirSync(transcriptDir)
    .filter(f => f.endsWith('.jsonl') && !f.startsWith('agent-'))
    .map(f => ({
      name: f,
      path: join(transcriptDir, f),
      mtime: statSync(join(transcriptDir, f)).mtimeMs
    }))
    .sort((a, b) => {
      if (b.mtime !== a.mtime) return b.mtime - a.mtime;
      return b.name.localeCompare(a.name); // Deterministic tiebreaker
    });

  if (files.length === 0) {
    return null;
  }

  const latest = files[0];
  return {
    sessionId: latest.name.replace('.jsonl', ''),
    transcriptPath: latest.path
  };
}

async function main() {
  try {
    // Determine mode
    const mode = process.argv.includes('--trip-computer') ? 'trip' : 'status';

    // Read stdin JSON from Claude Code
    const stdinData = await readStdin();

    let sessionId: string | null = null;
    let transcriptPath: string | null = null;
    let modelName = 'Unknown';
    let context: ContextWindow | null = null;
    let cwd: string = process.cwd();

    if (stdinData) {
      // Get from stdin (statusLine mode)
      sessionId = getSessionId(stdinData);
      transcriptPath = getTranscriptPath(stdinData);
      modelName = getModelName(stdinData);
      context = getContextWindow(stdinData);
      if (stdinData.cwd) {
        cwd = stdinData.cwd;
      }
    } else {
      // No stdin - fallback to finding current session (command mode)
      const result = await findCurrentSession();
      if (!result) {
        console.log('💬 0 msgs | 🔧 0 tools | 🎯 0 tok | 📈 /trip');
        return;
      }
      transcriptPath = result.transcriptPath;
      sessionId = result.sessionId;
      // Model and context will be null in this mode
    }

    if (!transcriptPath) {
      console.log('💬 0 msgs | 🔧 0 tools | 🎯 0 tok | 📈 /trip');
      return;
    }

    // Try cache first (fast path)
    const cacheManager = new SessionCacheManager();
    const billingConfig = readBillingConfig();
    let metrics: SessionMetrics | null = null;
    let analytics: SessionAnalytics | null = null;
    let rateLimits: any = null;
    let useCache = false;

    if (sessionId) {
      const cachedData = cacheManager.read(sessionId);
      if (cachedData && cacheManager.isValid(cachedData, transcriptPath)) {
        // ===== FAST PATH: Use cached data =====
        metrics = cachedData.metrics;
        analytics = cachedData.analytics;
        useCache = true;

        // Get cached context, model, and rate limits
        if (!context && cachedData.context_window) {
          context = cachedData.context_window;
        }
        if (modelName === 'Unknown' && cachedData.model_name) {
          modelName = cachedData.model_name;
        }
        if (cachedData.rate_limits) {
          rateLimits = cachedData.rate_limits;
        }
      }
    }

    if (!useCache) {
      // ===== SLOW PATH: Parse transcript and compute analytics =====
      const parser = new TranscriptParser(transcriptPath);
      metrics = parser.parse();

      // If we don't have model name yet, detect from transcript
      // Sort by model_id for deterministic primary model selection
      if (modelName === 'Unknown' && metrics.models && Object.keys(metrics.models).length > 0) {
        const sortedModels = Object.values(metrics.models).sort((a, b) => a.model_id.localeCompare(b.model_id));
        modelName = sortedModels[0].display_name;
      }

      // Get rate limits (for subscription users)
      const usageAPI = new UsageAPI();
      rateLimits = await usageAPI.getRateLimits();

      // Compute all analytics intelligence
      const analyticsComputer = new AnalyticsComputer(billingConfig);
      analytics = analyticsComputer.compute(metrics, context);

      // Write complete cache (metrics + analytics + stdin data + rate limits)
      if (sessionId) {
        const transcriptMtime = Math.floor(statSync(transcriptPath).mtimeMs / 1000);
        const cache = {
          version: '0.13.0',
          session_id: sessionId,
          last_updated: Math.floor(Date.now() / 1000),
          transcript_mtime: transcriptMtime,
          transcript_path: transcriptPath,
          metrics,
          context_window: context ?? undefined,
          model_name: modelName !== 'Unknown' ? modelName : undefined,
          analytics,
          rate_limits: rateLimits ?? undefined,
        };
        cacheManager.write(cache);
      }
    }

    // Safety check - should never happen but satisfies TypeScript
    if (!metrics || !analytics) {
      console.log('💬 Error | 📈 /trip');
      return;
    }

    // Get git status and activity for status line
    let gitStatus: GitStatus | null = null;
    let activity: ActivityData | null = null;

    if (mode === 'status') {
      // Only fetch for status mode (not trip computer)
      gitStatus = getGitStatus(cwd);
      activity = parseActivity(transcriptPath);
    }

    // Render based on mode
    if (mode === 'trip') {
      // Detailed trip computer analytics (uses pre-computed analytics from cache!)
      const tripRenderer = new TripComputerRenderer(billingConfig);
      tripRenderer.render(metrics, modelName, context, rateLimits, analytics);
    } else {
      // Brief status line with git, activity
      const statusRenderer = new StatusLineRenderer(billingConfig);
      const output = statusRenderer.render(metrics, modelName, context, rateLimits, gitStatus, activity);
      console.log(output);
    }
  } catch (error) {
    console.error('[claude-trip-computer] Error:', error instanceof Error ? error.message : 'Unknown error');
    console.log('💬 Error | 📈 /trip');
  }
}

main();
