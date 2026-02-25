# V2 Implementation Plan: UX Polish + Notifications + Habit Stacks

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Elevate the Atomic Habits Tracker from functional to delightful with polished transitions, smart notifications, and full habit stack support.

**Architecture:** Three parallel workstreams with minimal file overlap. Each workstream is self-contained and can be implemented by an independent agent teammate. Shared file conflicts resolved by clear ownership rules below.

**Tech Stack:** Flutter/Dart, Hive (manual adapters), Riverpod, flutter_local_notifications, permission_handler, flutter_animate, fl_chart

**Design Doc:** `docs/plans/2026-02-24-v2-design.md`

---

## File Ownership Rules

| File | Owner | Notes |
|------|-------|-------|
| `lib/presentation/widgets/**` | Polish | All widget changes (empty_state, particles, milestone, habit_card hero) |
| `lib/presentation/screens/home/home_screen.dart` | Polish | Empty state, pull-to-refresh, particle burst, milestone toast |
| `lib/presentation/widgets/navigation/bottom_nav_bar.dart` | Polish | Fade-through transitions |
| `lib/app/router.dart` | Polish | Page transition wrappers |
| `lib/domain/entities/habit.dart` | Notifications | Add reminderTime field |
| `lib/data/models/habit_model.dart` | Notifications | Add HiveField 19 |
| `lib/data/services/**` | Notifications | New notification + settings services |
| `lib/presentation/screens/settings/settings_screen.dart` | Notifications | Nudge settings section |
| `lib/presentation/screens/habits/habit_form_sheet.dart` | Notifications | Reminder time picker |
| `lib/presentation/providers/notification_provider.dart` | Notifications | New |
| `lib/presentation/providers/settings_provider.dart` | Notifications | New |
| `lib/domain/entities/stack.dart` | Stacks | New (or check existing) |
| `lib/data/models/stack_model.dart` | Stacks | Existing — review/update |
| `lib/presentation/screens/stacks/**` | Stacks | All new stack screens |
| `lib/presentation/screens/habits/habits_list_screen.dart` | Stacks | Add stacks toggle |
| `lib/presentation/providers/stacks_provider.dart` | Stacks | New |
| `lib/presentation/providers/stack_analytics_provider.dart` | Stacks | New |

**Integration points (handled in final synthesis):**
- Stacks adds chain prompt snackbar to `home_screen.dart` after Polish is done
- Polish teammate's empty state widget is reused by Stacks for empty stacks list

---

## Workstream 1: UX Polish

### Task P1: Rewrite EmptyState Widget

**Files:**
- Modify: `lib/presentation/widgets/common/empty_state.dart`

**Step 1: Rewrite EmptyState with illustration support**

Replace the current basic implementation with a richer empty state:

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.inbox_outlined,
    this.iconSize = 64,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final IconData icon;
  final double iconSize;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              title,
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.space20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.backgroundPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space24,
                    vertical: AppSpacing.space12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Run analyze**

Run: `/c/flutter/bin/flutter analyze`
Expected: 0 issues

**Step 3: Commit**

```bash
git add lib/presentation/widgets/common/empty_state.dart
git commit -m "feat: rewrite EmptyState widget with illustration circle and gold CTA"
```

---

### Task P2: Add Empty States to Home and Analytics Screens

**Files:**
- Modify: `lib/presentation/screens/home/home_screen.dart`
- Modify: `lib/presentation/screens/analytics/analytics_hub_screen.dart`

**Step 1: Update Home screen empty state**

In `home_screen.dart`, find the existing `EmptyState` usage (around line 63) and update to:

```dart
EmptyState(
  icon: Icons.wb_sunny_outlined,
  title: 'Your first habit starts here',
  description: 'Small daily habits compound into remarkable results. Start with just one.',
  actionLabel: 'Create First Habit',
  onAction: () async {
    final newHabit = await showHabitFormSheet(context: context, defaultDisplayOrder: 0);
    if (newHabit == null) return;
    await ref.read(habitsProvider.notifier).createHabit(newHabit);
  },
)
```

**Step 2: Add insufficient-data state to Analytics hub**

In `analytics_hub_screen.dart`, when all habits have < 3 days of data, show:

```dart
EmptyState(
  icon: Icons.insights_outlined,
  title: 'Building your story',
  description: 'Complete habits for a few days and your analytics will come alive.',
)
```

**Step 3: Run analyze**

Run: `/c/flutter/bin/flutter analyze`
Expected: 0 issues

**Step 4: Commit**

```bash
git add lib/presentation/screens/home/home_screen.dart lib/presentation/screens/analytics/analytics_hub_screen.dart
git commit -m "feat: add meaningful empty states to Home and Analytics screens"
```

---

### Task P3: Completion Particle Burst Animation

**Files:**
- Create: `lib/presentation/widgets/habit/completion_particles.dart`
- Modify: `lib/presentation/widgets/habit/habit_card.dart` (add Hero + particle overlay)

**Step 1: Create CompletionParticles widget**

```dart
import 'dart:math';
import 'package:flutter/material.dart';

class CompletionParticles extends StatefulWidget {
  const CompletionParticles({
    super.key,
    required this.color,
    required this.onComplete,
  });

  final Color color;
  final VoidCallback onComplete;

  @override
  State<CompletionParticles> createState() => _CompletionParticlesState();
}

class _CompletionParticlesState extends State<CompletionParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(6, (_) => _Particle(rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _Particle {
  _Particle(Random rng)
      : angle = rng.nextDouble() * 2 * pi,
        distance = 12.0 + rng.nextDouble() * 14.0,
        size = 2.0 + rng.nextDouble() * 2.0;

  final double angle;
  final double distance;
  final double size;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  final List<_Particle> particles;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color.withOpacity(1.0 - progress);

    for (final p in particles) {
      final dx = cos(p.angle) * p.distance * progress;
      final dy = sin(p.angle) * p.distance * progress;
      final radius = p.size * (1.0 - progress * 0.5);
      canvas.drawCircle(center + Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.progress != progress;
}
```

Note: `AnimatedBuilder` may need to be `AnimatedWidget` or the build should use `_controller.addListener` + `setState`. Verify the exact Flutter API — `AnimatedBuilder` takes `animation` and `builder` params.

**Step 2: Add Hero wrapper and particle trigger to HabitCard**

In `habit_card.dart`, wrap the accent color bar with `Hero(tag: 'habit_color_$id')` and add an `OverlayEntry` trigger on completion. The particle burst fires from the checkbox position when `onToggle` is called with `true`.

**Step 3: Run analyze and test**

Run: `/c/flutter/bin/flutter analyze && /c/flutter/bin/flutter test`
Expected: 0 issues, 1/1 test passing

**Step 4: Commit**

```bash
git add lib/presentation/widgets/habit/completion_particles.dart lib/presentation/widgets/habit/habit_card.dart
git commit -m "feat: add completion particle burst animation on habit toggle"
```

---

### Task P4: Streak Milestone Celebrations

**Files:**
- Create: `lib/presentation/widgets/common/milestone_celebration.dart`
- Modify: `lib/presentation/screens/home/home_screen.dart` (trigger on completion)

**Step 1: Create MilestoneCelebration overlay widget**

Build a brief gold confetti animation (1.5s) using `flutter_animate` that can be triggered as an overlay. Include a toast-style banner showing the milestone text (e.g., "7-day streak! You're building momentum.").

Milestone thresholds: `const milestones = [7, 30, 60, 90, 180, 365];`

**Step 2: Wire into home screen completion toggle**

After a successful completion toggle, check the new streak length. If it matches a milestone, trigger the celebration overlay.

```dart
// Inside onToggle callback, after toggleCompletion:
final newStreak = /* get updated streak */;
if (milestones.contains(newStreak)) {
  showMilestoneCelebration(context, streak: newStreak);
}
```

**Step 3: Add haptic feedback**

Import `package:flutter/services.dart` and add:
- `HapticFeedback.lightImpact()` on every completion toggle
- `HapticFeedback.mediumImpact()` on milestone celebrations

**Step 4: Run analyze and test**

Run: `/c/flutter/bin/flutter analyze && /c/flutter/bin/flutter test`

**Step 5: Commit**

```bash
git add lib/presentation/widgets/common/milestone_celebration.dart lib/presentation/screens/home/home_screen.dart
git commit -m "feat: add streak milestone celebrations with confetti and haptic feedback"
```

---

### Task P5: Page Transitions

**Files:**
- Modify: `lib/presentation/widgets/navigation/bottom_nav_bar.dart`
- Modify: `lib/app/router.dart`
- Modify: Parent scaffold that manages tab switching (check `main.dart` or root widget)

**Step 1: Add fade-through tab transitions**

Wrap the tab body in an `AnimatedSwitcher` with 300ms duration and `FadeTransition`:

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  child: screens[currentIndex],
)
```

Ensure each screen has a unique `key` (e.g., `ValueKey(currentIndex)`) for the switcher to detect changes.

**Step 2: Add Hero support for habit card → detail navigation**

In `habit_card.dart`, the color accent bar is wrapped with `Hero(tag: 'habit_color_${id}')`.
In `habit_detail_screen.dart`, the gradient header wraps with matching `Hero(tag: 'habit_color_${habitId}')`.

**Step 3: Update router.dart for container transforms**

For pushed routes (detail screens, drill-downs), use a custom `PageRouteBuilder` with a fade + slide-up:

```dart
PageRouteBuilder(
  pageBuilder: (_, __, ___) => TargetScreen(),
  transitionsBuilder: (_, animation, __, child) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  },
  transitionDuration: const Duration(milliseconds: 350),
)
```

**Step 4: Run analyze and test**

Run: `/c/flutter/bin/flutter analyze && /c/flutter/bin/flutter test`

**Step 5: Commit**

```bash
git add lib/presentation/widgets/navigation/bottom_nav_bar.dart lib/app/router.dart lib/presentation/widgets/habit/habit_card.dart
git commit -m "feat: add fade-through tab transitions and hero animations"
```

---

### Task P6: Pull-to-Refresh and Ripple Audit

**Files:**
- Modify: `lib/presentation/screens/home/home_screen.dart`
- Audit: All tappable widgets for proper InkWell/ripple feedback

**Step 1: Add pull-to-refresh to Home screen**

Wrap the `ListView` in a `RefreshIndicator`:

```dart
RefreshIndicator(
  onRefresh: () async {
    ref.invalidate(todayHabitsProvider);
    ref.invalidate(todayCompletionsProvider);
    ref.invalidate(currentStreaksProvider);
    ref.invalidate(dailyEffortProvider);
  },
  color: AppColors.accentGold,
  child: ListView(/* existing content */),
)
```

**Step 2: Audit ripple/press states**

Check that all tappable cards, tiles, and buttons use `InkWell` or `Material` wrappers with proper splash. Key areas:
- Analytics hub cards
- Ranking rows (already has InkWell ✓)
- Settings tiles (already has InkWell ✓)
- Habit cards — ensure the full card is tappable, not just the checkbox

**Step 3: Run analyze and test**

Run: `/c/flutter/bin/flutter analyze && /c/flutter/bin/flutter test`

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: add pull-to-refresh on Home screen and audit ripple states"
```

---

## Workstream 2: Notifications

### Task N1: Add reminderTime to Habit Entity and Model

**Files:**
- Modify: `lib/domain/entities/habit.dart`
- Modify: `lib/data/models/habit_model.dart`

**Step 1: Add reminderTime to Habit entity**

Add field to the Habit class (after `durationMinutes`):

```dart
final int? reminderTime; // minutes since midnight, nullable
```

Add to constructor, copyWith, == operator, and hashCode.

**Step 2: Add HiveField 19 to HabitModel**

In `habit_model.dart`:
- Add `int? reminderTime;` field to model class
- In adapter `read()`: add `reminderTime: fields[19] as int?,`
- In adapter `write()`: change `writeByte(19)` → `writeByte(20)` and add field 19 write
- Update `toEntity` and `fromEntity` to include `reminderTime`

**Step 3: Run analyze**

Run: `/c/flutter/bin/flutter analyze`
Expected: 0 issues

**Step 4: Commit**

```bash
git add lib/domain/entities/habit.dart lib/data/models/habit_model.dart
git commit -m "feat: add reminderTime field to Habit entity (HiveField 19)"
```

---

### Task N2: Create Settings Service

**Files:**
- Create: `lib/data/services/settings_service.dart`
- Modify: `lib/data/datasources/local/hive_database.dart` (add settings box)

**Step 1: Add settings box to HiveDatabase**

Add a new box name constant:
```dart
static const settingsBoxName = 'settings_box';
```

In `_openBoxes()`, add:
```dart
if (!Hive.isBoxOpen(settingsBoxName))
  Hive.openBox(settingsBoxName),
```

Add static getter:
```dart
static Box get settingsBox => Hive.box(settingsBoxName);
```

Note: This is a plain `Box` (not `Box<Model>`) since settings are simple key-value pairs.

**Step 2: Create SettingsService**

```dart
import '../../data/datasources/local/hive_database.dart';

class SettingsService {
  static const _eveningNudgeEnabledKey = 'eveningNudgeEnabled';
  static const _eveningNudgeTimeKey = 'eveningNudgeTime';
  static const _positiveNudgeEnabledKey = 'positiveNudgeEnabled';

  Box get _box => HiveDatabase.settingsBox;

  bool get eveningNudgeEnabled =>
      _box.get(_eveningNudgeEnabledKey, defaultValue: false) as bool;
  set eveningNudgeEnabled(bool v) => _box.put(_eveningNudgeEnabledKey, v);

  int get eveningNudgeTime =>
      _box.get(_eveningNudgeTimeKey, defaultValue: 1260) as int; // 9pm
  set eveningNudgeTime(int v) => _box.put(_eveningNudgeTimeKey, v);

  bool get positiveNudgeEnabled =>
      _box.get(_positiveNudgeEnabledKey, defaultValue: true) as bool;
  set positiveNudgeEnabled(bool v) => _box.put(_positiveNudgeEnabledKey, v);
}
```

**Step 3: Create settings provider**

```dart
// lib/presentation/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/settings_service.dart';

final settingsServiceProvider = Provider((_) => SettingsService());

final eveningNudgeEnabledProvider = StateProvider<bool>((ref) {
  return ref.watch(settingsServiceProvider).eveningNudgeEnabled;
});

final eveningNudgeTimeProvider = StateProvider<int>((ref) {
  return ref.watch(settingsServiceProvider).eveningNudgeTime;
});

final positiveNudgeEnabledProvider = StateProvider<bool>((ref) {
  return ref.watch(settingsServiceProvider).positiveNudgeEnabled;
});
```

**Step 4: Run analyze**

Run: `/c/flutter/bin/flutter analyze`

**Step 5: Commit**

```bash
git add lib/data/services/settings_service.dart lib/data/datasources/local/hive_database.dart lib/presentation/providers/settings_provider.dart
git commit -m "feat: add settings service with Hive box for notification preferences"
```

---

### Task N3: Create Notification Service

**Files:**
- Create: `lib/data/services/notification_service.dart`
- Create: `lib/presentation/providers/notification_provider.dart`

**Step 1: Create NotificationService**

Core class handling:
- `initialize()`: Set up `FlutterLocalNotificationsPlugin` with Android channel
- `requestPermission()`: Use `permission_handler` to request notification permission
- `scheduleHabitReminder(habit)`: Schedule a daily notification at `habit.reminderTime` using `zonedSchedule`, only on scheduled days
- `scheduleEveningNudge(time, habits, completions)`: Schedule evening check
- `cancelAll()`: Cancel all scheduled notifications
- `rescheduleAll(habits, settings)`: Cancel + reschedule everything (called on app launch and after edits)

Use `flutter_local_notifications` `zonedSchedule` with `timezone` package. Android notification channel: "Habit Reminders", importance high.

Notification IDs:
- Per-habit: `habit.id.hashCode.abs() % 100000`
- Evening nudge: fixed `0`

**Step 2: Create notification provider**

```dart
// lib/presentation/providers/notification_provider.dart
final notificationServiceProvider = Provider((_) => NotificationService());

final notificationSchedulerProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  final habits = await ref.watch(habitsProvider.future);
  final settings = ref.watch(settingsServiceProvider);
  await service.rescheduleAll(habits, settings);
});
```

**Step 3: Initialize on app launch**

In `main.dart` or the root widget, watch `notificationSchedulerProvider` to trigger scheduling on startup.

**Step 4: Run analyze**

Run: `/c/flutter/bin/flutter analyze`

**Step 5: Commit**

```bash
git add lib/data/services/notification_service.dart lib/presentation/providers/notification_provider.dart
git commit -m "feat: add notification service with per-habit reminders and evening nudge"
```

---

### Task N4: Add Reminder Time Picker to Habit Form

**Files:**
- Modify: `lib/presentation/screens/habits/habit_form_sheet.dart`

**Step 1: Add reminderTime state variable**

```dart
TimeOfDay? reminderTime = initialHabit?.reminderTime != null
    ? TimeOfDay(
        hour: initialHabit!.reminderTime! ~/ 60,
        minute: initialHabit.reminderTime! % 60,
      )
    : null;
```

**Step 2: Add reminder time picker UI**

After the 2-minute version field, add a section:

```dart
// Reminder
const SizedBox(height: AppSpacing.space16),
Text('Daily Reminder', style: AppTypography.labelMedium),
const SizedBox(height: AppSpacing.space8),
Row(
  children: [
    Switch(
      value: reminderTime != null,
      activeColor: AppColors.twoMinuteBlue,
      onChanged: (enabled) {
        setState(() {
          if (enabled) {
            // Auto-suggest from implementation time if available
            reminderTime = _parseImplementationTime(implementationTimeController.text)
                ?? const TimeOfDay(hour: 8, minute: 0);
          } else {
            reminderTime = null;
          }
        });
      },
    ),
    const SizedBox(width: 8),
    if (reminderTime != null)
      ActionChip(
        avatar: Icon(Icons.access_time, size: 16, color: AppColors.twoMinuteBlue),
        label: Text(reminderTime!.format(context)),
        backgroundColor: AppColors.twoMinuteBlueSubtle,
        onPressed: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: reminderTime!,
          );
          if (picked != null) setState(() => reminderTime = picked);
        },
      )
    else
      Text('No reminder', style: AppTypography.bodySmall.copyWith(
        color: AppColors.textTertiary,
      )),
  ],
),
```

**Step 3: Include reminderTime in save handler**

In the `Habit(...)` constructor call:
```dart
reminderTime: reminderTime != null
    ? reminderTime!.hour * 60 + reminderTime!.minute
    : null,
```

**Step 4: Request notification permission on first enable**

When the switch turns on and `reminderTime` was previously null for all habits, call:
```dart
await NotificationService().requestPermission();
```

**Step 5: Run analyze**

Run: `/c/flutter/bin/flutter analyze`

**Step 6: Commit**

```bash
git add lib/presentation/screens/habits/habit_form_sheet.dart
git commit -m "feat: add reminder time picker to habit form with auto-suggest from intentions"
```

---

### Task N5: Add Notification Settings to Settings Screen

**Files:**
- Modify: `lib/presentation/screens/settings/settings_screen.dart`

**Step 1: Add Notifications section**

After the "About" section, before "Developer Tools":

```dart
// Notifications
_SectionHeader(title: 'Notifications'),
const SizedBox(height: AppSpacing.space8),
_ToggleTile(
  icon: Icons.nightlight_outlined,
  title: 'Evening Nudge',
  subtitle: 'Remind me about uncompleted habits',
  value: ref.watch(eveningNudgeEnabledProvider),
  onChanged: (v) {
    ref.read(eveningNudgeEnabledProvider.notifier).state = v;
    ref.read(settingsServiceProvider).eveningNudgeEnabled = v;
  },
),
if (ref.watch(eveningNudgeEnabledProvider))
  _TimeTile(
    icon: Icons.access_time,
    title: 'Nudge Time',
    minutesSinceMidnight: ref.watch(eveningNudgeTimeProvider),
    onChanged: (minutes) {
      ref.read(eveningNudgeTimeProvider.notifier).state = minutes;
      ref.read(settingsServiceProvider).eveningNudgeTime = minutes;
    },
  ),
_ToggleTile(
  icon: Icons.celebration_outlined,
  title: 'Celebrate Perfect Days',
  subtitle: 'Notify when all habits are done',
  value: ref.watch(positiveNudgeEnabledProvider),
  onChanged: (v) {
    ref.read(positiveNudgeEnabledProvider.notifier).state = v;
    ref.read(settingsServiceProvider).positiveNudgeEnabled = v;
  },
),
const SizedBox(height: AppSpacing.space24),
```

**Step 2: Create _ToggleTile and _TimeTile private widgets**

`_ToggleTile`: Similar to `_ActionTile` but with a `Switch` instead of chevron.
`_TimeTile`: Shows formatted time as subtitle, taps to open `showTimePicker`.

**Step 3: Run analyze**

Run: `/c/flutter/bin/flutter analyze`

**Step 4: Commit**

```bash
git add lib/presentation/screens/settings/settings_screen.dart
git commit -m "feat: add notification settings section with evening nudge and celebration toggles"
```

---

### Task N6: Quick-Complete from Notification

**Files:**
- Modify: `lib/data/services/notification_service.dart`

**Step 1: Add Android notification action button**

Configure the notification with an action button "Mark Done" that triggers a background handler to mark the habit complete via Hive directly.

**Step 2: Handle notification tap**

When the notification body is tapped, navigate to the habit detail screen. Use `onDidReceiveNotificationResponse` callback with the habit ID as payload.

**Step 3: Run analyze and test**

Run: `/c/flutter/bin/flutter analyze && /c/flutter/bin/flutter test`

**Step 4: Commit**

```bash
git add lib/data/services/notification_service.dart
git commit -m "feat: add quick-complete action button and tap-to-detail on notifications"
```

---

## Workstream 3: Habit Stacks

### Task S1: Review and Update Stack Entity and Model

**Files:**
- Check/create: `lib/domain/entities/stack.dart`
- Check/modify: `lib/data/models/habit_stack_model.dart`

**Step 1: Check existing stack infrastructure**

`HiveDatabase` already registers `HabitStackModelAdapter` (typeId 2) and has a `habitStacksBox`. Check what fields exist on the model. If minimal/placeholder, create the full entity and update the model.

**Stack entity should have:**
```dart
class HabitStack {
  const HabitStack({
    required this.id,
    required this.name,
    required this.habitIds,
    required this.createdAt,
    this.description,
    this.iconEmoji,
    this.chainNotificationsEnabled = false,
  });

  final String id;
  final String name;
  final List<String> habitIds; // ordered
  final DateTime createdAt;
  final String? description;
  final String? iconEmoji;
  final bool chainNotificationsEnabled;
}
```

**Step 2: Ensure model adapter matches entity**

Update `HabitStackModel` adapter to read/write all fields. Ensure `toEntity`/`fromEntity` round-trips correctly.

**Step 3: Run analyze**

Run: `/c/flutter/bin/flutter analyze`

**Step 4: Commit**

```bash
git add lib/domain/entities/stack.dart lib/data/models/habit_stack_model.dart
git commit -m "feat: define HabitStack entity and update Hive model adapter"
```

---

### Task S2: Create Stacks Provider (CRUD)

**Files:**
- Create: `lib/presentation/providers/stacks_provider.dart`

**Step 1: Create AsyncNotifier for stacks CRUD**

```dart
final stacksProvider = AsyncNotifierProvider<StacksNotifier, List<HabitStack>>(
  StacksNotifier.new,
);

class StacksNotifier extends AsyncNotifier<List<HabitStack>> {
  @override
  Future<List<HabitStack>> build() async {
    final box = HiveDatabase.habitStacksBox;
    return box.values.map((m) => m.toEntity()).toList();
  }

  Future<void> createStack(HabitStack stack) async { /* add to box, update state */ }
  Future<void> updateStack(HabitStack stack) async { /* put in box, update state */ }
  Future<void> deleteStack(String id) async { /* delete from box, update state */ }
  Future<void> reorderHabits(String stackId, List<String> newOrder) async { /* update habitIds */ }
}
```

**Step 2: Run analyze**

Run: `/c/flutter/bin/flutter analyze`

**Step 3: Commit**

```bash
git add lib/presentation/providers/stacks_provider.dart
git commit -m "feat: add stacks provider with CRUD operations"
```

---

### Task S3: Create Stack Analytics Provider

**Files:**
- Create: `lib/presentation/providers/stack_analytics_provider.dart`

**Step 1: Create stack analytics computations**

```dart
class StackAnalytics {
  const StackAnalytics({
    required this.stackId,
    required this.completionRate,       // % of days all habits in stack completed
    required this.funnelData,           // per-habit completion rate in order
    required this.weakestLinkIndex,     // index of lowest-rate habit
    required this.totalChainCompletions, // days where full chain was done
  });
  // ...
}

final stackAnalyticsProvider = FutureProvider.family<StackAnalytics, String>((ref, stackId) async {
  // Get stack, get habits, get completions
  // Compute funnel: for each habit in order, what % of days was it completed
  // Compute full-chain rate: days where ALL habits in stack were done / total days
  // Find weakest link: habit with lowest rate
});
```

**Step 2: Run analyze**

Run: `/c/flutter/bin/flutter analyze`

**Step 3: Commit**

```bash
git add lib/presentation/providers/stack_analytics_provider.dart
git commit -m "feat: add stack analytics provider with funnel and weakest link"
```

---

### Task S4: Create Stacks List Screen

**Files:**
- Create: `lib/presentation/screens/stacks/stacks_list_screen.dart`
- Modify: `lib/presentation/screens/habits/habits_list_screen.dart` (add toggle)

**Step 1: Create stacks list screen**

Shows all stacks as cards with:
- Stack name + emoji icon
- Habit count badge ("5 habits")
- Today's progress (e.g., "3/5 done")
- Tappable → navigates to stack detail

Include `EmptyState` when no stacks exist:
```dart
EmptyState(
  icon: Icons.layers_outlined,
  title: 'Stack your habits',
  description: 'Chain habits together to build powerful routines.',
  actionLabel: 'Create First Stack',
  onAction: () => showStackFormSheet(context),
)
```

**Step 2: Add toggle to habits_list_screen.dart**

At the top of the screen, add a segmented control or chip toggle:
```dart
Row(
  children: [
    ChoiceChip(label: Text('Habits'), selected: !showStacks, onSelected: ...),
    const SizedBox(width: 8),
    ChoiceChip(label: Text('Stacks'), selected: showStacks, onSelected: ...),
  ],
)
```

When "Stacks" is selected, show `StacksListScreen()` content instead of the flat habits list.

**Step 3: Run analyze**

Run: `/c/flutter/bin/flutter analyze`

**Step 4: Commit**

```bash
git add lib/presentation/screens/stacks/stacks_list_screen.dart lib/presentation/screens/habits/habits_list_screen.dart
git commit -m "feat: add stacks list screen with toggle from habits list"
```

---

### Task S5: Create Stack Detail Screen

**Files:**
- Create: `lib/presentation/screens/stacks/stack_detail_screen.dart`
- Create: `lib/presentation/widgets/stacks/chain_connector.dart`

**Step 1: Create ChainConnector widget**

Vertical chain visualization:
- Vertical line connecting circles
- Each circle is the habit's color when completed today, `backgroundQuaternary` when pending
- Habit name and schedule label next to each node
- Drag handles for reordering

```dart
class ChainConnector extends StatelessWidget {
  const ChainConnector({
    super.key,
    required this.habits,
    required this.completedIds,
    required this.onReorder,
    required this.onTapHabit,
  });
  // Build a ReorderableListView with custom chain-line CustomPaint
}
```

**Step 2: Create stack detail screen**

Layout:
- AppBar with stack name, edit/delete actions
- Chain connector showing habits in order with today's completion state
- "Chain notifications" toggle (if notifications workstream is complete)
- Collapsible analytics section at bottom (funnel chart, completion rate, weakest link)

**Step 3: Run analyze**

Run: `/c/flutter/bin/flutter analyze`

**Step 4: Commit**

```bash
git add lib/presentation/screens/stacks/stack_detail_screen.dart lib/presentation/widgets/stacks/chain_connector.dart
git commit -m "feat: add stack detail screen with chain connector visualization"
```

---

### Task S6: Create Stack Form Sheet

**Files:**
- Create: `lib/presentation/screens/stacks/stack_form_sheet.dart`

**Step 1: Create stack creation/editing form**

Bottom sheet with:
- Name text field
- Optional description text field
- Optional emoji picker (simple text field for now)
- "Start from template" chips: "Morning Routine", "Wind Down", "Workout Prep"
- Habit multi-select with drag-to-reorder (show all active habits with checkboxes + ReorderableListView for selected)
- Save/cancel buttons

Templates auto-fill name + select matching habits by category/name heuristics.

**Step 2: Run analyze**

Run: `/c/flutter/bin/flutter analyze`

**Step 3: Commit**

```bash
git add lib/presentation/screens/stacks/stack_form_sheet.dart
git commit -m "feat: add stack form sheet with templates and drag-to-reorder habit selection"
```

---

### Task S7: Create Stack Funnel Chart Widget

**Files:**
- Create: `lib/presentation/widgets/stacks/stack_funnel_chart.dart`

**Step 1: Create funnel visualization**

Horizontal bars stacked vertically. Each bar represents a habit in order:
- Width proportional to completion rate (first habit = reference width)
- Color = habit's own `colorHex`
- Label shows habit name + rate percentage
- Narrows visually to show where people drop off

```dart
class StackFunnelChart extends StatelessWidget {
  const StackFunnelChart({
    super.key,
    required this.habitNames,
    required this.rates,
    required this.colors,
  });
  // Build column of sized containers with rounded corners
}
```

**Step 2: Run analyze**

Run: `/c/flutter/bin/flutter analyze`

**Step 3: Commit**

```bash
git add lib/presentation/widgets/stacks/stack_funnel_chart.dart
git commit -m "feat: add stack funnel chart widget for drop-off visualization"
```

---

### Task S8: Chain Prompt on Completion

**Files:**
- Modify: `lib/presentation/screens/home/home_screen.dart` (add chain prompt — coordinate with Polish teammate)

**Step 1: Add chain prompt snackbar**

After a habit is completed on the home screen, check if it belongs to any stack. If the next habit in the stack is uncompleted today, show a snackbar:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Next up: ${nextHabit.name}'),
    action: SnackBarAction(
      label: 'Start',
      onPressed: () {
        // Scroll to or highlight the next habit
      },
    ),
    duration: const Duration(seconds: 4),
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.backgroundSecondary,
  ),
);
```

**Step 2: Run analyze and test**

Run: `/c/flutter/bin/flutter analyze && /c/flutter/bin/flutter test`

**Step 3: Commit**

```bash
git add lib/presentation/screens/home/home_screen.dart
git commit -m "feat: add chain prompt snackbar after completing a stacked habit"
```

---

## Integration & Synthesis Tasks

### Task I1: Final Integration

**After all three workstreams complete:**

1. Run full analysis: `/c/flutter/bin/flutter analyze`
2. Run tests: `/c/flutter/bin/flutter test`
3. Verify no file conflicts between workstreams
4. Test end-to-end flows:
   - Create habit with reminder → notification appears
   - Complete habit → particle burst + streak check + chain prompt
   - Create stack → reorder → view analytics
   - Empty state flows for new users
5. Update `TASKS.md` with V2 completion status

### Task I2: Final Commit

```bash
git add -A
git commit -m "V2 complete: UX polish, notifications, habit stacks"
```

---

## Task Summary by Workstream

| ID | Task | Workstream | Blocked By |
|----|------|-----------|------------|
| P1 | Rewrite EmptyState widget | Polish | — |
| P2 | Add empty states to Home and Analytics | Polish | P1 |
| P3 | Completion particle burst animation | Polish | — |
| P4 | Streak milestone celebrations | Polish | P3 |
| P5 | Page transitions (fade-through, hero) | Polish | — |
| P6 | Pull-to-refresh and ripple audit | Polish | — |
| N1 | Add reminderTime to entity/model | Notifications | — |
| N2 | Create settings service + provider | Notifications | — |
| N3 | Create notification service + provider | Notifications | N1, N2 |
| N4 | Reminder time picker in habit form | Notifications | N1, N3 |
| N5 | Notification settings in Settings screen | Notifications | N2, N3 |
| N6 | Quick-complete from notification | Notifications | N3 |
| S1 | Review/update Stack entity and model | Stacks | — |
| S2 | Create stacks provider (CRUD) | Stacks | S1 |
| S3 | Create stack analytics provider | Stacks | S2 |
| S4 | Stacks list screen + habits toggle | Stacks | S2 |
| S5 | Stack detail screen + chain connector | Stacks | S2, S3 |
| S6 | Stack form sheet with templates | Stacks | S2 |
| S7 | Stack funnel chart widget | Stacks | S3 |
| S8 | Chain prompt on completion | Stacks | S2 (+ Polish done for home_screen) |
| I1 | Final integration verification | Lead | All above |
| I2 | Final commit | Lead | I1 |
