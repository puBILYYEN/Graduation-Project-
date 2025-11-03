import 'package:flutter/material.dart';
import '../../../../data/models/measurement_models.dart';

/// 邊緣檢測繪畫器
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

    if (edges.isNotEmpty) {
      textPaint.paint(canvas, Offset(edges.first.dx, edges.first.dy - 30));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is EdgeDetectionPainter && oldDelegate.edges != edges;
  }
}

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

  // Define paints here as class members
  final Paint pointPaint = Paint()
    ..color = Colors.red
    ..strokeWidth = 2
    ..style = PaintingStyle.fill;

  final Paint linePaint = Paint()
    ..color = Colors.blue
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  final Paint polygonPaint = Paint()
    ..color = Colors.green.withOpacity(0.5)
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    // 繪製參考點
    for (var point in referencePoints) {
      canvas.drawCircle(point.toOffset(), 6, pointPaint);
    }

    // 繪製測量點
    for (var point in measurementPoints) {
      canvas.drawCircle(point.toOffset(), 5, pointPaint);
    }

    switch (currentMode) {
      case MeasurementMode.calibration:
        _drawReferenceLine(canvas, size, referencePoints, linePaint);
        break;
      case MeasurementMode.measurement:
        _drawMeasurementLine(canvas, size, measurementPoints, linePaint);
        _drawMeasurementPolygon(canvas, size, measurementPoints, polygonPaint);
        break;
    }
  }

  // Helper methods for drawing
  void _drawReferenceLine(Canvas canvas, Size size, List<MeasurementPoint> points, Paint paint) {
    if (points.length == 2) {
      canvas.drawLine(points[0].toOffset(), points[1].toOffset(), paint);
    }
  }

  void _drawMeasurementLine(Canvas canvas, Size size, List<MeasurementPoint> points, Paint paint) {
    if (points.length >= 2) {
      canvas.drawLine(points[0].toOffset(), points[1].toOffset(), paint);
    }
  }

  void _drawMeasurementPolygon(Canvas canvas, Size size, List<MeasurementPoint> points, Paint paint) {
    if (points.length >= 3) {
      final path = Path();
      path.moveTo(points[0].toOffset().dx, points[0].toOffset().dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].toOffset().dx, points[i].toOffset().dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MeasurementPainter oldDelegate) {
    return oldDelegate.referencePoints != referencePoints ||
           oldDelegate.measurementPoints != measurementPoints ||
           oldDelegate.currentMode != currentMode ||
           oldDelegate.isCalibrated != isCalibrated;
  }
}