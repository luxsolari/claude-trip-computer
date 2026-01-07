# Trip Computer Architecture Diagram

## System Architecture - How It All Works Together

```mermaid
graph TB
    subgraph Input["🎬 INPUT: Claude Code Session"]
        Transcript["Transcript<br/>Session Data"]
        Status["Session Status<br/>Model, Messages, Tokens"]
    end

    subgraph Detection["🔍 AUTO-DETECTION LAYER"]
        BillingDetect["Billing Mode<br/>Detector<br/>(API vs Sub)"]
        TierDetect["Subscription Tier<br/>Detector<br/>(Pro/Max5/Max20)"]
        WindowDetect["/clear Cycle<br/>Detector"]
    end

    subgraph Storage["💾 PERSISTENT STORAGE"]
        Sessions["sessions.jsonl<br/>(All sessions)"]
        Index["session-index.json<br/>(Fast lookup)"]
        Config[".stats-config<br/>(Billing + Prefs)"]
    end

    subgraph Metrics["📊 METRIC CALCULATION"]
        TokenMath["Token Counting<br/>& Dedup"]
        QuotaMath["Quota Math<br/>(5h + 7d)"]
        BurnRate["Burn Rate<br/>Calculations"]
        Health["Health Scoring<br/>& Efficiency"]
    end

    subgraph StatusLine["📈 STATUS LINE GENERATOR"]
        Template["Template<br/>Selection"]
        Format["Dynamic<br/>Formatting"]
        Render["Real-time<br/>Rendering"]
    end

    subgraph Intelligence["🧠 INTELLIGENCE LAYER"]
        PatternDetect["Pattern Detection<br/>(Claude API)"]
        Insights["Insight Generation<br/>(Claude API)"]
        Predict["Predictive Analysis<br/>(Claude API)"]
    end

    subgraph Dashboard["📱 TRIP COMPUTER DASHBOARD"]
        DashQuick["Quick Summary<br/>Widget"]
        DashQuota["Quota Windows<br/>Widget"]
        DashModel["Model Mix<br/>Widget"]
        DashRecs["Smart Recs<br/>Widget"]
        DashPatterns["Patterns & Learning<br/>Widget"]
    end

    subgraph Export["📤 EXPORT & SHARING"]
        ExportJSON["Export JSON"]
        ExportCSV["Export CSV"]
        ExportMD["Export Markdown"]
        Share["Share Link<br/>Generator"]
    end

    Input --> Detection
    Detection --> Storage

    Input --> Metrics
    Storage --> Metrics

    Metrics --> StatusLine
    Metrics --> Dashboard
    Storage --> Dashboard

    Storage --> Intelligence
    Metrics --> Intelligence
    Intelligence --> Dashboard

    Dashboard --> Export

    Render -.->|Live Updates| StatusLine
    Config -.->|User Preferences| Template

    style Input fill:#bbdefb,stroke:#1565c0,stroke-width:2px
    style Detection fill:#c8e6c9,stroke:#1b5e20,stroke-width:2px
    style Storage fill:#ffe0b2,stroke:#e65100,stroke-width:2px
    style Metrics fill:#f8bbd0,stroke:#880e4f,stroke-width:2px
    style StatusLine fill:#d1c4e9,stroke:#3f51b5,stroke-width:2px
    style Intelligence fill:#c5e1a5,stroke:#558b2f,stroke-width:2px
    style Dashboard fill:#b2dfdb,stroke:#004d40,stroke-width:2px
    style Export fill:#ffccbc,stroke:#bf360c,stroke-width:2px
```

## Data Flow - From Session to Insights

```mermaid
graph LR
    Session["🎬 Claude Code<br/>Session"]

    Transcript["📄 Transcript<br/>JSONL"]

    Parse["Parse Tokens<br/>& Messages"]

    Store["Store in<br/>sessions.jsonl"]

    Calc["Calculate<br/>Metrics"]

    Display["Display on<br/>Status Line"]

    Command["/trip-computer<br/>Command"]

    Analyze["Claude Analyzes<br/>Patterns"]

    Dashboard["🖥️ Show<br/>Dashboard"]

    Session --> Transcript
    Transcript --> Parse
    Parse --> Store
    Store --> Calc
    Calc --> Display
    Calc --> Command
    Command --> Analyze
    Analyze --> Dashboard

    style Session fill:#bbdefb
    style Transcript fill:#e3f2fd
    style Parse fill:#f8bbd0
    style Store fill:#ffe0b2
    style Calc fill:#c8e6c9
    style Display fill:#d1c4e9
    style Command fill:#c5e1a5
    style Analyze fill:#b2dfdb
    style Dashboard fill:#ffccbc
```

## Status Line Evolution Across Phases

```mermaid
graph TB
    subgraph Phase1["Phase 1: Foundation"]
        SL1["💬 47 msgs | 🔧 12 tools<br/>💳 ~$2.35 | ⚡ 78% eff | 📊 /trip<br/><br/>(Basic metrics, no billing context)"]
    end

    subgraph Phase2["Phase 2: Subscription Excellence"]
        SL2["📅 Pro: 89K/220K (40%)<br/>⚡ 2.1K tokens/msg | 🕐 1h 15m until reset<br/>📊 /trip<br/><br/>(Quota-focused, burn rate visible)"]
    end

    subgraph Phase3["Phase 3: Claude Analyzing Claude"]
        SL3["📅 Pro: 89K (40%) | ↑+8 vs baseline<br/>⚡ 78/100 | 💾 42% cache | 📊 /trip<br/><br/>(Personalized, trended, analyzed)"]
    end

    subgraph Phase4["Phase 4: Customizable"]
        SL4A["📅 Pro: 89K/220K (40%) | 🕐 1h 15m | 📊 /trip<br/>(Subscription mode - custom choice)"]
        SL4B["💬 47 | 💳 $2.35 | ⚡ 42% cache | 📊 /trip<br/>(API mode - custom choice)"]
        SL4C["⭐ 78/100 | 📈 +8 vs baseline | 💾 42% | 📊 /trip<br/>(Performance mode - custom choice)"]
    end

    Phase1 --> Phase2
    Phase2 --> Phase3
    Phase3 --> Phase4

    style Phase1 fill:#e1f5ff,stroke:#01579b
    style Phase2 fill:#f3e5f5,stroke:#4a148c
    style Phase3 fill:#e8f5e9,stroke:#1b5e20
    style Phase4 fill:#fff3e0,stroke:#e65100
```

## Dashboard Widget Layout - /trip-computer Command

```mermaid
graph TB
    DashHeader["📊 QUICK SUMMARY<br/>Quota: 89K/220K (40%) | Time to limit: 1h 15m | Cycles: 3"]

    subgraph Windows["📅 QUOTA WINDOWS"]
        W5H["5-Hour: 89K/220K (40%)<br/>Burn: 2.1K/msg | Reset: 4h 37m"]
        W7D["7-Day: 450K/1.5M (30%)<br/>Avg: 150K/day | Days left: 4"]
    end

    subgraph Models["🤖 MODEL MIX"]
        MOpus["Opus: 30K (34%)"]
        MSonnet["Sonnet: 40K (45%)"]
        MHaiku["Haiku: 19K (21%)"]
    end

    subgraph Recs["🎯 SMART RECOMMENDATIONS"]
        R1["1. Switch Haiku for tests"]
        R2["2. Trim context by 30%"]
        R3["3. /clear at 75% threshold"]
    end

    subgraph Patterns["📚 YOUR PATTERNS"]
        Pat1["Best time: 9-12 AM (72% eff)"]
        Pat2["Haiku saves 50% quota"]
        Pat3["Research costs 3x more"]
    end

    subgraph Insights["📝 CLAUDE'S ANALYSIS"]
        Ins1["You're off to strong start"]
        Ins2["Context trimming improving"]
        Ins3["At this pace: 60 msgs remaining"]
    end

    DashHeader --> Windows
    Windows --> Models
    Models --> Recs
    Recs --> Patterns
    Patterns --> Insights

    style DashHeader fill:#b2dfdb,stroke:#00695c,stroke-width:2px
    style Windows fill:#c5e1a5,stroke:#558b2f,stroke-width:2px
    style Models fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style Recs fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    style Patterns fill:#f8bbd0,stroke:#c2185b,stroke-width:2px
    style Insights fill:#d1c4e9,stroke:#512da8,stroke-width:2px
```

## Core Feature Components by Phase

```mermaid
graph LR
    subgraph Phase1["Phase 1"]
        P1_Storage["Storage"]
        P1_Detect["Detection"]
        P1_Track["Tracking"]
        P1_API["Query API"]
    end

    subgraph Phase2["Phase 2"]
        P2_Burn["Burn Rate"]
        P2_Recs["Recommendations"]
        P2_Meta["Metadata"]
        P2_Dash["Dashboard v1"]
    end

    subgraph Phase3["Phase 3"]
        P3_Pattern["Patterns"]
        P3_Insight["Insights"]
        P3_Predict["Predictions"]
        P3_Dash["Dashboard v2"]
    end

    subgraph Phase4["Phase 4"]
        P4_Custom["Customization"]
        P4_Export["Export"]
        P4_Achieve["Achievements"]
        P4_Dash["Dashboard v3"]
    end

    P1_Storage --> P2_Burn
    P1_Detect --> P2_Recs
    P1_Track --> P3_Pattern
    P1_API --> P3_Insight

    P2_Burn --> P3_Predict
    P2_Recs --> P3_Insight
    P2_Meta --> P3_Pattern
    P2_Dash --> P3_Dash

    P3_Pattern --> P4_Custom
    P3_Insight --> P4_Export
    P3_Predict --> P4_Achieve
    P3_Dash --> P4_Dash

    style Phase1 fill:#e1f5ff,stroke:#01579b
    style Phase2 fill:#f3e5f5,stroke:#4a148c
    style Phase3 fill:#e8f5e9,stroke:#1b5e20
    style Phase4 fill:#fff3e0,stroke:#e65100
```

## Subscription User Journey

```mermaid
graph TB
    Start["User Starts Claude Code<br/>Session"]

    Install["First Time:<br/>Auto-detect Billing"]

    Session["Session Running"]

    StatusLine["Status Line Shows<br/>📅 Pro: 40% quota<br/>🕐 1h 15m until reset"]

    Mid["Mid-Session:<br/>Hit /trip-computer"]

    Dashboard["See Dashboard<br/>- Quota windows<br/>- Recommendations<br/>- Patterns"]

    Decision{"Continue or<br/>/clear?"}

    Switch["Switch Model<br/>or Trim Context<br/>per recommendation"]

    Continue["Complete Session"]

    End["Session Ends"]

    Meta["Save Metadata<br/>- Name<br/>- Tags<br/>- Notes"]

    Store["Stored in History<br/>for learning"]

    Next["Next Session:<br/>Claude analyzes<br/>your patterns"]

    Start --> Install
    Install --> Session
    Session --> StatusLine
    StatusLine --> Mid
    Mid --> Dashboard
    Dashboard --> Decision
    Decision -->|Follow Recs| Switch
    Switch --> Continue
    Decision -->|Continue| Continue
    Continue --> End
    End --> Meta
    Meta --> Store
    Store --> Next

    style Start fill:#c8e6c9,stroke:#1b5e20,stroke-width:2px
    style Install fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    style Session fill:#bbdefb,stroke:#1565c0,stroke-width:2px
    style StatusLine fill:#f8bbd0,stroke:#880e4f,stroke-width:2px
    style Mid fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style Dashboard fill:#b2dfdb,stroke:#00695c,stroke-width:2px
    style Decision fill:#d1c4e9,stroke:#512da8,stroke-width:2px
    style Switch fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    style Continue fill:#c8e6c9,stroke:#1b5e20,stroke-width:2px
    style End fill:#b2dfdb,stroke:#00695c,stroke-width:2px
    style Meta fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style Store fill:#f8bbd0,stroke:#880e4f,stroke-width:2px
    style Next fill:#c5e1a5,stroke:#558b2f,stroke-width:2px
```

## How Claude Analyzes Claude - Phase 3

```mermaid
graph TB
    History["📚 Session History<br/>(23 sessions)"]

    Extract["Extract Features<br/>- Tags<br/>- Times<br/>- Models used<br/>- Efficiency"]

    Summarize["Summarize for Claude<br/>JSON with metrics"]

    Call["Call Claude API<br/>with session data"]

    Claude["Claude Analyzes<br/>→ Patterns<br/>→ Insights<br/>→ Recommendations"]

    Parse["Parse Response<br/>into sections"]

    Cache["Cache for 24h<br/>(avoid repeated calls)"]

    Display["Display in<br/>/trip-computer"]

    Examples["Show examples:<br/>- Best times<br/>- Model choices<br/>- Context size"]

    Recommend["Personalized Recs<br/>based on YOUR patterns"]

    History --> Extract
    Extract --> Summarize
    Summarize --> Call
    Call --> Claude
    Claude --> Parse
    Parse --> Cache
    Cache --> Display
    Display --> Examples
    Examples --> Recommend

    style History fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    style Extract fill:#c5e1a5,stroke:#558b2f,stroke-width:2px
    style Summarize fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style Call fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    style Claude fill:#d1c4e9,stroke:#512da8,stroke-width:2px
    style Parse fill:#f8bbd0,stroke:#880e4f,stroke-width:2px
    style Cache fill:#b2dfdb,stroke:#00695c,stroke-width:2px
    style Display fill:#bbdefb,stroke:#1565c0,stroke-width:2px
    style Examples fill:#c8e6c9,stroke:#1b5e20,stroke-width:2px
    style Recommend fill:#ffccbc,stroke:#bf360c,stroke-width:2px
```
