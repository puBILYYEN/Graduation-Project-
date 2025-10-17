import 'package:flutter/material.dart';

/// 測量方法枚舉
enum MeasurementMethod {
  automatic, // 現有的自動容積計算
  referenceObject // 參考物體測量方式
}

/// 測量模式枚舉
enum MeasurementMode {
  calibration, // 校準模式 - 繪製參考物體
  length, // 長度測量模式
  area, // 面積測量模式 (多邊形)
  volume // 體積測量模式
}

/// 參考物體類型
enum ReferenceObjectType {
  coin, // 硬幣
  card, // 信用卡/名片
  utensil, // 餐具
  custom // 自定義
}

/// 參考物體數據
class ReferenceObject {
  final ReferenceObjectType type;
  final String name;
  final double width; // 寬度 (cm)
  final double height; // 高度 (cm)
  final String unit;

  const ReferenceObject({
    required this.type,
    required this.name,
    required this.width,
    required this.height,
    this.unit = 'cm',
  });
}

/// 測量點數據
class MeasurementPoint {
  final Offset position;
  final int index;
  final DateTime timestamp;

  MeasurementPoint({
    required this.position,
    required this.index,
  }) : timestamp = DateTime.now();
}

/// 測量結果數據
class MeasurementResult {
  final MeasurementMode mode;
  final double value;
  final String unit;
  final List<MeasurementPoint> points;
  final double scale; // 像素到現實世界的比例

  MeasurementResult({
    required this.mode,
    required this.value,
    required this.unit,
    required this.points,
    required this.scale,
  });

  String get description {
    switch (mode) {
      case MeasurementMode.length:
        return '長度: ${value.toStringAsFixed(2)} $unit';
      case MeasurementMode.area:
        return '面積: ${value.toStringAsFixed(2)} $unit²';
      case MeasurementMode.volume:
        return '體積: ${value.toStringAsFixed(2)} $unit³';
      case MeasurementMode.calibration:
        return '校準比例: ${scale.toStringAsFixed(4)} px/$unit';
    }
  }
}