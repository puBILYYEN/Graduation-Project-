// ====================================================================
// 測量計算服務模組
// ====================================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 測量計算服務
class MeasurementCalculator {
  /// 計算兩點之間的距離 (像素)
  static double calculatePixelDistance(Offset point1, Offset point2) {
    return math.sqrt(math.pow(point2.dx - point1.dx, 2) +
        math.pow(point2.dy - point1.dy, 2));
  }

  /// 計算比例 (像素/厘米)
  static double calculateScale(
      Offset startPoint, Offset endPoint, double realWorldSize) {
    double pixelDistance = calculatePixelDistance(startPoint, endPoint);
    return pixelDistance / realWorldSize;
  }

  /// 計算真實世界距離
  static double calculateRealDistance(
      Offset point1, Offset point2, double scale) {
    double pixelDistance = calculatePixelDistance(point1, point2);
    return pixelDistance / scale;
  }

  /// 計算多邊形面積 (使用鞋帶公式)
  static double calculatePolygonArea(List<Offset> points, double scale) {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    int n = points.length;

    for (int i = 0; i < n; i++) {
      int j = (i + 1) % n;
      area += points[i].dx * points[j].dy;
      area -= points[j].dx * points[i].dy;
    }

    area = area.abs() / 2.0;
    // 轉換為真實世界面積
    return area / (scale * scale);
  }

  /// 估算體積 (假設為圓柱體或長方體)
  static double estimateVolume(List<Offset> points, double scale,
      {double estimatedHeight = 2.0} // 預設高度 2cm
      ) {
    double area = calculatePolygonArea(points, scale);
    return area * estimatedHeight;
  }
}

// 設備物理方向枚舉 - 定義設備可能的物理方向狀態
enum DevicePhysicalOrientation {
  portraitUp, // 正常豎螢幕 - 設備垂直放置，Home鍵在下方
  portraitDown, // 倒置豎螢幕 - 設備垂直放置，Home鍵在上方
  landscapeLeft, // 左橫螢幕 - 設備逆時針旋轉90度，Home鍵在右側
  landscapeRight, // 右橫螢幕 - 設備順時針旋轉90度，Home鍵在左側
}
// ----- [services/measurement_calculator.dart] 結束 -----