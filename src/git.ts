/**
 * Git status detection for Claude Trip Computer
 * Version: 0.13.2
 */

import { execSync } from 'child_process';
import type { GitStatus } from './types.js';

/**
 * Get git status for the current working directory
 * Returns null if not a git repo or on error
 */
export function getGitStatus(cwd: string): GitStatus | null {
  try {
    // Get current branch name (500ms timeout)
    const branch = execSync('git rev-parse --abbrev-ref HEAD', {
      cwd,
      encoding: 'utf-8',
      timeout: 500,
      stdio: ['pipe', 'pipe', 'pipe'],
    }).trim();

    // Check for uncommitted changes
    const status = execSync('git status --porcelain', {
      cwd,
      encoding: 'utf-8',
      timeout: 500,
      stdio: ['pipe', 'pipe', 'pipe'],
    }).trim();

    const isDirty = status.length > 0;

    return { branch, isDirty };
  } catch {
    // Not a git repo or git not available
    return null;
  }
}
