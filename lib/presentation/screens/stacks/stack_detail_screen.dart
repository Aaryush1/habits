import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/color_utils.dart';
import '../../../domain/entities/stack.dart';
import '../../providers/habits_provider.dart';
import '../../providers/stack_analytics_provider.dart';
import '../../providers/stacks_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/stacks/stack_funnel_chart.dart';
import 'stack_form_sheet.dart';

class StackDetailScreen extends ConsumerWidget {
  const StackDetailScreen({super.key, required this.stackId});

  final String stackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stacksAsync = ref.watch(stacksProvider);
    final stack = stacksAsync.valueOrNull
        ?.where((s) => s.id == stackId)
        .firstOrNull;

    if (stacksAsync.isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Loading stack'),
      );
    }

    if (stack == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stack')),
        body: Center(
          child: Text('Stack not found', style: AppTypography.bodyMedium),
        ),
      );
    }

    return _StackDetailContent(stack: stack);
  }
}

class _StackDetailContent extends ConsumerWidget {
  const _StackDetailContent({required this.stack});

  final HabitStack stack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(stackAnalyticsProvider(stack.id));
    final habitsAsync = ref.watch(habitsProvider);
    final habitMap = <String, dynamic>{
      for (final h in habitsAsync.valueOrNull ?? []) h.id: h,
    };

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // --- Header ---
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x40E8A838), // accentGold at 25%
                      AppColors.backgroundPrimary,
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space16,
                  AppSpacing.space16,
                  AppSpacing.space16,
                  AppSpacing.space20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back + Edit row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 20),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          onPressed: () => _openEdit(context, ref),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space8),

                    // Icon + Name
                    Row(
                      children: [
                        if (stack.iconEmoji != null) ...[
                          Text(stack.iconEmoji!,
                              style: const TextStyle(fontSize: 32)),
                          const SizedBox(width: AppSpacing.space12),
                        ],
                        Expanded(
                          child: Text(
                            stack.name,
                            style: AppTypography.displayMedium,
                          ),
                        ),
                      ],
                    ),

                    if (stack.description != null &&
                        stack.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space8),
                      Text(
                        stack.description!,
                        style: AppTypography.bodyMedium,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.space12),

                    // Stats pill row
                    analyticsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => const SizedBox.shrink(),
                      data: (analytics) {
                        if (analytics == null) return const SizedBox.shrink();
                        return Row(
                          children: [
                            _StatPill(
                              label: 'Full Chain',
                              value:
                                  '${(analytics.fullChainRate * 100).round()}%',
                              color: AppColors.completionGreen,
                            ),
                            const SizedBox(width: AppSpacing.space8),
                            _StatPill(
                              label: 'Habits',
                              value: '${stack.habitIds.length}',
                              color: AppColors.accentGold,
                            ),
                            if (analytics.weakestLinkIndex >= 0 &&
                                analytics.funnel.isNotEmpty) ...[
                              const SizedBox(width: AppSpacing.space8),
                              _StatPill(
                                label: 'Needs Attention',
                                value: analytics
                                    .funnel[analytics.weakestLinkIndex]
                                    .habitName,
                                color: AppColors.missedCoral,
                                truncate: true,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // --- Chain connector visualization ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Habit Chain', style: AppTypography.headlineMedium),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      'Do these in order for maximum impact.',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    if (stack.habitIds.isEmpty)
                      Text(
                        'No habits in this stack yet.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      )
                    else
                      _ChainConnector(
                        habitIds: stack.habitIds,
                        habitMap: habitMap,
                        analyticsAsync: analyticsAsync,
                      ),
                  ],
                ),
              ),
            ),

            // --- Funnel chart ---
            analyticsAsync.when(
              loading: () =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (e, s) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (analytics) {
                if (analytics == null || analytics.funnel.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space16,
                      AppSpacing.space24,
                      AppSpacing.space16,
                      AppSpacing.space16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Completion Funnel',
                            style: AppTypography.headlineMedium),
                        const SizedBox(height: AppSpacing.space4),
                        Text(
                          'Last ${analytics.analyzedDays} days — where does the chain break?',
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.space16),
                        StackFunnelChart(analytics: analytics),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.space32)),
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, WidgetRef ref) async {
    final updated = await showStackFormSheet(
      context: context,
      initialStack: stack,
    );
    if (updated == null) return;
    await ref.read(stacksProvider.notifier).updateStack(updated);
  }
}

/// Chain connector — shows habits linked by vertical lines with step numbers.
class _ChainConnector extends StatelessWidget {
  const _ChainConnector({
    required this.habitIds,
    required this.habitMap,
    required this.analyticsAsync,
  });

  final List<String> habitIds;
  final Map<String, dynamic> habitMap;
  final AsyncValue<StackAnalytics?> analyticsAsync;

  @override
  Widget build(BuildContext context) {
    final funnelMap = <String, double>{};
    analyticsAsync.whenData((analytics) {
      if (analytics == null) return;
      for (final entry in analytics.funnel) {
        funnelMap[entry.habitId] = entry.completionRate;
      }
    });

    return Column(
      children: [
        for (var i = 0; i < habitIds.length; i++) ...[
          _ChainNode(
            habitId: habitIds[i],
            habitMap: habitMap,
            stepNumber: i + 1,
            completionRate: funnelMap[habitIds[i]],
            isLast: i == habitIds.length - 1,
          ),
        ],
      ],
    );
  }
}

class _ChainNode extends StatelessWidget {
  const _ChainNode({
    required this.habitId,
    required this.habitMap,
    required this.stepNumber,
    required this.isLast,
    this.completionRate,
  });

  final String habitId;
  final Map<String, dynamic> habitMap;
  final int stepNumber;
  final bool isLast;
  final double? completionRate;

  @override
  Widget build(BuildContext context) {
    final habit = habitMap[habitId];
    final habitName = habit?.name ?? 'Unknown habit';
    final habitColor =
        parseHexColor(habit?.colorHex) ?? AppColors.accentGold;
    final rate = completionRate;

    // Determine node color based on completion rate
    Color nodeColor;
    if (rate == null) {
      nodeColor = AppColors.backgroundQuaternary;
    } else if (rate >= 0.8) {
      nodeColor = AppColors.completionGreen;
    } else if (rate >= 0.5) {
      nodeColor = AppColors.accentGold;
    } else {
      nodeColor = AppColors.missedCoral;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: step indicator + connector line
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: nodeColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeColor, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$stepNumber',
                  style: AppTypography.labelLarge.copyWith(
                    color: nodeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 32,
                  color: AppColors.borderSubtle,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space12),

        // Right: habit card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space8),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space12),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: AppSpacing.borderRadiusMedium,
                border: Border.all(color: habitColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habitName,
                            style: AppTypography.headlineSmall),
                        if (habit?.category != null &&
                            habit!.category!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(habit.category!,
                              style: AppTypography.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  if (rate != null) ...[
                    const SizedBox(width: AppSpacing.space8),
                    Text(
                      '${(rate * 100).round()}%',
                      style: AppTypography.dataSmall.copyWith(
                        color: nodeColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    this.truncate = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool truncate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(
              value,
              style: AppTypography.labelLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: truncate ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }
}
