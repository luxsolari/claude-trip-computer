/**
 * Status line renderer
 * Version: 0.13.2
 * Multi-line status with git, duration, and tool activity
 */

import type { SessionMetrics, ContextWindow, RateLimits, BillingConfig, GitStatus, ActivityData } from '../types.js';
import { renderToolsLine } from './tools-line.js';
import { renderAgentsLine } from './agents-line.js';
import { renderTodosLine } from './todos-line.js';
import { formatDuration } from '../utils/format.js';

// ANSI color codes (matching claude-hud)
const RESET = '\x1b[0m';
const DIM = '\x1b[2m';
const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';

export class StatusLineRenderer {
  constructor(private config: BillingConfig) {}

  render(
    metrics: SessionMetrics,
    modelName: string,
    context: ContextWindow | null,
    rateLimits: RateLimits | null,
    gitStatus: GitStatus | null = null,
    activity: ActivityData | null = null
  ): string {
    const lines: string[] = [];

    // Line 1: Main session metrics
    lines.push(this.renderMainLine(metrics, modelName, context, rateLimits, gitStatus, activity));

    if (activity) {
      // Line 2: Tool activity (only if tools exist)
      const toolsLine = renderToolsLine(activity);
      if (toolsLine) {
        lines.push(toolsLine);
      }

      // Lines 3+: Agent status (only if agents exist)
      const agentsLine = renderAgentsLine(activity);
      if (agentsLine) {
        lines.push(agentsLine);
      }

      // Final line: Todo progress (only if todos exist)
      const todosLine = renderTodosLine(activity);
      if (todosLine) {
        lines.push(todosLine);
      }
    }

    return lines.join('\n');
  }

  private renderMainLine(
    metrics: SessionMetrics,
    modelName: string,
    context: ContextWindow | null,
    rateLimits: RateLimits | null,
    gitStatus: GitStatus | null,
    activity: ActivityData | null
  ): string {
    const parts: string[] = [];

    // Messages with model name
    parts.push(`💬 ${metrics.message_count} msgs (${modelName})`);

    // Tools
    const toolIntensity = metrics.tools_per_message.toFixed(1);
    parts.push(`🔧 ${metrics.tool_count} tools (${toolIntensity}/msg)`);

    // Total tokens
    const formattedTotal = this.formatTokens(metrics.total_tokens.input + metrics.total_tokens.output + metrics.total_tokens.cache_creation + metrics.total_tokens.cache_read);
    parts.push(`🎯 ${formattedTotal} tok`);

    // Git branch (if available)
    if (gitStatus) {
      const dirty = gitStatus.isDirty ? '*' : '';
      parts.push(`${CYAN}🌿 ${gitStatus.branch}${dirty}${RESET}`);
    }

    // Context window (if available) - matches /context output
    if (context) {
      const contextDisplay = this.renderContext(context);
      parts.push(contextDisplay);
    }

    // Cache efficiency
    parts.push(`⚡ ${Math.round(metrics.cache_efficiency)}% cached`);

    // Response verbosity
    const formattedVerbosity = this.formatTokens(metrics.tokens_per_message);
    parts.push(`📝 ${formattedVerbosity}/msg`);

    // Session duration (if available)
    if (activity?.session_start) {
      parts.push(`⏱️ ${formatDuration(activity.session_start)}`);
    }

    // Rate limits (subscription users only)
    if (rateLimits && rateLimits.plan_name && this.config.billing_mode === 'Sub') {
      parts.push(this.renderRateLimits(rateLimits));
    }

    // Cost (subscription users only)
    if (this.config.billing_mode === 'Sub') {
      const cost = (metrics.total_cost * this.config.safety_margin).toFixed(2);
      parts.push(`${this.config.billing_icon} ~$${cost} value`);
    }

    // Trip computer link
    parts.push('📈 /trip');

    return parts.join(' | ');
  }

  private renderContext(context: ContextWindow): string {
    const percent = Math.round(context.usage_percent);
    const bar = this.coloredBar(percent, 10);
    const color = this.getContextColor(percent);

    // Format: [████░░░░░░] 35%
    // Matches claude-hud and /context output
    return `${bar} ${color}${percent}%${RESET}`;
  }

  private coloredBar(percent: number, width: number = 10): string {
    // Exact implementation from claude-hud
    const filled = Math.round((percent / 100) * width);
    const empty = width - filled;
    const color = this.getContextColor(percent);
    return `${color}${'█'.repeat(filled)}${DIM}${'░'.repeat(empty)}${RESET}`;
  }

  private getContextColor(percent: number): string {
    // Exact thresholds from claude-hud
    if (percent >= 85) return RED;
    if (percent >= 70) return YELLOW;
    return GREEN;
  }

  private renderRateLimits(limits: RateLimits): string {
    const fiveHour = Math.round(limits.five_hour_percent ?? 0);
    const sevenDay = Math.round(limits.seven_day_percent ?? 0);
    return `📊 ${limits.plan_name} ${fiveHour}%/${sevenDay}%`;
  }

  private formatTokens(count: number): string {
    if (count >= 1000000) {
      return `${(count / 1000000).toFixed(1)}M`;
    } else if (count >= 1000) {
      return `${(count / 1000).toFixed(1)}K`;
    } else {
      return `${Math.round(count)}`;
    }
  }
}
