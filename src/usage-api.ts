/**
 * Anthropic OAuth Usage API for rate limit tracking
 * Version: 0.13.2
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';
import https from 'https';
import type { RateLimits } from './types.js';
import { USAGE_API_URL, USAGE_API_BETA_HEADER, RATE_LIMIT_CACHE_TTL_SUCCESS, RATE_LIMIT_CACHE_TTL_FAILURE } from './constants.js';

export class UsageAPI {
  private cacheFile: string;
  private credentialsFile: string;

  constructor() {
    const claudeDir = join(homedir(), '.claude');
    this.cacheFile = join(claudeDir, 'session-stats', '.usage-cache.json');
    this.credentialsFile = join(claudeDir, '.credentials.json');
  }

  async getRateLimits(): Promise<RateLimits | null> {
    // Check cache first
    const cached = this.readCache();
    if (cached) {
      return cached;
    }

    // Read credentials (token + subscriptionType)
    const credentials = this.readCredentials();
    if (!credentials) {
      return null;
    }

    const { accessToken, subscriptionType } = credentials;

    // Determine plan name from subscriptionType
    const planName = this.getPlanName(subscriptionType);
    if (!planName) {
      // API user, no usage limits to show
      return null;
    }

    // Fetch from API (only for subscription users)
    try {
      const data = await this.fetchAPI(accessToken);
      const limits = this.parseResponse(data, planName);
      this.writeCache(limits);
      return limits;
    } catch (error) {
      // Cache failure result (but keep plan name)
      const failure: RateLimits = {
        plan_name: planName,
        five_hour_percent: null,
        seven_day_percent: null,
        five_hour_reset_at: null,
        seven_day_reset_at: null,
        api_unavailable: true,
      };
      this.writeCacheFailure(failure);
      return failure;
    }
  }

  private readCredentials(): { accessToken: string; subscriptionType: string } | null {
    if (!existsSync(this.credentialsFile)) {
      return null;
    }

    try {
      const content = readFileSync(this.credentialsFile, 'utf-8');
      const data = JSON.parse(content);

      const oauth = data.claudeAiOauth ?? {};
      const accessToken = oauth.accessToken;
      const subscriptionType = oauth.subscriptionType ?? '';
      const expiresAt = oauth.expiresAt ?? 0;

      if (!accessToken) {
        return null;
      }

      // Check expiration (expiresAt is Unix ms timestamp)
      if (expiresAt && expiresAt <= Date.now()) {
        return null;
      }

      return { accessToken, subscriptionType };
    } catch {
      return null;
    }
  }

  private getPlanName(subscriptionType: string): string | null {
    const lower = subscriptionType.toLowerCase();
    if (lower.includes('max')) return 'Max';
    if (lower.includes('pro')) return 'Pro';
    if (lower.includes('team')) return 'Team';
    // API users don't have subscriptionType or have 'api'
    if (!subscriptionType || lower.includes('api')) return null;
    // Unknown subscription type - show it capitalized
    return subscriptionType.charAt(0).toUpperCase() + subscriptionType.slice(1);
  }

  private async fetchAPI(token: string): Promise<any> {
    return new Promise((resolve, reject) => {
      const url = new URL(USAGE_API_URL);

      const options = {
        hostname: url.hostname,
        path: url.pathname,
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
          'anthropic-beta': USAGE_API_BETA_HEADER,
          'User-Agent': 'claude-trip-computer/0.13.0',
        },
        timeout: 5000,
      };

      const req = https.request(options, (res) => {
        let data = '';

        res.on('data', (chunk) => {
          data += chunk;
        });

        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch {
            reject(new Error('Invalid JSON response'));
          }
        });
      });

      req.on('error', reject);
      req.on('timeout', () => reject(new Error('Request timeout')));
      req.end();
    });
  }

  private parseResponse(data: any, planName: string): RateLimits {
    const fiveHour = data.five_hour ?? {};
    const sevenDay = data.seven_day ?? {};

    return {
      plan_name: planName,
      five_hour_percent: this.parseUtilization(fiveHour.utilization),
      seven_day_percent: this.parseUtilization(sevenDay.utilization),
      five_hour_reset_at: this.parseDate(fiveHour.resets_at),
      seven_day_reset_at: this.parseDate(sevenDay.resets_at),
      api_unavailable: false,
    };
  }

  private parseUtilization(value: number | undefined): number | null {
    if (value == null) return null;
    if (!Number.isFinite(value)) return null;  // Handles NaN and Infinity
    return Math.round(Math.max(0, Math.min(100, value)));
  }

  private parseDate(dateStr: string | undefined): Date | null {
    if (!dateStr) return null;
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) {
      return null;
    }
    return date;
  }

  private readCache(): RateLimits | null {
    if (!existsSync(this.cacheFile)) {
      return null;
    }

    try {
      const content = readFileSync(this.cacheFile, 'utf-8');
      const cache = JSON.parse(content);

      // Check TTL
      const timestamp = cache.timestamp ?? 0;
      const age = Math.floor(Date.now() / 1000) - timestamp;

      const isFailure = cache.data?.api_unavailable ?? false;
      const ttl = isFailure ? RATE_LIMIT_CACHE_TTL_FAILURE : RATE_LIMIT_CACHE_TTL_SUCCESS;

      if (age > ttl) {
        return null;
      }

      return cache.data as RateLimits;
    } catch {
      return null;
    }
  }

  private writeCache(limits: RateLimits): void {
    try {
      const cache = {
        data: limits,
        timestamp: Math.floor(Date.now() / 1000),
      };

      writeFileSync(this.cacheFile, JSON.stringify(cache, null, 2));
    } catch {
      // Silently fail if can't write cache
    }
  }

  private writeCacheFailure(failure: RateLimits): void {
    try {
      const cache = {
        data: failure,
        timestamp: Math.floor(Date.now() / 1000),
      };

      writeFileSync(this.cacheFile, JSON.stringify(cache, null, 2));
    } catch {
      // Silently fail
    }
  }
}
