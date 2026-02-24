import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/habit.dart';

Future<Habit?> showHabitFormSheet({
  required BuildContext context,
  Habit? initialHabit,
  required int defaultDisplayOrder,
}) async {
  final nameController = TextEditingController(text: initialHabit?.name ?? '');
  final categoryController =
      TextEditingController(text: initialHabit?.category ?? '');
  final identityController =
      TextEditingController(text: initialHabit?.identityStatement ?? '');
  final implementationTimeController =
      TextEditingController(text: initialHabit?.implementationTime ?? '');
  final implementationLocationController =
      TextEditingController(text: initialHabit?.implementationLocation ?? '');
  final twoMinuteController =
      TextEditingController(text: initialHabit?.twoMinuteVersion ?? '');
  final durationController = TextEditingController(
    text: initialHabit?.durationMinutes?.toString() ?? '',
  );

  HabitScheduleType scheduleType =
      initialHabit?.scheduleType ?? HabitScheduleType.daily;
  final selectedWeekdays = <int>{
    ...(initialHabit?.scheduleDays ?? const <int>[]),
  };
  final selectedMonthDates = <int>{
    ...(initialHabit?.scheduleDates ?? const <int>[]),
  };

  // Color: default to gold hex, strip leading # if present
  String selectedColorHex = initialHabit?.colorHex ?? 'E8A838';

  // Validation error state
  String? nameError;
  String? scheduleError;

  Habit? result;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          void toggleWeekday(int day) {
            setModalState(() {
              if (!selectedWeekdays.remove(day)) {
                selectedWeekdays.add(day);
              }
              scheduleError = null;
            });
          }

          void toggleMonthDate(int date) {
            setModalState(() {
              if (!selectedMonthDates.remove(date)) {
                selectedMonthDates.add(date);
              }
              scheduleError = null;
            });
          }

          void setDurationPreset(int minutes) {
            setModalState(() {
              durationController.text = minutes.toString();
            });
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.space16,
                  right: AppSpacing.space16,
                  top: AppSpacing.space16,
                  bottom: MediaQuery.of(context).viewInsets.bottom +
                      AppSpacing.space16,
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Header
                    Text(
                      initialHabit == null ? 'Create Habit' : 'Edit Habit',
                      style: AppTypography.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.space16),

                    // --- Name ---
                    TextField(
                      controller: nameController,
                      autofocus: initialHabit == null,
                      decoration: InputDecoration(
                        hintText: 'Habit name',
                        errorText: nameError,
                      ),
                      onChanged: (_) {
                        if (nameError != null) {
                          setModalState(() => nameError = null);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.space12),

                    // --- Category ---
                    TextField(
                      controller: categoryController,
                      decoration:
                          const InputDecoration(hintText: 'Category (optional)'),
                    ),
                    const SizedBox(height: AppSpacing.space16),

                    // --- Color Picker ---
                    Text('Color', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.space8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _colorHexes.map((hex) {
                        final isSelected =
                            hex.toLowerCase() == selectedColorHex.toLowerCase();
                        final color = Color(
                          int.parse('FF$hex', radix: 16),
                        );
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedColorHex = hex),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.textPrimary, width: 2.5)
                                  : Border.all(
                                      color: AppColors.borderSubtle, width: 1),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    size: 16, color: AppColors.textPrimary)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.space16),

                    // --- Schedule ---
                    DropdownButtonFormField<HabitScheduleType>(
                      initialValue: scheduleType,
                      items: const [
                        DropdownMenuItem(
                          value: HabitScheduleType.daily,
                          child: Text('Daily'),
                        ),
                        DropdownMenuItem(
                          value: HabitScheduleType.weekly,
                          child: Text('Weekly'),
                        ),
                        DropdownMenuItem(
                          value: HabitScheduleType.monthly,
                          child: Text('Monthly'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            scheduleType = value;
                            scheduleError = null;
                          });
                        }
                      },
                    ),
                    if (scheduleError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        scheduleError!,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.missedCoral),
                      ),
                    ],

                    if (scheduleType == HabitScheduleType.weekly) ...[
                      const SizedBox(height: AppSpacing.space12),
                      Text('Select weekdays',
                          style: AppTypography.labelMedium),
                      const SizedBox(height: AppSpacing.space8),
                      Wrap(
                        spacing: AppSpacing.space8,
                        runSpacing: AppSpacing.space8,
                        children: List.generate(7, (index) {
                          const labels = [
                            'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                          ];
                          return FilterChip(
                            label: Text(labels[index]),
                            selected: selectedWeekdays.contains(index),
                            onSelected: (_) => toggleWeekday(index),
                          );
                        }),
                      ),
                    ],
                    if (scheduleType == HabitScheduleType.monthly) ...[
                      const SizedBox(height: AppSpacing.space12),
                      Text('Select days of the month',
                          style: AppTypography.labelMedium),
                      const SizedBox(height: AppSpacing.space8),
                      SizedBox(
                        height: 200,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                          itemCount: 31,
                          itemBuilder: (context, index) {
                            final value = index + 1;
                            final selected =
                                selectedMonthDates.contains(value);
                            return GestureDetector(
                              onTap: () => toggleMonthDate(value),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$value',
                                  style: TextStyle(
                                    color: selected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.space16),

                    // --- Duration ---
                    Text('Duration (optional)', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.space8),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: durationController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              hintText: '0',
                              suffixText: 'min',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space12),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [5, 10, 15, 20, 30, 45, 60]
                                  .map(
                                    (m) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ActionChip(
                                        label: Text('$m'),
                                        onPressed: () => setDurationPreset(m),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space16),

                    // --- Identity Statement ---
                    TextField(
                      controller: identityController,
                      decoration: const InputDecoration(
                        hintText: 'Identity statement (optional)',
                        helperText: 'e.g., "I am someone who..."',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space12),

                    // --- Implementation Intentions ---
                    Text('Implementation Intention (optional)',
                        style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.space8),
                    TextField(
                      controller: implementationTimeController,
                      decoration: const InputDecoration(
                        hintText: 'When?',
                        helperText: 'e.g., 7:00 AM, After breakfast',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    TextField(
                      controller: implementationLocationController,
                      decoration: const InputDecoration(
                        hintText: 'Where?',
                        helperText: 'e.g., Living room, Office desk',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space12),

                    // --- 2-Minute Version ---
                    TextField(
                      controller: twoMinuteController,
                      decoration: const InputDecoration(
                        hintText: '2-minute version (optional)',
                        helperText:
                            'What\'s the smallest version of this habit?',
                      ),
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
                            onPressed: () {
                              final name = nameController.text.trim();
                              if (name.isEmpty) {
                                setModalState(
                                    () => nameError = 'Name is required');
                                return;
                              }
                              if (scheduleType == HabitScheduleType.weekly &&
                                  selectedWeekdays.isEmpty) {
                                setModalState(() => scheduleError =
                                    'Select at least one weekday');
                                return;
                              }
                              if (scheduleType == HabitScheduleType.monthly &&
                                  selectedMonthDates.isEmpty) {
                                setModalState(() => scheduleError =
                                    'Select at least one date');
                                return;
                              }

                              final durationText =
                                  durationController.text.trim();
                              int? durationMinutes;
                              if (durationText.isNotEmpty) {
                                final parsed = int.tryParse(durationText);
                                if (parsed != null && parsed > 0) {
                                  durationMinutes = parsed;
                                }
                              }

                              result = Habit(
                                id: initialHabit?.id ?? const Uuid().v4(),
                                name: name,
                                createdAt:
                                    initialHabit?.createdAt ?? DateTime.now(),
                                scheduleType: scheduleType,
                                scheduleDays:
                                    scheduleType == HabitScheduleType.weekly
                                        ? (selectedWeekdays.toList()..sort())
                                        : null,
                                scheduleDates:
                                    scheduleType == HabitScheduleType.monthly
                                        ? (selectedMonthDates.toList()..sort())
                                        : null,
                                identityStatement:
                                    identityController.text.trim().isEmpty
                                        ? null
                                        : identityController.text.trim(),
                                category:
                                    categoryController.text.trim().isEmpty
                                        ? null
                                        : categoryController.text.trim(),
                                archivedAt: initialHabit?.archivedAt,
                                implementationTime:
                                    implementationTimeController
                                            .text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : implementationTimeController.text
                                            .trim(),
                                implementationLocation:
                                    implementationLocationController
                                            .text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : implementationLocationController.text
                                            .trim(),
                                twoMinuteVersion:
                                    twoMinuteController.text.trim().isEmpty
                                        ? null
                                        : twoMinuteController.text.trim(),
                                colorHex: selectedColorHex,
                                notes: initialHabit?.notes,
                                displayOrder: initialHabit?.displayOrder ??
                                    defaultDisplayOrder,
                                notificationsEnabled:
                                    initialHabit?.notificationsEnabled ?? false,
                                notificationTimes:
                                    initialHabit?.notificationTimes,
                                notificationTriggerHabitId:
                                    initialHabit?.notificationTriggerHabitId,
                                durationMinutes: durationMinutes,
                              );
                              Navigator.of(context).pop();
                            },
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
        },
      );
    },
  );

  nameController.dispose();
  categoryController.dispose();
  identityController.dispose();
  implementationTimeController.dispose();
  implementationLocationController.dispose();
  twoMinuteController.dispose();
  durationController.dispose();
  return result;
}

// Hex values matching AppColors.habitPalette (without 0xFF prefix)
const _colorHexes = [
  'E8A838', // Gold
  '7DB87D', // Sage
  '6B9BD2', // Sky
  'D4726A', // Coral
  'B088D4', // Lavender
  '5BC0BE', // Teal
  'E07B53', // Tangerine
  'C9B1FF', // Periwinkle
];
