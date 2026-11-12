import 'package:flutter/material.dart';

import '../theme.dart';

/// Мөнгөн дүнг өмнөх утгаас шинэ утга руу гүйлгэж харуулна.
class AnimatedMoney extends StatelessWidget {
  final double value;
  final TextStyle style;
  final String prefix;
  const AnimatedMoney(this.value,
      {super.key, required this.style, this.prefix = ''});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('$prefix${money(v)}', style: style),
    );
  }
}

/// Хүүхэд виджетийг бага зэрэг доороос дээш гулсуулж, тодруулж гаргана.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final double offset;
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
  });

  @override
  Widget build(BuildContext context) {
    const run = Duration(milliseconds: 450);
    final total = delay + run;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (_, t, c) => Opacity(
        opacity: t.clamp(0.0, 1.0).toDouble(),
        child: Transform.translate(offset: Offset(0, (1 - t) * offset), child: c),
      ),
      child: child,
    );
  }
}

/// Дарах үед бага зэрэг жижгэрдэг хүрэлцэх эффект.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const PressScale({super.key, required this.child, this.onTap});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        child: widget.child,
      ),
    );
  }
}
