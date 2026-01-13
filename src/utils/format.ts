/**
 * Formatting utilities for Claude Trip Computer
 * Version: 0.13.2
 */

/**
 * Format session duration from start time to now
 * Returns: "<1m", "45m", "1h 30m"
 */
export function formatDuration(startMs: number): string {
  const now = Date.now();
  const ms = now - startMs;

  if (ms < 60000) {
    return '<1m';
  }

  const totalMinutes = Math.floor(ms / 60000);
  if (totalMinutes < 60) {
    return `${totalMinutes}m`;
  }

  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  if (minutes === 0) {
    return `${hours}h`;
  }
  return `${hours}h ${minutes}m`;
}

/**
 * Format elapsed time for a task (running or completed)
 * Returns: "<1s", "5s", "1m 30s"
 */
export function formatElapsed(startMs: number, endMs?: number): string {
  const end = endMs ?? Date.now();
  const ms = end - startMs;

  if (ms < 1000) {
    return '<1s';
  }

  const totalSeconds = Math.round(ms / 1000);
  if (totalSeconds < 60) {
    return `${totalSeconds}s`;
  }

  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  if (seconds === 0) {
    return `${minutes}m`;
  }
  return `${minutes}m ${seconds}s`;
}

/**
 * Truncate file path to show only last N levels
 * Default: 1 level (just filename)
 */
export function truncatePath(path: string, levels: number = 1): string {
  if (!path) return '';

  const parts = path.split('/').filter(Boolean);
  if (parts.length <= levels) {
    return parts.join('/');
  }

  return parts.slice(-levels).join('/');
}

/**
 * Truncate content string to max length
 * Default: 50 characters
 */
export function truncateContent(content: string, maxLen: number = 50): string {
  if (!content) return '';

  if (content.length <= maxLen) {
    return content;
  }

  return content.slice(0, maxLen - 3) + '...';
}
