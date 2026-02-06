# Atomic Habits Tracker - Product Requirements Document

## 1. Overview

A native Android habits tracking application built on James Clear's "Atomic Habits" framework. The app enables users to build and maintain habits through identity-based tracking, habit stacking, implementation intentions, and comprehensive analytics. Fully offline-first with local data storage.

**Target Platform**: Android (primary), iOS (future)
**Target User**: Individuals seeking structured, science-backed habit formation
**Development Approach**: Full build, ship-ready

---

## 2. Goals & Success Metrics

### Primary Goals
1. Provide a complete implementation of Atomic Habits principles in app form
2. Enable deep self-analysis through rich analytics and drill-down dashboards
3. Deliver native performance with zero network dependency

### Success Metrics (Personal Use)
- Daily app engagement for habit logging
- Habit completion rate improvement over 30/60/90 day periods
- Streak maintenance across core habits

---

## 3. Core Concepts (Atomic Habits Framework)

### 3.1 Identity-Based Habits
Every habit is tied to an identity statement that reinforces who the user is becoming.

- **Structure**: "I am someone who [identity]"
- **Examples**:
  - "I am someone who exercises daily"
  - "I am someone who reads before bed"
- **Implementation**: Each habit can have an optional identity statement displayed during check-in

### 3.2 The Four Laws of Behavior Change
Each habit should be designed around these laws:

| Law | Principle | App Implementation |
|-----|-----------|-------------------|
| 1st Law | Make it Obvious | Implementation intentions, visual cues, notifications |
| 2nd Law | Make it Attractive | Habit stacking with enjoyable habits, streak rewards |
| 3rd Law | Make it Easy | 2-minute rule versions, friction reduction |
| 4th Law | Make it Satisfying | Immediate tracking feedback, visual progress, streaks |

### 3.3 Habit Stacking
Link habits together in chains where completing one triggers the next.

- **Structure**: "After I [CURRENT HABIT], I will [NEW HABIT]"
- **Chains**: Support multi-step chains (A → B → C → D)
- **Use Case**: Morning routine - Wake up → Make bed → Meditate → Exercise → Shower
- **Notification Behavior**: Completing a habit in a stack can trigger the notification for the next

### 3.4 Implementation Intentions
Every habit has a specific plan for execution.

- **Structure**: "I will [BEHAVIOR] at [TIME] in [LOCATION]"
- **Fields**:
  - Behavior: The habit itself
  - Time: Specific time or trigger (after another habit)
  - Location: Where the habit occurs
- **Example**: "I will meditate for 10 minutes at 7:00 AM in the living room"

### 3.5 Two-Minute Rule
Each habit has a scaled-down "gateway" version that takes 2 minutes or less.

- **Purpose**: Lower activation energy on difficult days
- **Structure**: Each habit has an optional 2-minute version
- **Examples**:
  - Full habit: "Run for 30 minutes" → 2-min version: "Put on running shoes"
  - Full habit: "Read for 1 hour" → 2-min version: "Read one page"
- **Tracking**: Both versions count as completion, but can be distinguished in analytics

### 3.6 Habit Scorecard
A daily/weekly view showing all habits and their completion status at a glance.

- Visual grid of habits × days
- Color-coded completion status
- Quick-entry mode for batch logging

---

## 4. Feature Specifications

### 4.1 Habit Management

#### 4.1.1 Create Habit
**Required Fields**:
- Name (string, max 100 chars)
- Schedule type: Daily | Weekly | Monthly
- Schedule details:
  - Daily: Every day
  - Weekly: Select days (M/T/W/T/F/S/S)
  - Monthly: Select dates (1-31, handles month variations)

**Optional Fields**:
- Identity statement (string)
- Implementation intention:
  - Time (time picker or "After [habit]")
  - Location (string)
- Two-minute version (string description)
- Habit stack position (link to previous/next habits)
- Category/Tag (for organization)
- Color (for visual identification)
- Notes (freeform text)

#### 4.1.2 Edit Habit
- All fields editable
- Schedule changes apply from current date forward
- Historical data preserved

#### 4.1.3 Archive/Delete Habit
- **Archive**: Removes from active view, preserves all history for analytics
- **Delete**: Permanent removal with confirmation (data unrecoverable)

#### 4.1.4 Reorder Habits
- Drag-and-drop reordering in list view
- Affects display order only (not stack order)

### 4.2 Habit Stacking

#### 4.2.1 Stack Creation
- Select a habit as "trigger" (After I...)
- Select a habit as "response" (I will...)
- Creates directional link

#### 4.2.2 Chain Building
- Multiple habits can be chained: A → B → C → D
- Visual representation of chains in dedicated view
- A habit can only have one "previous" but multiple "next" (branching allowed)

#### 4.2.3 Stack Execution
- Completing a habit shows prompt for next habit in chain
- Optional: Auto-trigger notification for next habit
- Chain progress visualized during execution

### 4.3 Habit Tracking

#### 4.3.1 Daily Check-in
- Main screen shows today's habits
- One-tap completion toggle
- Option to mark as "2-minute version completed"
- Optional note on completion

#### 4.3.2 Batch Entry (Habit Scorecard)
- Grid view: Habits (rows) × Days (columns)
- Tap to toggle any cell
- Scroll horizontally for past days
- Visual indicators: Complete / Incomplete / 2-min / Skipped

#### 4.3.3 Historical Edit
- Can modify past entries (with visual indicator that it was edited)
- Useful for catching up after forgetting to log

#### 4.3.4 Skip Functionality
- Mark a habit as "skipped" for a day with optional reason
- Skipped ≠ Failed (different analytics treatment)
- Use cases: Sick, traveling, intentional rest day

### 4.4 Notifications

#### 4.4.1 Per-Habit Notifications
- Enable/disable per habit
- Set specific time(s)
- Set trigger: Clock time OR "After completing [habit]"
- Customizable message (default: habit name)

#### 4.4.2 Notification Behavior
- Tapping notification opens app to that habit
- Quick-complete action from notification (Android)
- Snooze option (5/15/30 min)

#### 4.4.3 Daily Summary (Optional)
- End-of-day notification summarizing completion
- Morning notification showing today's habits

### 4.5 Analytics Dashboard

#### 4.5.1 Overview Screen
- Current streaks (all habits)
- Today's completion rate
- This week's completion rate
- Habit health score (composite metric)

#### 4.5.2 Streaks
- Current streak per habit
- Longest streak per habit
- Streak history (when streaks broke)
- Global "all habits completed" streak

#### 4.5.3 Completion Analytics
- Completion rate by: day/week/month/year/all-time
- Completion rate by: habit / category / all habits
- Trend lines showing improvement/decline

#### 4.5.4 Heatmaps
- GitHub-style contribution heatmap per habit
- Combined heatmap (all habits)
- Configurable time range

#### 4.5.5 Temporal Analysis
- Best/worst days of week
- Best/worst times of day (based on completion times)
- Monthly patterns
- Seasonal trends (if sufficient data)

#### 4.5.6 Drill-Down Capability
- Tap any metric to see underlying data
- Filter by: date range, habit, category, completion type
- Comparative views (habit vs habit, period vs period)

#### 4.5.7 Habit-Specific Deep Dive
- Individual habit screen with full history
- All metrics specific to that habit
- Streak timeline visualization
- Notes history

### 4.6 Data Management

#### 4.6.1 CSV Export
- Export all data or filtered subset
- Includes: habits, completions, streaks, notes
- Date range selection

#### 4.6.2 Backup (Future Consideration)
- Manual backup to device storage
- Restore from backup file

---

## 5. Data Model

### 5.1 Core Entities

```
Habit
├── id: UUID
├── name: String
├── createdAt: DateTime
├── archivedAt: DateTime?
├── scheduleType: Enum (daily, weekly, monthly)
├── scheduleDays: List<int>?        // For weekly: 0-6 (Mon-Sun)
├── scheduleDates: List<int>?       // For monthly: 1-31
├── identityStatement: String?
├── implementationTime: Time?
├── implementationLocation: String?
├── twoMinuteVersion: String?
├── color: String?
├── category: String?
├── notes: String?
├── displayOrder: int
├── notificationsEnabled: bool
├── notificationTimes: List<Time>
├── notificationTriggerHabitId: UUID?   // For "after habit X" triggers

HabitStack
├── id: UUID
├── previousHabitId: UUID
├── nextHabitId: UUID
├── createdAt: DateTime

HabitCompletion
├── id: UUID
├── habitId: UUID
├── date: Date
├── completedAt: DateTime
├── completionType: Enum (full, twoMinute, skipped)
├── skipReason: String?
├── note: String?
├── wasEdited: bool

Category
├── id: UUID
├── name: String
├── color: String?
├── displayOrder: int
```

### 5.2 Computed/Derived Data

```
HabitStats (computed on-demand or cached)
├── habitId: UUID
├── currentStreak: int
├── longestStreak: int
├── longestStreakStart: Date
├── longestStreakEnd: Date
├── totalCompletions: int
├── totalScheduledDays: int
├── completionRate: float
├── lastCompletedAt: DateTime?
```

---

## 6. Technical Architecture

### 6.1 Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.x |
| Language | Dart |
| State Management | Riverpod |
| Local Database | Isar |
| Charts | fl_chart |
| Notifications | flutter_local_notifications |
| Architecture | Clean Architecture + Repository Pattern |

### 6.2 Layer Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── router.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── extensions/
├── data/
│   ├── datasources/
│   │   └── local/
│   │       ├── isar_database.dart
│   │       └── habit_local_datasource.dart
│   ├── models/              # Isar models
│   │   ├── habit_model.dart
│   │   ├── completion_model.dart
│   │   └── ...
│   └── repositories/
│       └── habit_repository_impl.dart
├── domain/
│   ├── entities/            # Pure Dart classes
│   │   ├── habit.dart
│   │   ├── completion.dart
│   │   └── ...
│   ├── repositories/        # Abstract interfaces
│   │   └── habit_repository.dart
│   └── usecases/
│       ├── create_habit.dart
│       ├── complete_habit.dart
│       ├── get_habit_stats.dart
│       └── ...
├── presentation/
│   ├── providers/           # Riverpod providers
│   ├── screens/
│   │   ├── home/
│   │   ├── habit_detail/
│   │   ├── analytics/
│   │   ├── settings/
│   │   └── ...
│   └── widgets/
│       ├── common/
│       ├── habit/
│       ├── charts/
│       └── ...
└── services/
    ├── notification_service.dart
    └── export_service.dart
```

### 6.3 State Management (Riverpod)

Key providers:
- `habitsProvider`: All active habits
- `todayHabitsProvider`: Habits scheduled for today
- `habitCompletionsProvider(date)`: Completions for a date
- `habitStatsProvider(habitId)`: Stats for a habit
- `analyticsProvider`: Dashboard data
- `habitStacksProvider`: All habit stacks/chains

### 6.4 Database Schema (Isar)

Isar collections mirror the data model entities. Indexes on:
- `Habit.createdAt`
- `Habit.archivedAt`
- `HabitCompletion.habitId`
- `HabitCompletion.date`
- `HabitCompletion.completedAt`

---

## 7. Screen Inventory

### 7.1 Primary Screens

1. **Home / Today** - Today's habits with quick completion
2. **Habit Scorecard** - Grid view for batch entry
3. **Habits List** - All habits with management options
4. **Habit Detail** - Single habit view with all settings
5. **Create/Edit Habit** - Form for habit configuration
6. **Habit Stacks** - Visualize and manage chains
7. **Analytics Dashboard** - Overview metrics
8. **Analytics Detail** - Drill-down views (streaks, heatmaps, trends)
9. **Habit Analytics** - Single habit deep dive
10. **Settings** - App configuration, export, about

### 7.2 Navigation Structure

```
Bottom Navigation:
├── Today (Home)
├── Scorecard
├── Habits
├── Analytics
└── Settings
```

---

## 8. Non-Functional Requirements

### 8.1 Performance
- App launch to interactive: < 2 seconds
- Habit completion feedback: < 100ms
- Analytics load: < 1 second for 1 year of data
- Smooth 60fps scrolling in all lists

### 8.2 Storage
- Efficient storage: 1 year of data for 20 habits < 10MB
- Handle 100+ habits without degradation

### 8.3 Reliability
- Zero data loss on crash
- Transactional database writes
- Graceful handling of edge cases (month boundaries, timezone changes)

### 8.4 Accessibility
- Minimum touch target: 48x48dp
- Support for system font scaling
- Sufficient color contrast (WCAG AA)
- Screen reader compatibility

---

## 9. Future Considerations (Out of Scope for V1)

- iOS release
- Cloud backup/sync
- Widgets (home screen)
- Wear OS companion
- Habit templates/presets
- Social features (accountability partners)
- Gamification (points, levels, badges)
- Habit suggestions based on goals
- Integration with other apps (calendar, health)
- Quantitative habits (track amounts, not just done/not done)

---

## 10. Open Questions

1. **Streak forgiveness**: Should there be a "freeze" or "vacation mode" that pauses streaks without breaking them?
2. **Habit difficulty levels**: Track perceived difficulty at completion time?
3. **Time tracking**: Log how long habits take to complete?
4. **Cue/reward logging**: Explicitly track cues that triggered habits and rewards after?

---

## 11. Success Criteria for Launch

- [ ] All core habit CRUD operations functional
- [ ] All three schedule types working (daily/weekly/monthly)
- [ ] Habit stacking with chains functional
- [ ] Implementation intentions captured and displayed
- [ ] 2-minute versions trackable
- [ ] Notifications working reliably
- [ ] Analytics dashboard with all specified visualizations
- [ ] Drill-down capability functional
- [ ] CSV export working
- [ ] App performs within NFR targets
- [ ] No critical bugs in week of testing

---

*Document Version: 1.0*
*Last Updated: 2026-01-31*
