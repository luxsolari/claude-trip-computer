# Trip Computer - Visual Architecture & Flow Guide

## Quick Reference: The Complete Picture

### The Core Insight
```
🎬 Claude Code Session Data
         ↓
    🔍 Auto-Detection
    (Billing mode, tier)
         ↓
    💾 Persistent Storage
    (sessions.jsonl)
         ↓
    📊 Metric Calculation
    (Tokens, quota, burn rate)
         ↓
    📈 Status Line Display
    (Real-time speedometer)
         ↓
    🧠 Claude Intelligence Layer
    (Patterns, insights, predictions)
         ↓
    📱 /trip-computer Dashboard
    (Detailed analytics & recommendations)
```

---

## Phase 1: Foundation Layer

### What Gets Built
```
INPUT (Session Data from Claude Code)
  ├─ Transcript JSONL file
  ├─ Session ID
  ├─ Message count
  └─ Token usage

↓

DETECTION ENGINE
  ├─ Is this API or Subscription?
  ├─ What tier? (Pro/Max5/Max20)
  ├─ What billing limits apply?
  └─ Did /clear happen?

↓

PERSISTENT STORAGE
  ├─ ~/.claude/session-history/sessions.jsonl
  │  └─ One JSON record per session
  ├─ ~/.claude/session-history/session-index.json
  │  └─ Fast lookup by ID
  └─ ~/.claude/hooks/.stats-config
     └─ Billing mode + tier + preferences

↓

HISTORY AVAILABLE
  ├─ Query past sessions
  ├─ Search by tags
  ├─ Analyze trends
  └─ Enable all future features
```

### Storage Schema (Simplified)
```json
Session Record {
  sessionId: "abc123"
  startTime: "2025-12-19T10:30:00Z"
  billingMode: "Sub"              ← NEW
  billingTier: "Max5x"             ← NEW

  window5h: {                      ← NEW
    tokensUsed: 89000
    tokensRemaining: 131000
    percentOfLimit: 0.40
    timeUntilReset: "4h 37m"
  }

  window7d: {                      ← NEW
    tokensUsed: 450000
    tokensRemaining: 1050000
    percentOfLimit: 0.30
    daysUntilReset: 4
  }

  clearCycles: [                   ← NEW
    { cycle: 1, tokens: 45000, msgs: 12 }
    { cycle: 2, tokens: 31000, msgs: 18 }
    { cycle: 3, tokens: 13000, msgs: 17 }
  ]

  metadata: {                      ← Will be added in Phase 2
    name: "Bug Fix Sprint"
    tags: ["debugging", "auth"]
    notes: "Fixed OAuth..."
  }
}
```

---

## Phase 2: User Empowerment Layer

### Status Line Evolution
```
PHASE 1 (Basic):
💬 47 msgs | 🔧 12 tools | 💳 ~$2.35 | ⚡ 78% eff | 📊 /trip

PHASE 2 (Subscription-Focused):
📅 Max5x: 89K/220K (40%) | ⚡ 2.1K tokens/msg | 🕐 1h 15m until reset | 📊 /trip
```

### What Subscription Users See on Status Line

**Safe Zone** 🟢
```
📅 Pro: 45K/220K (20%) | ⚡ 1.5K tok/msg | 🕐 4h until reset | 📊 /trip
```

**Caution Zone** 🟡
```
📅 Pro: 150K/220K (68%) | ⚡ 2.5K tok/msg | 🕐 1h until reset | 📊 /trip
⚠️ Approaching limit!
```

**Danger Zone** 🔴
```
📅 Pro: 210K/220K (95%) | ⚡ 3.1K tok/msg | 🕐 12m until reset | 📊 /trip
🚨 LIMIT APPROACHING - Consider /clear or switch to Haiku
```

### Dashboard Sections (Phase 2)

```
┌─────────────────────────────────────────┐
│ 📊 QUICK SUMMARY                        │
│ Quota: 89K/220K (40%)                   │
│ Time to limit: 1h 15m                   │
│ Status: ✅ Comfortable                  │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ 📅 QUOTA WINDOWS                        │
│                                         │
│ 5-Hour Window:                          │
│  Used: 89K/220K (40%)                   │
│  Burn rate: 2.1K tokens/msg             │
│  Reset: 4h 37m (3:07 PM)                │
│  Msgs remaining: ~62                    │
│                                         │
│ 7-Day Cap:                              │
│  Used: 450K/1.5M (30%)                  │
│  Projected: 1.05M (70% safe)            │
│  Days left: 4                           │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ 🤖 MODEL MIX                            │
│  Opus:   30K (34%) ████████░░░          │
│  Sonnet: 40K (45%) ██████████░░         │
│  Haiku:  19K (21%) █████░░░░░░░         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ 🎯 SMART QUOTA RECOMMENDATIONS          │
│                                         │
│ 1. Switch to Haiku for auth tests       │
│    → Saves ~1,200 tokens/msg            │
│    → Add 20+ more messages               │
│    → You've done this 4 times            │
│                                         │
│ 2. Trim context by 30%                  │
│    → Your last 3 msgs: 15K input        │
│    → Could trim to 10K                  │
│    → Saves ~150 tokens/msg              │
│                                         │
│ 3. /clear at 75% threshold              │
│    → Still have 1h 15m left             │
│    → Fresh context helps                │
└─────────────────────────────────────────┘
```

---

## Phase 3: Intelligence Layer

### Claude Analyzing Claude

```
Your Session History (23 sessions)
  ↓
Extract: Tags, times, models, efficiency scores
  ↓
Summarize for Claude: Structured feature vectors
  ↓
Call Claude API:
  "Analyze these sessions and find patterns
   about when I'm most efficient and why"
  ↓
Claude Returns:
  - Activity patterns (debugging 35% quota, research 62%)
  - Time patterns (morning 72% eff, afternoon 48%)
  - Model patterns (Haiku for quick tasks)
  - Context patterns (100-150K is sweet spot)
  - Cache patterns (refactoring has 68% cache hits)
  ↓
Parse & Cache (for 24h)
  ↓
Display in /trip-computer with natural language
```

### Dashboard Additions (Phase 3)

```
NEW: 📚 YOUR PATTERNS
└─ Based on Claude's analysis of 23 sessions

Activity Types:
  Debugging (8 sessions)
    • Avg quota: 35% of window
    • Best time: 9-11 AM (27% quota)
    • Best model: Haiku (52% cheaper)
    • Insight: You're 40% more efficient AM!

  Research (6 sessions)
    • Avg quota: 62% of window
    • Duration: 2-4 hours typical
    • Models used: Sonnet + Opus mix
    • Insight: Needs focused time block

Time of Day:
  🏆 9-12 noon:    72% efficiency
  ✅ 12-3 PM:      65% efficiency
  ⚠️  3-6 PM:      48% efficiency
  🟢 6-9 PM:       60% efficiency

Context Size:
  📊 <100K:   65% efficiency (best!)
  📊 100-200K: 58% efficiency
  📊 >200K:   38% efficiency (worse)

Insight: Trim context to under 150K for best results


NEW: 🎯 PERSONALIZED RECOMMENDATIONS
└─ Based on YOUR patterns + current session

For This Debugging Session:
  ✅ Great timing: 10:30 AM is your peak
  ✅ Context: 87K is ideal (vs your 150K baseline)
  💡 Model: Sonnet fine, but Haiku saves 50%

Estimate: At 2.1K tokens/msg, ~30 more messages


NEW: 📝 CLAUDE'S SESSION ANALYSIS
└─ Natural language insights

"You're off to a strong start. Your efficiency
 improved with each /clear cycle - that's
 progress! Your output/input ratio suggests
 you're asking detailed questions. For future
 debugging, try targeting your questions more
 - I bet you'll save 30% quota and maintain
 quality."


NEW: 📈 YOUR LEARNING TRAJECTORY
└─ Month-over-month growth

Nov 2025:
  • Avg efficiency: 62/100
  • Avg quota/session: 47%

Dec 2025 (so far):
  • Avg efficiency: 71/100 ↑ 14%
  • Avg quota/session: 38% ↓ 19%

Grade: A-
"You've learned to trim context effectively.
 Next level: structured prompting for research."
```

---

## Phase 4: Customization & Polish

### Status Line Options

User configures preference:
```bash
# In settings or interactive setup
STATUS_TEMPLATE="subscription"
```

**Subscription-focused users** see:
```
📅 Max5x: 89K/220K (40%) | 🕐 1h 15m until reset | 📊 /trip
```

**API-focused users** see:
```
💬 47 msgs | 💳 $2.35 | ⚡ 78% eff | 📊 /trip
```

**Performance-focused users** see:
```
⭐ 78/100 | 📈 +8 vs baseline | 💾 42% cache | 📊 /trip
```

**Minimalist users** see:
```
📊 89/220 | $2.35 | 📊 /trip
```

### Export Options

```
./session-export.sh SESSION_ID --format [json|csv|markdown]

Output:
  session-2025-12-19.json      ← Programmatic
  session-2025-12-19.csv       ← Spreadsheet
  session-2025-12-19.md        ← Share/archive
```

### Achievement System

```
🏆 ACHIEVEMENTS UNLOCKED

✅ First 100K Session Tokens
✅ 10 Sessions Logged
✅ Cache Champion (50%+ cache hit)
✅ Perfect Morning (78+ eff at 9-12 AM)
✅ Week Under Budget (30% below cap)

🔄 ACTIVE STREAKS
  • Efficiency improving: 7 sessions (↑ 2.5 pts/session)
  • Cache usage: 42% (↑ 8% from start)
```

---

## Real-World User Journeys

### Journey 1: Subscription User (Max5x Plan)

```
9:45 AM - Start Debugging Session
  └─ Status line: 📅 Max5x: 0/220K | 📊 /trip

10:15 AM - 15 min in, 45K tokens used
  └─ Status line: 📅 Max5x: 45K/220K (20%) | ⚡ 1.5K/msg | 🕐 4h 45m | 📊 /trip

11:00 AM - Hit /trip-computer mid-session
  └─ Dashboard shows:
     • 5-hour window: 82K/220K (37%)
     • Recommendations: Switch to Haiku for unit tests
     • Pattern: Your debugging is 35% cheaper in mornings
     • Insight: You're on track, ~62 messages possible

11:30 AM - Follow recommendation, switch to Haiku
  └─ Status line now shows: ⚡ 1.2K/msg (better!)

12:00 PM - 2 hours in, 135K tokens used
  └─ Status line: 📅 Max5x: 135K/220K (61%) | ⚡ 1.35K/msg | 🕐 3h 45m | 📊 /trip

12:15 PM - Getting close to limit, uses /clear strategically
  └─ New cycle starts, limits reset

12:20 PM - After /clear
  └─ Status line: 📅 Max5x: Cycle #2 | 0/220K | 📊 /trip

1:30 PM - Session ends
  └─ Save metadata:
     Name: "Auth Bug Fix"
     Tags: debugging, auth, performance
     Notes: "Fixed token refresh logic, improved error handling"

Next session: Claude has learned this is your pattern
  └─ "Your debugging sessions average 35% quota. Good choices today!"
```

### Journey 2: API User (Cost-Conscious)

```
10:00 AM - Start Feature Implementation
  └─ Status line: 💬 0 msgs | 💳 ~$0.00 | 📊 /trip

11:30 AM - 15 messages later
  └─ Status line: 💬 15 msgs | 💳 ~$1.23 | ⚡ 65% eff | 📊 /trip

1:00 PM - Hit /trip-computer
  └─ Dashboard shows:
     • Cost breakdown: 42% output, 35% input, 18% cache write
     • Model mix: 60% Sonnet, 40% Haiku
     • Recommendation: Cache improvements could save 20%
     • Efficiency: 65/100 (good for feature work)

3:00 PM - Session ends, 45 messages, $3.45 total
  └─ Saves to history with metadata

Weekly review: Claude analyzes patterns
  └─ "Your implementation work averages $0.07/message.
     Research costs 3x more. Plan accordingly for big sprints."
```

---

## The "Trip Computer" Metaphor Explained

Your car's trip computer shows:

```
Status Line = Dashboard Speedometer
├─ Speed (msgs/sec)
├─ Distance (tokens used)
├─ Fuel level (quota remaining)
├─ Efficiency (miles per gallon → tokens/msg)
└─ ETA (time to limit)

/trip-computer = Full Trip Computer Display
├─ Detailed fuel consumption breakdown
├─ Average speed analysis
├─ Route efficiency compared to past trips
├─ Predictive remaining range
├─ Service recommendations
├─ Driving pattern insights
└─ Historical comparison
```

**Your car tells you:** "You're cruising at 60 mph, 10% fuel, ETA 2 hours"

**Trip-computer tells you:** "You're burning 8 gal/hr (vs your 6 gal/hr average),
  highway driving is less efficient than city, fuel range is 2 hours at this pace,
  you're 15% worse than your best drive, consider slower speeds"

---

## Implementation Roadmap Summary

```
WEEK 1-2: Phase 1 Foundation
  □ Auto-detect billing mode/tier
  □ Session storage with persistent records
  □ 5-hour window + 7-day cap tracking
  □ /clear cycle detection
  └─ Result: Sessions survive /clear, history available

WEEK 3-4: Phase 2 Subscription Excellence
  □ Quota burn rate calculation
  □ Smart recommendations (model, context)
  □ Session metadata & tagging
  □ Enhanced dashboard (sub-focused)
  └─ Result: Subs know when they'll hit limits

WEEK 5-7: Phase 3 Claude Analyzing Claude
  □ Claude API integration for pattern detection
  □ Natural language insights generation
  □ Predictive quota warnings
  □ Learning trajectory tracking
  └─ Result: Personalized, intelligent recommendations

WEEK 8-9: Phase 4 Polish & Integration
  □ Status line customization
  □ Export (JSON/CSV/Markdown)
  □ Achievement system
  □ Advanced analytics
  └─ Result: Polished, feature-complete tool
```

---

## Key Files by Phase

### Phase 1
```
~/.claude/session-history/sessions.jsonl      ← Core storage
~/.claude/session-history/session-index.json  ← Fast lookup
~/.claude/hooks/.stats-config                 ← Billing config
~/.claude/hooks/billing-mode-detector.sh      ← Auto-detection
~/.claude/hooks/session-query.sh              ← History API
```

### Phase 2
```
~/.claude/hooks/brief-stats.sh                ← Updated (burn rate)
~/.claude/hooks/show-session-stats.sh         ← Updated (new sections)
~/.claude/hooks/session-metadata.sh           ← Metadata management
```

### Phase 3
```
~/.claude/hooks/pattern-analyzer.sh           ← Claude API calls
~/.claude/hooks/insight-generator.sh          ← Natural language
```

### Phase 4
```
~/.claude/hooks/session-export.sh             ← Export formats
~/.claude/hooks/achievement-tracker.sh        ← Gamification
```
