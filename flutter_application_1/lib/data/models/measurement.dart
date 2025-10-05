// ====================================================================
// 測量相關資料模型 (Measurement Data Models)
// ====================================================================
// 這個檔案包含所有測量功能需要的資料結構和選項

import 'package:flutter/material.dart';

/// 測量方法選項(有哪些測量方式可以選)
enum MeasurementMethod {
  automatic, // 自動計算容量
  referenceObject // 用參考物體來測量(像硬幣、卡片等)
}

/// 測量模式選項(要測量什麼)
enum MeasurementMode {
  calibration, // 校準模式 - 先畫出參考物體
  length, // 長度測量模式(測量直線距離)
  area, // 面積測量模式(測量平面大小)
  volume // 體積測量模式(測量立體空間大小)
}

/// 參考物體類型(可以用什麼東西當標準)
enum ReferenceObjectType {
  coin, // 硬幣
  card, // 信用卡或名片
  utensil, // 餐具(湯匙、筷子等)
  custom // 自己設定的物品
}

/// 參考物體資料(記錄參考物品的尺寸)
class ReferenceObject {
  final ReferenceObjectType type;
  final String name;
  final double width; // 寬度(單位:公分)
  final double height; // 高度(單位:公分)
  final String unit;

  const ReferenceObject({
    required this.type,
    required this.name,
    required this.width,
    required this.height,
    this.unit = 'cm',
  });
}

/// 測量點資料(記錄畫面上點擊的位置)
class MeasurementPoint {
  final Offset position;
  final int index;
  final DateTime timestamp;

  MeasurementPoint({
    required this.position,
    required this.index,
  }) : timestamp = DateTime.now();
}

/// 測量結果資料(記錄測量出來的數值)
class MeasurementResult {
  final MeasurementMode mode;
  final double value;
  final String unit;
  final List<MeasurementPoint> points;
  final double scale; // 螢幕像素對應到實際尺寸的比例(用來換算真實大小)

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
