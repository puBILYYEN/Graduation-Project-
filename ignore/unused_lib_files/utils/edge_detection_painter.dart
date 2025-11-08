import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/models/measurement.dart';

class EdgeDetectionPainter extends CustomPainter {
  final List<MeasurementPoint> points;
  final Size? detectedSize;
  final double scale;
  final bool showGrid;

  EdgeDetectionPainter({
    required this.points,
    this.detectedSize,
    this.scale = 1.0,
    this.showGrid = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw grid if enabled
    if (showGrid) {
      _drawGrid(canvas, size, paint);
    }

    // Draw detected points
    final pointPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    for (var point in points) {
      canvas.drawPoints(
        PointMode.points,
        [point.position],
        pointPaint,
      );
    }

    // Draw lines between points
    if (points.length >= 2) {
      for (var i = 0; i < points.length - 1; i++) {
        canvas.drawLine(
          points[i].position,
          points[i + 1].position,
          paint,
        );
      }
    }

    // Draw detected size if available
    if (detectedSize != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text:
              '${(detectedSize!.width * scale).toStringAsFixed(1)} x ${(detectedSize!.height * scale).toStringAsFixed(1)} cm',
          style: const TextStyle(
            color: Colors.white,
            backgroundColor: Colors.black54,
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, const Offset(10, 10));
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.white.withAlpha(100);
    paint.strokeWidth = 0.5;

    const gridSize = 50.0;
    for (var i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
    for (var i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(EdgeDetectionPainter oldDelegate) {
    return points != oldDelegate.points ||
        detectedSize != oldDelegate.detectedSize ||
        scale != oldDelegate.scale ||
        showGrid != oldDelegate.showGrid;
  }
}