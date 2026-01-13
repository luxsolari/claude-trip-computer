/**
 * Configuration file handling
 * Version: 0.13.2
 */

import { readFileSync, existsSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';
import type { BillingConfig } from '../types.js';

export function readBillingConfig(): BillingConfig {
  const configPath = join(homedir(), '.claude', 'hooks', '.stats-config');

  if (!existsSync(configPath)) {
    // Fallback defaults
    return {
      billing_mode: 'API',
      billing_icon: '💳',
      safety_margin: 1.0,
    };
  }

  try {
    const content = readFileSync(configPath, 'utf-8');

    // Parse bash-style config
    const billingMode = content.match(/BILLING_MODE="(\w+)"/)?.[1] ?? 'API';
    const billingIcon = content.match(/BILLING_ICON="(.+)"/)?.[1] ?? '💳';
    const safetyMargin = parseFloat(content.match(/SAFETY_MARGIN="([\d.]+)"/)?.[1] ?? '1.0');

    return {
      billing_mode: billingMode as 'API' | 'Sub',
      billing_icon: billingIcon,
      safety_margin: safetyMargin,
    };
  } catch {
    return {
      billing_mode: 'API',
      billing_icon: '💳',
      safety_margin: 1.0,
    };
  }
}
