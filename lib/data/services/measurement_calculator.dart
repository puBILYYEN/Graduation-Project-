// ====================================================================
// 測量計算服務 (Measurement Calculator Service)
// ====================================================================
// 這個檔案提供各種測量相關的計算功能

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 測量計算服務(提供各種測量相關的計算功能)
class MeasurementCalculator {
  /// 計算兩點之間的距離(單位:螢幕上的像素點)
  static double calculatePixelDistance(Offset point1, Offset point2) {
    return math.sqrt(math.pow(point2.dx - point1.dx, 2) +
        math.pow(point2.dy - point1.dy, 2));
  }

  /// 計算比例(算出螢幕像素對應到實際公分的換算比例)
  static double calculateScale(
      Offset startPoint, Offset endPoint, double realWorldSize) {
    double pixelDistance = calculatePixelDistance(startPoint, endPoint);
    return pixelDistance / realWorldSize;
  }

  /// 計算真實世界距離(用比例把螢幕上的距離換算成實際的公分)
  static double calculateRealDistance(
      Offset point1, Offset point2, double scale) {
    double pixelDistance = calculatePixelDistance(point1, point2);
    return pixelDistance / scale;
  }

  /// 計算多邊形面積(用數學公式算出不規則形狀的面積，例如你畫一個五邊形)
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
    // 把螢幕上的面積換算成實際的面積(單位:平方公分)
    return area / (scale * scale);
  }

  /// 估算體積(假設容器是圓柱體或長方體，用底面積乘以高度來估算)
  static double estimateVolume(List<Offset> points, double scale,
      {double estimatedHeight = 2.0} // 預設高度2公分
      ) {
    double area = calculatePolygonArea(points, scale);
    return area * estimatedHeight;
  }
}

// 手機方向選項 - 記錄手機目前是直的還是橫的
enum DevicePhysicalOrientation {
  portraitUp, // 正常直立 - 手機直立放，Home鍵在下面
  portraitDown, // 上下顛倒 - 手機直立放，Home鍵在上面
  landscapeLeft, // 左橫 - 手機向左橫放，Home鍵在右邊
  landscapeRight, // 右橫 - 手機向右橫放，Home鍵在左邊
}
