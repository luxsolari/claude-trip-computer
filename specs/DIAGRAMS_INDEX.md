# Trip Computer - Mermaid Diagrams Index

All diagrams are created as `.mmd` files for easy visualization in Mermaid viewers.

## How to View These Diagrams

**Option 1: GitHub**
- Upload or view `.mmd` files directly in GitHub repo
- GitHub renders Mermaid diagrams automatically

**Option 2: Mermaid Live Editor**
- Visit: https://mermaid.live
- Copy-paste content from `.mmd` file
- Edit and visualize in real-time

**Option 3: Local Tools**
- VS Code with Markdown Preview Mermaid extension
- Obsidian (supports Mermaid natively)
- Any tool with Mermaid support

**Option 4: Export to Image**
- Use `mmdc` CLI tool
- `docker run --rm -v /absolute/path/to/diagrams:/data minlag/mermaid-cli mermaid -o /data /data/*.mmd`

---

## Diagram Descriptions

### 1. **phase-dependencies.mmd** - The Big Picture
```
📊 Shows: Phase progression and dependencies
🎯 Use for: Understanding the overall roadmap
👥 Audience: Executives, stakeholders, planners
📈 What it shows:
  - 4 sequential phases (1→2→3→4)
  - What gets built in each phase
  - Clear progression from foundation to polish
```

### 2. **feature-unlocks.mmd** - What Enables What
```
📊 Shows: How Phase 1 features enable Phase 2, etc
🎯 Use for: Understanding dependencies
👥 Audience: Developers, architects
📈 What it shows:
  - Session storage enables quota management
  - Billing detection enables burn rate
  - Window tracking enables predictions
  - Cross-phase dependency map
```

### 3. **feature-maturity.mmd** - Evolution Over Time
```
📊 Shows: How each feature matures across phases
🎯 Use for: Understanding feature completeness
👥 Audience: Product managers, developers
📈 What it shows:
  - Status line v1 → v2 → v3 → v4
  - Storage, detection, tracking progression
  - Dashboard dashboard evolution (v1 → v2 → v3)
  - Maturity stages
```

### 4. **system-architecture.mmd** - Complete System Design
```
📊 Shows: All components and how they connect
🎯 Use for: Technical architecture discussions
👥 Audience: Developers, architects
📈 What it shows:
  - Input layer (Claude Code session)
  - Detection layer (auto-detect billing)
  - Storage layer (persistent records)
  - Metrics layer (calculations)
  - Status line generator
  - Intelligence layer (Claude API)
  - Dashboard (widgets)
  - Export system
  - Data flow between components
```

### 5. **data-flow.mmd** - Session to Insights Pipeline
```
📊 Shows: How session data flows to dashboard
🎯 Use for: Understanding the data pipeline
👥 Audience: Developers
📈 What it shows:
  - Session data → Parsing → Storage
  - Storage → Metrics → Status line display
  - Storage + Metrics → Claude analysis → Dashboard
```

### 6. **status-line-evolution.mmd** - UI Evolution
```
📊 Shows: How status line changes across phases
🎯 Use for: UI/UX design discussions
👥 Audience: Designers, product managers
📈 What it shows:
  - Phase 1: Basic metrics (msgs, tokens, cost)
  - Phase 2: Subscription quotas (quota %, burn rate)
  - Phase 3: Personalized (trended, analyzed)
  - Phase 4: Customizable templates
```

### 7. **dashboard-layout.mmd** - /trip-computer Structure
```
📊 Shows: Dashboard widget hierarchy
🎯 Use for: Dashboard design and development
👥 Audience: Frontend developers, designers
📈 What it shows:
  - Quick summary at top
  - Quota windows section
  - Model mix section
  - Smart recommendations
  - Patterns section
  - Claude's analysis section
```

### 8. **claude-analyzing-claude.mmd** - Phase 3 Innovation
```
📊 Shows: How Claude analyzes your session history
🎯 Use for: Understanding Phase 3 innovation
👥 Audience: All (this is the key differentiator)
📈 What it shows:
  - History extraction
  - Feature summarization
  - Claude API call
  - Response parsing
  - Caching strategy
  - Display and personalization
```

### 9. **subscription-user-journey.mmd** - Real User Experience
```
📊 Shows: Complete flow from session start to next session
🎯 Use for: User experience validation
👥 Audience: Product managers, designers, users
📈 What it shows:
  - Session initialization
  - Status line usage
  - Mid-session /trip-computer
  - Decision points (continue/clear/modify)
  - Session end and metadata
  - Learning for next session
```

### 10. **feature-components.mmd** - Feature Dependencies
```
📊 Shows: How components build across phases
🎯 Use for: Implementation planning
👥 Audience: Project managers, developers
📈 What it shows:
  - Phase 1 storage → Phase 2 burn rate
  - Phase 1 detection → Phase 2 recommendations
  - Phase 2 data → Phase 3 patterns
  - Evolution of dashboard (v1 → v2 → v3)
```

### 11. **success-criteria.mmd** - Phase Completion Goals
```
📊 Shows: What "done" means for each phase
🎯 Use for: Quality assurance, acceptance testing
👥 Audience: QA, project managers, stakeholders
📈 What it shows:
  - Phase 1: Foundation ready (persistence, detection, tracking)
  - Phase 2: Subscription empowered (visibility, predictions)
  - Phase 3: Claude analyzing Claude (intelligence, learning)
  - Phase 4: Polished & delightful (customization, sharing)
```

### 12. **complete-flow.mmd** - End-to-End Journey
```
📊 Shows: Complete pipeline from session to intelligent feedback
🎯 Use for: Big picture understanding
👥 Audience: All stakeholders
📈 What it shows:
  - Input: Session starts
  - Phase 1-4 processing
  - Output: Real-time intelligent feedback
  - Shows linear progression and cumulative value
```

---

## Quick Navigation Guide

### If you want to understand...

**The Business Story**
→ Start with `phase-dependencies.mmd`
→ Then `success-criteria.mmd`
→ Then `subscription-user-journey.mmd`

**The Technical Architecture**
→ Start with `system-architecture.mmd`
→ Then `data-flow.mmd`
→ Then `feature-components.mmd`

**The User Interface**
→ Start with `status-line-evolution.mmd`
→ Then `dashboard-layout.mmd`
→ Then `subscription-user-journey.mmd`

**The Innovation (Phase 3)**
→ Start with `claude-analyzing-claude.mmd`
→ Then `feature-maturity.mmd` (look at phase 3 row)
→ Then `dashboard-layout.mmd` (for the output)

**The Complete Picture**
→ `complete-flow.mmd` (shows everything in one view)
→ Then dive into specific areas above

**Planning Implementation**
→ `feature-components.mmd` (dependencies)
→ `feature-unlocks.mmd` (what blocks what)
→ `success-criteria.mmd` (completion targets)

---

## Viewing All Diagrams at Once

Create a simple HTML file to view all diagrams:

```html
<!DOCTYPE html>
<html>
<head>
    <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
    <style>
        body { font-family: Arial; padding: 20px; background: #f5f5f5; }
        .diagram { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; }
        h2 { color: #333; }
    </style>
</head>
<body>
    <h1>Trip Computer - Architecture Diagrams</h1>

    <div class="diagram">
        <h2>Phase Dependencies</h2>
        <div class="mermaid">
            [PASTE CONTENT FROM phase-dependencies.mmd HERE]
        </div>
    </div>

    <div class="diagram">
        <h2>System Architecture</h2>
        <div class="mermaid">
            [PASTE CONTENT FROM system-architecture.mmd HERE]
        </div>
    </div>

    <!-- Repeat for other diagrams -->
</body>
</html>
```

---

## File List

```
specs/
├── DIAGRAMS_INDEX.md              ← This file
│
└── diagrams/
    ├── phase-dependencies.mmd          ← Phase progression
    ├── feature-unlocks.mmd             ← Feature dependencies
    ├── feature-maturity.mmd            ← Feature evolution
    ├── system-architecture.mmd         ← Complete system design
    ├── data-flow.mmd                   ← Data pipeline
    ├── status-line-evolution.mmd       ← UI changes by phase
    ├── dashboard-layout.mmd            ← Dashboard structure
    ├── claude-analyzing-claude.mmd     ← Phase 3 innovation
    ├── subscription-user-journey.mmd   ← User experience
    ├── feature-components.mmd          ← Component dependencies
    ├── success-criteria.mmd            ← Phase completion goals
    ├── complete-flow.mmd               ← End-to-end flow
    ├── phases-comprehensive.mmd        ← All 4 phases side-by-side
    └── api-vs-subscription-user.mmd    ← User type comparison
```

---

## Tips for Using These Diagrams

1. **Zoom in**: Most Mermaid viewers allow zoom - use it!
2. **Print**: All diagrams are designed to be printable
3. **Share**: Send `.mmd` files directly - they're text-based and version-control friendly
4. **Edit**: All `.mmd` files are plain text - easy to edit and customize
5. **Color coding**:
   - Blue = Phase 1 (Foundation)
   - Purple = Phase 2 (Subscription)
   - Green = Phase 3 (Intelligence)
   - Orange = Phase 4 (Polish)

---

## Converting to Other Formats

### To PNG/SVG using Docker:
```bash
docker run --rm -v /Users/llaje/Code/claude-trip-computer/specs/diagrams:/data \
  minlag/mermaid-cli mermaid -o /data /data/*.mmd
```

### To PDF using Mermaid Live Editor:
1. Go to https://mermaid.live
2. Paste diagram content
3. Use Export menu → Download as PDF

### To Excalidraw:
1. Paste diagram into https://mermaid.live
2. Screenshot or export as PNG
3. Upload to Excalidraw for additional editing

---

## Questions?

Each diagram is self-contained but they tell a complete story together.
Start with `phase-dependencies.mmd` for the overview, then dive into specific areas based on your needs.
