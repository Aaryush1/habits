import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/stack.dart';
import '../../providers/stacks_provider.dart';
import '../../widgets/common/empty_state.dart';
import 'stack_detail_screen.dart';
import 'stack_form_sheet.dart';

/// Standalone stacks list — embedded inside the Habits screen tab toggle.
class StacksListScreen extends ConsumerWidget {
  const StacksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stacksAsync = ref.watch(stacksProvider);

    return stacksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Failed to load stacks', style: AppTypography.bodyMedium),
      ),
      data: (stacks) {
        if (stacks.isEmpty) {
          return EmptyState(
            title: 'No stacks yet',
            description:
                'Group your habits into stacks to build powerful routines.',
            icon: Icons.layers_outlined,
            actionLabel: 'Create Stack',
            onAction: () => _openCreateSheet(context, ref, stacks.length),
          );
        }

        return ListView.builder(
          itemCount: stacks.length,
          itemBuilder: (context, index) {
            final stack = stacks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space12),
              child: _StackCard(
                stack: stack,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StackDetailScreen(stackId: stack.id),
                    ),
                  );
                },
                onDelete: () => _confirmDelete(context, ref, stack),
                onEdit: () => _openEditSheet(context, ref, stack),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCreateSheet(
    BuildContext context,
    WidgetRef ref,
    int currentCount,
  ) async {
    final newStack = await showStackFormSheet(context: context);
    if (newStack == null) return;
    await ref.read(stacksProvider.notifier).createStack(newStack);
  }

  Future<void> _openEditSheet(
    BuildContext context,
    WidgetRef ref,
    HabitStack stack,
  ) async {
    final updated = await showStackFormSheet(
      context: context,
      initialStack: stack,
    );
    if (updated == null) return;
    await ref.read(stacksProvider.notifier).updateStack(updated);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    HabitStack stack,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete stack?'),
        content: Text(
          'This removes "${stack.name}" and all its settings. '
          'Your habits will not be deleted.',
        ),
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
      ),
    );
    if (confirmed ?? false) {
      await ref.read(stacksProvider.notifier).deleteStack(stack.id);
    }
  }
}

class _StackCard extends StatelessWidget {
  const _StackCard({
    required this.stack,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  final HabitStack stack;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(stack.id),
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
          onDelete();
          return false; // handled by onDelete dialog
        }
        onEdit();
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space16),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: AppSpacing.borderRadiusMedium,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              // Emoji or default icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.backgroundTertiary,
                  borderRadius: AppSpacing.borderRadiusMedium,
                ),
                alignment: Alignment.center,
                child: stack.iconEmoji != null
                    ? Text(
                        stack.iconEmoji!,
                        style: const TextStyle(fontSize: 22),
                      )
                    : const Icon(
                        Icons.layers_outlined,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stack.name, style: AppTypography.headlineSmall),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      '${stack.habitIds.length} habit${stack.habitIds.length == 1 ? '' : 's'}',
                      style: AppTypography.bodySmall,
                    ),
                    if (stack.description != null &&
                        stack.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        stack.description!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
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
}
