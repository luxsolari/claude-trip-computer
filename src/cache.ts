/**
 * Session cache manager with atomic writes
 * Version: 0.13.6
 */

import { readFileSync, writeFileSync, existsSync, statSync, unlinkSync, readdirSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import type { SessionCache, SessionMetrics, ContextWindow } from './types.js';
import { CACHE_TTL_SECONDS } from './constants.js';

export class SessionCacheManager {
  private cacheDir: string;

  constructor() {
    this.cacheDir = join(homedir(), '.claude', 'session-stats');
  }

  read(sessionId: string): SessionCache | null {
    const cacheFile = join(this.cacheDir, `${sessionId}.json`);

    if (!existsSync(cacheFile)) {
      return null;
    }

    try {
      const content = readFileSync(cacheFile, 'utf-8');
      return JSON.parse(content) as SessionCache;
    } catch {
      return null;
    }
  }

  write(cache: SessionCache): void {
    const cacheFile = join(this.cacheDir, `${cache.session_id}.json`);
    const tempFile = `${cacheFile}.tmp.${process.pid}`;

    try {
      // Write to temp file
      writeFileSync(tempFile, JSON.stringify(cache, null, 2));

      // Atomic move (overwrites existing)
      if (existsSync(cacheFile)) {
        unlinkSync(cacheFile);
      }
      writeFileSync(cacheFile, readFileSync(tempFile));
      unlinkSync(tempFile);
    } catch {
      // Clean up temp file on error
      if (existsSync(tempFile)) {
        try {
          unlinkSync(tempFile);
        } catch {
          // Ignore cleanup errors
        }
      }
    }
  }

  isValid(cache: SessionCache, transcriptPath: string): boolean {
    // Check if transcript file exists
    if (!existsSync(transcriptPath)) {
      return false;
    }

    // Check transcript modification time
    try {
      const transcriptMtime = Math.floor(statSync(transcriptPath).mtimeMs / 1000);
      if (transcriptMtime !== cache.transcript_mtime) {
        return false;
      }
    } catch {
      return false;
    }

    // Check cache age (TTL: 5 seconds)
    const cacheAge = Math.floor(Date.now() / 1000) - cache.last_updated;
    if (cacheAge > CACHE_TTL_SECONDS) {
      return false;
    }

    return true;
  }

  cleanup(maxAgeHours: number = 24, maxCount: number = 50): void {
    if (!existsSync(this.cacheDir)) {
      return;
    }

    try {
      const now = Date.now();
      const maxAgeMs = maxAgeHours * 3600 * 1000;

      const cacheFiles = readdirSync(this.cacheDir)
        .filter(f => f.endsWith('.json') && !f.startsWith('.'))
        .map(f => ({
          path: join(this.cacheDir, f),
          mtime: statSync(join(this.cacheDir, f)).mtimeMs
        }))
        .sort((a, b) => b.mtime - a.mtime);

      for (let i = 0; i < cacheFiles.length; i++) {
        const file = cacheFiles[i];
        const age = now - file.mtime;

        // Delete if too old or beyond max count
        if (age > maxAgeMs || i >= maxCount) {
          try {
            unlinkSync(file.path);
          } catch {
            // Ignore deletion errors
          }
        }
      }
    } catch {
      // Ignore cleanup errors
    }
  }
}
