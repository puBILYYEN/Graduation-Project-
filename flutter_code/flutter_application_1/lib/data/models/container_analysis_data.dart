import 'package:flutter/material.dart';

/// 容器分析數據模型
/// 從 main.dart 提取，保持完全相同的功能

/// RAG 系統的容器分析數據結構
class ContainerAnalysisData {
  final String imagePath; // 圖片路徑
  final String timestamp; // 時間戳
  final ContainerInfo container; // 容器信息
  final MeasurementResults measurements; // 測量結果
  final AnalysisMetadata metadata; // 分析元數據

  ContainerAnalysisData({
    required this.imagePath,
    required this.timestamp,
    required this.container,
    required this.measurements,
    required this.metadata,
  });

  /// 轉換為 JSON 格式，適合 RAG 系統使用
  Map<String, dynamic> toJson() {
    return {
      'image_path': imagePath,
      'timestamp': timestamp,
      'container': container.toJson(),
      'measurements': measurements.toJson(),
      'metadata': metadata.toJson(),
    };
  }
}

/// 容器信息
class ContainerInfo {
  final String shape; // 形狀（圓柱體、立方體等）
  final String material; // 材質（推測）
  final String color; // 顏色（主要顏色）
  final List<String> features; // 特徵描述

  ContainerInfo({
    required this.shape,
    required this.material,
    required this.color,
    required this.features,
  });

  Map<String, dynamic> toJson() {
    return {
      'shape': shape,
      'material': material,
      'color': color,
      'features': features,
    };
  }
}

/// 測量結果
class MeasurementResults {
  final double volume; // 容積 (cm³)
  final double confidence; // 信心度 (0.0-1.0)
  final String method; // 測量方法
  final Map<String, double>? dimensions; // 尺寸（長寬高等）

  MeasurementResults({
    required this.volume,
    required this.confidence,
    required this.method,
    this.dimensions,
  });

  Map<String, dynamic> toJson() {
    return {
      'volume_cm3': volume,
      'confidence': confidence,
      'method': method,
      'dimensions': dimensions,
    };
  }
}

/// 分析元數據
class AnalysisMetadata {
  final String deviceModel; // 設備型號
  final String appVersion; // 應用版本
  final double processingTime; // 處理時間（秒）
  final Map<String, dynamic> settings; // 相機設置

  AnalysisMetadata({
    required this.deviceModel,
    required this.appVersion,
    required this.processingTime,
    required this.settings,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_model': deviceModel,
      'app_version': appVersion,
      'processing_time_seconds': processingTime,
      'camera_settings': settings,
    };
  }
}

// ====================================================================
// 參考物體測量相關數據模型和枚舉
// ====================================================================

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
    required this.timestamp,
  });
}

/// 測量結果數據
class MeasurementResult {
  final double value;
  final String unit;
  final String type; // 'length', 'area', 'volume'
  final List<MeasurementPoint> points;
  final double confidence;

  MeasurementResult({
    required this.value,
    required this.unit,
    required this.type,
    required this.points,
    required this.confidence,
  });
}