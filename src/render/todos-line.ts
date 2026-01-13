/**
 * Todo progress line renderer
 * Version: 0.13.2
 */

import type { ActivityData } from '../types.js';
import { truncateContent } from '../utils/format.js';

// ANSI color codes
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const DIM = '\x1b[2m';
const RESET = '\x1b[0m';

/**
 * Render todo progress line
 * Shows current in-progress task or completion status
 * Returns null if no todos or nothing active
 */
export function renderTodosLine(activity: ActivityData): string | null {
  const { todos } = activity;

  if (!todos || todos.length === 0) {
    return null;
  }

  const completed = todos.filter(t => t.status === 'completed').length;
  const total = todos.length;
  const inProgress = todos.find(t => t.status === 'in_progress');

  // If all complete, show completion message
  if (!inProgress) {
    if (completed === total && total > 0) {
      return `${GREEN}✓${RESET} All todos complete ${DIM}(${completed}/${total})${RESET}`;
    }
    // No in-progress and not all complete - don't show anything
    return null;
  }

  // Show current in-progress task
  const content = truncateContent(inProgress.content, 50);
  const progress = `${DIM}(${completed}/${total})${RESET}`;

  return `${YELLOW}▸${RESET} ${content} ${progress}`;
}
