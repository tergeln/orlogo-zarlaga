import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..repeat();

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _BackdropPainter()),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 26),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 571 / 937,
                        child: AnimatedBuilder(
                          animation: _float,
                          builder: (context, _) => _Figure(t: _float.value),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const FadeSlideIn(
            delay: Duration(milliseconds: 150),
            child: Text(
              'Ухаалаг Зарцуулж\nИлүү Хэмнэе',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 28),
          FadeSlideIn(
            delay: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: PrimaryButton(
                label: 'Эхлэх',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          FadeSlideIn(
            delay: const Duration(milliseconds: 420),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Хэрэглэгчийн Эрх Бий Юу?',
                    style: TextStyle(fontSize: 14, color: AppColors.grey)),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Нэвтрэх',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// Хөвж буй хүн, зоос, диаграм. [t] нь 0..1 хооронд давтагдана.
class _Figure extends StatelessWidget {
  final double t;
  const _Figure({required this.t});

  double _wave(double phase) => math.sin((t + phase) * 2 * math.pi);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final bob = _wave(0) * h * 0.012;
        Widget piece(String asset, double x, double y, double pw, double ph,
            double phase, double amp, double turn) {
          return Positioned(
            left: x * w,
            top: y * h + bob + _wave(phase) * h * amp,
            width: pw * w,
            height: ph * h,
            child: Transform.rotate(
              angle: _wave(phase + 0.25) * turn,
              child: Image.asset(asset,
                  fit: BoxFit.contain, filterQuality: FilterQuality.medium),
            ),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Доорх сүүдэр: хүн дээш хөөрөхөд жижгэрнэ.
            Positioned(
              left: w * 0.32,
              right: w * 0.2,
              bottom: -h * 0.012,
              height: h * 0.022,
              child: Transform.scale(
                scaleX: 1 - _wave(0) * -0.08,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.black.withValues(alpha: 0.07),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: bob,
              height: h,
              child: Image.asset('assets/images/onboarding_man.png',
                  fit: BoxFit.contain, filterQuality: FilterQuality.medium),
            ),
            piece('assets/images/onboarding_coin.png', 0.014, 0.051, 0.221,
                0.139, 0.30, 0.016, 0.10),
            piece('assets/images/onboarding_pie.png', 0.797, 0.165, 0.203,
                0.130, 0.65, 0.018, 0.08),
          ],
        );
      },
    );
  }
}

/// Figma дээрх цайвар ногоон дэвсгэр, тойрог шугамууд, доод талын цагаан налуу.
class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFEEF9F5));
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white;
    final center = Offset(size.width / 2, size.height * 0.47);
    for (final r in const [0.43, 0.60, 0.78, 0.98]) {
      canvas.drawCircle(center, size.width * r, ring);
    }
    final slope = Path()
      ..moveTo(0, size.height * 0.885)
      ..lineTo(size.width, size.height * 0.965)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(slope, Paint()..color = const Color(0xFFFCFCFC));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
