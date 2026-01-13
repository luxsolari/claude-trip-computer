/**
 * Trip Computer - Detailed analytics renderer
 * Version: 0.13.3
 */

import type { SessionMetrics, ContextWindow, RateLimits, BillingConfig, SessionAnalytics } from '../types.js';
import { MODEL_PRICING, DEFAULT_PRICING } from '../constants.js';

export class TripComputerRenderer {
  private analytics!: SessionAnalytics;

  constructor(private config: BillingConfig) {}

  render(
    metrics: SessionMetrics,
    modelName: string,
    context: ContextWindow | null,
    rateLimits: RateLimits | null,
    analytics: SessionAnalytics
  ): void {
    // Store analytics for use in render methods
    this.analytics = analytics;
    console.log('');
    console.log('═══════════════════════════════════════════════════════════════');
    console.log('  📊 TRIP COMPUTER - Session Analytics Dashboard');
    console.log('═══════════════════════════════════════════════════════════════');
    console.log('');

    // Quick Summary
    this.renderQuickSummary(metrics, context);

    // Session Health
    this.renderSessionHealth(metrics, context);

    // Model Mix
    this.renderModelMix(metrics);

    // Cost Drivers / Token Distribution
    if (this.config.billing_mode === 'Sub') {
      this.renderCostDrivers(metrics);
    } else {
      this.renderTokenDistribution(metrics);
    }

    // Efficiency Metrics
    this.renderEfficiencyMetrics(metrics);

    // Top Optimization Actions
    this.renderOptimizationActions(metrics);

    // AI Self-Assessment (deep behavioral introspection)
    this.renderBehavioralAnalysis();

    console.log('');
    console.log('═══════════════════════════════════════════════════════════════');
    console.log('');
  }

  private renderQuickSummary(metrics: SessionMetrics, context: ContextWindow | null): void {
    // Adjust health display when context unavailable
    const hasContext = context !== null;
    const maxScore = hasContext ? 100 : 70;
    const displayScore = hasContext
      ? this.analytics.health_score
      : this.analytics.cache_score + this.analytics.efficiency_score;
    const healthLabel = this.getHealthLabelForScore(displayScore, maxScore);

    console.log('📊 QUICK SUMMARY');
    console.log('─'.repeat(63));
    console.log(`  Health: ${healthLabel} (${displayScore}/${maxScore})`);
    console.log(`  Messages: ${metrics.message_count} | Tools: ${metrics.tool_count} | Tokens: ${this.formatTokens(this.getTotalTokens(metrics))}`);
    if (context) {
      console.log(`  Context: ${Math.round(context.usage_percent)}% (${this.getHealthIcon(context.health_status)} ${context.health_status})`);
    }
    console.log('');
  }

  private getHealthLabelForScore(score: number, maxScore: number): string {
    const percent = (score / maxScore) * 100;
    if (percent >= 90) return '⭐⭐⭐⭐⭐ Excellent';
    if (percent >= 75) return '⭐⭐⭐⭐ Good';
    if (percent >= 60) return '⭐⭐⭐ Fair';
    if (percent >= 40) return '⭐⭐ Poor';
    return '⭐ Critical';
  }

  private renderSessionHealth(metrics: SessionMetrics, context: ContextWindow | null): void {
    // When context unavailable, score is out of 70 (cache 40 + efficiency 30)
    const hasContext = context !== null;
    const maxScore = hasContext ? 100 : 70;
    const displayScore = hasContext
      ? this.analytics.health_score
      : this.analytics.cache_score + this.analytics.efficiency_score;
    const stars = this.getStars(Math.round((displayScore / maxScore) * 100));

    console.log(`📈 SESSION HEALTH (0-${maxScore})`);
    console.log('─'.repeat(63));
    console.log(`  Overall: ${stars} ${displayScore}/${maxScore}`);
    console.log('');

    console.log(`  ⚡ Cache Efficiency: ${this.getIndicator(this.analytics.cache_score, 40)} ${this.analytics.cache_score}/40 points`);
    console.log(`     ${Math.round(metrics.cache_efficiency)}% cache hit rate`);
    console.log('');

    // Only show context management when data is available
    if (context) {
      console.log(`  ⚙️  Context Management: ${this.getIndicator(this.analytics.context_score, 30)} ${this.analytics.context_score}/30 points`);
      console.log(`     ${Math.round(context.usage_percent)}% of context window used`);
      console.log('');
    }

    console.log(`  🎯 Efficiency: ${this.getIndicator(this.analytics.efficiency_score, 30)} ${this.analytics.efficiency_score}/30 points`);
    console.log(`     ${metrics.tools_per_message.toFixed(1)} tools/msg, ${this.formatTokens(metrics.tokens_per_message)} tok/msg`);
    console.log('');
  }

  private renderModelMix(metrics: SessionMetrics): void {
    console.log('🤖 MODEL MIX');
    console.log('─'.repeat(63));

    // Sort models by model_id for deterministic display order
    const models = Object.values(metrics.models).sort((a, b) => a.model_id.localeCompare(b.model_id));
    if (models.length === 0) {
      console.log('  No model usage data available');
      console.log('');
      return;
    }

    for (const model of models) {
      const costPercent = metrics.total_cost > 0
        ? ((model.cost / metrics.total_cost) * 100).toFixed(1)
        : '0.0';
      const bar = this.renderMiniBar(parseFloat(costPercent));

      console.log(`  ${model.display_name}`);
      console.log(`  ${bar} ${costPercent}% of cost`);
      console.log(`  Tokens: ${this.formatTokens(model.tokens.input + model.tokens.output + model.tokens.cache_creation + model.tokens.cache_read)}`);
      console.log('');
    }
  }

  private renderCostDrivers(metrics: SessionMetrics): void {
    console.log('💵 COST DRIVERS');
    console.log('─'.repeat(63));

    const totalCost = metrics.total_cost * this.config.safety_margin;
    const totalTokens = this.getTotalTokens(metrics);

    const inputCost = this.calculateTokenTypeCost(metrics, 'input') * this.config.safety_margin;
    const outputCost = this.calculateTokenTypeCost(metrics, 'output') * this.config.safety_margin;
    const cacheWriteCost = this.calculateTokenTypeCost(metrics, 'cache_creation') * this.config.safety_margin;
    const cacheReadCost = this.calculateTokenTypeCost(metrics, 'cache_read') * this.config.safety_margin;

    this.renderCostLine('Input tokens', inputCost, totalCost);
    this.renderCostLine('Output tokens', outputCost, totalCost);
    this.renderCostLine('Cache writes', cacheWriteCost, totalCost);
    this.renderCostLine('Cache reads', cacheReadCost, totalCost);
    console.log('');
  }

  private renderTokenDistribution(metrics: SessionMetrics): void {
    console.log('📊 TOKEN DISTRIBUTION');
    console.log('─'.repeat(63));

    const totalTokens = this.getTotalTokens(metrics);
    const inputPercent = ((metrics.total_tokens.input / totalTokens) * 100).toFixed(1);
    const outputPercent = ((metrics.total_tokens.output / totalTokens) * 100).toFixed(1);
    const cacheWritePercent = ((metrics.total_tokens.cache_creation / totalTokens) * 100).toFixed(1);
    const cacheReadPercent = ((metrics.total_tokens.cache_read / totalTokens) * 100).toFixed(1);

    console.log(`  Input: ${inputPercent}% ${this.renderMiniBar(parseFloat(inputPercent))}`);
    console.log(`  Output: ${outputPercent}% ${this.renderMiniBar(parseFloat(outputPercent))}`);
    console.log(`  Cache writes: ${cacheWritePercent}% ${this.renderMiniBar(parseFloat(cacheWritePercent))}`);
    console.log(`  Cache reads: ${cacheReadPercent}% ${this.renderMiniBar(parseFloat(cacheReadPercent))}`);
    console.log('');
  }

  private renderEfficiencyMetrics(metrics: SessionMetrics): void {
    console.log('⚡ EFFICIENCY METRICS');
    console.log('─'.repeat(63));

    console.log(`  Tool Intensity: ${this.analytics.tool_intensity_label}`);
    console.log(`    ${metrics.tool_count} tools (${metrics.tools_per_message.toFixed(1)} tools/msg) across ${metrics.message_count} msgs`);
    console.log('');

    console.log(`  Response Verbosity: ${this.analytics.verbosity_label}`);
    console.log(`    ${this.formatTokens(metrics.tokens_per_message)} tokens/msg average`);
    console.log('');

    const outputInputRatio = metrics.total_tokens.input > 0
      ? (metrics.total_tokens.output / metrics.total_tokens.input).toFixed(2)
      : '0.00';
    console.log(`  Output/Input Ratio: ${outputInputRatio}x`);
    console.log('');

    console.log(`  Cache Hit Rate: ${metrics.cache_efficiency.toFixed(1)}%`);
    console.log(`    ${this.analytics.cache_guidance}`);
    console.log('');
  }

  private renderOptimizationActions(metrics: SessionMetrics): void {
    console.log('🎯 TOP OPTIMIZATION ACTIONS');
    console.log('─'.repeat(63));

    if (this.analytics.optimization_actions.length === 0) {
      console.log('  ✅ Session looks well-optimized! Keep up the good work.');
      console.log('');
    } else {
      this.analytics.optimization_actions.slice(0, 3).forEach((action, idx) => {
        console.log(`  ${idx + 1}. [Priority: ${action.priority}] ${action.action}`);
        console.log(`     → ${action.impact}`);
        console.log('');
      });
    }
  }

  private renderBehavioralAnalysis(): void {
    console.log('🧠 AI SELF-ASSESSMENT');
    console.log('─'.repeat(63));

    this.analytics.behavioral_analysis.forEach((insight, idx) => {
      // Wrap text at 61 characters (63 - 2 for indent)
      const wrapped = this.wrapText(insight, 61);
      wrapped.forEach((line, lineIdx) => {
        if (lineIdx === 0) {
          console.log(`  • ${line}`);
        } else {
          console.log(`    ${line}`);
        }
      });
      console.log('');
    });
  }

  private wrapText(text: string, maxWidth: number): string[] {
    const words = text.split(' ');
    const lines: string[] = [];
    let currentLine = '';

    for (const word of words) {
      const testLine = currentLine ? `${currentLine} ${word}` : word;
      if (testLine.length <= maxWidth) {
        currentLine = testLine;
      } else {
        if (currentLine) lines.push(currentLine);
        currentLine = word;
      }
    }
    if (currentLine) lines.push(currentLine);

    return lines;
  }

  // Helper methods
  private getStars(health: number): string {
    const count = Math.ceil(health / 20);
    return '⭐'.repeat(Math.max(1, Math.min(5, count)));
  }

  private getHealthIcon(status: string): string {
    const icons: Record<string, string> = {
      healthy: '🟢',
      warning: '🟡',
      critical: '🔴',
    };
    return icons[status] ?? '⚪';
  }

  private getIndicator(score: number, maxForCategory: number): string {
    const percent = (score / maxForCategory) * 100;
    if (percent >= 80) return '✅';
    if (percent >= 50) return '➡️';
    return '⚠️';
  }

  private renderCostLine(label: string, cost: number, totalCost: number): void {
    const percent = totalCost > 0 ? ((cost / totalCost) * 100).toFixed(1) : '0.0';
    const bar = this.renderMiniBar(parseFloat(percent));
    console.log(`  ${label}: $${cost.toFixed(4)} (${percent}%) ${bar}`);
  }

  private renderMiniBar(percent: number): string {
    const filled = Math.min(10, Math.floor(percent / 10));
    const empty = 10 - filled;
    return `${'█'.repeat(filled)}${'░'.repeat(empty)}`;
  }

  private calculateTokenTypeCost(metrics: SessionMetrics, type: 'input' | 'output' | 'cache_creation' | 'cache_read'): number {
    let totalCost = 0;

    // Calculate cost for each model
    for (const model of Object.values(metrics.models)) {
      const pricing = this.getModelPricing(model.model_id);
      const tokens = model.tokens[type];

      // Calculate cost per million tokens
      const tokensMillion = tokens / 1_000_000;

      switch (type) {
        case 'input':
          totalCost += tokensMillion * pricing.input_rate;
          break;
        case 'output':
          totalCost += tokensMillion * pricing.output_rate;
          break;
        case 'cache_creation':
          totalCost += tokensMillion * pricing.input_rate * pricing.cache_write_mult;
          break;
        case 'cache_read':
          totalCost += tokensMillion * pricing.input_rate * pricing.cache_read_mult;
          break;
      }
    }

    return totalCost;
  }

  private getModelPricing(modelId: string): typeof DEFAULT_PRICING {
    for (const [key, pricing] of Object.entries(MODEL_PRICING)) {
      if (modelId.includes(key)) {
        return pricing;
      }
    }
    return DEFAULT_PRICING;
  }

  private formatTokens(count: number): string {
    if (count >= 1000000) return `${(count / 1000000).toFixed(1)}M`;
    if (count >= 1000) return `${(count / 1000).toFixed(1)}K`;
    return `${Math.round(count)}`;
  }

  private formatNumber(num: number): string {
    return num.toLocaleString('en-US');
  }

  private getTotalTokens(metrics: SessionMetrics): number {
    return metrics.total_tokens.input +
           metrics.total_tokens.output +
           metrics.total_tokens.cache_creation +
           metrics.total_tokens.cache_read;
  }
}
