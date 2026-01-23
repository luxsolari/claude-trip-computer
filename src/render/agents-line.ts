/**
 * Agent status line renderer
 * Version: 0.13.6
 */

import type { ActivityData, AgentEntry } from '../types.js';
import { formatElapsed, truncateContent } from '../utils/format.js';

// ANSI color codes
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const MAGENTA = '\x1b[35m';
const DIM = '\x1b[2m';
const RESET = '\x1b[0m';

/**
 * Format a single agent entry
 */
function formatAgent(agent: AgentEntry): string {
  const statusIcon = agent.status === 'running'
    ? `${YELLOW}◐${RESET}`
    : `${GREEN}✓${RESET}`;

  const type = `${MAGENTA}${agent.type}${RESET}`;
  const desc = agent.description
    ? `${DIM}: ${truncateContent(agent.description, 40)}${RESET}`
    : '';
  const elapsed = `${DIM}(${formatElapsed(agent.startTime, agent.endTime)})${RESET}`;

  return `${statusIcon} ${type}${desc} ${elapsed}`;
}

/**
 * Render agent status lines
 * Shows running agents and up to 2 recently completed
 * Returns null if no agents to show, or multi-line string
 */
export function renderAgentsLine(activity: ActivityData): string | null {
  const { agents } = activity;

  if (!agents || agents.length === 0) {
    return null;
  }

  // Get running agents and recent completed
  const runningAgents = agents.filter(a => a.status === 'running');
  const recentCompleted = agents
    .filter(a => a.status === 'completed')
    .slice(-2);

  // Show running first, then up to 2 recent completed (max 3 total)
  const toShow = [...runningAgents, ...recentCompleted].slice(-3);

  if (toShow.length === 0) {
    return null;
  }

  // Each agent gets its own line
  const lines = toShow.map(formatAgent);
  return lines.join('\n');
}
