import 'package:flutter/material.dart';
import 'dart:math' as math;

class MeteorShowerBackground extends StatefulWidget {
  const MeteorShowerBackground({super.key});

  @override
  State<MeteorShowerBackground> createState() => _MeteorShowerBackgroundState();
}

class _MeteorShowerBackgroundState extends State<MeteorShowerBackground>
    with TickerProviderStateMixin {
  List<Meteor> meteors = [];
  late AnimationController _meteorController;
  late AnimationController _spawnController;

  @override
  void initState() {
    super.initState();

    // 流星移動動畫控制器
    _meteorController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // 流星生成控制器（每3-5秒生成一顆流星）
    _spawnController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _spawnController.addListener(() {
      // 當動畫重新開始時（值接近0），生成新流星
      if (_spawnController.value < 0.05 && meteors.length < 3) {
        _generateMeteor();
      }
    });
  }

  void _generateMeteor() {
    if (!mounted) return;

    final size = MediaQuery.of(context).size;
    final random = math.Random();

    // 隨機選擇流星起始位置（從螢幕邊緣）
    double startX, startY, endX, endY;

    if (random.nextBool()) {
      // 從左上角到右下角
      startX = -50;
      startY = random.nextDouble() * size.height * 0.3;
      endX = size.width + 50;
      endY = size.height * 0.7 + random.nextDouble() * size.height * 0.3;
    } else {
      // 從右上角到左下角
      startX = size.width + 50;
      startY = random.nextDouble() * size.height * 0.3;
      endX = -50;
      endY = size.height * 0.7 + random.nextDouble() * size.height * 0.3;
    }

    final meteor = Meteor(
      startX: startX,
      startY: startY,
      endX: endX,
      endY: endY,
      speed: 0.8 + random.nextDouble() * 0.4, // 0.8-1.2的速度
      size: 1.5 + random.nextDouble() * 2, // 1.5-3.5的大小
      color: random.nextBool()
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF87CEEB),
      createdAt: DateTime.now(),
    );

    setState(() {
      meteors.add(meteor);
    });

    // 3秒後移除流星
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          meteors.remove(meteor);
        });
      }
    });
  }

  @override
  void dispose() {
    _meteorController.dispose();
    _spawnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _meteorController,
        builder: (context, child) {
          return CustomPaint(
            painter: MeteorPainter(meteors, _meteorController.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class Meteor {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double speed;
  final double size;
  final Color color;
  final DateTime createdAt;

  Meteor({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.speed,
    required this.size,
    required this.color,
    required this.createdAt,
  });

  // 計算當前位置
  Offset getCurrentPosition(double animationValue) {
    final elapsed = DateTime.now().difference(createdAt).inMilliseconds / 1000.0;
    final progress = (elapsed * speed).clamp(0.0, 1.0);

    final currentX = startX + (endX - startX) * progress;
    final currentY = startY + (endY - startY) * progress;

    return Offset(currentX, currentY);
  }

  // 檢查流星是否已經結束
  bool get isFinished {
    final elapsed = DateTime.now().difference(createdAt).inMilliseconds / 1000.0;
    return elapsed * speed >= 1.0;
  }
}

class MeteorPainter extends CustomPainter {
  final List<Meteor> meteors;
  final double animationValue;

  MeteorPainter(this.meteors, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (final meteor in meteors) {
      if (meteor.isFinished) continue;

      final currentPos = meteor.getCurrentPosition(animationValue);
      final elapsed = DateTime.now().difference(meteor.createdAt).inMilliseconds / 1000.0;
      final progress = (elapsed * meteor.speed).clamp(0.0, 1.0);

      // 計算流星的方向向量
      final directionX = meteor.endX - meteor.startX;
      final directionY = meteor.endY - meteor.startY;
      final directionLength = math.sqrt(directionX * directionX + directionY * directionY);
      final normalizedDx = directionX / directionLength;
      final normalizedDy = directionY / directionLength;

      // 流星拖尾長度
      final tailLength = 50.0 * meteor.size;

      // 創建流星拖尾的漸變
      final tailStart = Offset(
        currentPos.dx - normalizedDx * tailLength,
        currentPos.dy - normalizedDy * tailLength,
      );

      // 繪製流星拖尾（漸變線條）
      final tailPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            meteor.color.withOpacity(0.0),
            meteor.color.withOpacity(0.3),
            meteor.color.withOpacity(0.8),
          ],
        ).createShader(Rect.fromPoints(tailStart, currentPos))
        ..strokeWidth = meteor.size * 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(tailStart, currentPos, tailPaint);

      // 繪製流星本體（發光圓點）
      final meteorPaint = Paint()
        ..color = meteor.color.withOpacity(0.9)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(currentPos, meteor.size, meteorPaint);

      // 繪製流星光暈
      final glowPaint = Paint()
        ..color = meteor.color.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(currentPos, meteor.size * 3, glowPaint);

      // 繪製流星閃光效果
      if (progress < 0.3) {
        final sparkPaint = Paint()
          ..color = Colors.white.withOpacity(0.8 * (1 - progress / 0.3))
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

        // 繪製十字閃光
        canvas.drawLine(
          Offset(currentPos.dx - meteor.size * 4, currentPos.dy),
          Offset(currentPos.dx + meteor.size * 4, currentPos.dy),
          sparkPaint,
        );
        canvas.drawLine(
          Offset(currentPos.dx, currentPos.dy - meteor.size * 4),
          Offset(currentPos.dx, currentPos.dy + meteor.size * 4),
          sparkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(MeteorPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.meteors.length != meteors.length;
  }
}