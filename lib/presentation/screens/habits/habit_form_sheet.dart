import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
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

  HabitScheduleType scheduleType =
      initialHabit?.scheduleType ?? HabitScheduleType.daily;
  final selectedWeekdays = <int>{
    ...(initialHabit?.scheduleDays ?? const <int>[]),
  };
  final selectedMonthDates = <int>{
    ...(initialHabit?.scheduleDates ?? const <int>[]),
  };

  Habit? result;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.space16,
          right: AppSpacing.space16,
          top: AppSpacing.space16,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space16,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            void toggleWeekday(int day) {
              setModalState(() {
                if (!selectedWeekdays.remove(day)) {
                  selectedWeekdays.add(day);
                }
              });
            }

            void toggleMonthDate(int date) {
              setModalState(() {
                if (!selectedMonthDates.remove(date)) {
                  selectedMonthDates.add(date);
                }
              });
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  initialHabit == null ? 'Create Habit' : 'Edit Habit',
                  style: AppTypography.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.space12),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Habit name'),
                ),
                const SizedBox(height: AppSpacing.space12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(hintText: 'Category'),
                ),
                const SizedBox(height: AppSpacing.space12),
                TextField(
                  controller: identityController,
                  decoration: const InputDecoration(
                    hintText: 'Identity statement (optional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),
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
                      setModalState(() => scheduleType = value);
                    }
                  },
                ),
                if (scheduleType == HabitScheduleType.weekly) ...[
                  const SizedBox(height: AppSpacing.space12),
                  const Text('Select weekdays'),
                  const SizedBox(height: AppSpacing.space8),
                  Wrap(
                    spacing: AppSpacing.space8,
                    runSpacing: AppSpacing.space8,
                    children: List.generate(7, (index) {
                      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
                  Row(
                    children: [
                      const Expanded(child: Text('Select month dates')),
                      TextButton.icon(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null) {
                            setModalState(() {
                              selectedMonthDates.add(selected.day);
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_month_outlined, size: 18),
                        label: const Text('Calendar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  SizedBox(
                    height: 180,
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: AppSpacing.space8,
                        runSpacing: AppSpacing.space8,
                        children: List.generate(31, (index) {
                          final value = index + 1;
                          return FilterChip(
                            label: Text('$value'),
                            selected: selectedMonthDates.contains(value),
                            onSelected: (_) => toggleMonthDate(value),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.space16),
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
                            return;
                          }
                          if (scheduleType == HabitScheduleType.weekly &&
                              selectedWeekdays.isEmpty) {
                            return;
                          }
                          if (scheduleType == HabitScheduleType.monthly &&
                              selectedMonthDates.isEmpty) {
                            return;
                          }

                          result = Habit(
                            id: initialHabit?.id ?? const Uuid().v4(),
                            name: name,
                            createdAt: initialHabit?.createdAt ?? DateTime.now(),
                            scheduleType: scheduleType,
                            scheduleDays: scheduleType == HabitScheduleType.weekly
                                ? (selectedWeekdays.toList()..sort())
                                : null,
                            scheduleDates: scheduleType == HabitScheduleType.monthly
                                ? (selectedMonthDates.toList()..sort())
                                : null,
                            identityStatement: identityController.text.trim().isEmpty
                                ? null
                                : identityController.text.trim(),
                            category: categoryController.text.trim().isEmpty
                                ? null
                                : categoryController.text.trim(),
                            archivedAt: initialHabit?.archivedAt,
                            implementationTime: initialHabit?.implementationTime,
                            implementationLocation: initialHabit?.implementationLocation,
                            twoMinuteVersion: initialHabit?.twoMinuteVersion,
                            colorHex: initialHabit?.colorHex,
                            notes: initialHabit?.notes,
                            displayOrder: initialHabit?.displayOrder ?? defaultDisplayOrder,
                            notificationsEnabled:
                                initialHabit?.notificationsEnabled ?? false,
                            notificationTimes: initialHabit?.notificationTimes,
                            notificationTriggerHabitId:
                                initialHabit?.notificationTriggerHabitId,
                          );
                          Navigator.of(context).pop();
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    },
  );

  nameController.dispose();
  categoryController.dispose();
  identityController.dispose();
  return result;
}
