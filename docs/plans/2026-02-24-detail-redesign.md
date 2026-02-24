# Detail Screen Redesign + Form Improvements + Duration/Effort Tracking

**Date:** 2026-02-24
**Status:** Approved
**Depends on:** Deep Analytics (complete)

## Problem Statement

The habit detail screen is the single-habit deep-dive but currently shows minimal data: name, schedule label, identity statement, one progress ring, two stat cards, and a flat 35-day heatmap. Meanwhile, the app now computes rich per-habit data (habit strength, streak analytics, rankings) that is never surfaced here. Additionally, several entity fields exist but can't be edited (color, implementation intentions, 2-minute version), and the HabitCard widget shows dead streak dots. The user also wants a new duration/effort metric to track time investment per habit.

## Goals

1. **Redesign Habit Detail Screen** — Make it the definitive single-habit dashboard with all available data
2. **Complete Habit Form** — Add color picker, implementation intention inputs, 2-minute version, duration minutes, and validation
3. **Fix dead widgets** — HabitCard streak dots, Home FAB
4. **Add duration/effort tracking** — New `durationMinutes` field with parallel effort analytics alongside existing completion-rate analytics

## Non-Goals

- Stacks/chaining UI (deferred to v2)
- Notification settings in form (deferred to v2)
- Per-habit drill-down analytics screens (habit detail IS the drill-down for now)

---

## 1. Duration/Effort Feature (Data Layer Changes)

### New Field

Add `durationMinutes` (int?, nullable) to the Habit entity. Null means "no estimate" — these habits are excluded from effort calculations but still count for completion rate.

### Schema Change

- `Habit` entity: add `durationMinutes` field
- `HabitModel`: add `@HiveField(18) int? durationMinutes`
- `HabitModelAdapter`: bump field count from 18 to 19, add read/write for field 18
- Backward compatible: old data reads field 18 as null (Hive handles missing fields gracefully)

### Effort Analytics (Parallel Track)

Effort metrics live alongside completion metrics — they never replace them:

| Metric | Completion Track (existing) | Effort Track (new) |
|--------|---------------------------|-------------------|
| Daily progress | "5/7 habits done" | "85/120 min invested" |
| Weekly rate | 73% completion rate | 78% effort rate |
| Overall score | Avg habit strength | Weighted habit strength (strength × duration) |
| Hub card | Shows both side by side | |

**Effort rate formula:** `sum(completed_habit_durations) / sum(scheduled_habit_durations)` for a given period. Habits with null duration are excluded from effort calculations.

**Weighted overall score:** `sum(habit_strength[i] * duration[i]) / sum(duration[i])` for all habits with duration set. Shown alongside unweighted score.

### Where Effort Shows Up

- **Home screen** daily progress card: second line "X/Y min invested"
- **Analytics hub** Overall Score card: "73% | 85 min today"
- **Weekly trends** drill-down: effort bar chart alongside completion bar chart
- **Habit detail** screen: duration badge + effort stats
- **Habit rankings**: sortable by effort (total minutes completed)

---

## 2. Habit Detail Screen Redesign

### Layout (top to bottom)

#### A. Color Header Bar
- Thin gradient bar at top using habit's `colorHex` (fading from color to transparent)
- Habit name in `displayMedium`
- Category chip + schedule label on same row
- Duration badge: "20 min" pill if set

#### B. Identity & Intentions Card
- Identity statement in Fraunces italic (existing style)
- If implementation intention set: "When: 7:00 AM | Where: Living room"
- If 2-minute version set: "Start with: Meditate for 2 minutes"
- Card uses `backgroundSecondary` with left accent border in habit color

#### C. Streak Hero
- Large streak number using `dataLarge` (JetBrains Mono)
- Fire icon scaled by streak length (small < 7d, medium 7-29d, large 30d+)
- "Current Streak" label below
- Beside it: longest streak with trophy icon, smaller

#### D. Stats Grid (2x2)
- Completion Rate (progress ring)
- Habit Strength (progress ring, using per-habit strength from existing provider)
- Total Completions / Scheduled Days
- Effort Invested (total minutes, if duration set)

#### E. Heatmap
- GitHub-style grid (reuse the pattern from full_heatmap_screen)
- 12-week view for this specific habit
- Uses habit's color instead of default green gradient

#### F. Quick Actions Row
- "View in Rankings" → navigates to rankings screen
- "Full Heatmap" → navigates to heatmap screen pre-filtered to this habit
- "Edit" → opens form sheet

---

## 3. Habit Form Improvements

### New Fields

#### Color Picker
- Horizontal row of 8 color circles (from `AppColors.habitPalette`)
- Tap to select, show checkmark on selected
- Default: gold (first in palette)

#### Duration Minutes
- Simple number input with "min" suffix label
- Preset chips: 5, 10, 15, 20, 30, 45, 60
- Or type custom value
- Optional — can leave empty

#### Implementation Intention (Time)
- Text field: "What time?" with hint "e.g., 7:00 AM, After breakfast"
- Free text, not a time picker (supports "After lunch", "Before bed", etc.)

#### Implementation Intention (Location)
- Text field: "Where?" with hint "e.g., Living room, Office desk"

#### 2-Minute Version
- Text field: "2-minute version" with hint "e.g., Put on running shoes"
- Helper text: "What's the smallest version of this habit?"

### Validation
- Name: required, non-empty (show error text if empty on save)
- Weekly: at least 1 day selected (show error text)
- Monthly: at least 1 date selected (show error text)
- Duration: positive integer if provided

### Reorganized Form Layout
1. Name (existing)
2. Category (existing)
3. Color picker (new)
4. Schedule type + day/date selectors (existing)
5. Duration minutes (new)
6. Identity statement (existing)
7. Implementation time (new)
8. Implementation location (new)
9. 2-minute version (new)
10. Save/Cancel (existing)

---

## 4. HabitCard Streak Fix

The `HabitCard` widget currently hardcodes `StreakDots(length: 0)`. Fix by:
- Adding `streakLength` parameter to `HabitCard`
- Computing current streak per habit in the list views (Home, Habits List)
- Passing actual streak length to `StreakDots`

This requires a lightweight streak lookup. Options:
- **A)** Add a `currentStreakProvider` that batch-computes streaks for all today's habits
- **B)** Use `habitStatsProvider` per-habit (already exists, but N+1 queries)

Recommendation: **A** — batch compute in a single provider that returns `Map<String, int>` of habitId → currentStreak for all active habits.

---

## 5. Home FAB Cleanup

Current FAB shows a snackbar saying "Create habits from the Habits tab." Options:
- **A)** Make it actually open the habit form sheet (same as Habits tab)
- **B)** Remove it entirely

Recommendation: **A** — the FAB is prominent; it should work. Reuse `showHabitFormSheet()` directly.

---

## Visual Design Notes

- All new UI follows existing "Scientific Minimalism with Warmth" dark theme
- Duration badge: pill shape with `backgroundTertiary`, JetBrains Mono text
- Color picker: circles with subtle border, checkmark overlay on selected
- Streak hero: accent gold for number, flame icon uses gold/coral gradient concept
- Implementation intention card: left border accent in habit color, muted background
- Effort metrics use `twoMinuteBlue` color to distinguish from completion metrics (green/gold)
