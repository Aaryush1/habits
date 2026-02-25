import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/stack.dart';
import '../../providers/habits_provider.dart';

/// Emoji options for stack icon selection.
const _stackEmojis = [
  '🌅', '🧘', '📖', '💪', '🏃', '🥗', '💧', '🎯',
  '✍️', '🎵', '🌿', '⚡', '🧠', '🌙', '🌸', '🔥',
];

/// Template definitions: name, emoji, description, and keyword matchers.
class _StackTemplate {
  const _StackTemplate({
    required this.name,
    required this.emoji,
    required this.description,
    required this.keywords,
  });

  final String name;
  final String emoji;
  final String description;
  final List<String> keywords;
}

const _templates = [
  _StackTemplate(
    name: 'Morning Routine',
    emoji: '🌅',
    description: 'Start your day with intention.',
    keywords: ['morning', 'meditat', 'journal', 'stretch', 'wake', 'sunrise'],
  ),
  _StackTemplate(
    name: 'Wind Down',
    emoji: '🌙',
    description: 'Signal to your body that it\'s time to rest.',
    keywords: ['evening', 'night', 'read', 'journal', 'stretch', 'wind', 'sleep'],
  ),
  _StackTemplate(
    name: 'Workout Prep',
    emoji: '💪',
    description: 'Get ready to train at your best.',
    keywords: ['gym', 'workout', 'stretch', 'hydrat', 'exercise', 'run', 'train'],
  ),
];

/// Matches habits from [habits] to a template by name and category keywords.
List<String> _matchHabitsToTemplate(_StackTemplate template, List<Habit> habits) {
  return habits
      .where((h) {
        final haystack = '${h.name} ${h.category ?? ''}'.toLowerCase();
        return template.keywords.any((kw) => haystack.contains(kw));
      })
      .map((h) => h.id)
      .toList();
}

/// Shows the stack form sheet modal. Returns the created/updated [HabitStack] or null.
Future<HabitStack?> showStackFormSheet({
  required BuildContext context,
  HabitStack? initialStack,
}) async {
  return showModalBottomSheet<HabitStack>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _StackFormSheet(initialStack: initialStack),
  );
}

class _StackFormSheet extends ConsumerStatefulWidget {
  const _StackFormSheet({this.initialStack});

  final HabitStack? initialStack;

  @override
  ConsumerState<_StackFormSheet> createState() => _StackFormSheetState();
}

class _StackFormSheetState extends ConsumerState<_StackFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late List<String> _selectedHabitIds;
  String? _selectedEmoji;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialStack?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialStack?.description ?? '');
    _selectedHabitIds = List<String>.from(
      widget.initialStack?.habitIds ?? const <String>[],
    );
    _selectedEmoji = widget.initialStack?.iconEmoji;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyTemplate(_StackTemplate template, List<Habit> habits) {
    setState(() {
      _nameController.text = template.name;
      _descriptionController.text = template.description;
      _selectedEmoji = template.emoji;
      _selectedHabitIds = _matchHabitsToTemplate(template, habits);
    });
  }

  void _toggleHabit(String habitId) {
    setState(() {
      if (_selectedHabitIds.contains(habitId)) {
        _selectedHabitIds.remove(habitId);
      } else {
        _selectedHabitIds.add(habitId);
      }
    });
  }

  void _reorderHabit(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final moved = _selectedHabitIds.removeAt(oldIndex);
      _selectedHabitIds.insert(newIndex, moved);
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Stack name is required');
      return;
    }

    final stack = HabitStack(
      id: widget.initialStack?.id ?? const Uuid().v4(),
      name: name,
      habitIds: List<String>.from(_selectedHabitIds),
      createdAt: widget.initialStack?.createdAt ?? DateTime.now(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      iconEmoji: _selectedEmoji,
      chainNotificationsEnabled:
          widget.initialStack?.chainNotificationsEnabled ?? false,
    );

    Navigator.of(context).pop(stack);
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final habits = habitsAsync.valueOrNull ?? <Habit>[];

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.space16,
            right: AppSpacing.space16,
            top: AppSpacing.space16,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.space16,
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Header
              Text(
                widget.initialStack == null ? 'Create Stack' : 'Edit Stack',
                style: AppTypography.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.space16),

              // --- Templates (only when creating) ---
              if (widget.initialStack == null) ...[
                Text('Start from a template',
                    style: AppTypography.labelMedium),
                const SizedBox(height: AppSpacing.space8),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _templates
                        .map(
                          (template) => Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.space8),
                            child: ActionChip(
                              avatar: Text(template.emoji,
                                  style: const TextStyle(fontSize: 16)),
                              label: Text(template.name),
                              onPressed: () =>
                                  _applyTemplate(template, habits),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
              ],

              // --- Name ---
              TextField(
                controller: _nameController,
                autofocus: widget.initialStack == null,
                decoration: InputDecoration(
                  hintText: 'Stack name',
                  errorText: _nameError,
                ),
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() => _nameError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.space12),

              // --- Description ---
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.space16),

              // --- Emoji picker ---
              Text('Icon', style: AppTypography.labelMedium),
              const SizedBox(height: AppSpacing.space8),
              Wrap(
                spacing: AppSpacing.space8,
                runSpacing: AppSpacing.space8,
                children: _stackEmojis.map((emoji) {
                  final selected = _selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedEmoji = selected ? null : emoji;
                    }),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accentGoldSubtle
                            : AppColors.backgroundTertiary,
                        borderRadius: AppSpacing.borderRadiusMedium,
                        border: Border.all(
                          color: selected
                              ? AppColors.accentGoldMuted
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child:
                          Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.space16),

              // --- Habit selection & ordering ---
              Text('Habits in this stack',
                  style: AppTypography.labelMedium),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Tap to add habits. Drag to reorder the sequence.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.space12),

              if (habits.isEmpty)
                Text(
                  'No habits yet. Create some habits first.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                )
              else
                _HabitSelectionList(
                  habits: habits,
                  selectedHabitIds: _selectedHabitIds,
                  onToggle: _toggleHabit,
                  onReorder: _reorderHabit,
                ),

              const SizedBox(height: AppSpacing.space24),

              // --- Save / Cancel ---
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),
            ],
          ),
        );
      },
    );
  }
}

/// Shows all habits with checkboxes for selection, and drag handles for the
/// already-selected ones (displayed first in order).
class _HabitSelectionList extends StatelessWidget {
  const _HabitSelectionList({
    required this.habits,
    required this.selectedHabitIds,
    required this.onToggle,
    required this.onReorder,
  });

  final List<Habit> habits;
  final List<String> selectedHabitIds;
  final void Function(String habitId) onToggle;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    // Build habit map for quick lookup
    final habitMap = {for (final h in habits) h.id: h};

    // Ordered selected habits first, then unselected
    final selectedInOrder = selectedHabitIds
        .map((id) => habitMap[id])
        .whereType<Habit>()
        .toList();
    final unselected = habits
        .where((h) => !selectedHabitIds.contains(h.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected habits - reorderable
        if (selectedInOrder.isNotEmpty) ...[
          Text(
            'Selected (${selectedInOrder.length})',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.accentGold,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: selectedInOrder.length,
            onReorder: onReorder,
            itemBuilder: (context, index) {
              final habit = selectedInOrder[index];
              return _HabitRow(
                key: ValueKey(habit.id),
                habit: habit,
                isSelected: true,
                onToggle: () => onToggle(habit.id),
                showDragHandle: true,
              );
            },
          ),
          const SizedBox(height: AppSpacing.space12),
        ],

        // Unselected habits
        if (unselected.isNotEmpty) ...[
          Text(
            'Available habits',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          ...unselected.map(
            (habit) => _HabitRow(
              key: ValueKey(habit.id),
              habit: habit,
              isSelected: false,
              onToggle: () => onToggle(habit.id),
              showDragHandle: false,
            ),
          ),
        ],
      ],
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    super.key,
    required this.habit,
    required this.isSelected,
    required this.onToggle,
    required this.showDragHandle,
  });

  final Habit habit;
  final bool isSelected;
  final VoidCallback onToggle;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentGoldSubtle
                : AppColors.backgroundTertiary,
            borderRadius: AppSpacing.borderRadiusMedium,
            border: Border.all(
              color: isSelected
                  ? AppColors.accentGoldMuted
                  : AppColors.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 20,
                color: isSelected
                    ? AppColors.accentGold
                    : AppColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: AppTypography.headlineSmall.copyWith(
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (habit.category != null &&
                        habit.category!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        habit.category!,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (showDragHandle)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.space8),
                  child: Icon(
                    Icons.drag_indicator,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
