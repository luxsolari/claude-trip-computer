/**
 * Session analytics computer - generates intelligence from metrics
 * Version: 0.13.2
 */

import type { SessionMetrics, ContextWindow, SessionAnalytics, OptimizationAction, BillingConfig } from './types.js';

export class AnalyticsComputer {
  constructor(private config: BillingConfig) {}

  compute(metrics: SessionMetrics, context: ContextWindow | null): SessionAnalytics {
    const cacheScore = this.calculateCacheScore(metrics);
    const contextScore = this.calculateContextScore(context);
    const efficiencyScore = this.calculateEfficiencyScore(metrics);
    const healthScore = cacheScore + contextScore + efficiencyScore;

    return {
      health_score: healthScore,
      health_label: this.getHealthLabel(healthScore),
      cache_score: cacheScore,
      context_score: contextScore,
      efficiency_score: efficiencyScore,
      tool_intensity_label: this.assessToolIntensity(metrics),
      verbosity_label: this.assessVerbosity(metrics),
      context_growth_label: this.assessContextGrowth(metrics.tokens_per_message),
      cache_guidance: this.getCacheGuidance(metrics.cache_efficiency),
      optimization_actions: this.generateOptimizationActions(metrics),
      behavioral_analysis: this.generateBehavioralAnalysis(metrics, context),
    };
  }

  private calculateCacheScore(metrics: SessionMetrics): number {
    // 40 points max for cache efficiency
    if (metrics.cache_efficiency >= 90) return 40;
    if (metrics.cache_efficiency >= 70) return 30;
    if (metrics.cache_efficiency >= 50) return 20;
    return 10;
  }

  private calculateContextScore(context: ContextWindow | null): number {
    // 30 points max for context management
    if (!context) return 15; // Neutral if unavailable

    const percent = context.usage_percent;
    if (percent < 70) return 30;
    if (percent < 85) return 20;
    return 10;
  }

  private calculateEfficiencyScore(metrics: SessionMetrics): number {
    // 30 points max for efficiency (verbosity + tool usage)
    let score = 30;

    // Penalize high verbosity if low tool intensity
    if (metrics.tokens_per_message > 15000 && metrics.tools_per_message < 10) {
      score -= 10;
    }

    // Reward efficient tool usage
    if (metrics.tools_per_message >= 5 && metrics.tools_per_message <= 20) {
      score = Math.min(30, score + 5);
    }

    return Math.max(0, score);
  }

  private getHealthLabel(health: number): string {
    if (health >= 90) return '⭐⭐⭐⭐⭐ Excellent';
    if (health >= 75) return '⭐⭐⭐⭐ Good';
    if (health >= 60) return '⭐⭐⭐ Fair';
    if (health >= 40) return '⭐⭐ Poor';
    return '⭐ Critical';
  }

  private assessToolIntensity(metrics: SessionMetrics): string {
    const { tool_count, tools_per_message, message_count } = metrics;

    if (tool_count >= 250 && tools_per_message >= 15) {
      return 'Very intensive - heavy implementation with high tool rate';
    }
    if (tool_count >= 100 && tools_per_message >= 15 && message_count < 20) {
      return 'Intensive - focused implementation burst';
    }
    if (tool_count >= 100 && message_count >= 20) {
      return 'Moderate - steady workflow over extended session';
    }
    if (tool_count >= 25 && tools_per_message < 10) {
      return 'Light - planning/exploration phase';
    }
    return 'Minimal - early session or simple tasks';
  }

  private assessVerbosity(metrics: SessionMetrics): string {
    const tokPerMsg = metrics.tokens_per_message;
    if (tokPerMsg > 15000) return 'High - detailed responses';
    if (tokPerMsg > 8000) return 'Moderate - balanced responses';
    return 'Concise - brief responses';
  }

  private assessContextGrowth(avgTokensPerMsg: number): string {
    if (avgTokensPerMsg > 50000) return 'Fast growth → consider /clear soon';
    if (avgTokensPerMsg > 20000) return 'Moderate growth → monitor context size';
    return 'Slow growth → healthy pace';
  }

  private getCacheGuidance(efficiency: number): string {
    if (efficiency > 90) return 'Excellent → stay in session';
    if (efficiency > 70) return 'Good → cache is helping';
    return 'Low → consider /clear to rebuild cache';
  }

  private generateOptimizationActions(metrics: SessionMetrics): OptimizationAction[] {
    const actions: OptimizationAction[] = [];

    // High verbosity + low tool intensity
    if (metrics.tokens_per_message > 15000 && metrics.tools_per_message < 10) {
      const impact = this.config.billing_mode === 'Sub'
        ? `Save ~$${(metrics.total_cost * 0.25 / metrics.message_count * 10 * this.config.safety_margin).toFixed(2)}/10 msgs (25% reduction)`
        : 'High efficiency gain (25% improvement)';

      actions.push({
        action: 'Add brevity constraints to prompts',
        impact,
        priority: 25
      });
    }

    // Low cache efficiency
    if (metrics.cache_efficiency < 70) {
      const impact = this.config.billing_mode === 'Sub'
        ? `Save ~$${(metrics.total_cost * 0.20 / metrics.message_count * 10 * this.config.safety_margin).toFixed(2)}/10 msgs (20% reduction)`
        : 'Moderate efficiency gain (20% improvement)';

      actions.push({
        action: 'Start fresh session to rebuild cache',
        impact,
        priority: 20
      });
    }

    // High tool intensity but low progress
    if (metrics.tools_per_message > 30 && metrics.message_count > 10) {
      actions.push({
        action: 'Review if tasks could be simplified',
        impact: 'Potential workflow optimization',
        priority: 15
      });
    }

    // Sort by priority
    return actions.sort((a, b) => b.priority - a.priority);
  }

  private generateBehavioralAnalysis(metrics: SessionMetrics, context: ContextWindow | null): string[] {
    const analysis: string[] = [];

    // Analyze work pattern based on tool/message ratio
    const toolsPerMsg = metrics.tools_per_message;
    const tokPerMsg = metrics.tokens_per_message;

    // Work type inference
    if (toolsPerMsg > 15 && tokPerMsg > 8000) {
      analysis.push(
        `This session exhibits intensive implementation behavior (${toolsPerMsg.toFixed(1)} tools/msg) combined with ` +
        `detailed explanations (${this.formatTokens(tokPerMsg)}/msg). The AI is actively building complex features ` +
        `while providing thorough documentation. This pattern is costly but high-value for learning.`
      );
    } else if (toolsPerMsg > 10 && tokPerMsg < 5000) {
      analysis.push(
        `The AI is in focused execution mode: high tool activity (${toolsPerMsg.toFixed(1)} tools/msg) with ` +
        `concise communication (${this.formatTokens(tokPerMsg)}/msg). This is an efficient pattern for implementing ` +
        `well-defined tasks where less explanation is needed.`
      );
    } else if (toolsPerMsg < 5 && tokPerMsg > 10000) {
      analysis.push(
        `Conversation-heavy session with low tool activity (${toolsPerMsg.toFixed(1)} tools/msg) but verbose responses ` +
        `(${this.formatTokens(tokPerMsg)}/msg). The AI is explaining concepts or planning rather than executing. ` +
        `Consider whether this level of detail is necessary, or if you could request more action and less talk.`
      );
    } else if (toolsPerMsg >= 5 && tokPerMsg >= 5000 && tokPerMsg <= 10000) {
      analysis.push(
        `Balanced workflow detected: moderate tool usage (${toolsPerMsg.toFixed(1)} tools/msg) with appropriately ` +
        `detailed responses (${this.formatTokens(tokPerMsg)}/msg). This represents efficient collaboration ` +
        `where the AI both executes and explains at a sustainable pace.`
      );
    }

    // Cache behavior analysis
    if (metrics.cache_efficiency > 90) {
      analysis.push(
        `Exceptional cache efficiency (${Math.round(metrics.cache_efficiency)}%) indicates this session is building ` +
        `on previous context effectively. The AI is reusing prior work rather than re-processing. Starting a new ` +
        `session would lose this 10x cost advantage. Stay in this session as long as possible.`
      );
    } else if (metrics.cache_efficiency < 50 && metrics.message_count > 5) {
      analysis.push(
        `Low cache efficiency (${Math.round(metrics.cache_efficiency)}%) suggests frequent context switching or a ` +
        `cold start. The AI is processing most content from scratch, which is expensive. If this session continues ` +
        `to be unfocused, consider using /clear to rebuild a clean cache for your current task.`
      );
    }

    // Context pressure analysis
    if (context && context.usage_percent > 85) {
      const remaining = 100 - context.usage_percent;
      analysis.push(
        `Context window is at ${context.usage_percent}% capacity with only ~${remaining}% remaining. At current ` +
        `verbosity (${this.formatTokens(tokPerMsg)}/msg), you have approximately ` +
        `${Math.floor(remaining / (tokPerMsg / (context.size / 100)))} messages before autocompact triggers. ` +
        `The AI may start dropping earlier context to make room. Consider /clear or requesting more concise responses.`
      );
    } else if (context && context.usage_percent > 70 && tokPerMsg > 15000) {
      analysis.push(
        `Context at ${context.usage_percent}% with high verbosity (${this.formatTokens(tokPerMsg)}/msg) creates ` +
        `pressure. The AI is providing detailed responses which fill context quickly. If you're approaching limits, ` +
        `explicitly request brevity: "Be more concise" or "Just show code changes" can reduce tokens by 50-70%.`
      );
    } else if (context && context.usage_percent < 50) {
      analysis.push(
        `Healthy context headroom (${context.usage_percent}% used). The AI has plenty of space to maintain ` +
        `full conversation history without compression. This enables better coherence and reference to earlier work.`
      );
    }

    // Cost/efficiency trade-off analysis (for high-cost sessions)
    const avgCostPerMsg = metrics.total_cost / Math.max(metrics.message_count, 1);
    if (avgCostPerMsg > 2.0 && this.config.billing_mode === 'Sub') {
      analysis.push(
        `This session is averaging $${avgCostPerMsg.toFixed(2)}/message, which is premium territory. You're getting ` +
        `${this.formatTokens(tokPerMsg)} of output per message, suggesting complex multi-step operations. ` +
        `This investment makes sense for difficult problems, but simpler tasks could use cheaper models or more focused prompts.`
      );
    }

    // Pattern sustainability
    if (metrics.message_count > 10) {
      const projectedMessages = Math.floor(((context?.size ?? 200000) * 0.85 - (context?.usage ?? 0)) / tokPerMsg);
      if (projectedMessages < 5) {
        analysis.push(
          `At current pace, you have approximately ${projectedMessages} messages before hitting context limits. ` +
          `The AI's current pattern is not sustainable for extended sessions. Either reduce verbosity now or ` +
          `plan to use /clear soon to continue working efficiently.`
        );
      }
    }

    return analysis.length > 0 ? analysis : [
      'Early session - behavioral patterns not yet established. Continue working to generate meaningful insights.'
    ];
  }

  private formatTokens(count: number): string {
    if (count >= 1000000) return `${(count / 1000000).toFixed(1)}M`;
    if (count >= 1000) return `${(count / 1000).toFixed(1)}K`;
    return `${Math.round(count)}`;
  }
}
