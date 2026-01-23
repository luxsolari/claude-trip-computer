/**
 * Constants and pricing tables
 * Version: 0.13.6
 */

export interface ModelPricing {
  input_rate: number;
  output_rate: number;
  cache_write_mult: number;
  cache_read_mult: number;
}

export const MODEL_PRICING: Record<string, ModelPricing> = {
  'opus-4-5': {
    input_rate: 5,
    output_rate: 25,
    cache_write_mult: 1.25,
    cache_read_mult: 0.10,
  },
  'opus-4': {
    input_rate: 15,
    output_rate: 75,
    cache_write_mult: 1.25,
    cache_read_mult: 0.10,
  },
  'opus-3': {
    input_rate: 15,
    output_rate: 75,
    cache_write_mult: 1.25,
    cache_read_mult: 0.10,
  },
  'sonnet-4-5': {
    input_rate: 3,
    output_rate: 15,
    cache_write_mult: 1.25,
    cache_read_mult: 0.10,
  },
  'sonnet-4': {
    input_rate: 3,
    output_rate: 15,
    cache_write_mult: 1.25,
    cache_read_mult: 0.10,
  },
  'sonnet-3-7': {
    input_rate: 3,
    output_rate: 15,
    cache_write_mult: 1.25,
    cache_read_mult: 0.10,
  },
  'haiku-4-5': {
    input_rate: 1,
    output_rate: 5,
    cache_write_mult: 1.25,
    cache_read_mult: 0.10,
  },
  'haiku-3-5': {
    input_rate: 0.80,
    output_rate: 4,
    cache_write_mult: 1.25,
    cache_read_mult: 0.10,
  },
  'haiku-3': {
    input_rate: 0.25,
    output_rate: 1.25,
    cache_write_mult: 1.20,
    cache_read_mult: 0.12,
  },
};

export const DEFAULT_PRICING: ModelPricing = {
  input_rate: 3,
  output_rate: 15,
  cache_write_mult: 1.25,
  cache_read_mult: 0.10,
};

export const CACHE_TTL_SECONDS = 5;
export const RATE_LIMIT_CACHE_TTL_SUCCESS = 60;
export const RATE_LIMIT_CACHE_TTL_FAILURE = 15;

export const USAGE_API_URL = 'https://api.anthropic.com/api/oauth/usage';
export const USAGE_API_BETA_HEADER = 'oauth-2025-04-20';

// Autocompact buffer: Claude Code reserves 22.5% for autocompaction
// The /context command displays the buffered percentage (used + buffer)
// This value (22.5% = 45k/200k for Sonnet) is empirically derived
// Source: claude-hud implementation and community observations
export const AUTOCOMPACT_BUFFER_PERCENT = 0.225;  // 22.5% buffer
