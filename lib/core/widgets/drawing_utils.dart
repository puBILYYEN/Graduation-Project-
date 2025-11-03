
import 'package:flutter/material.dart';

// ====================================================================
// 繪製器工具類 (Painter Utilities)
// ====================================================================

/// 繪製器工具類 - 提供繪製器的常用工具方法
class PainterUtils {
  /// 創建標準的點繪製器
  static Paint createPointPaint(Color color) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.fill;
  }

  /// 創建標準的線條繪製器
  static Paint createLinePaint(Color color, {double strokeWidth = 2.0}) {
    return Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
  }

  /// 創建帶陰影的文字繪製器
  static TextPainter createTextPainter(
    String text, {
    Color color = Colors.black,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
  }

  /// 計算安全的文字位置（避免超出邊界）
  static Offset calculateSafeTextPosition(
    Size canvasSize,
    Size textSize, {
    double horizontalRatio = 0.5, // 水平位置比例
    double verticalRatio = 0.4, // 垂直位置比例
  }) {
    final x = (canvasSize.width * horizontalRatio - textSize.width / 2)
        .clamp(0, canvasSize.width - textSize.width);
    final y = (canvasSize.height * verticalRatio - textSize.height / 2)
        .clamp(0, canvasSize.height - textSize.height);
    return Offset(x.toDouble(), y.toDouble());
  }
}

// ====================================================================
// 擴展的自定義繪製器示例
// ====================================================================

/// 網格繪製器 - 繪製參考網格
class GridPainter extends CustomPainter {
  final double gridSize;
  final Color gridColor;

  GridPainter({
    this.gridSize = 20.0,
    this.gridColor = Colors.grey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withOpacity(0.3)
      ..strokeWidth = 1.0;

    // 繪製垂直線
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 繪製水平線
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 十字準線繪製器 - 繪製中心十字準線
class CrosshairPainter extends CustomPainter {
  final Color crosshairColor;
  final double strokeWidth;

  CrosshairPainter({
    this.crosshairColor = Colors.red,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = crosshairColor
      ..strokeWidth = strokeWidth;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final lineLength = 20.0;

    // 繪製水平線
    canvas.drawLine(
      Offset(centerX - lineLength, centerY),
      Offset(centerX + lineLength, centerY),
      paint,
    );

    // 繪製垂直線
    canvas.drawLine(
      Offset(centerX, centerY - lineLength),
      Offset(centerX, centerY + lineLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
