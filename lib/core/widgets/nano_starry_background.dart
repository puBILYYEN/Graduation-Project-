
import 'dart:math';
import 'package:flutter/material.dart';

// ==========================================================================
// Nano Starry Background Widget
// ==========================================================================
/// 一個由 Gemini (Nano Banana) 創作的、充滿動態的星空背景動畫。
/// 特色：
///   - 多層次視差效果，營造深邃感。
///   - 星星隨機閃爍，增加生動感。
///   - 偶爾劃過的流星，帶來驚喜。
///   - 緩慢移動的微妙星雲，增加背景層次。
class NanoStarryBackground extends StatefulWidget {
  const NanoStarryBackground({super.key});

  @override
  State<NanoStarryBackground> createState() => _NanoStarryBackgroundState();
}

class _NanoStarryBackgroundState extends State<NanoStarryBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Star> _stars;
  late List<Meteor> _meteors;
  late List<Nebula> _nebulas;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _stars = [];
    _meteors = [];
    _nebulas = List.generate(5, (index) => Nebula.random());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 確保 _stars 在 context 可用後被初始化
    if (_stars.isEmpty) {
      _stars = List.generate(300, (index) => Star.random(context));
    }
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
        // 更新星星、星雲的位置
        for (var star in _stars) {
          star.update(context);
        }
        for (var nebula in _nebulas) {
          nebula.update();
        }

        // 隨機產生流星
        if (Random().nextDouble() < 0.005 && _meteors.isEmpty) {
          _meteors.add(Meteor.random(context));
        }

        // 更新流星位置並移除消失的流星
        _meteors.removeWhere((meteor) {
          meteor.update();
          return meteor.isGone(context);
        });

        return CustomPaint(
          painter: _StarrySkyPainter(
            stars: _stars,
            meteors: _meteors,
            nebulas: _nebulas,
          ),
          child: Container(),
        );
      },
    );
  }
}

// ==========================================================================
// Custom Painter
// ==========================================================================
class _StarrySkyPainter extends CustomPainter {
  final List<Star> stars;
  final List<Meteor> meteors;
  final List<Nebula> nebulas;

  _StarrySkyPainter({
    required this.stars,
    required this.meteors,
    required this.nebulas,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 繪製純黑背景
    canvas.drawColor(Colors.black, BlendMode.src);

    // 繪製星雲
    for (final nebula in nebulas) {
      final nebulaPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            nebula.color.withOpacity(0.3),
            nebula.color.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: nebula.position, radius: nebula.radius));
      canvas.drawCircle(nebula.position, nebula.radius, nebulaPaint);
    }

    // 繪製星星
    for (final star in stars) {
      final starPaint = Paint()
        ..color = Colors.white.withOpacity(star.opacity)
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(star.position, star.size, starPaint);
    }

    // 繪製流星
    for (final meteor in meteors) {
      final meteorPaint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ).createShader(Rect.fromPoints(meteor.start, meteor.end))
        ..strokeWidth = meteor.thickness
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(meteor.start, meteor.end, meteorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================================================
// Data Models
// ==========================================================================

/// 代表一顆星星
class Star {
  Offset position;
  double size;
  double opacity;
  double speed; // 視差速度

  Star(this.position, this.size, this.opacity, this.speed);

  factory Star.random(BuildContext context) {
    final random = Random();
    final size = MediaQuery.of(context).size;
    return Star(
      Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
      random.nextDouble() * 1.5 + 0.5, // 尺寸 0.5 到 2.0
      random.nextDouble() * 0.8 + 0.2, // 透明度 0.2 到 1.0
      random.nextDouble() * 0.3 + 0.1, // 速度 0.1 到 0.4
    );
  }

  void update(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // 根據速度移動
    position = Offset(position.dx - speed, position.dy);
    // 如果移出左邊，從右邊重新進入
    if (position.dx < 0) {
      position = Offset(size.width, Random().nextDouble() * size.height);
    }
    // 隨機改變透明度來閃爍
    if (Random().nextDouble() < 0.01) {
      opacity = Random().nextDouble() * 0.8 + 0.2;
    }
  }
}

/// 代表一顆流星
class Meteor {
  Offset start;
  Offset end;
  double thickness;
  double speed;
  
  Meteor(this.start, this.end, this.thickness, this.speed);

  factory Meteor.random(BuildContext context) {
    final random = Random();
    final size = MediaQuery.of(context).size;
    final startX = random.nextDouble() * size.width * 1.5;
    final startY = random.nextDouble() * size.height * 0.5;
    final length = random.nextDouble() * 150 + 50;
    return Meteor(
      Offset(startX, startY),
      Offset(startX - length, startY + length),
      random.nextDouble() * 1.5 + 0.5,
      random.nextDouble() * 15 + 10, // 速度 10 到 25
    );
  }

  void update() {
    start = Offset(start.dx - speed, start.dy + speed);
    end = Offset(end.dx - speed, end.dy + speed);
  }

  bool isGone(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return start.dx < -200 || start.dy > size.height + 200;
  }
}

/// 代表一團星雲
class Nebula {
  Offset position;
  double radius;
  Color color;
  Offset velocity;

  Nebula(this.position, this.radius, this.color, this.velocity);

  factory Nebula.random() {
    final random = Random();
    final colors = [
      Colors.purple.withOpacity(0.3),
      Colors.blue.withOpacity(0.3),
      Colors.pink.withOpacity(0.2),
    ];
    return Nebula(
      Offset(random.nextDouble() * 500 - 100, random.nextDouble() * 800 - 200),
      random.nextDouble() * 200 + 150, // 半徑 150 到 350
      colors[random.nextInt(colors.length)],
      Offset(random.nextDouble() * 0.05 - 0.025, random.nextDouble() * 0.05 - 0.025),
    );
  }

  void update() {
    position = position + velocity;
  }
}
