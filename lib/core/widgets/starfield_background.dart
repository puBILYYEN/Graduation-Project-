import 'package:flutter/material.dart';
import 'dart:math' as math;

class StarfieldBackground extends StatefulWidget {
  const StarfieldBackground({super.key});

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground>
    with TickerProviderStateMixin {
  List<Star> stars = [];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // 延遲生成星星，等待螢幕尺寸確定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateStars();
    });
  }

  void _generateStars() {
    final size = MediaQuery.of(context).size;
    stars.clear();

    for (int i = 0; i < 80; i++) {
      stars.add(Star(
        x: math.Random().nextDouble() * size.width,
        y: math.Random().nextDouble() * size.height,
        size: math.Random().nextDouble() * 2 + 1,
        color: math.Random().nextBool()
            ? Colors.white
            : const Color(0xFF87CEEB), // 淡藍色
        animationDelay: math.Random().nextDouble() * 3,
      ));
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: StarfieldPainter(stars, _controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class Star {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double animationDelay;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.animationDelay,
  });
}

class StarfieldPainter extends CustomPainter {
  final List<Star> stars;
  final double animationValue;

  StarfieldPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      // 計算每顆星星的閃爍透明度
      final adjustedTime = (animationValue + star.animationDelay) % 1.0;
      final opacity = (math.sin(adjustedTime * 2 * math.pi) + 1) / 2;

      final paint = Paint()
        ..color = star.color.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;

      // 繪製星星（小圓點）
      canvas.drawCircle(
        Offset(star.x, star.y),
        star.size,
        paint,
      );

      // 為較大的星星添加十字形光芒
      if (star.size > 1.5 && opacity > 0.7) {
        final glowPaint = Paint()
          ..color = star.color.withOpacity(opacity * 0.4)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

        // 繪製十字光芒
        canvas.drawLine(
          Offset(star.x - star.size * 2, star.y),
          Offset(star.x + star.size * 2, star.y),
          glowPaint,
        );
        canvas.drawLine(
          Offset(star.x, star.y - star.size * 2),
          Offset(star.x, star.y + star.size * 2),
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}