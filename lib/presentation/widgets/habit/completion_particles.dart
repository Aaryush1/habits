import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Wraps [child] and plays a small particle burst when [isCompleted] flips
/// from false to true. Particles radiate ~20px outward in the habit's [color]
/// and fade over 350ms.
///
/// Typical usage: wrap the HabitCheckbox inside HabitCard.
class CompletionParticles extends StatefulWidget {
  const CompletionParticles({
    super.key,
    required this.isCompleted,
    required this.child,
    this.color = const Color(0xFFE8A838),
    this.particleCount = 6,
  });

  /// When this flips to `true` the burst plays.
  final bool isCompleted;

  final Widget child;

  /// Particle color — should match the habit's accent color.
  final Color color;

  /// Number of dots to emit (4–6 recommended).
  final int particleCount;

  @override
  State<CompletionParticles> createState() => _CompletionParticlesState();
}

class _CompletionParticlesState extends State<CompletionParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _active = false);
        _controller.reset();
      }
    });
  }

  @override
  void didUpdateWidget(CompletionParticles old) {
    super.didUpdateWidget(old);
    // Fire only on false → true transition.
    if (!old.isCompleted && widget.isCompleted) {
      setState(() => _active = true);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_active)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) => CustomPaint(
                  painter: _ParticlePainter(
                    progress: _animation.value,
                    color: widget.color,
                    particleCount: widget.particleCount,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({
    required this.progress,
    required this.color,
    required this.particleCount,
  });

  final double progress;
  final Color color;
  final int particleCount;

  /// Max radius particles travel from center (px).
  static const double _maxRadius = 20.0;

  /// Dot size at t=0 shrinks to 0 at t=1.
  static const double _dotRadius = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Fade out starts at 60% of animation.
    final opacity = progress < 0.6 ? 1.0 : 1.0 - ((progress - 0.6) / 0.4);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0));

    final center = Offset(size.width / 2, size.height / 2);
    final dist = _maxRadius * progress;
    final dotSize = _dotRadius * (1.0 - progress * 0.5);

    for (var i = 0; i < particleCount; i++) {
      // Evenly distribute around the circle, offset by a fixed phase.
      final angle = (2 * math.pi * i / particleCount) - math.pi / 2;
      final x = center.dx + math.cos(angle) * dist;
      final y = center.dy + math.sin(angle) * dist;
      canvas.drawCircle(Offset(x, y), dotSize.clamp(0.5, _dotRadius), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress || old.color != color;
}
