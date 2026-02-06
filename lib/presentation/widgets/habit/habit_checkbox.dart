import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class HabitCheckbox extends StatefulWidget {
  const HabitCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.color,
    this.size = 32,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? color;
  final double size;

  @override
  State<HabitCheckbox> createState() => _HabitCheckboxState();
}

class _HabitCheckboxState extends State<HabitCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
      ),
    );
    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(HabitCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? AppColors.completionGreen;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onChanged(!widget.value);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = _scaleAnimation.value;
          final progress = _controller.value;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Color.lerp(Colors.transparent, accent, progress),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color.lerp(AppColors.borderMedium, accent, progress)!,
                  width: 2.0,
                ),
              ),
              child: Opacity(
                opacity: _checkAnimation.value,
                child: Icon(
                  Icons.check_rounded,
                  size: widget.size * 0.55,
                  color: AppColors.textInverse,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
