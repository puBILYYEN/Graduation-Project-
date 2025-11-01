// ====================================================================
// 測量相關資料模型 - Measurement Models
// ====================================================================

import 'dart:ui';

/// 測量模式枚舉
enum MeasurementMode {
  calibration,    // 校準模式
  measurement,    // 測量模式
}

/// 測量點位置
class MeasurementPoint {
  final double x;
  final double y;

  const MeasurementPoint({
    required this.x,
    required this.y,
  });

  /// 轉換為 Offset 物件
  Offset toOffset() => Offset(x, y);

  /// 從 Offset 物件創建
  factory MeasurementPoint.fromOffset(Offset offset) {
    return MeasurementPoint(
      x: offset.dx,
      y: offset.dy,
    );
  }

  @override
  String toString() => 'MeasurementPoint(x: $x, y: $y)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeasurementPoint && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}

/// 測量結果
class MeasurementResult {
  final String id;
  final String type; // Added type
  final double width;
  final double height;
  final double volume;
  final String unit;
  final DateTime timestamp;
  final String? imagePath;
  final List<MeasurementPoint>? measurementPoints;

  const MeasurementResult({
    required this.id,
    required this.type, // Added type
    required this.width,
    required this.height,
    required this.volume,
    required this.unit,
    required this.timestamp,
    this.imagePath,
    this.measurementPoints,
  });

  /// 創建測量結果副本
  MeasurementResult copyWith({
    String? id,
    String? type,
    double? width,
    double? height,
    double? volume,
    String? unit,
    DateTime? timestamp,
    String? imagePath,
    List<MeasurementPoint>? measurementPoints,
  }) {
    return MeasurementResult(
      id: id ?? this.id,
      type: type ?? this.type,
      width: width ?? this.width,
      height: height ?? this.height,
      volume: volume ?? this.volume,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      measurementPoints: measurementPoints ?? this.measurementPoints,
    );
  }

  /// 轉換為 Map (用於序列化)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type, // Added type
      'width': width,
      'height': height,
      'volume': volume,
      'unit': unit,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'imagePath': imagePath,
      'measurementPoints': measurementPoints?.map((p) => {
        'x': p.x,
        'y': p.y,
      }).toList(),
    };
  }

  /// 從 Map 創建 (用於反序列化)
  factory MeasurementResult.fromMap(Map<String, dynamic> map) {
    return MeasurementResult(
      id: map['id'] ?? '',
      type: map['type'] as String? ?? 'unknown', // Made type optional with default
      width: (map['width'] ?? 0.0).toDouble(),
      height: (map['height'] ?? 0.0).toDouble(),
      volume: (map['volume'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'cm',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      imagePath: map['imagePath'],
      measurementPoints: (map['measurementPoints'] as List?)?.map((p) =>
        MeasurementPoint(x: p['x'].toDouble(), y: p['y'].toDouble())
      ).toList(),
    );
  }

  @override
  String toString() {
    return 'MeasurementResult(id: $id, width: $width, height: $height, volume: $volume, unit: $unit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeasurementResult && other.id == id;
  }

  String get description {
    switch (type) {
      case 'length':
        return '長度: ${width.toStringAsFixed(2)} $unit';
      case 'area':
        return '面積: ${width.toStringAsFixed(2)} $unit²'; // Assuming width is area here
      case 'volume':
        return '體積: ${volume.toStringAsFixed(2)} $unit³';
      default:
        return '測量結果: ${width.toStringAsFixed(2)} $unit';
    }
  }

  @override
  int get hashCode => id.hashCode;
}