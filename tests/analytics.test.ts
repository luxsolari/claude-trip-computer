/**
 * Unit tests for AnalyticsComputer
 */

import { describe, it, expect } from 'vitest';
import { AnalyticsComputer } from '../src/analytics.js';
import type { SessionMetrics, ContextWindow, BillingConfig } from '../src/types.js';

const API_CONFIG: BillingConfig = {
  billing_mode: 'API',
  billing_icon: '💳',
  safety_margin: 1.0,
};

const SUB_CONFIG: BillingConfig = {
  billing_mode: 'Sub',
  billing_icon: '📅',
  safety_margin: 1.1,
};

const createMockMetrics = (overrides?: Partial<SessionMetrics>): SessionMetrics => ({
  session_id: 'test-session',
  message_count: 10,
  tool_count: 50,
  total_tokens: {
    input: 10000,
    output: 5000,
    cache_creation: 1000,
    cache_read: 9000,
  },
  models: {
    'claude-sonnet-4-5': {
      model_id: 'claude-sonnet-4-5',
      display_name: 'Sonnet 4.5',
      requests: 10,
      tokens: {
        input: 10000,
        output: 5000,
        cache_creation: 1000,
        cache_read: 9000,
      },
      cost: 0.15,
    },
  },
  cache_efficiency: 90,
  tokens_per_message: 500,
  tools_per_message: 5,
  total_cost: 0.15,
  ...overrides,
});

describe('AnalyticsComputer', () => {
  describe('Health Score Calculation', () => {
    it('should calculate excellent health (90-100)', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const metrics = createMockMetrics({
        cache_efficiency: 95, // 40 points
        tokens_per_message: 5000, // 30 points (efficient)
        tools_per_message: 10, // 30 points
      });
      const context: ContextWindow = {
        size: 200000,
        usage: 100000,
        usage_percent: 50, // 30 points
        health_status: 'healthy',
      };

      const analytics = computer.compute(metrics, context);

      expect(analytics.health_score).toBeGreaterThanOrEqual(90);
      expect(analytics.health_label).toContain('⭐⭐⭐⭐⭐');
    });

    it('should calculate good health (75-89)', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const metrics = createMockMetrics({
        cache_efficiency: 75, // 30 points (70-89 range)
        tokens_per_message: 10000, // Moderate verbosity
        tools_per_message: 3, // Lower tool count
      });
      const context: ContextWindow = {
        size: 200000,
        usage: 150000,
        usage_percent: 75, // 20 points (70-84 range)
        health_status: 'warning',
      };

      const analytics = computer.compute(metrics, context);

      // 30 (cache) + 20 (context) + 30 (efficiency) = 80 points
      expect(analytics.health_score).toBeGreaterThanOrEqual(75);
      expect(analytics.health_score).toBeLessThan(90);
      expect(analytics.health_label).toContain('⭐⭐⭐⭐');
    });

    it('should calculate fair health (60-74)', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const metrics = createMockMetrics({
        cache_efficiency: 65, // 20 points
        tokens_per_message: 10000,
        tools_per_message: 5,
      });
      const context: ContextWindow = {
        size: 200000,
        usage: 150000,
        usage_percent: 75,
        health_status: 'warning',
      };

      const analytics = computer.compute(metrics, context);

      expect(analytics.health_score).toBeGreaterThanOrEqual(60);
      expect(analytics.health_score).toBeLessThan(75);
      expect(analytics.health_label).toContain('⭐⭐⭐');
    });

    it('should calculate poor health (40-59)', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const metrics = createMockMetrics({
        cache_efficiency: 45, // 10 points
        tokens_per_message: 20000,
        tools_per_message: 2,
      });
      const context: ContextWindow = {
        size: 200000,
        usage: 180000,
        usage_percent: 90,
        health_status: 'critical',
      };

      const analytics = computer.compute(metrics, context);

      expect(analytics.health_score).toBeGreaterThanOrEqual(40);
      expect(analytics.health_score).toBeLessThan(60);
      expect(analytics.health_label).toContain('⭐⭐');
    });
  });

  describe('Cache Score', () => {
    it('should give 40 points for >= 90% efficiency', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const metrics = createMockMetrics({ cache_efficiency: 95 });
      const analytics = computer.compute(metrics, null);

      expect(analytics.cache_score).toBe(40);
    });

    it('should give 30 points for 70-89% efficiency', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const metrics = createMockMetrics({ cache_efficiency: 75 });
      const analytics = computer.compute(metrics, null);

      expect(analytics.cache_score).toBe(30);
    });

    it('should give 20 points for 50-69% efficiency', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const metrics = createMockMetrics({ cache_efficiency: 60 });
      const analytics = computer.compute(metrics, null);

      expect(analytics.cache_score).toBe(20);
    });

    it('should give 10 points for < 50% efficiency', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const metrics = createMockMetrics({ cache_efficiency: 30 });
      const analytics = computer.compute(metrics, null);

      expect(analytics.cache_score).toBe(10);
    });
  });

  describe('Context Score', () => {
    it('should give 30 points for < 70% usage', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const context: ContextWindow = {
        size: 200000,
        usage: 100000,
        usage_percent: 50,
        health_status: 'healthy',
      };
      const analytics = computer.compute(createMockMetrics(), context);

      expect(analytics.context_score).toBe(30);
    });

    it('should give 20 points for 70-84% usage', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const context: ContextWindow = {
        size: 200000,
        usage: 150000,
        usage_percent: 75,
        health_status: 'warning',
      };
      const analytics = computer.compute(createMockMetrics(), context);

      expect(analytics.context_score).toBe(20);
    });

    it('should give 10 points for >= 85% usage', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const context: ContextWindow = {
        size: 200000,
        usage: 180000,
        usage_percent: 90,
        health_status: 'critical',
      };
      const analytics = computer.compute(createMockMetrics(), context);

      expect(analytics.context_score).toBe(10);
    });

    it('should give 15 points (neutral) when context unavailable', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const analytics = computer.compute(createMockMetrics(), null);

      expect(analytics.context_score).toBe(15);
    });
  });

  describe('Optimization Actions', () => {
    it('should recommend brevity for high verbosity + low tools', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const metrics = createMockMetrics({
        tokens_per_message: 16000, // High verbosity
        tools_per_message: 5, // Low tool intensity
        message_count: 10,
        total_cost: 0.50,
      });
      const analytics = computer.compute(metrics, null);

      const brevityAction = analytics.optimization_actions.find(a =>
        a.action.includes('brevity')
      );
      expect(brevityAction).toBeDefined();
      expect(brevityAction?.priority).toBe(25);
    });

    it('should recommend cache rebuild for low efficiency', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const metrics = createMockMetrics({
        cache_efficiency: 60, // Low cache efficiency
        message_count: 10,
        total_cost: 0.50,
      });
      const analytics = computer.compute(metrics, null);

      const cacheAction = analytics.optimization_actions.find(a =>
        a.action.includes('cache')
      );
      expect(cacheAction).toBeDefined();
      expect(cacheAction?.priority).toBe(20);
    });

    it('should recommend workflow review for high tools + many messages', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const metrics = createMockMetrics({
        tools_per_message: 35, // Very high tool intensity
        message_count: 15, // Many messages
      });
      const analytics = computer.compute(metrics, null);

      const workflowAction = analytics.optimization_actions.find(a =>
        a.action.includes('simplified')
      );
      expect(workflowAction).toBeDefined();
      expect(workflowAction?.priority).toBe(15);
    });

    it('should sort actions by priority (descending)', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const metrics = createMockMetrics({
        tokens_per_message: 16000,
        tools_per_message: 5,
        cache_efficiency: 60,
        message_count: 10,
        total_cost: 0.50,
      });
      const analytics = computer.compute(metrics, null);

      const priorities = analytics.optimization_actions.map(a => a.priority);
      const sortedPriorities = [...priorities].sort((a, b) => b - a);

      expect(priorities).toEqual(sortedPriorities);
    });
  });

  describe('Billing Mode Impact on Actions', () => {
    it('should show cost savings for Subscription users', () => {
      const computer = new AnalyticsComputer(SUB_CONFIG);
      const metrics = createMockMetrics({
        tokens_per_message: 16000,
        tools_per_message: 5,
        message_count: 10,
        total_cost: 0.50,
      });
      const analytics = computer.compute(metrics, null);

      const brevityAction = analytics.optimization_actions.find(a =>
        a.action.includes('brevity')
      );
      expect(brevityAction?.impact).toContain('$');
      expect(brevityAction?.impact).toContain('Save');
    });

    it('should show efficiency gains for API users', () => {
      const computer = new AnalyticsComputer(API_CONFIG);
      const metrics = createMockMetrics({
        tokens_per_message: 16000,
        tools_per_message: 5,
        message_count: 10,
        total_cost: 0.50,
      });
      const analytics = computer.compute(metrics, null);

      const brevityAction = analytics.optimization_actions.find(a =>
        a.action.includes('brevity')
      );
      expect(brevityAction?.impact).toContain('efficiency');
      expect(brevityAction?.impact).not.toContain('$');
    });

    it('should apply safety margin to Subscription cost estimates', () => {
      const subComputer = new AnalyticsComputer(SUB_CONFIG);
      const apiComputer = new AnalyticsComputer(API_CONFIG);

      const metrics = createMockMetrics({
        tokens_per_message: 16000,
        tools_per_message: 5,
        message_count: 10,
        total_cost: 1.00, // $1.00 total cost
      });

      const subAnalytics = subComputer.compute(metrics, null);
      const apiAnalytics = apiComputer.compute(metrics, null);

      // Sub should have 1.1x safety margin vs API's 1.0x
      const subAction = subAnalytics.optimization_actions.find(a => a.action.includes('brevity'));
      const apiAction = apiAnalytics.optimization_actions.find(a => a.action.includes('brevity'));

      // Both should exist but with different impacts
      expect(subAction).toBeDefined();
      expect(apiAction).toBeDefined();
    });
  });

  describe('Guidance Labels', () => {
    it('should provide appropriate tool intensity labels', () => {
      const computer = new AnalyticsComputer(API_CONFIG);

      const veryIntensive = createMockMetrics({
        tool_count: 300,
        tools_per_message: 20,
        message_count: 15,
      });
      expect(computer.compute(veryIntensive, null).tool_intensity_label)
        .toContain('Very intensive');

      const moderate = createMockMetrics({
        tool_count: 120,
        tools_per_message: 6,
        message_count: 20,
      });
      expect(computer.compute(moderate, null).tool_intensity_label)
        .toContain('Moderate');

      const minimal = createMockMetrics({
        tool_count: 5,
        tools_per_message: 1,
        message_count: 5,
      });
      expect(computer.compute(minimal, null).tool_intensity_label)
        .toContain('Minimal');
    });

    it('should provide appropriate verbosity labels', () => {
      const computer = new AnalyticsComputer(API_CONFIG);

      const high = createMockMetrics({ tokens_per_message: 16000 });
      expect(computer.compute(high, null).verbosity_label).toContain('High');

      const moderate = createMockMetrics({ tokens_per_message: 10000 });
      expect(computer.compute(moderate, null).verbosity_label).toContain('Moderate');

      const concise = createMockMetrics({ tokens_per_message: 3000 });
      expect(computer.compute(concise, null).verbosity_label).toContain('Concise');
    });

    it('should provide appropriate cache guidance', () => {
      const computer = new AnalyticsComputer(API_CONFIG);

      const excellent = createMockMetrics({ cache_efficiency: 95 });
      expect(computer.compute(excellent, null).cache_guidance).toContain('Excellent');

      const good = createMockMetrics({ cache_efficiency: 75 });
      expect(computer.compute(good, null).cache_guidance).toContain('Good');

      const low = createMockMetrics({ cache_efficiency: 40 });
      expect(computer.compute(low, null).cache_guidance).toContain('Low');
    });
  });
});
