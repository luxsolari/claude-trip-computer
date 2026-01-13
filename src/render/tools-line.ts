/**
 * Tool activity line renderer
 * Version: 0.13.2
 */

import type { ActivityData } from '../types.js';
import { truncatePath } from '../utils/format.js';

// ANSI color codes
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';
const DIM = '\x1b[2m';
const RESET = '\x1b[0m';

/**
 * Render tool activity line
 * Shows running tools and top completed tools by frequency
 * Returns null if no tools to show
 */
export function renderToolsLine(activity: ActivityData): string | null {
  const { runningTools, toolCounts } = activity;

  // Nothing to show if no running tools and no completed tools
  if ((!runningTools || runningTools.length === 0) && (!toolCounts || toolCounts.size === 0)) {
    return null;
  }

  const parts: string[] = [];

  // Show running tools (already limited to last 2 in activity.ts)
  for (const tool of runningTools) {
    const target = tool.target ? truncatePath(tool.target) : '';
    if (target) {
      parts.push(`${YELLOW}◐${RESET} ${CYAN}${tool.name}${RESET}${DIM}: ${target}${RESET}`);
    } else {
      parts.push(`${YELLOW}◐${RESET} ${CYAN}${tool.name}${RESET}`);
    }
  }

  // Show top 5 completed tools by count (leaves room for running commands)
  const sortedTools = Array.from(toolCounts.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);

  for (const [name, count] of sortedTools) {
    parts.push(`${GREEN}✓${RESET} ${name} ${DIM}×${count}${RESET}`);
  }

  if (parts.length === 0) {
    return null;
  }

  return parts.join(' | ');
}
