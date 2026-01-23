/**
 * Stdin reading and parsing (from Claude Code)
 * Version: 0.13.6
 * Synchronized with claude-hud implementation for accurate context tracking
 */

import type { StdinData, ContextWindow } from './types.js';
import { AUTOCOMPACT_BUFFER_PERCENT } from './constants.js';

export async function readStdin(): Promise<StdinData | null> {
  if (process.stdin.isTTY) {
    return null;
  }

  const chunks: string[] = [];

  try {
    process.stdin.setEncoding('utf8');
    for await (const chunk of process.stdin) {
      chunks.push(chunk as string);
    }
    const raw = chunks.join('');
    if (!raw.trim()) {
      return null;
    }

    return JSON.parse(raw) as StdinData;
  } catch {
    return null;
  }
}

function getTotalTokens(stdin: StdinData): number {
  // Sum current_usage fields: input + cache_creation + cache_read
  // This represents actual context window usage (matches /context output)
  // Note: total_input_tokens excludes System tools & Memory files
  const usage = stdin.context_window?.current_usage;
  return (
    (usage?.input_tokens ?? 0) +
    (usage?.cache_creation_input_tokens ?? 0) +
    (usage?.cache_read_input_tokens ?? 0)
  );
}

export function getContextPercent(stdin: StdinData): number {
  const size = stdin.context_window?.context_window_size;

  if (!size || size <= 0) {
    return 0;
  }

  const totalTokens = getTotalTokens(stdin);
  return Math.min(100, Math.round((totalTokens / size) * 100));
}

export function getBufferedPercent(stdin: StdinData): number {
  const size = stdin.context_window?.context_window_size;

  if (!size || size <= 0) {
    return 0;
  }

  const totalTokens = getTotalTokens(stdin);
  const buffer = size * AUTOCOMPACT_BUFFER_PERCENT;
  return Math.min(100, Math.round(((totalTokens + buffer) / size) * 100));
}

export function getContextWindow(stdin: StdinData): ContextWindow | null {
  const size = stdin.context_window?.context_window_size;
  if (!size || size <= 0) {
    return null;
  }

  const usage = getTotalTokens(stdin);

  // Use buffered percent to match /context display (includes 22.5% buffer)
  const percent = getBufferedPercent(stdin);

  // DEBUG: Log calculation details
  const isDebug = process.env.DEBUG?.includes('context') || process.env.DEBUG === '*';
  if (isDebug) {
    const cw = stdin.context_window;
    const cu = cw?.current_usage;
    const buffer = size * AUTOCOMPACT_BUFFER_PERCENT;
    const rawPercent = getContextPercent(stdin);
    console.error('[claude-trip-computer:context]');
    console.error(`  Context window size: ${size.toLocaleString()}`);
    console.error(`  current_usage.input_tokens: ${(cu?.input_tokens ?? 0).toLocaleString()}`);
    console.error(`  current_usage.cache_creation: ${(cu?.cache_creation_input_tokens ?? 0).toLocaleString()}`);
    console.error(`  current_usage.cache_read: ${(cu?.cache_read_input_tokens ?? 0).toLocaleString()}`);
    console.error(`  Sum (context usage): ${usage.toLocaleString()}`);
    console.error(`  Buffer (22.5%): ${buffer.toLocaleString()}`);
    console.error(`  Raw %: ${rawPercent}%`);
    console.error(`  Buffered % (used+buffer): ${percent}%`);
    console.error(`  -> Should match /context header percentage`);
  }

  // Determine health status
  let health_status: 'healthy' | 'warning' | 'critical' = 'healthy';
  if (percent >= 85) {
    health_status = 'critical';
  } else if (percent >= 70) {
    health_status = 'warning';
  }

  return {
    size,
    usage,
    usage_percent: percent,
    health_status,
  };
}

export function getModelName(stdin: StdinData): string {
  return stdin.model?.display_name ?? stdin.model?.id ?? 'Unknown';
}

export function getSessionId(stdin: StdinData): string | null {
  return stdin.session_id ?? null;
}

export function getTranscriptPath(stdin: StdinData): string | null {
  return stdin.transcript_path ?? null;
}
