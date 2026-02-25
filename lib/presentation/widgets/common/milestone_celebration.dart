import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Milestone streak counts that trigger a celebration.
const _milestones = [7, 30, 60, 90, 180, 365];

/// Shows a confetti overlay + toast for [streak] if it is a milestone value.
///
/// Fires [HapticFeedback.mediumImpact] on milestone.
/// Regular-toggle haptics ([HapticFeedback.lightImpact]) must be called by
/// the caller separately on every toggle.
///
/// Safe to call unconditionally — returns immediately if [streak] is not a
/// milestone.
void showMilestoneCelebration(
  BuildContext context, {
  required int streak,
  required String habitName,
}) {
  if (!_milestones.contains(streak)) return;

  HapticFeedback.mediumImpact();

  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CelebrationOverlay(
      streak: streak,
      habitName: habitName,
      onDismiss: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

// ---------------------------------------------------------------------------
// Overlay widget
// ---------------------------------------------------------------------------

class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay({
    required this.streak,
    required this.habitName,
    required this.onDismiss,
  });

  final int streak;
  final String habitName;
  final VoidCallback onDismiss;

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;

  /// Total visible duration of the overlay (confetti + toast).
  static const _totalDuration = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: _totalDuration,
    )..forward();

    // Auto-dismiss after animation completes.
    Future.delayed(_totalDuration + const Duration(milliseconds: 200), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String get _message {
    if (widget.streak >= 365) return '365 days — a full year! Legendary.';
    if (widget.streak >= 180) return '${widget.streak} days — half a year!';
    if (widget.streak >= 90) return '${widget.streak} days — three months!';
    if (widget.streak >= 60) return '${widget.streak} days — two months!';
    if (widget.streak >= 30) return '${widget.streak} days — a full month!';
    return '${widget.streak}-day streak — one full week!';
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // --- Confetti layer (full screen) ---
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) => CustomPaint(
                painter: _ConfettiPainter(progress: _confettiController.value),
              ),
            ),
          ),

          // --- Toast (bottom of screen) ---
          Positioned(
            left: AppSpacing.space24,
            right: AppSpacing.space24,
            bottom: 100,
            child: _MilestoneToast(
              message: _message,
              habitName: widget.habitName,
              streak: widget.streak,
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: 300.ms,
                  curve: Curves.easeOutCubic,
                )
                .then(delay: 900.ms)
                .fadeOut(duration: 300.ms),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toast widget
// ---------------------------------------------------------------------------

class _MilestoneToast extends StatelessWidget {
  const _MilestoneToast({
    required this.message,
    required this.habitName,
    required this.streak,
  });

  final String message;
  final String habitName;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space20,
        vertical: AppSpacing.space16,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.accentGoldMuted, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Streak count badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGoldSubtle,
              border: Border.all(color: AppColors.accentGoldMuted),
            ),
            child: Center(
              child: Text(
                '${streak}d',
                style: AppTypography.dataSmall.copyWith(
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: AppTypography.headlineSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  habitName,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          const Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.accentGold,
            size: 22,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confetti painter
// ---------------------------------------------------------------------------

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress});

  final double progress;

  static final _rng = math.Random(13);

  static final List<_Particle> _particles = List.generate(50, (i) {
    return _Particle(
      x: _rng.nextDouble(),
      delay: _rng.nextDouble() * 0.35,
      speed: 0.55 + _rng.nextDouble() * 0.45,
      size: 4.0 + _rng.nextDouble() * 5.0,
      angle: _rng.nextDouble() * math.pi * 2,
      rotationSpeed: (_rng.nextDouble() - 0.5) * 10,
      color: _palette[i % _palette.length],
      isRect: i % 3 != 0,
    );
  });

  static const _palette = [
    AppColors.accentGold,
    AppColors.completionGreen,
    AppColors.twoMinuteBlue,
    AppColors.missedCoral,
    Color(0xFFB088D4), // lavender
    Color(0xFF5BC0BE), // teal
    Color(0xFFE07B53), // tangerine
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in _particles) {
      final t = ((progress - p.delay) / p.speed).clamp(0.0, 1.0);
      if (t <= 0) continue;

      // Fade out the last 20% of each particle's life.
      final opacity = t < 0.8 ? 1.0 : (1.0 - t) / 0.2;
      final x = size.width * p.x;
      final y = -20.0 +
          (size.height + 40) * t * p.speed +
          math.sin(t * math.pi * 3 + p.angle) * 18;
      final rotation = p.angle + p.rotationSpeed * t;

      paint.color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      if (p.isRect) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.45,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  const _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.angle,
    required this.rotationSpeed,
    required this.color,
    required this.isRect,
  });

  final double x;
  final double delay;
  final double speed;
  final double size;
  final double angle;
  final double rotationSpeed;
  final Color color;
  final bool isRect;
}
