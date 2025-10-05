// ====================================================================
// 自訂繪圖器 (Custom Painters)
// ====================================================================
// 這個檔案包含自訂的 CustomPainter 類別，用於在 Canvas 上繪製特殊圖形

import 'package:flutter/material.dart';
import '../data/models/measurement.dart';

// EdgeDetectionPainter - 用於繪製邊緣檢測結果
class EdgeDetectionPainter extends CustomPainter {
  final List<Offset> edges;

  EdgeDetectionPainter(this.edges);

  @override
  void paint(Canvas canvas, Size size) {
    if (edges.isEmpty) return;

    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // 繪製邊緣線條
    if (edges.length >= 2) {
      final path = Path();
      path.moveTo(edges.first.dx, edges.first.dy);

      for (int i = 1; i < edges.length; i++) {
        path.lineTo(edges[i].dx, edges[i].dy);
      }

      // 閉合路徑
      if (edges.length >= 3) {
        path.close();
      }

      canvas.drawPath(path, paint);
    }

    // 繪製邊緣點
    for (final edge in edges) {
      canvas.drawCircle(edge, 6.0, dotPaint);
    }

    // 繪製標籤
    final textPaint = TextPainter(
      text: TextSpan(
        text: '檢測到的容器邊緣',
        style: TextStyle(
          color: Colors.red,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white.withOpacity(0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPaint.layout();
    // 將文字移到螢幕中央偏下位置，避免擋住頂部按鍵
    final centerX = size.width / 2 - textPaint.width / 2;
    final safeY = size.height * 0.4; // 螢幕高度40%位置
    textPaint.paint(canvas, Offset(centerX, safeY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is EdgeDetectionPainter && oldDelegate.edges != edges;
  }
}

// MeasurementPainter - 用於繪製測量點和線條
class MeasurementPainter extends CustomPainter {
  final List<MeasurementPoint> referencePoints;
  final List<MeasurementPoint> measurementPoints;
  final MeasurementMode currentMode;
  final bool isCalibrated;

  MeasurementPainter({
    required this.referencePoints,
    required this.measurementPoints,
    required this.currentMode,
    required this.isCalibrated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 設定繪製邊界，避免繪製到底部控制面板區域
    final maxY = size.height * 0.75; // 只在上方75%區域繪製
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, maxY));

    // 繪製參考線
    _drawReferencePoints(canvas);

    // 繪製測量點和線條
    if (isCalibrated) {
      _drawMeasurementPoints(canvas);
    }
  }

  /// 繪製參考點
  void _drawReferencePoints(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0;

    final pointPaint = Paint()..color = Colors.red;

    // 繪製參考點
    for (var point in referencePoints) {
      canvas.drawCircle(point.position, 6, pointPaint);
    }

    // 繪製參考線
    if (referencePoints.length >= 2) {
      canvas.drawLine(
        referencePoints[0].position,
        referencePoints[1].position,
        paint,
      );
    }
  }

  /// 繪製測量點
  void _drawMeasurementPoints(Canvas canvas) {
    if (measurementPoints.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0;

    final pointPaint = Paint()..color = Colors.blue;

    // 繪製測量點
    for (var point in measurementPoints) {
      canvas.drawCircle(point.position, 5, pointPaint);
    }

    // 根據模式繪製不同形狀
    switch (currentMode) {
      case MeasurementMode.length:
        _drawLengthLines(canvas, paint);
        break;
      case MeasurementMode.area:
      case MeasurementMode.volume:
        _drawPolygon(canvas, paint);
        break;
      default:
        break;
    }
  }

  /// 繪製長度線條
  void _drawLengthLines(Canvas canvas, Paint paint) {
    for (int i = 0; i < measurementPoints.length - 1; i += 2) {
      if (i + 1 < measurementPoints.length) {
        canvas.drawLine(
          measurementPoints[i].position,
          measurementPoints[i + 1].position,
          paint,
        );
      }
    }
  }

  /// 繪製多邊形
  void _drawPolygon(Canvas canvas, Paint paint) {
    if (measurementPoints.length < 2) return;

    final path = Path();
    path.moveTo(
        measurementPoints[0].position.dx, measurementPoints[0].position.dy);

    for (int i = 1; i < measurementPoints.length; i++) {
      path.lineTo(
          measurementPoints[i].position.dx, measurementPoints[i].position.dy);
    }

    // 如果有3個以上的點，閉合多邊形
    if (measurementPoints.length >= 3) {
      path.close();
    }

    paint.style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
