# Atomic Habits Tracker - Development Tasks

This document tracks all development tasks with testing phases. Mark tasks as:
- `[ ]` Not started
- `[~]` In progress
- `[x]` Complete
- `[!]` Blocked

---

## Phase 1: Project Setup & Infrastructure

### 1.1 Flutter Project Initialization
- [x] Create new Flutter project with `flutter create --org com.atomichabits atomic_habits`
- [x] Configure `pubspec.yaml` with all dependencies
- [ ] Set up Android-specific configurations (min SDK, permissions)
- [ ] Configure app icon and splash screen placeholders
- [x] Set up folder structure per Clean Architecture

**Dependencies (updated - using Hive instead of Isar due to codegen conflicts):**
```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.5
  flutter_local_notifications: ^18.0.1
  timezone: ^0.10.0
  fl_chart: ^0.69.0
  google_fonts: ^6.2.1
  phosphor_flutter: ^2.1.0
  flutter_animate: ^4.5.2
  uuid: ^4.5.1
  intl: ^0.20.2
  csv: ^6.0.0
  share_plus: ^10.1.4
  permission_handler: ^11.4.0
  collection: ^1.19.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  mocktail: ^1.0.4
```

#### Testing Phase 1.1
- [x] `flutter run` launches without errors (APK builds successfully)
- [ ] Hot reload works
- [x] All packages resolve correctly
- [x] Folder structure matches architecture diagram

---

### 1.2 Theme & Design System Implementation
- [x] Create `core/theme/app_colors.dart` with color constants
- [x] Create `core/theme/app_typography.dart` with text styles
- [x] Create `core/theme/app_spacing.dart` with spacing constants
- [x] Create `core/theme/app_theme.dart` combining all into ThemeData
- [x] Add Google Fonts (Fraunces, DM Sans, JetBrains Mono)
- [x] Create `core/theme/app_shadows.dart` for elevation styles

#### Testing Phase 1.2
- [~] Theme applies correctly to MaterialApp (pending app run)
- [ ] All three font families load and render
- [ ] Colors display correctly in dark mode
- [ ] Text styles match design system specs

---

### 1.3 App Shell & Navigation
- [x] Create `app/app.dart` with MaterialApp setup
- [x] Create `app/router.dart` with route definitions
- [x] Implement bottom navigation scaffold
- [x] Create placeholder screens for all 5 nav destinations
- [x] Implement navigation state management

#### Testing Phase 1.3
- [ ] Bottom nav switches between all 5 tabs
- [ ] Nav state persists correctly
- [ ] Active tab indicator shows gold accent
- [ ] Navigation animations are smooth

---

## Phase 2: Data Layer

### 2.1 Hive Database Setup
- [x] Create `data/datasources/local/hive_database.dart` with init logic
- [x] Configure Hive boxes for each entity type
- [x] Create database provider for Riverpod
- [x] Register Hive type adapters for all models

#### Testing Phase 2.1
- [ ] Database initializes on first launch
- [ ] Database persists between app restarts
- [ ] No crashes on rapid open/close

---

### 2.2 Habit Model
- [x] Create `data/models/habit_model.dart` HiveObject
- [x] Define all fields per data model in PRD
- [x] Create HabitAdapter type adapter
- [x] Implement toEntity/fromEntity converters

**Fields:**
```dart
@HiveType(typeId: 0)
class HabitModel extends HiveObject {
  @HiveField(0)
  String id; // UUID
  @HiveField(1)
  String name;
  @HiveField(2)
  DateTime createdAt;
  @HiveField(3)
  DateTime? archivedAt;
  @HiveField(4)
  int scheduleType; // 0=daily, 1=weekly, 2=monthly
  @HiveField(5)
  List<int>? scheduleDays;
  @HiveField(6)
  List<int>? scheduleDates;
  @HiveField(7)
  String? identityStatement;
  @HiveField(8)
  String? implementationTime;
  @HiveField(9)
  String? implementationLocation;
  @HiveField(10)
  String? twoMinuteVersion;
  @HiveField(11)
  String? colorHex;
  @HiveField(12)
  String? category;
  @HiveField(13)
  String? notes;
  @HiveField(14)
  int displayOrder;
  @HiveField(15)
  bool notificationsEnabled;
  @HiveField(16)
  List<String>? notificationTimes;
  @HiveField(17)
  String? notificationTriggerHabitId;
}
```

#### Testing Phase 2.2
- [ ] Can create habit with all required fields
- [ ] Can create habit with all optional fields
- [ ] Type adapter registers correctly
- [ ] Entity conversion is bidirectional and lossless

---

### 2.3 HabitCompletion Model
- [x] Create `data/models/completion_model.dart` HiveObject
- [x] Define all fields per data model
- [x] Create CompletionAdapter type adapter
- [x] Implement toEntity/fromEntity converters

**Fields:**
```dart
@HiveType(typeId: 1)
class CompletionModel extends HiveObject {
  @HiveField(0)
  String id; // UUID
  @HiveField(1)
  String habitId;
  @HiveField(2)
  DateTime date; // Date only, no time
  @HiveField(3)
  DateTime completedAt;
  @HiveField(4)
  int completionType; // 0=full, 1=twoMinute, 2=skipped
  @HiveField(5)
  String? skipReason;
  @HiveField(6)
  String? note;
  @HiveField(7)
  bool wasEdited;
}
```

#### Testing Phase 2.3
- [ ] Can create completion records
- [ ] Can query all completions for a habit
- [ ] Can query all completions for a date
- [ ] Date range queries work correctly

---

### 2.4 HabitStack Model
- [x] Create `data/models/habit_stack_model.dart` HiveObject
- [x] Define previousHabitId and nextHabitId fields
- [x] Create HabitStackAdapter type adapter

#### Testing Phase 2.4
- [ ] Can create stack links
- [ ] Can query next habits for a given habit
- [ ] Can query previous habit for a given habit
- [ ] Handles chain traversal

---

### 2.5 Category Model
- [x] Create `data/models/category_model.dart` HiveObject
- [x] Define name, colorHex, displayOrder fields
- [x] Create CategoryAdapter type adapter

#### Testing Phase 2.5
- [ ] Can create categories
- [ ] Can query all categories ordered by displayOrder

---

### 2.6 Habit Repository
- [x] Create `domain/repositories/habit_repository.dart` abstract interface
- [x] Create `data/repositories/habit_repository_impl.dart` implementation
- [x] Implement CRUD operations for habits
- [x] Implement archive/unarchive operations
- [x] Implement reorder operation
- [x] Implement query methods (active, archived, by category)

#### Testing Phase 2.6
- [ ] Create habit persists to database
- [ ] Read habit returns correct data
- [ ] Update habit modifies correct record
- [ ] Delete habit removes record
- [ ] Archive sets archivedAt timestamp
- [ ] Query active habits excludes archived
- [ ] Reorder updates displayOrder correctly

---

### 2.7 Completion Repository
- [x] Create `domain/repositories/completion_repository.dart` interface
- [x] Create `data/repositories/completion_repository_impl.dart`
- [x] Implement create/update/delete completions
- [x] Implement query by date range
- [x] Implement query by habit
- [x] Implement streak calculation queries

#### Testing Phase 2.7
- [ ] Can record a completion
- [ ] Can update completion type
- [ ] Can delete completion
- [ ] Date range queries return correct data
- [ ] Streak calculation is accurate

---

### 2.8 Stack Repository
- [x] Create `domain/repositories/stack_repository.dart` interface
- [x] Create `data/repositories/stack_repository_impl.dart`
- [x] Implement link/unlink habits
- [x] Implement get chain for habit
- [ ] Implement reorder within chain

#### Testing Phase 2.8
- [ ] Can link two habits
- [ ] Can unlink habits
- [ ] Chain traversal returns correct order
- [ ] Handles branching (one previous, multiple next)

---

## Phase 3: Domain Layer

### 3.1 Domain Entities
- [x] Create `domain/entities/habit.dart` pure Dart class
- [x] Create `domain/entities/completion.dart`
- [x] Create `domain/entities/habit_stack.dart`
- [x] Create `domain/entities/category.dart`
- [x] Create `domain/entities/habit_stats.dart` for computed stats

#### Testing Phase 3.1
- [ ] Entities are immutable (use freezed or manual)
- [ ] Equality comparison works correctly
- [ ] copyWith methods work

---

### 3.2 Use Cases - Habit Management
- [x] Create `domain/usecases/habits/create_habit.dart`
- [x] Create `domain/usecases/habits/update_habit.dart`
- [x] Create `domain/usecases/habits/delete_habit.dart`
- [x] Create `domain/usecases/habits/archive_habit.dart`
- [x] Create `domain/usecases/habits/get_habits.dart`
- [x] Create `domain/usecases/habits/reorder_habits.dart`

#### Testing Phase 3.2
- [ ] Each use case executes correctly
- [ ] Use cases validate input
- [ ] Use cases handle errors gracefully

---

### 3.3 Use Cases - Completions
- [x] Create `domain/usecases/completions/complete_habit.dart`
- [x] Create `domain/usecases/completions/uncomplete_habit.dart`
- [x] Create `domain/usecases/completions/skip_habit.dart`
- [x] Create `domain/usecases/completions/get_completions_for_date.dart`
- [x] Create `domain/usecases/completions/get_completions_for_range.dart`

#### Testing Phase 3.3
- [ ] Completing habit creates correct record
- [ ] Uncompleting removes record
- [ ] Skip creates record with skipReason
- [ ] Date queries are timezone-aware

---

### 3.4 Deep Analytics Providers & Computation (Design: `docs/plans/2026-02-24-deep-analytics-design.md`)

#### 3.4a Habit Strength Score Provider
- [x] Create `presentation/providers/habit_strength_provider.dart`
- [x] Implement decaying score algorithm: `score = score * (1 - decay) + (completed ? decay : 0)` per habit
- [x] Compute overall score as average of all active habit scores
- [x] Cache with revision-aware invalidation (same pattern as `habitStatsProvider`)
- [x] Support historical score computation for chart data (last 30/90/365 days)

#### 3.4b Weekly Trends Provider
- [x] Create `presentation/providers/weekly_trends_provider.dart`
- [x] Compute completion rate per week for last N weeks
- [x] Compute day-of-week aggregation (average completion rate per weekday across all time)
- [x] Compute week-over-week delta (this week vs last week %)

#### 3.4c Streak Analytics Provider
- [x] Create `presentation/providers/streak_analytics_provider.dart`
- [x] Compute all active streaks sorted by length
- [x] Compute personal records (longest streak per habit with date ranges)
- [x] Compute streak timeline data (start/end dates for all streak periods)
- [x] Identify "at risk" habits (active streak but not completed today)

#### 3.4d Rankings Provider
- [x] Create `presentation/providers/rankings_provider.dart`
- [x] Compute sortable habit list with: completion rate, current streak, total completions, habit strength
- [x] Assign status badges: On Fire (>90%), Steady (70-90%), Needs Attention (50-70%), Stalled (<50%)

#### 3.4e Extract Shared Utilities
- [x] Extract `_isHabitScheduledOn()` to `core/utils/schedule_utils.dart` (currently duplicated 3x)
- [x] Extract `_parseColor()` to `core/utils/color_utils.dart` (currently duplicated 2x)

#### Testing Phase 3.4
- [ ] Habit strength score decays correctly on misses and recovers on completions
- [ ] Habit strength score handles edge cases (new habit with no data, archived habits)
- [ ] Weekly trends match manual calculation for a known dataset
- [ ] Day-of-week aggregation correctly groups across months/years
- [ ] Streak timeline identifies all historical streak periods
- [ ] "At risk" list correctly identifies habits not yet done today
- [ ] Rankings sort correctly by each metric
- [ ] Status badges assign at correct thresholds

---

### 3.5 Use Cases - Stacks
- [x] Create `domain/usecases/stacks/link_habits.dart`
- [x] Create `domain/usecases/stacks/unlink_habits.dart`
- [x] Create `domain/usecases/stacks/get_habit_chain.dart`
- [x] Create `domain/usecases/stacks/get_next_in_stack.dart`

#### Testing Phase 3.5
- [ ] Linking creates bidirectional relationship
- [ ] Unlinking cleans up both directions
- [ ] Chain returns complete ordered list
- [ ] Next-in-stack returns correct habit

---

## Phase 4: State Management (Riverpod)

### 4.1 Core Providers
- [x] Create `presentation/providers/database_provider.dart`
- [x] Create `presentation/providers/repository_providers.dart`
- [x] Create `presentation/providers/habits_provider.dart`
- [x] Create `presentation/providers/today_habits_provider.dart`

#### Testing Phase 4.1
- [ ] Providers initialize without errors
- [ ] Dependency injection works correctly
- [ ] Providers dispose properly

---

### 4.2 Completion Providers
- [x] Create `presentation/providers/completions_provider.dart`
- [x] Create `presentation/providers/today_completions_provider.dart`
- [x] Implement completion toggle logic
- [x] Handle optimistic updates

#### Testing Phase 4.2
- [ ] Completing habit updates UI immediately
- [ ] Failed completion reverts UI
- [ ] Multiple rapid toggles handled correctly

---

### 4.3 Analytics Providers
- [x] Create `presentation/providers/analytics_provider.dart`
- [x] Create `presentation/providers/habit_stats_provider.dart`
- [x] Create `presentation/providers/heatmap_provider.dart`
- [x] Implement caching for expensive calculations

#### Testing Phase 4.3
- [ ] Analytics load within performance budget
- [ ] Data refreshes when completions change
- [ ] Caching prevents redundant calculations

---

### 4.4 Stack Providers
- [x] Create `presentation/providers/stacks_provider.dart`
- [x] Create `presentation/providers/habit_chain_provider.dart`

#### Testing Phase 4.4
- [ ] Stack chains load correctly
- [ ] UI updates when stacks modified

---

## Phase 5: Core UI Components

### 5.1 Common Widgets
- [x] Create `presentation/widgets/common/app_card.dart`
- [x] Create `presentation/widgets/common/app_button.dart`
- [x] Create `presentation/widgets/common/app_text_field.dart`
- [x] Create `presentation/widgets/common/section_header.dart`
- [x] Create `presentation/widgets/common/loading_indicator.dart`
- [x] Create `presentation/widgets/common/empty_state.dart`

#### Testing Phase 5.1
- [ ] All widgets render correctly
- [ ] Widgets follow design system
- [ ] Widgets handle edge cases (long text, etc.)

---

### 5.2 Habit Widgets
- [x] Create `presentation/widgets/habit/habit_card.dart`
- [~] Create `presentation/widgets/habit/habit_checkbox.dart` with animation
- [x] Create `presentation/widgets/habit/streak_dots.dart`
- [x] Create `presentation/widgets/habit/identity_statement.dart`
- [x] Create `presentation/widgets/habit/habit_color_picker.dart`

#### Testing Phase 5.2
- [ ] Habit card matches design mockup
- [ ] Checkbox animation is smooth and satisfying
- [ ] Streak dots display correct history
- [ ] Haptic feedback works on completion

---

### 5.3 Chart Widgets
- [x] Create `presentation/widgets/charts/completion_bar_chart.dart`
- [x] Create `presentation/widgets/charts/streak_line_chart.dart`
- [x] Create `presentation/widgets/charts/heatmap_grid.dart`
- [x] Create `presentation/widgets/charts/progress_ring.dart`
- [x] Create `presentation/widgets/charts/stat_card.dart`

#### Testing Phase 5.3
- [ ] Charts render with sample data
- [ ] Charts animate on load
- [ ] Charts handle empty data gracefully
- [ ] Touch interactions work (tooltips)

---

### 5.4 Navigation Widgets
- [x] Create `presentation/widgets/navigation/bottom_nav_bar.dart`
- [x] Create `presentation/widgets/navigation/app_bar_title.dart`
- [x] Create `presentation/widgets/navigation/back_button.dart`

#### Testing Phase 5.4
- [ ] Bottom nav matches design
- [ ] Active state shows correctly
- [ ] Navigation is smooth

---

## Phase 6: Screens

### 6.1 Home / Today Screen
- [x] Create `presentation/screens/home/home_screen.dart`
- [x] Implement date header with formatted date
- [x] Implement daily progress card
- [~] Implement habit list grouped by time/category
- [x] Implement habit completion toggle
- [~] Implement FAB for adding habits
- [x] Add pull-to-refresh

#### Testing Phase 6.1
- [ ] Shows only today's scheduled habits
- [ ] Completion toggles update immediately
- [ ] Progress bar updates on completion
- [ ] Groups display correctly
- [ ] Empty state shows when no habits

---

### 6.2 Scorecard Screen
- [x] Create `presentation/screens/scorecard/scorecard_screen.dart`
- [~] Implement week/month selector
- [x] Implement grid layout (habits x days)
- [~] Implement cell tap to toggle
- [~] Implement horizontal scroll for more days
- [x] Implement legend
- [~] Implement week summary stats

#### Testing Phase 6.2
- [ ] Grid displays correct completion states
- [ ] Tapping cells toggles completion
- [ ] Scrolling is smooth
- [ ] Week selector changes data

---

### 6.3 Habits List Screen
- [x] Create `presentation/screens/habits/habits_list_screen.dart`
- [x] Implement list of all active habits
- [x] Implement drag-to-reorder
- [~] Implement swipe actions (edit/delete + undo/confirm polish)
- [x] Implement filter by category
- [x] Implement search
- [x] Add navigation to habit detail

#### Testing Phase 6.3
- [ ] All habits display
- [ ] Reorder persists
- [ ] Swipe actions work
- [ ] Filter reduces list correctly
- [ ] Search finds matches

---

### 6.4 Habit Detail Screen
- [~] Create `presentation/screens/habits/habit_detail_screen.dart`
- [ ] Implement streak hero section
- [ ] Implement implementation intention display
- [x] Implement schedule display
- [ ] Implement stack position display
- [~] Implement stats grid
- [~] Add edit button
- [ ] Add link to full analytics

#### Testing Phase 6.4
- [ ] All habit data displays correctly
- [ ] Streak hero animates
- [ ] Edit navigates to form
- [ ] Stats are accurate

---

### 6.5 Create/Edit Habit Screen
- [~] Create `presentation/screens/habits/habit_form_screen.dart`
- [x] Implement name input
- [x] Implement schedule type picker
- [~] Implement day/date selectors
- [x] Implement identity statement input
- [ ] Implement implementation intention inputs (time, location)
- [ ] Implement 2-minute version input
- [ ] Implement color picker
- [x] Implement category selector
- [ ] Implement notification settings
- [ ] Implement stack linking
- [x] Implement save/cancel actions
- [~] Implement validation

#### Testing Phase 6.5
- [ ] All fields save correctly
- [ ] Validation prevents invalid data
- [ ] Edit mode pre-fills data
- [ ] Cancel discards changes
- [ ] Keyboard handling is smooth

---

### 6.11 UI/UX Usability Pass (Approved 2026-02-05)
- [~] Add delete confirmation and archive/delete undo snackbars
- [x] Replace plain empty states with guided cards and strong CTA actions
- [~] Add playful visual language to Habits list (color accents, status chips, stronger affordances)
- [x] Add Today progress summary card (x/y completed, clear action cues)
- [x] Upgrade quick-create from dialog to bottom-sheet form
- [x] Add tap-through from Habits list to Habit Detail with analytics glimpse

**Execution Order (locked):**
1. Safer swipe actions
2. Empty states + CTA
3. Today progress card
4. Bottom-sheet habit form
5. Playful Habits card polish
6. Habit Detail navigation + analytics glimpse

#### Testing Phase 6.11
- [ ] Delete confirmation prevents accidental deletion
- [ ] Undo restores archived/deleted items correctly
- [ ] Empty state CTA reliably creates first habit
- [ ] Progress card reflects completion changes immediately
- [ ] Bottom-sheet form is smoother than dialog on mobile
- [ ] Habit cards feel playful without reducing readability
- [ ] Habit detail opens from list and shows useful analytics preview

---

### 6.6 Analytics — Deep Hub + Drill-Down (Design: `docs/plans/2026-02-24-deep-analytics-design.md`)

**Previously completed (scorecard grid):**
- [x] Rename scorecard to analytics throughout codebase
- [x] Redesign as read-only visual scorecard (no accidental edits)
- [x] Fill vertical space, prettier cells, better typography
- [x] Add summary stat cards (completion rate, count, habit count)
- [x] Today highlight in header, habit color indicators, check marks in cells

#### 6.6a Analytics Hub Screen
- [x] Replace current Analytics tab content with hub dashboard
- [x] Overall Score card — habit strength %, today's completion, best active streak
- [x] Weekly Report card — this week's rate vs last week, 7-day mini bar chart
- [x] Streaks card — top 3 active streaks with flame indicators
- [x] Heatmap card — 12-week GitHub-style contribution grid preview
- [x] Habit Rankings card — top/bottom habits by completion rate
- [x] Scorecard Grid card — miniature 7-day preview linking to existing full grid
- [x] All cards tappable, navigating to their drill-down screens

#### 6.6b Score History Screen (drill-down)
- [x] Large score display with progress ring
- [x] Line chart: score over last 30/90/365 days (segmented control toggle)
- [x] Per-habit score breakdown: ranked list with mini progress bars
- [x] Color coding: green (>75%), gold (50-75%), coral (<50%)

#### 6.6c Weekly Trends Screen (drill-down)
- [x] Weekly comparison bar chart: last 4 weeks side by side
- [x] Day-of-week heatmap: 7 columns (Mon-Sun), average completion rate per weekday
- [x] This week detail: expandable per-day breakdown with completions/misses per habit
- [x] Week-over-week delta: "+12% vs last week" with directional arrow

#### 6.6d Streaks Screen (drill-down)
- [x] Active streaks: sorted by length, flame icon scaled by streak size
- [x] Personal records: longest streak per habit with date range
- [x] Streak timeline: horizontal Gantt-style chart of streak periods
- [x] At risk: habits with active streaks not yet completed today

#### 6.6e Full Heatmap Screen (drill-down)
- [x] GitHub-style grid: 7 rows (Mon-Sun) x N columns (weeks)
- [x] Default 12-week view, expandable to full year
- [x] Month labels along top
- [x] Filter by habit dropdown (all habits vs individual)
- [x] 5-level intensity legend
- [x] Auto-generated insight text: "Most active in [month]" / "Best day is [weekday]"

#### 6.6f Habit Rankings Screen (drill-down)
- [x] Sortable list: each habit row with completion rate, current streak, total completions, habit strength
- [x] Tap column header to sort by that metric
- [x] Tap habit row to open habit detail screen
- [x] Status badges: On Fire (>90%), Steady (70-90%), Needs Attention (50-70%), Stalled (<50%)

#### 6.6g Scorecard Grid (existing, preserved)
- [x] Full 35-day scrollable grid (already implemented)
- [x] Accessible as drill-down from hub's Scorecard card

#### Testing Phase 6.6
- [x] Scorecard grid displays correct completion states
- [x] No accidental edits possible in scorecard
- [x] Scorecard fills screen beautifully
- [ ] Hub loads without errors and shows all 6 cards
- [ ] Each hub card navigates to correct drill-down screen
- [ ] Overall score matches manual calculation
- [ ] Score history chart renders correctly for 30/90/365 day ranges
- [ ] Weekly trends show correct completion rates per week
- [ ] Day-of-week heatmap accurately reflects historical patterns
- [ ] Streaks screen shows all active streaks sorted correctly
- [ ] "At risk" list correctly identifies habits due today
- [ ] Full heatmap renders correct grid for 12-week and year views
- [ ] Heatmap filter by habit works correctly
- [ ] Rankings sort by each column correctly
- [ ] Status badges assign at correct thresholds
- [ ] All drill-down screens use consistent dark theme styling

---

### 6.7 Settings Screen
- [ ] Implement app info section
- [ ] Implement archived habits access
- [ ] Implement about/credits

---

## Deferred to v2

The following features are preserved for future development. They are not blockers for v1.

### Habit Stacks Screen
- [ ] Create `presentation/screens/stacks/stacks_screen.dart`
- [ ] Implement list of all stacks/chains
- [ ] Implement chain visualization
- [ ] Implement tap to expand chain
- [ ] Implement create new stack flow
- [ ] Implement edit/delete stack

### Analytics Drill-Down Screens
- [ ] Streaks detail, completion detail, heatmap detail, trends
- [ ] Date range filters, habit filters, comparison views

### Habit Analytics Screen (per-habit deep dive)
- [ ] Full history for single habit
- [ ] All stats, streak timeline, notes history, per-habit heatmap

### Notifications Service
- [ ] Permission request flow
- [ ] Schedule/cancel notifications
- [ ] Tap handling, quick-complete, snooze
- [ ] Stack triggers after completion

### CSV Export Service
- [ ] Export all habits/completions
- [ ] Date range filter, share/save file

### Streak Milestone Celebrations
- [ ] Confetti animation on milestones (7, 30, 60, 90, 365)
- [ ] Store milestone achievements

### Accessibility
- [ ] Semantic labels, TalkBack testing, WCAG AA contrast, font scaling

### Performance Optimization
- [ ] Profile startup, optimize DB queries, pagination, loading states

---

### 8.2 Performance Optimization
- [ ] Profile app startup time
- [ ] Optimize database queries
- [ ] Implement pagination for large lists
- [ ] Add loading states
- [ ] Optimize image/asset loading

#### Testing Phase 8.2
- [ ] App launches < 2 seconds
- [ ] Analytics loads < 1 second
- [ ] Scrolling is 60fps
- [ ] Memory usage is reasonable

---

### 8.3 Error Handling & Edge Cases
- [ ] Add global error handler
- [ ] Handle database errors gracefully
- [ ] Handle timezone changes
- [ ] Handle month boundary edge cases
- [ ] Add retry mechanisms

#### Testing Phase 8.3
- [ ] App doesn't crash on errors
- [ ] User sees helpful error messages
- [ ] Timezone changes don't corrupt data

---

### 8.4 Accessibility
- [ ] Add semantic labels to all interactive elements
- [ ] Test with TalkBack
- [ ] Ensure color contrast meets WCAG AA
- [ ] Support system font scaling
- [ ] Add focus indicators

#### Testing Phase 8.4
- [ ] TalkBack can navigate entire app
- [ ] All actions have labels
- [ ] Large text mode works

---

## Phase 9: Testing & Release

### 9.1 Unit Tests
- [ ] Test all use cases
- [ ] Test all repositories
- [ ] Test stat calculations
- [ ] Test date utilities

#### Testing Phase 9.1
- [ ] >80% code coverage on domain layer
- [ ] All edge cases covered

---

### 9.2 Widget Tests
- [ ] Test habit card widget
- [ ] Test completion toggle
- [ ] Test form validation
- [ ] Test navigation

#### Testing Phase 9.2
- [ ] Key widgets have tests
- [ ] Interactions work as expected

---

### 9.3 Integration Tests
- [ ] Test full habit creation flow
- [ ] Test completion flow
- [ ] Test analytics accuracy
- [ ] Test notification flow

#### Testing Phase 9.3
- [ ] Critical paths all pass
- [ ] No regressions

---

### 9.4 Manual QA
- [ ] Test on multiple Android versions (API 26+)
- [ ] Test on different screen sizes
- [ ] Test offline functionality
- [ ] Test data persistence across updates
- [ ] Dogfood for 1 week

#### Testing Phase 9.4
- [ ] No critical bugs
- [ ] App is pleasant to use daily

---

### 9.5 Release Preparation
- [ ] Finalize app icon
- [ ] Create splash screen
- [ ] Write Play Store description (if publishing)
- [ ] Create screenshots
- [ ] Configure release build
- [ ] Test release APK

#### Testing Phase 9.5
- [ ] Release build works correctly
- [ ] APK size is reasonable
- [ ] All assets included

---

## Current Status

**Current Phase:** Phase 6 - Screens (core screens functional; deep analytics redesign next)
**Current Task:** Deep analytics hub + drill-down design approved. Providers (3.4) then screens (6.6a-g) next.
**Last Updated:** 2026-02-24
**Blockers:** None
**Design Doc:** `docs/plans/2026-02-24-deep-analytics-design.md`

---

## Notes & Decisions

- **CHANGED:** Using Hive instead of Isar due to codegen conflicts with riverpod_generator (source_gen version mismatch)
- **CHANGED:** Dropped code generators (riverpod_generator, isar_generator) - writing providers and type adapters manually
- **PROGRESS 2026-02-05:** Added `app/router.dart`, `core/theme/app_shadows.dart`, domain entity classes, manual Hive models/adapters, Hive database bootstrap, and `database_provider`.
- **PROGRESS 2026-02-05:** Added repository interfaces/implementations, habit/completion/stack use cases, and core+completion Riverpod providers with optimistic completion toggles.
- **PROGRESS 2026-02-05:** Replaced Home/Habits placeholder content with provider-backed lists, quick habit creation dialog, and completion toggles.
- **PROGRESS 2026-02-05:** Completed Phase 4.3 and 4.4 providers (analytics/habit stats/heatmap/stacks/chain) with cache-aware recomputation tied to completion revisions.
- **PROGRESS 2026-02-05:** Completed Phase 5 widget scaffolding (common/habit/chart/navigation) and wired app shell to shared bottom navigation widget.
- **DECISION 2026-02-05:** Approved full usability/polish pass before deeper feature expansion; keep implementation in locked sequence and include playful Habits UI plus Habit Detail analytics glimpse.
- **PROGRESS 2026-02-06:** Added shared create/edit habit form sheet with weekly multi-day selection, monthly date multi-select, and calendar-assisted date picking.
- **PROGRESS 2026-02-06:** Reworked scorecard to a rolling timeline grid and added refresh/horizontal-scroll improvements.
- **FEEDBACK 2026-02-06:** Remaining fixes requested: scorecard edit-guardrails, detail edit reliability, completion animation redesign, and overflow/polish issues.
- **PROGRESS 2026-02-05 (Claude):** Phase A - Created habit_checkbox.dart, fixed Scrollbar ScrollController crash, hardened Hive init with corruption recovery.
- **PROGRESS 2026-02-05 (Claude):** Phase B - Fixed edit from detail screen, added bottom padding for chart overlap, replaced month picker with calendar grid, made analytics grid read-only.
- **PROGRESS 2026-02-05 (Claude):** Phase C - Redesigned completion animation (bounce-scale + color fill), overhauled analytics screen (summary cards, today highlight, color indicators), consolidated to 4-tab nav (removed empty Analytics placeholder, renamed Scorecard to Analytics).
- **DECISION 2026-02-05:** Deferred stacks, notifications, CSV export, drill-down analytics, accessibility, and performance optimization to v2.
- **DECISION 2026-02-24:** Approved deep analytics redesign — hub + drill-down replacing the shallow scorecard-only Analytics tab. Design doc: `docs/plans/2026-02-24-deep-analytics-design.md`. Inspired by Loop (habit strength algorithm), Habitify (multi-timeframe trends), and Pattrn (score-based tracking). Six hub cards drill into: Score History, Weekly Trends, Streaks, Full Heatmap, Habit Rankings, and existing Scorecard Grid.
- Riverpod chosen for testability and clean state management
- Clean Architecture for maintainability
- Dark mode only for v1 (light mode can be added later)
- Notifications use local scheduling, no server required
- Windows Developer Mode enabled for symlinks

---

## Dependencies Between Tasks

```
Phase 1 (Setup)
    ↓
Phase 2 (Data) → Phase 3 (Domain) → Phase 4 (State)
    ↓                                    ↓
Phase 5 (Components) ←──────────────────┘
    ↓
Phase 6 (Screens)
    ↓
Phase 7 (Features)
    ↓
Phase 8 (Polish)
    ↓
Phase 9 (Testing & Release)
```

---

## Quick Reference

| Phase | Est. Complexity | Critical Path |
|-------|----------------|---------------|
| 1. Setup | Low | Yes |
| 2. Data | Medium | Yes |
| 3. Domain | Medium | Yes |
| 4. State | Medium | Yes |
| 5. Components | Medium | Yes |
| 6. Screens | High | Yes |
| 7. Features | Medium | No (can parallelize) |
| 8. Polish | Low-Medium | No |
| 9. Testing | Medium | Yes |


