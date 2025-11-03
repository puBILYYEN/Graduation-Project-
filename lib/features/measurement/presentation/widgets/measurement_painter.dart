
import 'package:flutter/material.dart';

// 新增測量模式列舉
enum MeasurementMode {
  calibration,
  length,
  area,
  volume,
}

// 新增測量點類別
class MeasurementPoint {
  final Offset position;
  final String? label;

  MeasurementPoint({
    required this.position,
    this.label,
  });
}

// ====================================================================
// 測量繪圖器 (Measurement Painter)
// ====================================================================

/// 測量繪圖器 - 用於繪製各種測量操作的視覺反饋
///
/// 功能：
/// - 繪製參考物體校準點和線條
/// - 繪製測量點和測量線條
/// - 支援多種測量模式（長度、面積、體積）
/// - 動態視覺反饋和狀態顯示
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
    try {
      // 設定繪製邊界，避免繪製到底部控制面板區域
      final maxY = size.height * 0.75;
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, maxY));

      // 繪製參考線
      if (referencePoints.isNotEmpty) {
        _drawReferencePoints(canvas);
      }

      // 繪製測量點和線條
      if (isCalibrated && measurementPoints.isNotEmpty) {
        _drawMeasurementPoints(canvas);
      }
    } catch (e) {
      // 錯誤處理：記錄錯誤但不中斷繪製
      debugPrint('MeasurementPainter 繪製錯誤: $e');
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
  bool shouldRepaint(covariant MeasurementPainter oldDelegate) {
    return oldDelegate.referencePoints != referencePoints ||
        oldDelegate.measurementPoints != measurementPoints ||
        oldDelegate.currentMode != currentMode ||
        oldDelegate.isCalibrated != isCalibrated;
  }
}
