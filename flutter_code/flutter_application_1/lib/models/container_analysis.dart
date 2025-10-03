// ===== 【數據模型模組】開始 -----
import 'package:flutter/material.dart';

// ====================================================================
// RAG 系統數據結構
// ====================================================================
/*
模組化建議：【數據模型模組 - models/container_analysis.dart】
以下類別可以獨立成為數據模型模組：
- ContainerAnalysisData: 容器分析數據結構
- ContainerInfo: 容器信息類別
- MeasurementResults: 測量結果類別
- AnalysisMetadata: 分析元數據類別
- ReferenceObject: 參考物件類別
- MeasurementPoint: 測量點類別
- MeasurementResult: 測量結果類別

這些類別專責數據結構定義，無UI依賴，適合獨立模組。
*/

/// RAG 系統的容器分析數據結構
class ContainerAnalysisData {
  final String imagePath; // 圖片路徑
  final String timestamp; // 時間戳
  final ContainerInfo container; // 容器信息
  final MeasurementResults measurements; // 測量結果
  final AnalysisMetadata metadata; // 分析元數據

  ContainerAnalysisData({
    // ⚠️ 以下每行包含3個獨立的Dart語法元素：
    // 1. { } = Named Parameters（具名參數）官方語法，來源：dart.dev/language/functions
    // 2. required = 必填關鍵字，使具名參數變為必填，來源：dart.dev/language/functions
    // 3. this.參數名 = Initializing Formal Parameters，自動賦值給實例變數，來源：dart.dev/language/constructors

    required this.imagePath, // required（必填）+ this.imagePath（自動賦值給imagePath實例變數）
    required this.timestamp, // required（必填）+ this.timestamp（自動賦值給timestamp實例變數）
    required this.container, // required（必填）+ this.container（自動賦值給container實例變數）
    required this.measurements, // required（必填）+ this.measurements（自動賦值給measurements實例變數）
    required this.metadata, // required（必填）+ this.metadata（自動賦值給metadata實例變數）
  });

  /// 轉換為 JSON 格式，適合 RAG 系統使用
  Map<String, dynamic> toJson() {
    // 將容器分析數據轉換為JSON格式的自定義方法：用於數據序列化和RAG系統整合
    // 返回值：Map<String, dynamic> 包含所有容器分析資料的JSON映射表
    return {
      'imagePath': imagePath, // 將圖片路徑字串加入JSON，鍵名為'image_path'
      'timestamp': timestamp, // 將時間戳記字串加入JSON，鍵名為'timestamp'
      'container': container.toJson(), // 呼叫容器物件的toJson()方法，將容器資訊轉為JSON子物件
      'measurements':
          measurements.toJson(), // 呼叫測量結果物件的toJson()方法，將測量數據轉為JSON子物件
      'metadata': metadata.toJson(), // 呼叫分析元數據物件的toJson()方法，將元數據轉為JSON子物件
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
    // ⚠️ 每個參數包含2個獨立的Dart官方語法元素：
    // 1. required = 必填關鍵字（dart.dev/language/functions）
    // 2. this.參數名 = Initializing Formal Parameters（dart.dev/language/constructors）

    required this.shape, // required（必填）+ this.shape（自動賦值給shape實例變數）
    required this.material, // required（必填）+ this.material（自動賦值給material實例變數）
    required this.color, // required（必填）+ this.color（自動賦值給color實例變數）
    required this.features, // required（必填）+ this.features（自動賦值給features實例變數）
  });

  Map<String, dynamic> toJson() {
    // 將容器資訊轉換為JSON格式的自定義方法：序列化容器的物理屬性數據
    // 返回值：Map<String, dynamic> 包含容器形狀、材質、顏色、特徵的JSON映射表
    return {
      'shape': shape, // 將容器形狀字串加入JSON，如'圓柱體'、'立方體'等
      'material': material, // 將材質推測字串加入JSON，如'塑膠'、'金屬'等
      'color': color, // 將主要顏色字串加入JSON，如'白色'、'透明'等
      'features': features, // 將特徵描述字串列表加入JSON，如['有蓋子', '透明', '圓形底部']
    };
  }
}

/// 測量結果
class MeasurementResults {
  final double volume; // 容積 (cm³)
  final double confidence; // 信心度 (0.0-1.0)
  final String method; // 測量方法
  final Map<String, double> dimensions; // 尺寸（長寬高等）

  MeasurementResults({
    required this.volume,
    required this.confidence,
    required this.method,
    required this.dimensions,
  });

  Map<String, dynamic> toJson() {
    return {
      'volume': volume,
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
      'deviceModel': deviceModel,
      'appVersion': appVersion,
      'processingTime': processingTime,
      'settings': settings,
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

// ====================================================================
// 營養數據模型
// ====================================================================

/// 營養素數據類別 - 儲存營養素的名稱、百分比和顯示顏色
class NutrientData {
  final String name; // 營養素名稱（如：蛋白質、碳水化合物、脂肪等）
  final double percentage; // 營養素所佔的百分比（0.0-100.0）
  final Color color; // 在圖表中顯示的顏色

  // 構造函數 - 使用位置參數的簡潔形式初始化營養素數據
  NutrientData(this.name, this.percentage, this.color);
}

/// 飲食記錄數據類別 - 儲存單一飲食記錄的完整資訊
class FoodEntry {
  final String name; // 食物英文名稱
  final String chineseName; // 食物中文名稱
  final String mealType; // 餐點類型（如：早餐、午餐、晚餐、點心）
  final int calories; // 熱量（大卡/kcal）
  final List<String> imageUrls; // 食物圖片 URL 列表，支援多張圖片展示
  final String servingInfo; // 份量資訊（如："150g"、"1杯"、"1份"）

  // 構造函數 - 初始化飲食記錄的所有屬性，所有參數都是必需的
  FoodEntry({
    required this.name, // 必填：食物英文名稱
    required this.chineseName, // 必填：食物中文名稱
    required this.mealType, // 必填：餐點類型
    required this.calories, // 必填：熱量值
    required this.imageUrls, // 必填：圖片 URL 列表（可為空列表）
    required this.servingInfo, // 必填：份量資訊
  });
}

// ===== 【數據模型模組】結束 =====