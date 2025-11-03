// ----- [utils/image_processing.dart] 開始 -----
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ====================================================================
// 圖像處理工具模組 (Image Processing Utils Module)
// ====================================================================
/*
模組化建議：【工具類模組 - utils/image_processing.dart】
圖像處理類別可以獨立成為工具模組：
- EdgeDetector: 邊緣檢測算法
- ContainerDetector: 容器檢測器
- VolumeCalculator: 體積計算器
- ImageProcessor: 圖像處理核心類
這些處理器專責圖像分析邏輯，可復用性高。
*/

// ====================================================================
// 圖像處理數據模型 (Image Processing Data Models)
// ====================================================================

/// 像素點數據
class PixelData {
  final int x;
  final int y;
  final Color color;
  final double brightness;

  PixelData({
    required this.x,
    required this.y,
    required this.color,
    required this.brightness,
  });

  /// 從顏色計算亮度
  static double calculateBrightness(Color color) {
    return (color.red * 0.299 + color.green * 0.587 + color.blue * 0.114) / 255.0;
  }
}

/// 邊緣檢測結果
class EdgeDetectionResult {
  final List<Offset> edgePoints;
  final List<List<Offset>> contours;
  final double confidence;
  final DateTime timestamp;

  EdgeDetectionResult({
    required this.edgePoints,
    required this.contours,
    required this.confidence,
  }) : timestamp = DateTime.now();
}

/// 容器檢測結果
class ContainerDetectionResult {
  final List<Offset> containerBounds;
  final ContainerShape shape;
  final double area;
  final double perimeter;
  final Rect boundingBox;
  final double confidence;

  ContainerDetectionResult({
    required this.containerBounds,
    required this.shape,
    required this.area,
    required this.perimeter,
    required this.boundingBox,
    required this.confidence,
  });
}

/// 容器形狀枚舉
enum ContainerShape {
  rectangle,  // 矩形
  circle,     // 圓形
  ellipse,    // 橢圓
  polygon,    // 多邊形
  unknown     // 未知形狀
}

// ====================================================================
// 邊緣檢測器 (Edge Detector)
// ====================================================================

/// 邊緣檢測器 - 使用Canny算法檢測圖像邊緣
///
/// 功能：
/// - 高斯模糊預處理
/// - 梯度計算
/// - 非極大值抑制
/// - 雙閾值檢測
/// - 邊緣連接
class EdgeDetector {
  static const double defaultLowThreshold = 50.0;
  static const double defaultHighThreshold = 150.0;
  static const double defaultSigma = 1.4;

  /// 執行Canny邊緣檢測
  ///
  /// 參數：
  /// - [imageData]: 輸入圖像數據
  /// - [lowThreshold]: 低閾值
  /// - [highThreshold]: 高閾值
  /// - [sigma]: 高斯核標準差
  static Future<EdgeDetectionResult> detectEdges(
    List<List<PixelData>> imageData, {
    double lowThreshold = defaultLowThreshold,
    double highThreshold = defaultHighThreshold,
    double sigma = defaultSigma,
  }) async {
    if (imageData.isEmpty || imageData[0].isEmpty) {
      return EdgeDetectionResult(
        edgePoints: [],
        contours: [],
        confidence: 0.0,
      );
    }

    try {
      // 1. 高斯模糊
      final blurred = await _applyGaussianBlur(imageData, sigma);

      // 2. 計算梯度
      final gradients = _calculateGradients(blurred);

      // 3. 非極大值抑制
      final suppressed = _nonMaximumSuppression(gradients);

      // 4. 雙閾值檢測
      final edges = _doubleThresholding(suppressed, lowThreshold, highThreshold);

      // 5. 邊緣追蹤
      final edgePoints = _edgeTracking(edges);

      // 6. 輪廓提取
      final contours = _extractContours(edgePoints);

      // 7. 計算置信度
      final confidence = _calculateConfidence(edgePoints, imageData);

      return EdgeDetectionResult(
        edgePoints: edgePoints,
        contours: contours,
        confidence: confidence,
      );
    } catch (e) {
      return EdgeDetectionResult(
        edgePoints: [],
        contours: [],
        confidence: 0.0,
      );
    }
  }

  /// 應用高斯模糊
  static Future<List<List<double>>> _applyGaussianBlur(
    List<List<PixelData>> imageData,
    double sigma,
  ) async {
    final height = imageData.length;
    final width = imageData[0].length;
    final result = List.generate(height, (i) => List.filled(width, 0.0));

    // 創建高斯核
    final kernelSize = (6 * sigma).toInt() + 1;
    final kernel = _createGaussianKernel(kernelSize, sigma);
    final offset = kernelSize ~/ 2;

    // 應用卷積
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double sum = 0.0;
        double weightSum = 0.0;

        for (int ky = -offset; ky <= offset; ky++) {
          for (int kx = -offset; kx <= offset; kx++) {
            final ny = y + ky;
            final nx = x + kx;

            if (ny >= 0 && ny < height && nx >= 0 && nx < width) {
              final weight = kernel[ky + offset][kx + offset];
              sum += imageData[ny][nx].brightness * weight;
              weightSum += weight;
            }
          }
        }

        result[y][x] = weightSum > 0 ? sum / weightSum : 0.0;
      }
    }

    return result;
  }

  /// 創建高斯核
  static List<List<double>> _createGaussianKernel(int size, double sigma) {
    final kernel = List.generate(size, (i) => List.filled(size, 0.0));
    final center = size ~/ 2;
    double sum = 0.0;

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final dx = x - center;
        final dy = y - center;
        final value = math.exp(-(dx * dx + dy * dy) / (2 * sigma * sigma));
        kernel[y][x] = value;
        sum += value;
      }
    }

    // 歸一化
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        kernel[y][x] /= sum;
      }
    }

    return kernel;
  }

  /// 計算梯度
  static List<List<GradientData>> _calculateGradients(List<List<double>> imageData) {
    final height = imageData.length;
    final width = imageData[0].length;
    final result = List.generate(height, (i) => List.filled(width, GradientData(0, 0, 0)));

    // Sobel運算子
    final sobelX = [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]];
    final sobelY = [[-1, -2, -1], [0, 0, 0], [1, 2, 1]];

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        double gx = 0.0;
        double gy = 0.0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = imageData[y + ky][x + kx];
            gx += pixel * sobelX[ky + 1][kx + 1];
            gy += pixel * sobelY[ky + 1][kx + 1];
          }
        }

        final magnitude = math.sqrt(gx * gx + gy * gy);
        final direction = math.atan2(gy, gx);

        result[y][x] = GradientData(magnitude, direction, 0);
      }
    }

    return result;
  }

  /// 非極大值抑制
  static List<List<GradientData>> _nonMaximumSuppression(List<List<GradientData>> gradients) {
    final height = gradients.length;
    final width = gradients[0].length;
    final result = List.generate(height, (i) => List.filled(width, GradientData(0, 0, 0)));

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final current = gradients[y][x];
        final angle = current.direction * 180 / math.pi;
        final normalizedAngle = ((angle % 180) + 180) % 180;

        double neighbor1 = 0;
        double neighbor2 = 0;

        if ((normalizedAngle >= 0 && normalizedAngle < 22.5) ||
            (normalizedAngle >= 157.5 && normalizedAngle <= 180)) {
          // 水平方向
          neighbor1 = gradients[y][x - 1].magnitude;
          neighbor2 = gradients[y][x + 1].magnitude;
        } else if (normalizedAngle >= 22.5 && normalizedAngle < 67.5) {
          // 對角線方向 (/)
          neighbor1 = gradients[y - 1][x + 1].magnitude;
          neighbor2 = gradients[y + 1][x - 1].magnitude;
        } else if (normalizedAngle >= 67.5 && normalizedAngle < 112.5) {
          // 垂直方向
          neighbor1 = gradients[y - 1][x].magnitude;
          neighbor2 = gradients[y + 1][x].magnitude;
        } else {
          // 對角線方向 (\)
          neighbor1 = gradients[y - 1][x - 1].magnitude;
          neighbor2 = gradients[y + 1][x + 1].magnitude;
        }

        if (current.magnitude >= neighbor1 && current.magnitude >= neighbor2) {
          result[y][x] = current;
        }
      }
    }

    return result;
  }

  /// 雙閾值檢測
  static List<List<EdgeType>> _doubleThresholding(
    List<List<GradientData>> gradients,
    double lowThreshold,
    double highThreshold,
  ) {
    final height = gradients.length;
    final width = gradients[0].length;
    final result = List.generate(height, (i) => List.filled(width, EdgeType.none));

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final magnitude = gradients[y][x].magnitude;

        if (magnitude >= highThreshold) {
          result[y][x] = EdgeType.strong;
        } else if (magnitude >= lowThreshold) {
          result[y][x] = EdgeType.weak;
        }
      }
    }

    return result;
  }

  /// 邊緣追蹤
  static List<Offset> _edgeTracking(List<List<EdgeType>> edges) {
    final height = edges.length;
    final width = edges[0].length;
    final visited = List.generate(height, (i) => List.filled(width, false));
    final edgePoints = <Offset>[];

    // 從強邊緣開始追蹤
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (edges[y][x] == EdgeType.strong && !visited[y][x]) {
          _traceEdge(edges, visited, x, y, edgePoints);
        }
      }
    }

    return edgePoints;
  }

  /// 追蹤單條邊緣
  static void _traceEdge(
    List<List<EdgeType>> edges,
    List<List<bool>> visited,
    int x,
    int y,
    List<Offset> edgePoints,
  ) {
    final height = edges.length;
    final width = edges[0].length;
    final stack = <Point<int>>[];
    stack.add(Point(x, y));

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      final cx = current.x;
      final cy = current.y;

      if (cx < 0 || cx >= width || cy < 0 || cy >= height || visited[cy][cx]) {
        continue;
      }

      visited[cy][cx] = true;

      if (edges[cy][cx] != EdgeType.none) {
        edgePoints.add(Offset(cx.toDouble(), cy.toDouble()));

        // 檢查8鄰域
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;

            final nx = cx + dx;
            final ny = cy + dy;

            if (nx >= 0 && nx < width && ny >= 0 && ny < height &&
                !visited[ny][nx] && edges[ny][nx] != EdgeType.none) {
              stack.add(Point(nx, ny));
            }
          }
        }
      }
    }
  }

  /// 提取輪廓
  static List<List<Offset>> _extractContours(List<Offset> edgePoints) {
    if (edgePoints.isEmpty) return [];

    final contours = <List<Offset>>[];
    final used = <bool>[];
    used.addAll(List.filled(edgePoints.length, false));

    for (int i = 0; i < edgePoints.length; i++) {
      if (used[i]) continue;

      final contour = <Offset>[];
      _buildContour(edgePoints, used, i, contour);

      if (contour.length > 2) {
        contours.add(contour);
      }
    }

    return contours;
  }

  /// 構建單個輪廓
  static void _buildContour(
    List<Offset> edgePoints,
    List<bool> used,
    int startIndex,
    List<Offset> contour,
  ) {
    final visited = <int>{};
    final queue = <int>[];
    queue.add(startIndex);

    while (queue.isNotEmpty) {
      final index = queue.removeAt(0);

      if (visited.contains(index) || used[index]) continue;

      visited.add(index);
      used[index] = true;
      contour.add(edgePoints[index]);

      // 查找鄰近點
      final current = edgePoints[index];
      const maxDistance = 2.0;

      for (int i = 0; i < edgePoints.length; i++) {
        if (used[i] || visited.contains(i)) continue;

        final distance = (edgePoints[i] - current).distance;
        if (distance <= maxDistance) {
          queue.add(i);
        }
      }
    }
  }

  /// 計算檢測置信度
  static double _calculateConfidence(List<Offset> edgePoints, List<List<PixelData>> imageData) {
    if (edgePoints.isEmpty || imageData.isEmpty) return 0.0;

    final totalPixels = imageData.length * imageData[0].length;
    final edgeRatio = edgePoints.length / totalPixels;

    // 基於邊緣密度和分佈計算置信度
    return (edgeRatio * 100).clamp(0.0, 1.0);
  }
}

// ====================================================================
// 輔助數據類別
// ====================================================================

/// 梯度數據
class GradientData {
  final double magnitude;
  final double direction;
  final double phase;

  GradientData(this.magnitude, this.direction, this.phase);
}

/// 邊緣類型
enum EdgeType {
  none,   // 非邊緣
  weak,   // 弱邊緣
  strong  // 強邊緣
}

/// 點類別
class Point<T extends num> {
  final T x;
  final T y;

  Point(this.x, this.y);
}

// ====================================================================
// 容器檢測器 (Container Detector)
// ====================================================================

/// 容器檢測器 - 檢測圖像中的容器形狀和邊界
///
/// 功能：
/// - 形狀識別（矩形、圓形、多邊形等）
/// - 邊界檢測和輪廓提取
/// - 幾何特徵計算
/// - 容器分類和置信度評估
class ContainerDetector {
  /// 檢測容器
  static Future<ContainerDetectionResult?> detectContainer(
    EdgeDetectionResult edgeResult, {
    double minArea = 100.0,
    double maxArea = double.infinity,
    double minConfidence = 0.5,
  }) async {
    if (edgeResult.contours.isEmpty) return null;

    ContainerDetectionResult? bestResult;
    double bestScore = 0.0;

    for (final contour in edgeResult.contours) {
      if (contour.length < 3) continue;

      final result = await _analyzeContour(contour);
      if (result.area >= minArea &&
          result.area <= maxArea &&
          result.confidence >= minConfidence) {

        final score = _calculateContainerScore(result);
        if (score > bestScore) {
          bestScore = score;
          bestResult = result;
        }
      }
    }

    return bestResult;
  }

  /// 分析輪廓
  static Future<ContainerDetectionResult> _analyzeContour(List<Offset> contour) async {
    final area = _calculatePolygonArea(contour);
    final perimeter = _calculatePerimeter(contour);
    final boundingBox = _calculateBoundingBox(contour);
    final shape = _classifyShape(contour, area, perimeter);
    final confidence = _calculateShapeConfidence(contour, shape, area, perimeter);

    return ContainerDetectionResult(
      containerBounds: contour,
      shape: shape,
      area: area,
      perimeter: perimeter,
      boundingBox: boundingBox,
      confidence: confidence,
    );
  }

  /// 計算多邊形面積
  static double _calculatePolygonArea(List<Offset> points) {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].dx * points[j].dy;
      area -= points[j].dx * points[i].dy;
    }
    return area.abs() / 2.0;
  }

  /// 計算周長
  static double _calculatePerimeter(List<Offset> points) {
    if (points.length < 2) return 0.0;

    double perimeter = 0.0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      perimeter += (points[j] - points[i]).distance;
    }
    return perimeter;
  }

  /// 計算邊界框
  static Rect _calculateBoundingBox(List<Offset> points) {
    if (points.isEmpty) return Rect.zero;

    double minX = points[0].dx;
    double maxX = points[0].dx;
    double minY = points[0].dy;
    double maxY = points[0].dy;

    for (final point in points) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// 分類形狀
  static ContainerShape _classifyShape(List<Offset> contour, double area, double perimeter) {
    if (contour.length < 3) return ContainerShape.unknown;

    // 計算圓形度
    final circularity = 4 * math.pi * area / (perimeter * perimeter);

    if (circularity > 0.85) {
      return ContainerShape.circle;
    } else if (circularity > 0.65) {
      return ContainerShape.ellipse;
    } else if (contour.length <= 6) {
      // 檢查是否為矩形
      if (_isRectangular(contour)) {
        return ContainerShape.rectangle;
      }
    }

    return ContainerShape.polygon;
  }

  /// 檢查是否為矩形
  static bool _isRectangular(List<Offset> contour) {
    if (contour.length != 4) return false;

    // 計算角度
    final angles = <double>[];
    for (int i = 0; i < 4; i++) {
      final p1 = contour[i];
      final p2 = contour[(i + 1) % 4];
      final p3 = contour[(i + 2) % 4];

      final v1 = p1 - p2;
      final v2 = p3 - p2;

      final angle = math.acos((v1.dx * v2.dx + v1.dy * v2.dy) /
                             (v1.distance * v2.distance));
      angles.add(angle * 180 / math.pi);
    }

    // 檢查是否接近90度
    return angles.every((angle) => (angle - 90).abs() < 15);
  }

  /// 計算形狀置信度
  static double _calculateShapeConfidence(
    List<Offset> contour,
    ContainerShape shape,
    double area,
    double perimeter,
  ) {
    switch (shape) {
      case ContainerShape.circle:
        final circularity = 4 * math.pi * area / (perimeter * perimeter);
        return circularity.clamp(0.0, 1.0);

      case ContainerShape.rectangle:
        return _isRectangular(contour) ? 0.9 : 0.6;

      case ContainerShape.ellipse:
        final circularity = 4 * math.pi * area / (perimeter * perimeter);
        return (circularity * 1.2).clamp(0.0, 1.0);

      case ContainerShape.polygon:
        return 0.7;

      default:
        return 0.3;
    }
  }

  /// 計算容器評分
  static double _calculateContainerScore(ContainerDetectionResult result) {
    double score = result.confidence;

    // 面積獎勵
    if (result.area > 500) score += 0.1;
    if (result.area > 1000) score += 0.1;

    // 形狀獎勵
    switch (result.shape) {
      case ContainerShape.rectangle:
      case ContainerShape.circle:
        score += 0.2;
        break;
      case ContainerShape.ellipse:
        score += 0.1;
        break;
      default:
        break;
    }

    return score.clamp(0.0, 1.0);
  }
}

// ====================================================================
// 體積計算器 (Volume Calculator)
// ====================================================================

/// 體積計算器 - 基於容器檢測結果計算體積
///
/// 功能：
/// - 2D到3D投影
/// - 不同形狀的體積計算
/// - 深度估算
/// - 校準和比例轉換
class VolumeCalculator {
  /// 計算容器體積
  static Future<VolumeResult> calculateVolume(
    ContainerDetectionResult containerResult,
    double pixelsPerCm, {
    double estimatedDepthCm = 5.0,
    VolumeMethod method = VolumeMethod.geometric,
  }) async {
    switch (method) {
      case VolumeMethod.geometric:
        return _calculateGeometricVolume(containerResult, pixelsPerCm, estimatedDepthCm);

      case VolumeMethod.projection:
        return _calculateProjectionVolume(containerResult, pixelsPerCm, estimatedDepthCm);

      case VolumeMethod.integration:
        return _calculateIntegrationVolume(containerResult, pixelsPerCm, estimatedDepthCm);

      default:
        return VolumeResult(
          volumeMl: 0.0,
          volumeCm3: 0.0,
          confidence: 0.0,
          method: method,
        );
    }
  }

  /// 幾何體積計算
  static VolumeResult _calculateGeometricVolume(
    ContainerDetectionResult containerResult,
    double pixelsPerCm,
    double estimatedDepthCm,
  ) {
    final areaCm2 = containerResult.area / (pixelsPerCm * pixelsPerCm);
    double volumeCm3 = 0.0;
    double confidence = containerResult.confidence;

    switch (containerResult.shape) {
      case ContainerShape.rectangle:
        volumeCm3 = areaCm2 * estimatedDepthCm;
        confidence *= 0.9;
        break;

      case ContainerShape.circle:
        final radius = math.sqrt(areaCm2 / math.pi);
        volumeCm3 = math.pi * radius * radius * estimatedDepthCm;
        confidence *= 0.85;
        break;

      case ContainerShape.ellipse:
        volumeCm3 = areaCm2 * estimatedDepthCm * 0.8; // 橢圓修正係數
        confidence *= 0.75;
        break;

      case ContainerShape.polygon:
        volumeCm3 = areaCm2 * estimatedDepthCm * 0.7; // 多邊形修正係數
        confidence *= 0.7;
        break;

      default:
        volumeCm3 = areaCm2 * estimatedDepthCm * 0.5;
        confidence *= 0.5;
        break;
    }

    final volumeMl = volumeCm3; // 1 cm³ = 1 mL

    return VolumeResult(
      volumeMl: volumeMl,
      volumeCm3: volumeCm3,
      confidence: confidence,
      method: VolumeMethod.geometric,
    );
  }

  /// 投影體積計算
  static VolumeResult _calculateProjectionVolume(
    ContainerDetectionResult containerResult,
    double pixelsPerCm,
    double estimatedDepthCm,
  ) {
    // 使用輪廓投影估算體積
    final contour = containerResult.containerBounds;
    final areaCm2 = containerResult.area / (pixelsPerCm * pixelsPerCm);

    // 分析輪廓複雜度
    final complexity = _calculateContourComplexity(contour);
    final depthFactor = 1.0 - (complexity * 0.3); // 複雜度越高，深度係數越小

    final adjustedDepth = estimatedDepthCm * depthFactor;
    final volumeCm3 = areaCm2 * adjustedDepth;
    final volumeMl = volumeCm3;

    final confidence = containerResult.confidence * (1.0 - complexity * 0.2);

    return VolumeResult(
      volumeMl: volumeMl,
      volumeCm3: volumeCm3,
      confidence: confidence,
      method: VolumeMethod.projection,
    );
  }

  /// 積分體積計算
  static VolumeResult _calculateIntegrationVolume(
    ContainerDetectionResult containerResult,
    double pixelsPerCm,
    double estimatedDepthCm,
  ) {
    // 使用數值積分方法
    final contour = containerResult.containerBounds;
    final boundingBox = containerResult.boundingBox;

    double volumeCm3 = 0.0;
    const stepSize = 1.0; // 像素

    // 在邊界框內進行積分
    for (double x = boundingBox.left; x < boundingBox.right; x += stepSize) {
      for (double y = boundingBox.top; y < boundingBox.bottom; y += stepSize) {
        if (_isPointInPolygon(Offset(x, y), contour)) {
          final depthAtPoint = _estimateDepthAtPoint(Offset(x, y), contour, estimatedDepthCm);
          volumeCm3 += (stepSize * stepSize * depthAtPoint) / (pixelsPerCm * pixelsPerCm * pixelsPerCm);
        }
      }
    }

    final volumeMl = volumeCm3;
    final confidence = containerResult.confidence * 0.8; // 積分方法有一定誤差

    return VolumeResult(
      volumeMl: volumeMl,
      volumeCm3: volumeCm3,
      confidence: confidence,
      method: VolumeMethod.integration,
    );
  }

  /// 計算輪廓複雜度
  static double _calculateContourComplexity(List<Offset> contour) {
    if (contour.length < 3) return 1.0;

    // 基於角度變化計算複雜度
    double totalAngleChange = 0.0;

    for (int i = 0; i < contour.length; i++) {
      final p1 = contour[i];
      final p2 = contour[(i + 1) % contour.length];
      final p3 = contour[(i + 2) % contour.length];

      final v1 = p2 - p1;
      final v2 = p3 - p2;

      final angle1 = math.atan2(v1.dy, v1.dx);
      final angle2 = math.atan2(v2.dy, v2.dx);

      double angleChange = (angle2 - angle1).abs();
      if (angleChange > math.pi) angleChange = 2 * math.pi - angleChange;

      totalAngleChange += angleChange;
    }

    final normalizedComplexity = totalAngleChange / (2 * math.pi);
    return normalizedComplexity.clamp(0.0, 1.0);
  }

  /// 點是否在多邊形內
  static bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    bool inside = false;

    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].dx;
      final yi = polygon[i].dy;
      final xj = polygon[j].dx;
      final yj = polygon[j].dy;

      if (((yi > point.dy) != (yj > point.dy)) &&
          (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }

    return inside;
  }

  /// 估算點的深度
  static double _estimateDepthAtPoint(
    Offset point,
    List<Offset> contour,
    double maxDepth,
  ) {
    // 計算點到輪廓邊界的最短距離
    double minDistance = double.infinity;

    for (int i = 0; i < contour.length; i++) {
      final p1 = contour[i];
      final p2 = contour[(i + 1) % contour.length];
      final distance = _pointToLineDistance(point, p1, p2);
      minDistance = math.min(minDistance, distance);
    }

    // 使用距離來估算深度（越靠近中心深度越大）
    final normalizedDistance = minDistance / 100.0; // 假設最大距離為100像素
    final depthFactor = math.exp(-normalizedDistance * 2); // 指數衰減

    return maxDepth * depthFactor;
  }

  /// 點到線段的距離
  static double _pointToLineDistance(Offset point, Offset lineStart, Offset lineEnd) {
    final A = point.dx - lineStart.dx;
    final B = point.dy - lineStart.dy;
    final C = lineEnd.dx - lineStart.dx;
    final D = lineEnd.dy - lineStart.dy;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;

    if (lenSq == 0) return math.sqrt(A * A + B * B);

    final param = dot / lenSq;

    double xx, yy;
    if (param < 0) {
      xx = lineStart.dx;
      yy = lineStart.dy;
    } else if (param > 1) {
      xx = lineEnd.dx;
      yy = lineEnd.dy;
    } else {
      xx = lineStart.dx + param * C;
      yy = lineStart.dy + param * D;
    }

    final dx = point.dx - xx;
    final dy = point.dy - yy;
    return math.sqrt(dx * dx + dy * dy);
  }
}

// ====================================================================
// 體積計算相關數據類別
// ====================================================================

/// 體積計算結果
class VolumeResult {
  final double volumeMl;
  final double volumeCm3;
  final double confidence;
  final VolumeMethod method;
  final DateTime timestamp;

  VolumeResult({
    required this.volumeMl,
    required this.volumeCm3,
    required this.confidence,
    required this.method,
  }) : timestamp = DateTime.now();
}

/// 體積計算方法
enum VolumeMethod {
  geometric,   // 幾何計算
  projection,  // 投影計算
  integration  // 積分計算
}

// ====================================================================
// 圖像處理核心類 (Image Processor)
// ====================================================================

/// 圖像處理核心類 - 整合所有圖像處理功能
///
/// 功能：
/// - 統一的圖像處理接口
/// - 處理流程管理
/// - 結果整合和驗證
/// - 性能優化和緩存
class ImageProcessor {
  static const String version = '1.0.0';

  /// 完整的容器分析流程
  static Future<ContainerAnalysisResult> analyzeContainer(
    List<List<PixelData>> imageData, {
    double pixelsPerCm = 10.0,
    double estimatedDepthCm = 5.0,
    VolumeMethod volumeMethod = VolumeMethod.geometric,
    EdgeDetectionConfig? edgeConfig,
  }) async {
    try {
      // 1. 邊緣檢測
      final edgeConfig_ = edgeConfig ?? EdgeDetectionConfig();
      final edgeResult = await EdgeDetector.detectEdges(
        imageData,
        lowThreshold: edgeConfig_.lowThreshold,
        highThreshold: edgeConfig_.highThreshold,
        sigma: edgeConfig_.sigma,
      );

      if (edgeResult.edgePoints.isEmpty) {
        return ContainerAnalysisResult.empty();
      }

      // 2. 容器檢測
      final containerResult = await ContainerDetector.detectContainer(
        edgeResult,
        minArea: edgeConfig_.minArea,
        maxArea: edgeConfig_.maxArea,
        minConfidence: edgeConfig_.minConfidence,
      );

      if (containerResult == null) {
        return ContainerAnalysisResult.empty();
      }

      // 3. 體積計算
      final volumeResult = await VolumeCalculator.calculateVolume(
        containerResult,
        pixelsPerCm,
        estimatedDepthCm: estimatedDepthCm,
        method: volumeMethod,
      );

      // 4. 整合結果
      return ContainerAnalysisResult(
        edgeDetection: edgeResult,
        containerDetection: containerResult,
        volumeCalculation: volumeResult,
        overallConfidence: _calculateOverallConfidence(
          edgeResult.confidence,
          containerResult.confidence,
          volumeResult.confidence,
        ),
        processingTime: DateTime.now().difference(DateTime.now()),
      );

    } catch (e) {
      return ContainerAnalysisResult.empty();
    }
  }

  /// 計算總體置信度
  static double _calculateOverallConfidence(
    double edgeConfidence,
    double containerConfidence,
    double volumeConfidence,
  ) {
    // 加權平均
    final weights = [0.3, 0.5, 0.2]; // 邊緣檢測30%，容器檢測50%，體積計算20%
    final confidences = [edgeConfidence, containerConfidence, volumeConfidence];

    double weightedSum = 0.0;
    double totalWeight = 0.0;

    for (int i = 0; i < weights.length; i++) {
      weightedSum += confidences[i] * weights[i];
      totalWeight += weights[i];
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
  }

  /// 優化圖像數據
  static Future<List<List<PixelData>>> optimizeImageData(
    List<List<PixelData>> imageData,
  ) async {
    // 實施圖像優化算法
    // 例如：噪聲減少、對比度增強等
    return imageData; // 暫時返回原始數據
  }

  /// 驗證處理結果
  static bool validateResult(ContainerAnalysisResult result) {
    return result.overallConfidence > 0.3 &&
           result.volumeCalculation.volumeMl > 0 &&
           result.containerDetection.area > 0;
  }
}

// ====================================================================
// 配置和結果類別
// ====================================================================

/// 邊緣檢測配置
class EdgeDetectionConfig {
  final double lowThreshold;
  final double highThreshold;
  final double sigma;
  final double minArea;
  final double maxArea;
  final double minConfidence;

  EdgeDetectionConfig({
    this.lowThreshold = 50.0,
    this.highThreshold = 150.0,
    this.sigma = 1.4,
    this.minArea = 100.0,
    this.maxArea = double.infinity,
    this.minConfidence = 0.5,
  });
}

/// 容器分析完整結果
class ContainerAnalysisResult {
  final EdgeDetectionResult edgeDetection;
  final ContainerDetectionResult containerDetection;
  final VolumeResult volumeCalculation;
  final double overallConfidence;
  final Duration processingTime;

  ContainerAnalysisResult({
    required this.edgeDetection,
    required this.containerDetection,
    required this.volumeCalculation,
    required this.overallConfidence,
    required this.processingTime,
  });

  /// 創建空結果
  static ContainerAnalysisResult empty() {
    return ContainerAnalysisResult(
      edgeDetection: EdgeDetectionResult(
        edgePoints: [],
        contours: [],
        confidence: 0.0,
      ),
      containerDetection: ContainerDetectionResult(
        containerBounds: [],
        shape: ContainerShape.unknown,
        area: 0.0,
        perimeter: 0.0,
        boundingBox: Rect.zero,
        confidence: 0.0,
      ),
      volumeCalculation: VolumeResult(
        volumeMl: 0.0,
        volumeCm3: 0.0,
        confidence: 0.0,
        method: VolumeMethod.geometric,
      ),
      overallConfidence: 0.0,
      processingTime: Duration.zero,
    );
  }
}

// ----- [utils/image_processing.dart] 結束 -----