import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadAuthData();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final value = _animationController.value;
          final screenSize = MediaQuery.sizeOf(context);
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(
                  -1 + (math.sin(value * math.pi * 2) * 0.25),
                  -1,
                ),
                end: Alignment(
                  1,
                  1 + (math.cos(value * math.pi * 2) * 0.25),
                ),
                colors: [
                  Color.lerp(
                    const Color(0xFF020202),
                    const Color(0xFF170006),
                    value,
                  )!,
                  Color.lerp(
                    const Color(0xFF1B0507),
                    const Color(0xFF3B0309),
                    (value + 0.35) % 1,
                  )!,
                  Color.lerp(
                    const Color(0xFFE50914),
                    const Color(0xFF7A0007),
                    (value + 0.7) % 1,
                  )!,
                ],
              ),
            ),
            child: Stack(
              children: [
                _MovingGlow(
                  size: screenSize.shortestSide * 0.58,
                  color: const Color(0xFFE50914),
                  left: -90 + (math.sin(value * math.pi * 2) * 70),
                  top: screenSize.height * 0.10,
                ),
                _MovingGlow(
                  size: screenSize.shortestSide * 0.42,
                  color: Colors.white,
                  right: -110 + (math.cos(value * math.pi * 2) * 55),
                  bottom: screenSize.height * 0.08,
                  opacity: 0.05,
                ),
                _MovingGlow(
                  size: screenSize.shortestSide * 0.34,
                  color: const Color(0xFFE50914),
                  right: screenSize.width * 0.20,
                  top: -80 + (math.cos(value * math.pi * 2) * 45),
                  opacity: 0.08,
                ),
                Positioned.fill(child: child!),
              ],
            ),
          );
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _PulseAnimation(animation: _animationController),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE50914).withValues(alpha: 0.25),
                        blurRadius: 22,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.30),
                        blurRadius: 5,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 300,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Media House Edge',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Film | Montage | Advertising',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 46),
              _CinemaLoader(animation: _animationController),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class _PulseAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  @override
  final Animation<double> parent;

  const _PulseAnimation({required Animation<double> animation})
    : parent = animation;

  @override
  double get value {
    final wave = (math.sin(parent.value * math.pi * 2) + 1) / 2;
    return 0.97 + (wave * 0.05);
  }
}

class _MovingGlow extends StatelessWidget {
  final double size;
  final Color color;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double opacity;

  const _MovingGlow({
    required this.size,
    required this.color,
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.opacity = 0.10,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: opacity * 0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CinemaLoader extends StatelessWidget {
  final Animation<double> animation;

  const _CinemaLoader({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              width: 92,
              height: 92,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE50914).withValues(alpha: 0.28),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _CinemaLoaderPainter(progress: animation.value),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: const Text(
                'Loading studio assets',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CinemaLoaderPainter extends CustomPainter {
  final double progress;

  const _CinemaLoaderPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final redPaint = Paint()
      ..color = const Color(0xFFE50914)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.4
      ..strokeCap = StrokeCap.round;
    final softPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final dotPaint = Paint()..color = Colors.white;
    final reelPaint = Paint()..color = Colors.white.withValues(alpha: 0.72);
    final angle = progress * math.pi * 2;
    final rect = Rect.fromCircle(center: center, radius: radius - 4);

    canvas.drawCircle(center, radius - 5, softPaint);
    canvas.drawArc(rect, angle, math.pi * 1.35, false, redPaint);

    for (var index = 0; index < 6; index++) {
      final holeAngle = angle + (index * math.pi / 3);
      final holeCenter = Offset(
        center.dx + math.cos(holeAngle) * (radius * 0.42),
        center.dy + math.sin(holeAngle) * (radius * 0.42),
      );
      canvas.drawCircle(holeCenter, 3.2, reelPaint);
    }

    final sweepDot = Offset(
      center.dx + math.cos(angle + math.pi * 1.35) * (radius - 4),
      center.dy + math.sin(angle + math.pi * 1.35) * (radius - 4),
    );
    canvas.drawCircle(sweepDot, 4.6, dotPaint);

    final clapperWidth = radius * 0.92;
    final clapperHeight = radius * 0.42;
    final clapperRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: clapperWidth,
        height: clapperHeight,
      ),
      const Radius.circular(5),
    );
    final clapperPaint = Paint()..color = const Color(0xFFE50914);
    canvas.drawRRect(clapperRect, clapperPaint);

    final stripePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..strokeWidth = 3;
    for (var index = -1; index <= 1; index++) {
      final dx = center.dx + (index * clapperWidth / 4);
      canvas.drawLine(
        Offset(dx - 7, center.dy - clapperHeight / 2),
        Offset(dx + 7, center.dy),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CinemaLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
