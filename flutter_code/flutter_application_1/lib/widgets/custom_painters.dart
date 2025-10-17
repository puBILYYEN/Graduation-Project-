// ----- [widgets/custom_painters.dart] 開始 -----
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

import '../models/container_analysis.dart';

// ====================================================================
// 自定義繪製器模組 (Custom Painters Module)
// ====================================================================
/*
模組化建議：【工具類模組 - widgets/custom_painters.dart】
自定義繪製器類別可以獨立成為工具模組：
- EdgeDetectionPainter: 邊緣檢測繪畫器
- MeasurementPainter: 測量繪圖器
這些繪製器專責UI繪製邏輯，可復用性高。
*/

// ====================================================================
// 邊緣檢測繪畫器 (Edge Detection Painter)
// ====================================================================

/// 邊緣檢測繪畫器 - 用於繪製容器邊緣檢測結果
///
/// 功能：
/// - 繪製檢測到的邊緣點
/// - 連接邊緣點形成輪廓線
/// - 自動閉合多邊形
/// - 顯示檢測結果標籤
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
  ///
  /// 功能：
  /// - 繪製參考物體的標記點（紅色圓點）
  /// - 連接參考點形成參考線（用於校準比例）
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
  ///
  /// 功能：
  /// - 繪製測量操作的標記點（藍色圓點）
  /// - 根據測量模式繪製不同的連接線和形狀
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
  ///
  /// 功能：
  /// - 將測量點成對連接，形成長度測量線
  /// - 適用於長度測量模式
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
  ///
  /// 功能：
  /// - 連接所有測量點形成多邊形
  /// - 自動閉合多邊形（當點數>=3時）
  /// - 適用於面積和體積測量模式
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
    return Offset(x, y);
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

// ----- [widgets/custom_painters.dart] 結束 -----