import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:math' as math;
import 'dart:io';

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

    required this.imagePath,    // required（必填）+ this.imagePath（自動賦值給imagePath實例變數）
    required this.timestamp,    // required（必填）+ this.timestamp（自動賦值給timestamp實例變數）
    required this.container,    // required（必填）+ this.container（自動賦值給container實例變數）
    required this.measurements, // required（必填）+ this.measurements（自動賦值給measurements實例變數）
    required this.metadata,     // required（必填）+ this.metadata（自動賦值給metadata實例變數）
  });

  /// 轉換為 JSON 格式，適合 RAG 系統使用
  Map<String, dynamic> toJson() {
    // 將容器分析數據轉換為JSON格式的自定義方法：用於數據序列化和RAG系統整合
    // 返回值：Map<String, dynamic> 包含所有容器分析資料的JSON映射表
    return {
      'image_path': imagePath,               // 將圖片路徑字串加入JSON，鍵名為'image_path'
      'timestamp': timestamp,                // 將時間戳記字串加入JSON，鍵名為'timestamp'
      'container': container.toJson(),       // 呼叫容器物件的toJson()方法，將容器資訊轉為JSON子物件
      'measurements': measurements.toJson(), // 呼叫測量結果物件的toJson()方法，將測量數據轉為JSON子物件
      'metadata': metadata.toJson(),         // 呼叫分析元數據物件的toJson()方法，將元數據轉為JSON子物件
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

    required this.shape,    // required（必填）+ this.shape（自動賦值給shape實例變數）
    required this.material, // required（必填）+ this.material（自動賦值給material實例變數）
    required this.color,    // required（必填）+ this.color（自動賦值給color實例變數）
    required this.features, // required（必填）+ this.features（自動賦值給features實例變數）
  });

  Map<String, dynamic> toJson() {
    // 將容器資訊轉換為JSON格式的自定義方法：序列化容器的物理屬性數據
    // 返回值：Map<String, dynamic> 包含容器形狀、材質、顏色、特徵的JSON映射表
    return {
      'shape': shape,         // 將容器形狀字串加入JSON，如'圓柱體'、'立方體'等
      'material': material,   // 將材質推測字串加入JSON，如'塑膠'、'金屬'等
      'color': color,         // 將主要顏色字串加入JSON，如'白色'、'透明'等
      'features': features,   // 將特徵描述字串列表加入JSON，如['有蓋子', '透明', '圓形底部']
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
    // ⚠️ 混合用法：同時有必填和可選的具名參數
    // 語法元素說明：
    // 1. { } = Named Parameters（具名參數）
    // 2. required = 必填關鍵字（可選，不加則為可選參數）
    // 3. this.參數名 = Initializing Formal Parameters（自動賦值）

    required this.volume,     // required（必填）+ this.volume（自動賦值）
    required this.confidence, // required（必填）+ this.confidence（自動賦值）
    required this.method,     // required（必填）+ this.method（自動賦值）
    this.dimensions,          // 只有 this.dimensions（自動賦值），沒有required所以為可選參數
  });

  Map<String, dynamic> toJson() {
    // 將測量結果轉換為JSON格式的自定義方法：序列化容積測量的數值和元數據
    // 返回值：Map<String, dynamic> 包含容積、信心度、方法、尺寸的JSON映射表
    return {
      'volume_cm3': volume,       // 將容積數值(立方公分)加入JSON，鍵名明確標示單位
      'confidence': confidence,   // 將測量信心度(0.0-1.0)加入JSON，表示結果可靠程度
      'method': method,           // 將測量方法字串加入JSON，如'自動檢測'、'參考物體'等
      'dimensions': dimensions,   // 將尺寸映射表加入JSON，可能為null，包含長寬高等數據
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
    // ⚠️ 每個參數包含2個獨立的Dart官方語法元素：
    // 1. required = 必填關鍵字
    // 2. this.參數名 = Initializing Formal Parameters（自動賦值）

    required this.deviceModel,    // required（必填）+ this.deviceModel（自動賦值）
    required this.appVersion,     // required（必填）+ this.appVersion（自動賦值）
    required this.processingTime, // required（必填）+ this.processingTime（自動賦值）
    required this.settings,       // required（必填）+ this.settings（自動賦值）
  });

  Map<String, dynamic> toJson() {
    // 將分析元數據轉換為JSON格式的自定義方法：序列化設備和處理過程的技術資訊
    // 返回值：Map<String, dynamic> 包含設備型號、應用版本、處理時間、相機設定的JSON映射表
    return {
      'device_model': deviceModel,              // 將設備型號字串加入JSON，如'iPhone 14'、'Samsung Galaxy'等
      'app_version': appVersion,                // 將應用程式版本字串加入JSON，如'1.0.0'、'2.1.3'等
      'processing_time_seconds': processingTime, // 將處理時間(秒)加入JSON，記錄分析所需的時間
      'camera_settings': settings,              // 將相機設定映射表加入JSON，包含解析度、對焦模式等參數
    };
  }
}

// ====================================================================
// ----- [models/container_analysis.dart] 結束 -----

// ----- [models/measurement.dart] 開始 -----
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
    // ⚠️ 此建構函數展示了3種不同的參數語法：
    // 1. required this.參數名 = 必填 + 自動賦值
    // 2. this.參數名 = 預設值 = 可選 + 自動賦值 + 預設值

    required this.type,   // required（必填）+ this.type（自動賦值）
    required this.name,   // required（必填）+ this.name（自動賦值）
    required this.width,  // required（必填）+ this.width（自動賦值）
    required this.height, // required（必填）+ this.height（自動賦值）
    this.unit = 'cm',     // this.unit（自動賦值）+ = 'cm'（預設值），沒有required所以為可選
  });
}

/// 測量點數據
class MeasurementPoint {
  final Offset position;
  final int index;
  final DateTime timestamp;

  MeasurementPoint({
    // ⚠️ 建構函數參數部分包含3個獨立語法元素：
    // 1. { } = Named Parameters（具名參數）
    // 2. required = 必填關鍵字
    // 3. this.參數名 = Initializing Formal Parameters（自動賦值）

    required this.position, // required（必填）+ this.position（自動賦值給position實例變數）
    required this.index,    // required（必填）+ this.index（自動賦值給index實例變數）
  }) : timestamp = DateTime.now(); // ⚠️ 這是第4個獨立語法元素：
  // : timestamp = DateTime.now() = Initializer List（初始化列表）
  // 作用：在建構函數體執行前初始化timestamp變數（來源：dart.dev/language/constructors）
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
    // Getter 方法（Dart官方語法）：使用 get 關鍵字定義計算屬性
    // 來源：dart.dev/language/methods （Getters and setters）
    // 功能：根據測量模式動態生成格式化的測量結果描述
    switch (mode) { // 根據測量模式返回不同格式的描述文字
      case MeasurementMode.length:
        return '長度: ${value.toStringAsFixed(2)} $unit';          // 長度測量結果格式
      case MeasurementMode.area:
        return '面積: ${value.toStringAsFixed(2)} $unit²';         // 面積測量結果格式，添加平方符號
      case MeasurementMode.volume:
        return '體積: ${value.toStringAsFixed(2)} $unit³';         // 體積測量結果格式，添加立方符號
      case MeasurementMode.calibration:
        return '校準比例: ${scale.toStringAsFixed(4)} px/$unit';   // 校準比例格式，顯示像素比例
    }
  }
}
// ----- [models/measurement.dart] 結束 -----

// ===== 【服務模組】開始 =====
// ====================================================================
// 參考物體數據庫和服務
// ====================================================================
/*
模組化建議：【服務模組 - services/】
以下類別可以拆分為獨立的服務模組：

1. services/reference_database.dart
   - ReferenceObjectDatabase: 參考物件數據庫服務

2. services/measurement_calculator.dart
   - MeasurementCalculator: 測量計算服務

3. services/log_manager.dart
   - LogManager: 日誌管理服務

這些服務類別負責業務邏輯處理，獨立性強，適合模組化。
*/

// ----- [services/reference_database.dart] 開始 -----
/// 參考物體數據庫
class ReferenceObjectDatabase {
  // 常見硬幣尺寸 (台灣)
  static const Map<String, ReferenceObject> coins = {
    'NT_50': ReferenceObject(
      type: ReferenceObjectType.coin,
      name: '50元硬幣',
      width: 2.5,
      height: 2.5,
    ),
    'NT_10': ReferenceObject(
      type: ReferenceObjectType.coin,
      name: '10元硬幣',
      width: 2.6,
      height: 2.6,
    ),
    'NT_5': ReferenceObject(
      type: ReferenceObjectType.coin,
      name: '5元硬幣',
      width: 2.2,
      height: 2.2,
    ),
    'NT_1': ReferenceObject(
      type: ReferenceObjectType.coin,
      name: '1元硬幣',
      width: 2.0,
      height: 2.0,
    ),
  };

  // 常見卡片尺寸
  static const Map<String, ReferenceObject> cards = {
    'CREDIT_CARD': ReferenceObject(
      type: ReferenceObjectType.card,
      name: '信用卡',
      width: 8.56,
      height: 5.398,
    ),
    'BUSINESS_CARD': ReferenceObject(
      type: ReferenceObjectType.card,
      name: '名片',
      width: 9.0,
      height: 5.4,
    ),
  };

  // 常見餐具尺寸
  static const Map<String, ReferenceObject> utensils = {
    'SPOON': ReferenceObject(
      type: ReferenceObjectType.utensil,
      name: '湯匙',
      width: 2.0,
      height: 18.0,
    ),
    'FORK': ReferenceObject(
      type: ReferenceObjectType.utensil,
      name: '叉子',
      width: 2.5,
      height: 18.0,
    ),
    'CHOPSTICKS': ReferenceObject(
      type: ReferenceObjectType.utensil,
      name: '筷子',
      width: 0.8,
      height: 23.0,
    ),
  };

  /// 取得所有參考物體
  static List<ReferenceObject> getAllObjects() {
    // 取得所有參考物體的靜態方法：將所有類別的參考物體合併為單一列表
    // 返回值：List<ReferenceObject> 包含硬幣、卡片、餐具等所有參考物體的完整列表
    return [
      ...coins.values,    // 展開硬幣映射表中的所有值，將硬幣物件加入列表
      ...cards.values,    // 展開卡片映射表中的所有值，將卡片物件加入列表
      ...utensils.values, // 展開餐具映射表中的所有值，將餐具物件加入列表
    ];
  }

  /// 根據類型取得參考物體
  static List<ReferenceObject> getObjectsByType(ReferenceObjectType type) {
    // 根據指定類型篩選參考物體的靜態方法：從資料庫中取得特定類別的物體
    // 參數type：ReferenceObjectType枚舉，指定要篩選的物體類型
    // 返回值：List<ReferenceObject> 符合指定類型的參考物體列表
    switch (type) { // 使用switch語句根據類型進行分流處理
      case ReferenceObjectType.coin:    // 當類型為硬幣時
        return coins.values.toList();   // 將硬幣映射表的所有值轉換為列表並返回
      case ReferenceObjectType.card:    // 當類型為卡片時
        return cards.values.toList();   // 將卡片映射表的所有值轉換為列表並返回
      case ReferenceObjectType.utensil: // 當類型為餐具時
        return utensils.values.toList(); // 將餐具映射表的所有值轉換為列表並返回
      case ReferenceObjectType.custom:  // 當類型為自定義時
        return [];                      // 返回空列表，表示目前無自定義參考物體
    }
  }
}
// ----- [services/reference_database.dart] 結束 -----

// ----- [services/measurement_calculator.dart] 開始 -----
/// 測量計算服務
class MeasurementCalculator {
  /// 計算兩點之間的距離 (像素)
  static double calculatePixelDistance(Offset point1, Offset point2) {
    // 計算兩個二維座標點之間歐氏距離的靜態方法：使用畢達哥拉斯定理
    // 參數point1：第一個座標點的Offset物件，包含x(dx)和y(dy)座標
    // 參數point2：第二個座標點的Offset物件，包含x(dx)和y(dy)座標
    // 返回值：double型別的像素距離值
    return math.sqrt(math.pow(point2.dx - point1.dx, 2) + // 計算X軸差值的平方
        math.pow(point2.dy - point1.dy, 2));              // 計算Y軸差值的平方，然後開平方根得到距離
  }

  /// 計算比例 (像素/厘米)
  static double calculateScale(
      Offset startPoint, Offset endPoint, double realWorldSize) {
    // 計算像素到實際尺寸比例的靜態方法：建立圖像與現實世界的尺度對應關係
    // 參數startPoint：參考物體起始點的Offset座標
    // 參數endPoint：參考物體結束點的Offset座標
    // 參數realWorldSize：參考物體在現實世界中的實際尺寸(公分)
    // 返回值：double型別的比例係數(像素/公分)，用於後續真實尺寸計算
    double pixelDistance = calculatePixelDistance(startPoint, endPoint); // 計算參考物體在圖像中的像素距離
    return pixelDistance / realWorldSize; // 像素距離除以實際尺寸得到比例係數
  }

  /// 計算真實世界距離
  static double calculateRealDistance(
      Offset point1, Offset point2, double scale) {
    // 將像素距離轉換為真實世界距離的靜態方法：使用已知比例係數進行單位轉換
    // 參數point1：要測量的第一個座標點
    // 參數point2：要測量的第二個座標點
    // 參數scale：像素與實際尺寸的比例係數(像素/公分)
    // 返回值：double型別的真實世界距離(公分)
    double pixelDistance = calculatePixelDistance(point1, point2); // 先計算兩點之間的像素距離
    return pixelDistance / scale; // 像素距離除以比例係數得到真實世界距離
  }

  /// 計算多邊形面積 (使用鞋帶公式)
  static double calculatePolygonArea(List<Offset> points, double scale) {
    // 使用鞋帶公式計算多邊形面積的靜態方法：適用於任意形狀的多邊形面積計算
    // 參數points：構成多邊形的頂點座標列表，按順序排列
    // 參數scale：像素與實際尺寸的比例係數(像素/公分)
    // 返回值：double型別的真實世界面積(平方公分)
    if (points.length < 3) return 0.0; // 少於3個點無法構成多邊形，返回0

    double area = 0.0; // 初始化面積累加器
    int n = points.length; // 取得頂點數量

    // 實作鞋帶公式 (Shoelace formula)：Σ(xi*yi+1 - xi+1*yi)
    for (int i = 0; i < n; i++) { // 遍歷所有頂點
      int j = (i + 1) % n;        // 下一個頂點的索引，使用模運算處理最後一個點回到第一個點
      area += points[i].dx * points[j].dy; // 加上當前點x座標乘以下一點y座標
      area -= points[j].dx * points[i].dy; // 減去下一點x座標乘以當前點y座標
    }

    area = area.abs() / 2.0; // 取絕對值並除以2得到像素面積
    // 轉換為真實世界面積：像素面積除以比例係數的平方
    return area / (scale * scale); // 因為面積是二維的，所以比例係數需要平方
  }

  /// 估算體積 (假設為圓柱體或長方體)
  static double estimateVolume(List<Offset> points, double scale,
      {double estimatedHeight = 2.0} // 預設高度 2cm
      ) {
    // 基於底面積估算容器體積的靜態方法：假設容器為規則立體形狀
    // 參數points：構成底面形狀的頂點座標列表
    // 參數scale：像素與實際尺寸的比例係數(像素/公分)
    // 參數estimatedHeight：估算的容器高度(公分)，預設值為2.0公分
    // 返回值：double型別的估算體積(立方公分)
    double area = calculatePolygonArea(points, scale); // 先計算底面積(平方公分)
    return area * estimatedHeight; // 底面積乘以高度得到體積(立方公分)
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

// ----- [services/log_manager.dart] 開始 -----
// 日誌管理器類別 - 採用單例模式管理應用程式的日誌記錄
class LogManager {
  static LogManager? _instance; // 私有静態變數儲存單例實體
  static LogManager get instance =>
      _instance ??= LogManager._(); // 單例取得器，使用空合併運算符確保只有一個實體
  LogManager._(); // 私有構造函數，防止外部直接實例化

  File? _logFile; // 日誌檔案物件引用

  // 初始化日誌文件 - 建立日誌檔案的存放位置和設定
  Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory(); // 取得應用程式文件目錄
      final logPath =
          path.join(directory.path, 'app_log.log'); // 組合檔案路徑，建立日誌檔案路徑
      _logFile = File(logPath); // 建立檔案物件

      // 如果文件不存在則創建 - 確保日誌檔案存在
      if (!await _logFile!.exists()) {
        await _logFile!.create(); // 非同步建立檔案
      }

      // 在應用啟動時記錄 - 記錄應用程式啟動時間點
      await writeLog('=== 應用啟動 ===');
    } catch (e) {
      print('日誌管理器初始化失敗: $e'); // 印出初始化錯誤訊息
    }
  }

  // 寫入日誌 - 將訊息記錄到日誌檔案並同時輸出到控制台
  Future<void> writeLog(String message) async {
    try {
      final timestamp = DateTime.now().toString(); // 取得目前時間戳
      final logEntry = '[$timestamp] $message\n'; // 格式化日誌項目，包含時間戳和訊息

      // 同時輸出到控制台 - 便於除錯和即時監控
      print(message);

      // 寫入到文件 - 持久化儲存日誌資料
      if (_logFile != null) {
        await _logFile!
            .writeAsString(logEntry, mode: FileMode.append); // 使用附加模式不覆蓋既有內容
      }
    } catch (e) {
      print('寫入日誌失敗: $e'); // 印出錯誤訊息，防止無窮遞迴
    }
  }

  // 獲取日誌文件路徑 - 提供日誌檔案的完整路徑供外部存取
  String? get logFilePath => _logFile?.path; // 使用安全導航運算符避免空指針錯誤
}

// 全局日誌函數 - 提供簡潔的日誌記錄接口
Future<void> log(String message) async {
  // 異步日誌記錄函數：將訊息透過LogManager單例寫入日誌檔案
  // 參數message：要記錄的日誌訊息內容
  // 返回值：Future<void>，表示異步操作完成
  await LogManager.instance.writeLog(message); // 調用單例的寫入日誌方法：透過LogManager的instance單例實體調用writeLog方法執行實際的檔案寫入操作
}
