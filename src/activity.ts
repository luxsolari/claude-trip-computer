/**
 * Activity parsing from transcript
 * Version: 0.13.6
 * Extracts tool usage, agent status, and todo progress from transcript
 */

import { readFileSync, existsSync } from 'fs';
import type { ActivityData, ToolEntry, AgentEntry, TodoItem } from './types.js';

/**
 * Extract target from tool input based on tool name
 */
function extractTarget(toolName: string, input?: Record<string, unknown>): string | undefined {
  if (!input) return undefined;

  switch (toolName) {
    case 'Read':
    case 'Write':
    case 'Edit':
    case 'NotebookEdit':
      return (input.file_path as string) ?? (input.path as string) ?? (input.notebook_path as string);
    case 'Glob':
    case 'Grep':
      return input.pattern as string;
    case 'Bash':
      const cmd = input.command as string;
      if (!cmd) return undefined;
      return cmd.length > 30 ? cmd.slice(0, 30) + '...' : cmd;
    case 'WebFetch':
    case 'WebSearch':
      return (input.url as string) ?? (input.query as string);
    case 'LSP':
      return input.operation as string;
    default:
      return undefined;
  }
}

/**
 * Parse transcript file for activity data
 */
export function parseActivity(transcriptPath: string): ActivityData {
  const activity: ActivityData = {
    runningTools: [],
    toolCounts: new Map<string, number>(),
    agents: [],
    todos: [],
    session_start: undefined,
  };

  if (!existsSync(transcriptPath)) {
    return activity;
  }

  try {
    const content = readFileSync(transcriptPath, 'utf-8');
    const lines = content.trim().split('\n');

    // Maps for tracking tools/agents by ID
    const toolMap = new Map<string, ToolEntry>();
    const agentMap = new Map<string, AgentEntry>();

    for (const line of lines) {
      if (!line.trim()) continue;

      try {
        const entry = JSON.parse(line);

        // Extract timestamp from various locations in the entry
        let timestamp: number | undefined;
        if (entry.timestamp) {
          timestamp = new Date(entry.timestamp).getTime();
        } else if (entry.snapshot?.timestamp) {
          timestamp = new Date(entry.snapshot.timestamp).getTime();
        } else if (entry.message?.timestamp) {
          timestamp = new Date(entry.message.timestamp).getTime();
        }

        // Track first valid timestamp as session start
        if (timestamp && !activity.session_start) {
          activity.session_start = timestamp;
        }

        // Use current time if no timestamp found
        if (!timestamp) {
          timestamp = Date.now();
        }

        // Process assistant messages for tool_use blocks
        if (entry.type === 'assistant' && entry.message?.content) {
          const content = entry.message.content;
          if (!Array.isArray(content)) continue;

          for (const block of content) {
            if (block.type === 'tool_use') {
              const toolId = block.id;
              const toolName = block.name;
              const input = block.input as Record<string, unknown> | undefined;

              // Special handling for Task (agents)
              if (toolName === 'Task') {
                const agentEntry: AgentEntry = {
                  id: toolId,
                  type: (input?.subagent_type as string) ?? 'unknown',
                  description: (input?.description as string) ?? undefined,
                  status: 'running',
                  startTime: timestamp,
                };
                agentMap.set(toolId, agentEntry);
                continue;
              }

              // Special handling for TodoWrite
              if (toolName === 'TodoWrite') {
                const todos = input?.todos;
                if (Array.isArray(todos)) {
                  // Replace with latest todos
                  activity.todos = todos.map((t: any) => ({
                    content: t.content ?? '',
                    status: t.status ?? 'pending',
                  }));
                }
                continue;
              }

              // Regular tool
              const toolEntry: ToolEntry = {
                id: toolId,
                name: toolName,
                target: extractTarget(toolName, input),
                status: 'running',
                startTime: timestamp,
              };
              toolMap.set(toolId, toolEntry);
            }

            // Process tool_result blocks to mark tools as completed
            if (block.type === 'tool_result') {
              const toolId = block.tool_use_id;
              const isError = block.is_error === true;

              // Check if it's an agent
              if (agentMap.has(toolId)) {
                const agent = agentMap.get(toolId)!;
                agent.status = 'completed';
                agent.endTime = timestamp;
              }

              // Check if it's a tool
              if (toolMap.has(toolId)) {
                const tool = toolMap.get(toolId)!;
                tool.status = isError ? 'error' : 'completed';
                tool.endTime = timestamp;
              }
            }
          }
        }

        // Also check user messages for tool_result blocks
        if (entry.type === 'user' && entry.message?.content) {
          const content = entry.message.content;
          if (!Array.isArray(content)) continue;

          for (const block of content) {
            if (block.type === 'tool_result') {
              const toolId = block.tool_use_id;
              const isError = block.is_error === true;

              if (agentMap.has(toolId)) {
                const agent = agentMap.get(toolId)!;
                agent.status = 'completed';
                agent.endTime = timestamp;
              }

              if (toolMap.has(toolId)) {
                const tool = toolMap.get(toolId)!;
                tool.status = isError ? 'error' : 'completed';
                tool.endTime = timestamp;
              }
            }
          }
        }
      } catch {
        // Skip invalid lines
      }
    }

    // Separate running tools and aggregate completed tool counts
    for (const tool of toolMap.values()) {
      if (tool.status === 'running') {
        activity.runningTools.push(tool);
      } else {
        // Aggregate completed/error tools by name
        const count = activity.toolCounts.get(tool.name) ?? 0;
        activity.toolCounts.set(tool.name, count + 1);
      }
    }

    // Keep only last 2 running tools for display
    activity.runningTools = activity.runningTools.slice(-2);

    // Keep only recent agents
    activity.agents = Array.from(agentMap.values()).slice(-10);

  } catch {
    // Return empty activity on error
  }

  return activity;
}
