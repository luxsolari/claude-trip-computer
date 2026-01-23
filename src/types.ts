/**
 * Type definitions for Claude Trip Computer
 * Version: 0.13.6
 */

export interface StdinData {
  session_id?: string;  // Note: snake_case from Claude Code
  transcript_path?: string;
  cwd?: string;
  model?: {
    id?: string;
    display_name?: string;
  };
  context_window?: {
    context_window_size?: number;
    total_input_tokens?: number;   // Total context usage - USE THIS for context %
    total_output_tokens?: number;
    current_usage?: {
      input_tokens?: number;       // Per-request: new input tokens
      output_tokens?: number;      // Per-request: output tokens
      cache_creation_input_tokens?: number;  // Per-request: tokens written to cache
      cache_read_input_tokens?: number;      // Per-request: tokens read from cache
    };
  };
}

// Git status for branch display
export interface GitStatus {
  branch: string;
  isDirty: boolean;
}

// Tool activity tracking
export interface ToolEntry {
  id: string;
  name: string;
  target?: string;
  status: 'running' | 'completed' | 'error';
  startTime: number;
  endTime?: number;
}

// Agent (subagent) tracking
export interface AgentEntry {
  id: string;
  type: string;
  description?: string;
  status: 'running' | 'completed';
  startTime: number;
  endTime?: number;
}

// Todo item from TodoWrite
export interface TodoItem {
  content: string;
  status: 'pending' | 'in_progress' | 'completed';
}

// Activity data parsed from transcript
export interface ActivityData {
  runningTools: ToolEntry[];         // Running tools only (for spinner display)
  toolCounts: Map<string, number>;   // Aggregated counts of ALL completed tools
  agents: AgentEntry[];
  todos: TodoItem[];
  session_start?: number;
}

export interface TokenUsage {
  input: number;
  output: number;
  cache_creation: number;
  cache_read: number;
}

export interface ModelUsage {
  model_id: string;
  display_name: string;
  requests: number;
  tokens: TokenUsage;
  cost: number;
}

export interface ContextWindow {
  size: number;
  usage: number;
  usage_percent: number;
  health_status: 'healthy' | 'warning' | 'critical';
}

export interface SessionMetrics {
  session_id: string;
  message_count: number;
  tool_count: number;
  total_tokens: TokenUsage;
  models: Record<string, ModelUsage>;
  context_window?: ContextWindow;
  cache_efficiency: number;
  tokens_per_message: number;
  tools_per_message: number;
  total_cost: number;
}

export interface RateLimits {
  plan_name: string | null;
  five_hour_percent: number | null;
  seven_day_percent: number | null;
  five_hour_reset_at: Date | null;
  seven_day_reset_at: Date | null;
  api_unavailable: boolean;
}

export interface OptimizationAction {
  action: string;
  impact: string;
  priority: number;
}

export interface SessionAnalytics {
  health_score: number;
  health_label: string;
  cache_score: number;
  context_score: number;
  efficiency_score: number;
  tool_intensity_label: string;
  verbosity_label: string;
  context_growth_label: string;
  cache_guidance: string;
  optimization_actions: OptimizationAction[];
  behavioral_analysis: string[];  // Deep AI introspection
}

export interface SessionCache {
  version: string;
  session_id: string;
  last_updated: number;
  transcript_mtime: number;
  transcript_path: string;
  metrics: SessionMetrics;
  context_window?: ContextWindow;  // From stdin
  model_name?: string;  // From stdin
  analytics: SessionAnalytics;  // Pre-computed intelligence
  rate_limits?: RateLimits;  // Cached rate limits
}

export interface BillingConfig {
  billing_mode: 'API' | 'Sub';
  billing_icon: string;
  safety_margin: number;
}
