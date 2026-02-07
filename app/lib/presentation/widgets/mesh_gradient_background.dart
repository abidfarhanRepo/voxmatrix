import 'dart:math';
import 'package:flutter/material.dart';

class MeshGradientBackground extends StatefulWidget {
  const MeshGradientBackground({super.key});

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientPainter(_controller.value),
          child: Container(),
        );
      },
    );
  }
}

class _GradientPainter extends CustomPainter {
  final double animationValue;

  _GradientPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // 1. Draw base black
    canvas.drawRect(rect, Paint()..color = Colors.black);

    // 2. Draw organic blobs
    // Top Left Area
    _drawBlob(
      canvas,
      size,
      color: const Color(0xFF4A0404).withOpacity(0.35),
      centerX: 0.1 + 0.2 * sin(animationValue * 2 * pi),
      centerY: 0.2 + 0.1 * cos(animationValue * 2 * pi),
      radius: size.width * 0.9,
    );

    // Bottom Right Area
    _drawBlob(
      canvas,
      size,
      color: const Color(0xFF330202).withOpacity(0.3),
      centerX: 0.9 + 0.15 * cos(animationValue * 2 * pi + 1.5),
      centerY: 0.8 + 0.2 * sin(animationValue * 2 * pi + 1.5),
      radius: size.width * 1.0,
    );

    // Center Moving Area
    _drawBlob(
      canvas,
      size,
      color: const Color(0xFF660505).withOpacity(0.25),
      centerX: 0.5 + 0.3 * sin(animationValue * 2 * pi + 3.0),
      centerY: 0.5 + 0.3 * cos(animationValue * 2 * pi + 3.0),
      radius: size.width * 0.8,
    );

    // Subtle Highlight
    _drawBlob(
      canvas,
      size,
      color: const Color(0xFFB30000).withOpacity(0.1),
      centerX: 0.3 + 0.4 * cos(animationValue * 2 * pi + 4.5),
      centerY: 0.7 + 0.2 * sin(animationValue * 2 * pi + 4.5),
      radius: size.width * 0.6,
    );
  }

  void _drawBlob(
    Canvas canvas,
    Size size, {
    required Color color,
    required double centerX,
    required double centerY,
    required double radius,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * centerX, size.height * centerY),
          radius: radius,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * centerX, size.height * centerY),
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
