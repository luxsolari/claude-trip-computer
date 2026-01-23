/**
 * Transcript parsing
 * Version: 0.13.6
 */

import { readFileSync, existsSync } from 'fs';
import { homedir } from 'os';
import { join, dirname } from 'path';
import { execSync } from 'child_process';
import type { SessionMetrics, TokenUsage, ModelUsage } from './types.js';
import { MODEL_PRICING, DEFAULT_PRICING } from './constants.js';

export class TranscriptParser {
  constructor(private transcriptPath: string) {}

  parse(): SessionMetrics {
    const metrics: SessionMetrics = {
      session_id: this.extractSessionId(),
      message_count: 0,
      tool_count: 0,
      total_tokens: { input: 0, output: 0, cache_creation: 0, cache_read: 0 },
      models: {},
      cache_efficiency: 0,
      tokens_per_message: 0,
      tools_per_message: 0,
      total_cost: 0,
    };

    // Parse main transcript
    this.parseFile(this.transcriptPath, metrics);

    // Find and parse agent transcripts
    const agentPaths = this.findAgentTranscripts();
    for (const agentPath of agentPaths) {
      this.parseFile(agentPath, metrics);
    }

    // Calculate derived metrics
    this.calculateDerivedMetrics(metrics);

    return metrics;
  }

  private parseFile(path: string, metrics: SessionMetrics): void {
    if (!existsSync(path)) {
      return;
    }

    const content = readFileSync(path, 'utf-8');
    const lines = content.trim().split('\n');

    const seenRequests = new Map<string, TokenUsage>();

    for (const line of lines) {
      if (!line.trim()) continue;

      try {
        const entry = JSON.parse(line);

        // Count user messages (main transcript only)
        if (path === this.transcriptPath && entry.type === 'user') {
          const isMeta = entry.isMeta === true;
          const hasToolResults = Array.isArray(entry.message?.content) &&
            entry.message.content.every((c: any) => c.type === 'tool_result');
          const isCommand = typeof entry.message?.content === 'string' &&
            /<command-name>|<command-args>|<local-command-stdout>|<command-message>/.test(entry.message.content);

          if (!isMeta && !hasToolResults && !isCommand) {
            metrics.message_count++;
          }
        }

        // Count tools (main transcript only)
        if (path === this.transcriptPath && entry.type === 'assistant') {
          const content = entry.message?.content;
          if (Array.isArray(content)) {
            const toolUses = content.filter((c: any) => c.type === 'tool_use');
            metrics.tool_count += toolUses.length;
          }
        }

        // Extract token usage
        if (entry.message?.usage && entry.message?.model) {
          const requestId = entry.requestId || '';
          const modelId = entry.message.model;
          const usage = entry.message.usage;

          // Create unique key for deduplication: requestId + modelId
          const dedupKey = `${requestId}|${modelId}`;

          // Track per-request for deduplication
          if (!seenRequests.has(dedupKey)) {
            seenRequests.set(dedupKey, {
              input: 0,
              output: 0,
              cache_creation: 0,
              cache_read: 0,
            });
          }

          const reqUsage = seenRequests.get(dedupKey)!;
          reqUsage.input = Math.max(reqUsage.input, usage.input_tokens ?? 0);
          reqUsage.output = Math.max(reqUsage.output, usage.output_tokens ?? 0);
          reqUsage.cache_creation = Math.max(reqUsage.cache_creation, usage.cache_creation_input_tokens ?? 0);
          reqUsage.cache_read = Math.max(reqUsage.cache_read, usage.cache_read_input_tokens ?? 0);

          // Track per-model
          if (!metrics.models[modelId]) {
            metrics.models[modelId] = {
              model_id: modelId,
              display_name: this.formatModelName(modelId),
              requests: 0,
              tokens: { input: 0, output: 0, cache_creation: 0, cache_read: 0 },
              cost: 0,
            };
          }
        }
      } catch {
        // Skip invalid lines
      }
    }

    // Deduplicate and aggregate tokens
    for (const [dedupKey, usage] of seenRequests) {
      // Extract modelId from dedupKey (format: "requestId|modelId")
      const modelId = dedupKey.split('|')[1];

      // Aggregate into total tokens
      metrics.total_tokens.input += usage.input;
      metrics.total_tokens.output += usage.output;
      metrics.total_tokens.cache_creation += usage.cache_creation;
      metrics.total_tokens.cache_read += usage.cache_read;

      // Aggregate into per-model tokens
      if (metrics.models[modelId]) {
        metrics.models[modelId].tokens.input += usage.input;
        metrics.models[modelId].tokens.output += usage.output;
        metrics.models[modelId].tokens.cache_creation += usage.cache_creation;
        metrics.models[modelId].tokens.cache_read += usage.cache_read;
        metrics.models[modelId].requests++;
      }
    }
  }

  private findAgentTranscripts(): string[] {
    if (!existsSync(this.transcriptPath)) {
      return [];
    }

    try {
      const content = readFileSync(this.transcriptPath, 'utf-8');
      const agentIds = new Set<string>();

      // Extract agent IDs
      const matches = content.matchAll(/agent-[a-z0-9]+/g);
      for (const match of matches) {
        agentIds.add(match[0]);
      }

      // Find agent files across all project directories
      const projectsDir = join(homedir(), '.claude', 'projects');
      const agentPaths: string[] = [];

      // Sort agent IDs for deterministic processing order
      const sortedAgentIds = Array.from(agentIds).sort();

      for (const agentId of sortedAgentIds) {
        try {
          // Sort find results for determinism before taking first match
          const result = execSync(
            `find "${projectsDir}" -name "${agentId}.jsonl" 2>/dev/null | sort | head -1`,
            { encoding: 'utf-8' }
          );
          const path = result.trim();
          if (path && existsSync(path)) {
            agentPaths.push(path);
          }
        } catch {
          // Skip if find fails
        }
      }

      // Return paths in sorted order for deterministic processing
      return agentPaths.sort();
    } catch {
      return [];
    }
  }

  private calculateDerivedMetrics(metrics: SessionMetrics): void {
    // Cache efficiency
    const totalCache = metrics.total_tokens.cache_creation + metrics.total_tokens.cache_read;
    if (totalCache > 0) {
      metrics.cache_efficiency = (metrics.total_tokens.cache_read / totalCache) * 100;
    }

    // Tokens per message
    if (metrics.message_count > 0) {
      metrics.tokens_per_message = metrics.total_tokens.output / metrics.message_count;
    }

    // Tools per message
    if (metrics.message_count > 0) {
      metrics.tools_per_message = metrics.tool_count / metrics.message_count;
    }

    // Calculate total cost
    metrics.total_cost = this.calculateCost(metrics);
  }

  private calculateCost(metrics: SessionMetrics): number {
    let totalCost = 0;

    for (const model of Object.values(metrics.models)) {
      const pricing = this.getModelPricing(model.model_id);

      const inputCost = (model.tokens.input * pricing.input_rate) / 1000000;
      const outputCost = (model.tokens.output * pricing.output_rate) / 1000000;
      const cacheWriteCost = (model.tokens.cache_creation * pricing.input_rate * pricing.cache_write_mult) / 1000000;
      const cacheReadCost = (model.tokens.cache_read * pricing.input_rate * pricing.cache_read_mult) / 1000000;

      model.cost = inputCost + outputCost + cacheWriteCost + cacheReadCost;
      totalCost += model.cost;
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

  private formatModelName(modelId: string): string {
    if (modelId.includes('opus-4-5') || modelId.includes('opus-4.5')) return 'Opus 4.5';
    if (modelId.includes('opus-4')) return 'Opus 4';
    if (modelId.includes('opus')) return 'Opus';
    if (modelId.includes('sonnet-4-5') || modelId.includes('sonnet-4.5')) return 'Sonnet 4.5';
    if (modelId.includes('sonnet-4')) return 'Sonnet 4';
    if (modelId.includes('sonnet-3-7') || modelId.includes('sonnet-3.7')) return 'Sonnet 3.7';
    if (modelId.includes('sonnet')) return 'Sonnet';
    if (modelId.includes('haiku-4-5') || modelId.includes('haiku-4.5')) return 'Haiku 4.5';
    if (modelId.includes('haiku-3-5') || modelId.includes('haiku-3.5')) return 'Haiku 3.5';
    if (modelId.includes('haiku')) return 'Haiku';
    return modelId;
  }

  private extractSessionId(): string {
    const filename = this.transcriptPath.split('/').pop() ?? '';
    return filename.replace('.jsonl', '');
  }
}
