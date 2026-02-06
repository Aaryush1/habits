import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/habit.dart';
import '../../providers/habits_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/habit/habit_card.dart';
import 'habit_form_sheet.dart';
import 'habit_detail_screen.dart';

/// Habits list screen showing all habits.
class HabitsListScreen extends ConsumerStatefulWidget {
  const HabitsListScreen({super.key});

  @override
  ConsumerState<HabitsListScreen> createState() => _HabitsListScreenState();
}

class _HabitsListScreenState extends ConsumerState<HabitsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _categoryFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space16),
              const SectionHeader(
                title: 'Habits',
                subtitle: 'Build your streak one check at a time',
              ),
              const SizedBox(height: AppSpacing.space12),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search habits',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: AppSpacing.space12),
              habitsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
                data: (habits) {
                  final categories = {
                    'All',
                    ...habits
                        .map((h) => (h.category == null || h.category!.isEmpty)
                            ? 'General'
                            : h.category!)
                        .toSet(),
                  };
                  return SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: categories.map((category) {
                        final selected = _categoryFilter == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.space8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: selected,
                            onSelected: (_) => setState(() => _categoryFilter = category),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.space12),
              Expanded(
                child: habitsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Text(
                      'Failed to load habits',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  data: (habits) {
                    final filtered = habits.where((habit) {
                      final category = (habit.category == null || habit.category!.isEmpty)
                          ? 'General'
                          : habit.category!;
                      final categoryMatches =
                          _categoryFilter == 'All' || category == _categoryFilter;
                      final queryMatches =
                          _query.isEmpty || habit.name.toLowerCase().contains(_query);
                      return categoryMatches && queryMatches;
                    }).toList();

                    if (filtered.isEmpty) {
                      return EmptyState(
                        title: 'No matching habits',
                        description: 'Try a different search or filter.',
                        icon: Icons.filter_alt_off_outlined,
                        actionLabel: 'Clear Filters',
                        onAction: () {
                          setState(() {
                            _query = '';
                            _searchController.clear();
                            _categoryFilter = 'All';
                          });
                        },
                      );
                    }

                    final fullListView = _query.isEmpty && _categoryFilter == 'All';
                    if (fullListView) {
                      return ReorderableListView.builder(
                        itemCount: filtered.length,
                        onReorder: (oldIndex, newIndex) async {
                          final reordered = [...filtered];
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final moved = reordered.removeAt(oldIndex);
                          reordered.insert(newIndex, moved);
                          await ref
                              .read(habitsProvider.notifier)
                              .reorderHabits(reordered.map((h) => h.id).toList());
                        },
                        itemBuilder: (context, index) {
                          final habit = filtered[index];
                          return Padding(
                            key: ValueKey(habit.id),
                            padding: const EdgeInsets.only(bottom: AppSpacing.space12),
                            child: _buildDismissibleHabitCard(context, habit, filtered.length),
                          );
                        },
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final habit = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.space12),
                          child: _buildDismissibleHabitCard(context, habit, filtered.length),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'habits_fab',
        onPressed: () async {
          final newHabit = await showHabitFormSheet(
            context: context,
            defaultDisplayOrder: habitsAsync.valueOrNull?.length ?? 0,
          );
          if (newHabit == null) {
            return;
          }
          await ref.read(habitsProvider.notifier).createHabit(newHabit);
        },
        icon: const Icon(Icons.add),
        label: const Text('Habit'),
      ),
    );
  }

  Widget _buildDismissibleHabitCard(
    BuildContext context,
    Habit habit,
    int currentCount,
  ) {
    return Dismissible(
      key: ValueKey(habit.id),
      background: _swipeBackground(
        color: AppColors.missedCoral,
        icon: Icons.delete_outline,
        label: 'Delete',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBackground(
        color: AppColors.accentGoldMuted,
        icon: Icons.edit_outlined,
        label: 'Edit',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return _confirmDelete(context, habit);
        }

        final updated = await showHabitFormSheet(
          context: context,
          initialHabit: habit,
          defaultDisplayOrder: habit.displayOrder,
        );
        if (updated != null) {
          await ref.read(habitsProvider.notifier).updateHabit(updated);
        }
        return false;
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await ref.read(habitsProvider.notifier).deleteHabit(habit.id);
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 4),
                content: Text('Deleted "${habit.name}"'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    ref.read(habitsProvider.notifier).createHabit(
                          habit.copyWith(displayOrder: currentCount),
                        );
                  },
                ),
              ),
            );
        }
      },
      child: HabitCard(
        id: habit.id,
        name: habit.name,
        scheduleLabel: _scheduleLabel(habit),
        isCompleted: false,
        identityStatement: habit.identityStatement,
        color: _parseColor(habit.colorHex),
        onToggle: (_) {},
        showCheckbox: false,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HabitDetailScreen(habitId: habit.id),
            ),
          );
        },
        trailing: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.space8),
          child: Align(
            alignment: Alignment.center,
            child: Icon(Icons.drag_indicator),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Habit habit) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete habit?'),
          content: Text('This permanently removes "${habit.name}" from your list.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Widget _swipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: AppSpacing.borderRadiusMedium,
      ),
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          Icon(icon, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.space8),
          Text(label, style: AppTypography.labelMedium),
        ],
      ),
    );
  }

  String _scheduleLabel(Habit habit) {
    switch (habit.scheduleType) {
      case HabitScheduleType.daily:
        return 'Daily';
      case HabitScheduleType.weekly:
        final days = habit.scheduleDays ?? const <int>[];
        if (days.isEmpty) {
          return 'Weekly';
        }
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days.map((day) => labels[day]).join(', ');
      case HabitScheduleType.monthly:
        final dates = habit.scheduleDates ?? const <int>[];
        if (dates.isEmpty) {
          return 'Monthly';
        }
        return 'Dates: ${dates.join(', ')}';
    }
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return null;
    }
    try {
      final normalized = hex.replaceAll('#', '');
      final value = int.parse(
        normalized.length == 6 ? 'FF$normalized' : normalized,
        radix: 16,
      );
      return Color(value);
    } catch (_) {
      return null;
    }
  }
}
