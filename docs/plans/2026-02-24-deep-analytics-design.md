# Deep Analytics — Design Document

**Date:** 2026-02-24
**Status:** Approved

## Problem Statement

The current analytics are shallow — a 35-day scorecard grid, 3 summary cards, and basic per-habit stats (streak, completion rate). A data-oriented user has no way to see trends over time, day-of-week patterns, habit comparisons, or a holistic "habit strength" score. The app tracks rich data but reflects almost none of it back.

## Goals

- Replace the Analytics tab with a **hub + drill-down** dashboard
- Surface every meaningful insight derivable from the existing completion data
- Provide accountability (honest scorecards, rankings) and insight (patterns, trends)
- Keep the existing scorecard grid accessible as one drill-down from the hub

## Non-Goals

- AI-powered insights (v2+)
- Social/sharing features
- Notifications or nudges based on analytics
- Export/reporting (already deferred to v2)

## Research

Based on analysis of Loop Habit Tracker, Habitify, Pattrn, and fitness app dashboard patterns:

- **Loop**: Habit strength algorithm (decaying score rewarding consistency, forgiving single misses)
- **Habitify**: Multi-timeframe views (7d/30d/month/year), trend lines, active vs stalled classification
- **Pattrn**: "Locked-In Score" replacing pure streaks, weekly/monthly trend visualization
- **Fitness apps**: Tile-based dark mode hubs, thumb-friendly vertical scroll, accent colors on dark cards

## Architecture: Hub + Drill-Down

### Analytics Hub (main tab)

A vertically scrollable dashboard replacing the current scorecard-only tab. Six tappable cards:

| Card | Glance Data | Drill-Down Target |
|------|-------------|-------------------|
| **Overall Score** | Habit strength %, today's completion, best active streak | Score History screen |
| **Weekly Report** | This week completion rate vs last week, 7-day bar chart | Weekly Trends screen |
| **Streaks** | Top 3 active streaks with flame indicators | Streaks screen |
| **Heatmap** | 12-week GitHub-style contribution grid | Full Heatmap screen |
| **Habit Rankings** | Top/bottom habits by completion rate | Rankings screen |
| **Scorecard Grid** | Miniature 7-day preview | Full Scorecard (existing screen) |

### Drill-Down Screens

#### A. Score History

**Purpose:** Track habit strength over time using a decaying score algorithm.

**Habit Strength Algorithm:**
- Each habit gets a score from 0-100%
- Every completion nudges score up; every miss nudges it down
- Gentle decay: missing 1 day after a 30-day streak barely dents it; missing 5 in a row drops it fast
- Formula: `score = score * (1 - decay) + (completed ? decay : 0)` where decay ~0.05
- Overall Score = average of all active habit scores

**UI:**
- Large score display with progress ring
- Line chart: last 30/90/365 days (segmented control)
- Per-habit score breakdown: ranked list with mini progress bars
- Color coding: green (>75%), gold (50-75%), coral (<50%)

#### B. Weekly Trends

**Purpose:** Week-over-week patterns and day-of-week analysis.

**UI:**
- Weekly comparison bar chart: last 4 weeks side by side
- Day-of-week heatmap: 7 columns (Mon-Sun), average completion rate per weekday across all time
- This week detail: expandable per-day breakdown
- Week-over-week delta: "+12% vs last week" with directional arrow

#### C. Streaks

**Purpose:** Gamified view of all streaks — current, longest, history.

**UI:**
- Active streaks: sorted by length, flame icon scaled by streak size
- Personal records: longest streak per habit with date range
- Streak timeline: horizontal Gantt-style chart of streak periods
- At risk: habits with active streaks not yet completed today

#### D. Full Heatmap

**Purpose:** GitHub-style year view of habit activity.

**UI:**
- 7 rows (Mon-Sun) x N columns (weeks), colored by completion count
- Default 12-week view, expandable to full year
- Month labels along top
- Filter by habit dropdown (all vs individual)
- 5-level intensity legend
- Auto-generated insight: "Most active in January" / "Best day is Wednesday"

#### E. Habit Rankings

**Purpose:** Compare all habits head-to-head.

**UI:**
- Sortable list: each habit as a row with completion rate, current streak, total completions, habit strength
- Tap column header to sort
- Tap row to open habit detail (enhanced)
- Status badges: On Fire (>90%), Steady (70-90%), Needs Attention (50-70%), Stalled (<50%)

#### F. Scorecard Grid (existing)

The current 35-day scrollable grid, preserved as-is, now accessible as a drill-down from the hub.

## Data Requirements

All data is already captured in Hive. New computation needed:

- **Habit strength score**: New provider that computes decaying score from completion history
- **Day-of-week aggregation**: Group completions by weekday across configurable time ranges
- **Week-over-week comparison**: Completion rates per week for last N weeks
- **Streak timeline data**: Start/end dates for all streak periods per habit
- **Ranking/sorting**: Computed from existing stats, just needs a new sorted view

No schema changes required. All new analytics are derived from existing `completions` and `habits` boxes.

## Visual Design

- Consistent with existing dark theme ("Scientific Minimalism with Warmth")
- Hub cards use `backgroundSecondary` with `borderSubtle`, accent color highlights
- Charts use `fl_chart` (already a dependency)
- Heatmap uses existing `heatmapGradient` color scale
- Status colors: `completionGreen` (good), `accentGold` (moderate), `missedCoral` (poor)
