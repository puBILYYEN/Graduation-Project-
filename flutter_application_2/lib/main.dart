// ====================================================================
// 匯入和應用程式入口點
// ====================================================================
/*
模組化重構建議：
此檔案目前包含多個功能模組，建議拆分為以下獨立模組：

1. 數據模型模組 (models/)
   - ContainerAnalysisData, ContainerInfo, MeasurementResults 等數據類別

2. 服務模組 (services/)
   - ReferenceObjectDatabase (參考物件數據庫服務)
   - MeasurementCalculator (測量計算服務)
   - LogManager (日誌管理服務)

3. UI頁面模組 (pages/)
   - LoginPage (登入頁面)
   - RegisterPage (註冊頁面)
   - HomePageContent (首頁內容)
   - BodyAnalysisPageContent (身體分析頁面)
   - FoodDiaryPageContent (飲食日記頁面)
   - CameraScreen (相機螢幕)
   - NutritionDetailPage (營養詳情頁面)

4. 工具類模組 (utils/)
   - ImageProcessingResult (圖像處理結果)
   - CustomPainters (自定義繪製器)

5. 配置模組 (config/)
   - 應用程式配置和常數

拆分後的好處：
- 提高代碼可維護性
- 便於團隊協作開發
- 降低代碼耦合度
- 提升代碼復用性
- 便於單元測試
*/
import 'package:flutter/material.dart'; // Flutter Material Design 元件庫
import 'package:flutter/cupertino.dart'; // Flutter iOS 風格 Cupertino 元件庫
import 'package:flutter/services.dart'; // Flutter 系統服務（如螢幕方向控制）
import 'package:camera/camera.dart'; // 相機功能套件
import 'package:path_provider/path_provider.dart'; // 檔案路徑提供者套件
import 'package:path/path.dart' as path; // 路徑操作工具套件
import 'package:image_picker/image_picker.dart'; // 圖片選擇器套件
import 'package:permission_handler/permission_handler.dart'; // 權限處理套件
import 'package:sensors_plus/sensors_plus.dart'; // 感測器套件（加速度計等）
import 'package:google_sign_in/google_sign_in.dart'; // Google 登入套件
import 'package:image_gallery_saver/image_gallery_saver.dart'; // 照片保存套件
import 'dart:math' as math; // Dart 數學函式庫
import 'dart:async'; // Dart 異步程式設計套件
import 'dart:io'; // Dart 檔案輸入輸出套件
import 'dart:typed_data'; // Dart 型別化數據套件
import 'dart:convert'; // JSON 編碼解碼
import 'package:http/http.dart' as http; // HTTP 客戶端
import 'package:firebase_core/firebase_core.dart'; // Firebase 核心
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 資料庫
import 'package:firebase_storage/firebase_storage.dart'; // Firebase 儲存

// ===== 【數據模型模組】開始 =====
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

// ----- [models/container_analysis.dart] 開始 -----
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
// ----- [models/measurement.dart] 結束 -----

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
    return [
      ...coins.values,
      ...cards.values,
      ...utensils.values,
    ];
  }

  /// 根據類型取得參考物體
  static List<ReferenceObject> getObjectsByType(ReferenceObjectType type) {
    switch (type) {
      case ReferenceObjectType.coin:
        return coins.values.toList();
      case ReferenceObjectType.card:
        return cards.values.toList();
      case ReferenceObjectType.utensil:
        return utensils.values.toList();
      case ReferenceObjectType.custom:
        return [];
    }
  }
}
// ----- [services/reference_database.dart] 結束 -----

// ----- [services/measurement_calculator.dart] 開始 -----
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
  await LogManager.instance.writeLog(message); // 調用單例的寫入日誌方法
}

// 同步日誌函數 - 用於 build 方法等不允許異步操作的同步上下文
void logSync(String message) {
  // 只輸出到控制台，不寫入文件以避免同步環境中的異步問題
  print(message);
  // 異步寫入文件，但不等待完成 - 避免阻塞 UI 繪製
  LogManager.instance.writeLog(message);
}
// ----- [services/log_manager.dart] 結束 -----

// ----- [main函數和應用程式入口] 開始 -----
// 應用程式主要入口函數 - 程式執行的起始點
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 確保 Flutter 綁定已初始化，必須在使用異步操作前調用

  // 初始化日誌管理器 - 設定應用程式的日誌記錄系統
  await LogManager.instance.initialize();

  // 設定螢幕方向 - 允許所有螢幕方向（拍照頁面會單獨控制）
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // 允許正常豎螢幕
    DeviceOrientation.portraitDown, // 允許倒置豎螢幕
    DeviceOrientation.landscapeLeft, // 允許左橫螢幕
    DeviceOrientation.landscapeRight, // 允許右橫螢幕
  ]);

  runApp(const MyApp()); // 啟動 Flutter 應用程式
}
// ----- [main函數和應用程式入口] 結束 -----

// ===== 【服務模組】結束 =====

// ===== 【主應用程式框架】開始 =====
// ====================================================================
// 統一導航框架
// ====================================================================

// 主要頁面枚舉 - 定義應用程式中可切換的主要頁面（不包含相機頁面）
enum AppPage {
  home, // 首頁 - 索引 0，顯示營養資訊和 AI 建議
  foodDiary, // 飲食記錄 - 索引 1，管理日常飲食記錄
  exercise, // 運動 - 索引 3（跳過相機的索引 2），運動記錄功能
  analysis, // 身體分析 - 索引 4，健康數據分析和報告
}

// 統一主框架 Widget - 應用程式的主要容器，管理頁面切換和底部導航
class MainFrame extends StatefulWidget {
  const MainFrame({super.key}); // 構造函數，接受可選的 key 參數

  @override
  State<MainFrame> createState() => _MainFrameState(); // 建立狀態物件
}

// MainFrame 的狀態管理類別
class _MainFrameState extends State<MainFrame> {
  AppPage _currentPage = AppPage.home; // 目前選中的頁面，預設為首頁

  // 導航索引映射方法 - 將頁面枚舉轉換為底部導航欄的索引
  int _getNavigationIndex() {
    switch (_currentPage) {
      case AppPage.home: // 首頁對應索引 0
        return 0;
      case AppPage.foodDiary: // 飲食記錄對應索引 1
        return 1;
      case AppPage.exercise: // 運動對應索引 3（跳過相機的索引 2）
        return 3;
      case AppPage.analysis: // 身體分析對應索引 4
        return 4;
    }
  }

  // 從導航索引轉換為頁面枚舉 - 將底部導航欄的索引轉換為頁面枚舉
  AppPage _getPageFromNavigationIndex(int index) {
    switch (index) {
      case 0: // 索引 0 對應首頁
        return AppPage.home;
      case 1: // 索引 1 對應飲食記錄
        return AppPage.foodDiary;
      case 3: // 索引 3 對應運動（跳過索引 2 的相機）
        return AppPage.exercise;
      case 4: // 索引 4 對應身體分析
        return AppPage.analysis;
      default: // 預設情況返回首頁
        return AppPage.home;
    }
  }

  // 建立目前頁面的 Widget - 根據目前選中的頁面返回對應的內容 Widget
  Widget _buildCurrentPage() {
    print('構建頁面: $_currentPage'); // 輸出除錯訊息
    switch (_currentPage) {
      case AppPage.home: // 首頁情況
        print('返回首頁內容'); // 除錯訊息
        return const HomePageContent(); // 返回首頁內容 Widget
      case AppPage.foodDiary: // 飲食記錄情況
        print('返回飲食日記內容'); // 除錯訊息
        return const FoodDiaryPageContent(); // 返回飲食記錄內容 Widget
      case AppPage.exercise: // 運動頁面情況
        print('返回運動頁面內容'); // 除錯訊息
        return const Center(
            child: Text('運動頁面開發中...',
                style: TextStyle(fontSize: 18))); // 臨時顯示開發中的提示
      case AppPage.analysis: // 身體分析情況
        print('返回身體分析內容'); // 除錯訊息
        return const BodyAnalysisPageContent(); // 返回身體分析內容 Widget
    }
  }

  @override
  Widget build(BuildContext context) {
    print('MainFrame build() 被調用，當前頁面: $_currentPage');
    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getNavigationIndex(),
        onTap: (index) {
          print('導航欄點擊 - index: $index, 當前頁面: $_currentPage');
          if (index == 2) {
            print('跳轉到相機頁面');
            // 相機頁面特殊處理 - 使用 push 而不是切換 tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CameraScreen()),
            );
          } else {
            // 映射導航索引到頁面枚舉
            final newPage = _getPageFromNavigationIndex(index);
            print('切換頁面: $_currentPage -> $newPage');
            setState(() {
              _currentPage = newPage;
            });
            print('setState 完成，當前頁面: $_currentPage');
          }
        },
        backgroundColor: Colors.white, // 導航欄背景色為白色
        selectedItemColor: Colors.black87, // 選中項目的顏色為深灰色
        unselectedItemColor: Colors.grey[400], // 未選中項目的顏色為淺灰色
        selectedFontSize: 12, // 選中項目的字體大小
        unselectedFontSize: 12, // 未選中項目的字體大小
        elevation: 0, // 陰影效果設為 0，去除高度感
        items: const [
          // 導航欄項目列表，定義所有導航選項
          BottomNavigationBarItem(
            // 首頁導航項（索引 0）
            icon: Icon(Icons.home_outlined), // 未選中時的空心家庭圖示
            activeIcon: Icon(Icons.home), // 選中時的實心家庭圖示
            label: '首頁', // 項目標籤文字
          ),
          BottomNavigationBarItem(
            // 飲食記錄導航項（索引 1）
            icon: Icon(Icons.restaurant_menu_outlined), // 未選中時的空心餐廳選單圖示
            activeIcon: Icon(Icons.restaurant_menu), // 選中時的實心餐廳選單圖示
            label: '飲食記錄', // 項目標籤文字
          ),
          BottomNavigationBarItem(
            // 相機拍照導航項（索引 2）
            icon: Icon(Icons.camera_alt_outlined), // 未選中時的空心相機圖示
            activeIcon: Icon(Icons.camera_alt), // 選中時的實心相機圖示
            label: '拍照辨識', // 項目標籤文字
          ),
          BottomNavigationBarItem(
            // 運動導航項（索引 3）
            icon: Icon(Icons.fitness_center_outlined), // 未選中時的空心健身圖示
            activeIcon: Icon(Icons.fitness_center), // 選中時的實心健身圖示
            label: '運動', // 項目標籤文字
          ),
          BottomNavigationBarItem(
            // 身體分析導航項（索引 4）
            icon: Icon(Icons.analytics_outlined), // 未選中時的空心分析圖示
            activeIcon: Icon(Icons.analytics), // 選中時的實心分析圖示
            label: '分析', // 項目標籤文字
          ),
        ],
      ),
    );
  }
}

// ----- [models/nutrition.dart] 開始 -----
// ====================================================================
// 數據模型 (Data Models)
// ====================================================================

// 身體指標數據模型 - 存儲用戶的各種健康指標數據和變化率
class BodyMetrics {
  final int sleepHours; // 睡眠時長（小時）
  final double sleepChange; // 睡眠時長變化百分比（正值表示增加，負值表示減少）
  final int height; // 身高（公分）
  final double heightChange; // 身高變化百分比（通常為 0，成人身高不會變化）
  final int weight; // 體重（公斤）
  final double weightChange; // 體重變化百分比（正值表示增加，負值表示減少）
  final int heartRate; // 心率（次/分鐘）
  final double heartRateChange; // 心率變化百分比（正值表示增加，負值表示減少）
  final String bloodPressure; // 血壓（格式：縮張壓/舟張壓，如 "120/80"）
  final double bloodPressureChange; // 血壓變化百分比（正值表示增加，負值表示減少）

  // 構造函數 - 初始化所有身體指標數據，所有參數都是必需的
  BodyMetrics({
    required this.sleepHours, // 必填：睡眠時長
    required this.sleepChange, // 必填：睡眠變化率
    required this.height, // 必填：身高
    required this.heightChange, // 必填：身高變化率
    required this.weight, // 必填：體重
    required this.weightChange, // 必填：體重變化率
    required this.heartRate, // 必填：心率
    required this.heartRateChange, // 必填：心率變化率
    required this.bloodPressure, // 必填：血壓
    required this.bloodPressureChange, // 必填：血壓變化率
  });
}

// 飲食記錄數據模型 - 存儲單一飲食項目的詳細資訊
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

// 營養素數據模型 - 存儲單一營養素的名稱、百分比和顯示顏色
class NutrientData {
  final String name; // 營養素名稱（如：蛋白質、碳水化合物、脂肪等）
  final double percentage; // 營養素所佔的百分比（0.0-100.0）
  final Color color; // 在圖表中顯示的顏色

  // 構造函數 - 使用位置參數的簡潔形式初始化營養素數據
  NutrientData(this.name, this.percentage, this.color);
}

// ====================================================================
// 應用程式主體 (Main App)
// ====================================================================
// ----- [models/nutrition.dart] 結束 -----

// ===== 【數據模型模組】結束 =====

// ====================================================================
// 主應用程式類別 (Main Application Class)
// ====================================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '登入系統', // 應用程式標題
      debugShowCheckedModeBanner: false, // 隱藏Debug橫幅
      theme: ThemeData(
        primarySwatch: Colors.blue, // 主色系設定
        useMaterial3: true, // 啟用Material 3設計系統
      ),
      home: const LoginPage(), // 首頁設定為登入頁面
    );
  }
}

// ===== 【主應用程式框架】結束 =====

// ===== 【UI頁面模組】開始 =====
// ====================================================================
// 登入頁面 (Login Page)
// ====================================================================
/*
模組化建議：【頁面模組 - pages/auth/login_page.dart】
LoginPage 和 _LoginPageState 可以獨立成為登入頁面模組。
包含用戶認證相關的UI和邏輯，適合放在 pages/auth/ 目錄下。
*/

// ----- [pages/auth/login_page.dart] 開始 -----
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// 登入頁面狀態管理類別 - 處理登入邏輯和使用者介面狀態
class _LoginPageState extends State<LoginPage> {
  // 文字輸入控制器：管理使用者名稱輸入框的文字內容
  final TextEditingController _usernameController = TextEditingController();

  // 文字輸入控制器：管理密碼輸入框的文字內容
  final TextEditingController _passwordController = TextEditingController();

  // 表單驗證鍵：用於觸發表單驗證和取得表單狀態
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 密碼可見性控制：true 表示密碼以明文顯示，false 表示以密碼符號顯示
  bool _isPasswordVisible = false;

  // 一般登入載入狀態：true 表示正在進行登入處理，顯示載入指示器
  bool _isLoading = false;

  // Google 登入載入狀態：true 表示正在進行 Google 登入處理
  bool _isGoogleLoading = false;

  // Google 登入配置物件 - 設定登入範圍和權限
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'], // 請求存取使用者的電子郵件和基本個人資料
  );

  /// 處理一般登入流程 - 驗證表單並執行登入邏輯
  void _handleLogin() async {
    // 驗證表單輸入：檢查所有必填欄位是否符合驗證規則
    if (!_formKey.currentState!.validate()) return;

    // 設定載入狀態為真：觸發 UI 重新渲染以顯示載入指示器
    setState(() {
      _isLoading = true;
    });

    // 模擬登入過程：在實際應用中這裡會呼叫 API 進行身分驗證
    await Future.delayed(const Duration(seconds: 1));

    // 關閉載入狀態：隱藏載入指示器
    setState(() {
      _isLoading = false;
    });

    // 檢查 Widget 是否仍在 Widget 樹中：防止在異步操作完成後對已銷毀的 Widget 進行操作
    if (!context.mounted) return;

    // 顯示登入成功的訊息給使用者
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('登入成功'), // 成功訊息內容
        backgroundColor: Colors.green, // 設定為綠色背景表示成功
      ),
    );

    // 導航到主框架頁面：使用 pushReplacement 替換當前頁面，防止使用者按返回鍵回到登入頁面
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainFrame()),
    );
  }

  /// Google 登入處理方法 - 執行 Google 第三方登入流程
  Future<void> _handleGoogleSignIn() async {
    // 設定 Google 登入載入狀態：顯示載入指示器表示正在處理 Google 登入
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      // 執行 Google 登入：開啟 Google 登入對話框讓使用者選擇帳戶
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      // 檢查是否成功取得使用者帳戶資訊
      if (account != null) {
        // 記錄成功登入的資訊到日誌系統
        await log('Google 登入成功: ${account.displayName} (${account.email})');

        // 檢查 Widget 是否仍在 Widget 樹中
        if (!context.mounted) return;

        // 顯示歡迎訊息：使用使用者的 Google 顯示名稱
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('歡迎 ${account.displayName}！'), // 個人化歡迎訊息
            backgroundColor: Colors.green, // 綠色背景表示成功
          ),
        );

        // 導航到主框架頁面：登入成功後進入應用程式主要功能
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainFrame()),
        );
      } else {
        // 使用者取消登入：記錄取消事件到日誌
        await log('Google 登入被取消');
      }
    } catch (error) {
      // 捕獲並記錄 Google 登入過程中的任何錯誤
      await log('Google 登入錯誤: $error');

      // 檢查 Widget 是否仍在 Widget 樹中
      if (!context.mounted) return;

      // 顯示錯誤訊息給使用者
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google 登入失敗: $error'), // 顯示具體錯誤訊息
          backgroundColor: Colors.red, // 紅色背景表示錯誤
        ),
      );
    } finally {
      // 無論成功或失敗都要執行的清理工作：關閉載入狀態
      if (mounted) {
        // 檢查 Widget 是否仍然存在
        setState(() {
          _isGoogleLoading = false; // 隱藏 Google 登入載入指示器
        });
      }
    }
  }

  /// 建構登入頁面的使用者介面
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // 設定頁面背景為淺灰色
      body: SafeArea(
        // 確保內容不會被系統狀態列或導航列遮擋
        child: Center(
          // 將所有內容置中顯示
          child: SingleChildScrollView(
            // 允許頁面在內容過長時可以滾動
            padding: const EdgeInsets.all(32.0), // 設定頁面內邊距
            child: Form(
              // 表單容器，用於管理輸入驗證
              key: _formKey, // 綁定表單驗證鍵
              child: Column(
                // 垂直排列所有 UI 元件
                mainAxisAlignment: MainAxisAlignment.center, // 垂直置中對齊
                children: [
                  // 使用者頭像圓形容器
                  Container(
                    width: 120, // 設定寬度為 120 像素
                    height: 120, // 設定高度為 120 像素
                    decoration: BoxDecoration(
                      color: Colors.blue, // 設定背景顏色為藍色
                      borderRadius: BorderRadius.circular(60), // 設定圓角半徑使其成為圓形
                    ),
                    child: const Icon(
                      Icons.person, // 使用人物圖示
                      size: 60, // 設定圖示大小
                      color: Colors.white, // 設定圖示顏色為白色
                    ),
                  ),
                  const SizedBox(height: 32), // 垂直間距

                  // 主標題文字
                  const Text(
                    '歡迎回來',
                    style: TextStyle(
                      fontSize: 28, // 設定字體大小
                      fontWeight: FontWeight.bold, // 設定字體粗細為粗體
                      color: Colors.black87, // 設定字體顏色
                    ),
                  ),
                  const SizedBox(height: 8), // 垂直間距

                  // 副標題說明文字
                  const Text(
                    '請輸入您的帳號資訊',
                    style: TextStyle(fontSize: 16, color: Colors.grey), // 灰色副標題
                  ),
                  const SizedBox(height: 8), // 垂直間距

                  // 測試帳號資訊提示
                  const Text(
                    '測試帳號: test\n測試密碼: 123456',
                    style:
                        TextStyle(fontSize: 14, color: Colors.blue), // 藍色提示文字
                    textAlign: TextAlign.center, // 文字置中對齊
                  ),
                  const SizedBox(height: 32), // 垂直間距

                  // 帳號輸入欄位
                  TextFormField(
                    controller: _usernameController, // 綁定帳號輸入控制器
                    decoration: InputDecoration(
                      labelText: '帳號', // 輸入欄位標籤
                      hintText: '請輸入您的帳號', // 提示文字
                      prefixIcon: const Icon(Icons.person_outline), // 前置圖示
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), // 設定圓角邊框
                      ),
                      filled: true, // 啟用填充色
                      fillColor: Colors.white, // 設定填充顏色為白色
                    ),
                    // 輸入驗證函數
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入帳號'; // 空值驗證錯誤訊息
                      }
                      if (value.length < 3) {
                        return '帳號至少需要3個字元'; // 長度驗證錯誤訊息
                      }
                      return null; // 驗證通過回傳 null
                    },
                  ),
                  const SizedBox(height: 16), // 垂直間距

                  // 密碼輸入欄位
                  TextFormField(
                    controller: _passwordController, // 綁定密碼輸入控制器
                    obscureText: !_isPasswordVisible, // 根據可見性狀態決定是否隱藏密碼
                    decoration: InputDecoration(
                      labelText: '密碼', // 輸入欄位標籤
                      hintText: '請輸入您的密碼', // 提示文字
                      prefixIcon: const Icon(Icons.lock_outline), // 前置鎖定圖示
                      // 密碼可見性切換按鈕
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility // 顯示眼睛圖示（密碼可見）
                              : Icons.visibility_off, // 顯示關閉眼睛圖示（密碼隱藏）
                        ),
                        onPressed: () {
                          // 切換密碼可見性狀態
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), // 設定圓角邊框
                      ),
                      filled: true, // 啟用填充色
                      fillColor: Colors.white, // 設定填充顏色為白色
                    ),
                    // 密碼輸入驗證函數
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入密碼'; // 空值驗證錯誤訊息
                      }
                      if (value.length < 6) {
                        return '密碼至少需要6個字元'; // 長度驗證錯誤訊息
                      }
                      return null; // 驗證通過回傳 null
                    },
                  ),
                  const SizedBox(height: 32), // 垂直間距

                  // 登入按鈕容器
                  SizedBox(
                    width: double.infinity, // 設定按鈕寬度為父容器的全寬
                    height: 50, // 設定按鈕高度
                    child: ElevatedButton(
                      // 根據載入狀態決定是否啟用按鈕：載入中時禁用按鈕
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // 按鈕背景顏色
                        foregroundColor: Colors.white, // 按鈕文字顏色
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // 按鈕圓角
                        ),
                        elevation: 2, // 按鈕陰影高度
                      ),
                      // 按鈕內容：根據載入狀態顯示不同內容
                      child: _isLoading
                          ? const Row(
                              // 載入中顯示進度指示器和文字
                              mainAxisAlignment:
                                  MainAxisAlignment.center, // 水平置中
                              children: [
                                SizedBox(
                                  width: 20, // 進度指示器寬度
                                  height: 20, // 進度指示器高度
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, // 進度條線條寬度
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white), // 設定進度條顏色為白色
                                  ),
                                ),
                                SizedBox(width: 12), // 間距
                                Text('登入中...'), // 載入中文字
                              ],
                            )
                          : const Text(
                              // 正常狀態顯示登入文字
                              '登入',
                              style: TextStyle(
                                fontSize: 16, // 文字大小
                                fontWeight: FontWeight.bold, // 粗體文字
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16), // 垂直間距

                  // 分隔線區域：顯示「或」字樣的分隔線
                  Row(
                    children: [
                      // 左側分隔線：自動擴展填滿可用空間
                      Expanded(child: Divider(color: Colors.grey[400])),
                      // 中間「或」字文字
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16), // 水平內邊距
                        child: Text(
                          '或',
                          style: TextStyle(color: Colors.grey[600]), // 灰色文字
                        ),
                      ),
                      // 右側分隔線：自動擴展填滿可用空間
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 16), // 垂直間距

                  // Google 登入按鈕容器
                  SizedBox(
                    width: double.infinity, // 設定按鈕寬度為父容器的全寬
                    height: 50, // 設定按鈕高度
                    child: OutlinedButton.icon(
                      // 帶圖示的外框按鈕
                      // 根據 Google 登入載入狀態決定是否啟用按鈕
                      onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white, // 白色背景
                        foregroundColor: Colors.black87, // 深灰色文字
                        side: BorderSide(color: Colors.grey[300]!), // 淺灰色邊框
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // 圓角邊框
                        ),
                      ),
                      // 按鈕圖示：根據載入狀態顯示不同圖示
                      icon: _isGoogleLoading
                          ? const SizedBox(
                              // 載入中顯示進度指示器
                              width: 20, // 指示器寬度
                              height: 20, // 指示器高度
                              child: CircularProgressIndicator(
                                strokeWidth: 2, // 進度條線條寬度
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue), // 藍色進度條
                              ),
                            )
                          : Image.network(
                              // 正常狀態顯示 Google Logo
                              'https://developers.google.com/identity/images/g-logo.png',
                              width: 20, // 圖片寬度
                              height: 20, // 圖片高度
                              // 圖片載入失敗時的備用方案
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.g_mobiledata,
                                    size: 20); // 顯示 G 圖示
                              },
                            ),
                      // 按鈕文字標籤：根據載入狀態顯示不同文字
                      label: Text(
                        _isGoogleLoading ? '登入中...' : '使用 Google 登入', // 動態文字內容
                        style: const TextStyle(
                          fontSize: 16, // 文字大小
                          fontWeight: FontWeight.w500, // 中等粗細文字
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24), // 垂直間距

                  // 註冊連結區域：引導使用者到註冊頁面
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // 水平置中對齊
                    children: [
                      const Text('還沒有帳號？'), // 提示文字
                      TextButton(
                        // 文字按鈕
                        onPressed: () {
                          // 導航到註冊頁面：使用 push 方式保留返回功能
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          '立即註冊', // 註冊按鈕文字
                          style: TextStyle(fontWeight: FontWeight.bold), // 粗體文字
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 資源清理方法 - 在 Widget 被銷毀時釋放資源
  @override
  void dispose() {
    // 釋放帳號輸入控制器：防止記憶體洩漏
    _usernameController.dispose();
    // 釋放密碼輸入控制器：防止記憶體洩漏
    _passwordController.dispose();
    // 呼叫父類別的 dispose 方法：執行標準清理流程
    super.dispose();
  }
}

// ====================================================================
// 註冊頁面 (Register Page)
// ====================================================================
/*
模組化建議：【頁面模組 - pages/auth/register_page.dart】
RegisterPage 和 _RegisterPageState 可以獨立成為註冊頁面模組。
與登入頁面相關，同樣適合放在 pages/auth/ 目錄下。
*/
// ----- [pages/auth/login_page.dart] 結束 -----

// ----- [pages/auth/register_page.dart] 開始 -----
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

// 註冊頁面狀態管理類別 - 處理使用者註冊流程和表單驗證
class _RegisterPageState extends State<RegisterPage> {
  // 文字輸入控制器：管理使用者名稱輸入框的文字內容
  final TextEditingController _usernameController = TextEditingController();

  // 文字輸入控制器：管理電子郵件輸入框的文字內容
  final TextEditingController _emailController = TextEditingController();

  // 文字輸入控制器：管理密碼輸入框的文字內容
  final TextEditingController _passwordController = TextEditingController();

  // 文字輸入控制器：管理確認密碼輸入框的文字內容
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // 表單驗證鍵：用於觸發整個註冊表單的驗證
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 密碼可見性控制：true 表示密碼以明文顯示
  bool _isPasswordVisible = false;

  // 確認密碼可見性控制：true 表示確認密碼以明文顯示
  bool _isConfirmPasswordVisible = false;

  // 註冊載入狀態：true 表示正在進行註冊處理
  bool _isLoading = false;

  /// 處理使用者註冊流程 - 驗證表單並執行註冊邏輯
  void _handleRegister() async {
    // 驗證所有表單輸入：檢查必填欄位和格式是否正確
    if (!_formKey.currentState!.validate()) return;

    // 設定載入狀態：顯示載入指示器
    setState(() {
      _isLoading = true;
    });

    // 模擬註冊過程：在實際應用中這裡會呼叫註冊 API
    await Future.delayed(const Duration(seconds: 2));

    // 關閉載入狀態：隱藏載入指示器
    setState(() {
      _isLoading = false;
    });

    // 檢查 Widget 是否仍在 Widget 樹中
    if (!context.mounted) return;

    // 顯示註冊成功訊息給使用者
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('註冊成功！請使用新帳號登入'), // 成功訊息內容
        backgroundColor: Colors.green, // 綠色背景表示成功
        duration: Duration(seconds: 3), // 訊息顯示時間
      ),
    );

    // 返回登入頁面：註冊成功後回到登入頁面
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo區域
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 標題
                  const Text(
                    '建立新帳號',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '請填寫以下資訊來建立您的帳號',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // 帳號輸入框
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: '帳號',
                      hintText: '請輸入您的帳號',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入帳號';
                      }
                      if (value.length < 3) {
                        return '帳號至少需要3個字元';
                      }
                      if (value.length > 20) {
                        return '帳號不能超過20個字元';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email輸入框
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: '請輸入您的Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入Email';
                      }
                      // 簡單的Email格式檢查
                      if (!value.contains('@') || !value.contains('.')) {
                        return '請輸入有效的Email格式';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 密碼輸入框
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: '密碼',
                      hintText: '請輸入您的密碼',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入密碼';
                      }
                      if (value.length < 6) {
                        return '密碼至少需要6個字元';
                      }
                      if (value.length > 20) {
                        return '密碼不能超過20個字元';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 確認密碼輸入框
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: '確認密碼',
                      hintText: '請再次輸入您的密碼',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請確認密碼';
                      }
                      if (value != _passwordController.text) {
                        return '密碼不一致，請重新輸入';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // 註冊按鈕
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('註冊中...'),
                              ],
                            )
                          : const Text(
                              '註冊',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 返回登入連結
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('已經有帳號了？'),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          '立即登入',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

// ====================================================================
// ----- [pages/auth/register_page.dart] 結束 -----

// ----- [pages/home/home_page.dart] 開始 -----
// 首頁 (Home Page)
// ====================================================================
// 首頁內容頁面 - 顯示營養攝取概覽和健康數據摘要
class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

// 首頁內容狀態管理類別 - 管理卡路里追蹤和營養素數據
class _HomePageContentState extends State<HomePageContent> {
  // 當前已攝取的卡路里數量
  double currentCalories = 1200;

  // 目標卡路里攝取量
  double targetCalories = 2000;

  // 宏量營養素比例數據：包含營養素名稱、百分比和顯示顏色
  List<NutrientData> nutrients = [
    NutrientData('蛋白質', 25, Colors.blue[300]!), // 蛋白質 25% - 藍色
    NutrientData('碳水化合物', 35, Colors.grey[400]!), // 碳水化合物 35% - 灰色
    NutrientData('脂肪', 25, Colors.grey[400]!), // 脂肪 25% - 灰色
    NutrientData('膳食纖維', 15, Colors.grey[400]!), // 膳食纖維 15% - 灰色
  ];

  // ====================================================================
  // 首頁建構方法和主要 UI
  // ====================================================================
  /// 建構首頁使用者介面 - 顯示營養追蹤和健康概覽
  @override
  Widget build(BuildContext context) {
    // 鎖定首頁為豎螢幕：確保用戶體驗一致性
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, // 允許正向直立
      DeviceOrientation.portraitDown, // 允許倒向直立
    ]);

    return Scaffold(
      backgroundColor: Colors.grey[50], // 設定頁面背景為淺灰色
      appBar: AppBar(
        // 頂部應用程式列
        backgroundColor: Colors.transparent, // 透明背景
        elevation: 0, // 無陰影效果
        // 左側選單按鈕
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.grey[800]), // 選單圖示
          onPressed: () {}, // 暫時無功能
        ),
        // 頁面標題
        title: Text(
          '首頁',
          style: TextStyle(
            color: Colors.grey[800], // 深灰色文字
            fontSize: 20, // 字體大小
            fontWeight: FontWeight.w500, // 中等粗細
          ),
        ),
        centerTitle: true, // 標題置中
        // 右側操作按鈕
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.grey[800]),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 每日熱量目標
            _buildCalorieSection(),
            const SizedBox(height: 30),

            // 宏量熱量比例
            _buildMacroSection(),
            const SizedBox(height: 30),

            // 個人化飲食建議
            _buildAISection(),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // 首頁 UI 組件方法
  // ====================================================================

  // 熱量目標區塊
  Widget _buildCalorieSection() {
    double progress = currentCalories / targetCalories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '每日熱量目標',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            Text(
              '${currentCalories.toInt()}/${targetCalories.toInt()} kcal',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey[300],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress > 1 ? 1 : progress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 宏量營養素區塊
  Widget _buildMacroSection() {
    // 動態生成營養素比例文字
    String ratioText = nutrients
        .map((nutrient) =>
            '${nutrient.name} ${nutrient.percentage.toStringAsFixed(1)}%')
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '宏量熱量比例',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 20),

        // 營養素百分比顯示
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                ratioText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 營養素圖表
              Column(
                children: [
                  Text(
                    '本日',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: nutrients
                        .map((nutrient) => _buildNutrientBar(nutrient))
                        .toList(),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 測試功能區塊
        const SizedBox(height: 15),
        _buildTestSection(),
      ],
    );
  }

  // 營養素長條圖
  Widget _buildNutrientBar(NutrientData nutrient) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey[200],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 60,
                height: (120 * nutrient.percentage / 100).clamp(0, 120),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: nutrient.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          nutrient.name,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // 測試功能區塊
  Widget _buildTestSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '測試功能：',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildTestButton('更新蛋白質', () => _updateNutrientData('蛋白質', 30.0)),
              _buildTestButton(
                  '更新碳水', () => _updateNutrientData('碳水化合物', 40.0)),
              _buildTestButton('重置數據', _resetData),
            ],
          ),
        ],
      ),
    );
  }

  // 測試按鈕
  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.blue[700],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }

  // AI 建議區塊
  Widget _buildAISection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '個人化飲食建議',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI 健康助手',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    '為您量身打造營養建議',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),

          // 問題輸入區域
          GestureDetector(
            onTap: () {
              _showQuestionDialog();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '有什麼營養問題想諮詢嗎？',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.mic_outlined,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 首頁功能方法
  // ====================================================================

  // 更新營養素數據
  void _updateNutrientData(String name, double newPercentage) {
    setState(() {
      for (int i = 0; i < nutrients.length; i++) {
        if (nutrients[i].name == name) {
          nutrients[i] = NutrientData(name, newPercentage, Colors.blue[300]!);
          break;
        }
      }
    });
  }

  // 重置數據
  void _resetData() {
    setState(() {
      // 重置熱量數據
      currentCalories = 1200;
      targetCalories = 2000;

      // 重置營養素數據
      nutrients = [
        NutrientData('蛋白質', 25, Colors.blue[300]!),
        NutrientData('碳水化合物', 35, Colors.grey[400]!),
        NutrientData('脂肪', 25, Colors.grey[400]!),
        NutrientData('膳食纖維', 15, Colors.grey[400]!),
      ];
    });
  }

  // 顯示問題輸入對話框
  void _showQuestionDialog() {
    final TextEditingController questionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI 健康助手',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '請輸入您想諮詢的健康或營養問題：',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: questionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '例如：我應該如何增加蛋白質攝取？',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (questionController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  _handleAIQuestion(questionController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('發送'),
            ),
          ],
        );
      },
    );
  }

  // 處理 AI 問題 - 預留給 RAG 整合
  void _handleAIQuestion(String question) {
    // TODO: 整合 RAG 系統來處理問題
    // 目前只顯示確認訊息

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已收到您的問題：$question'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );

    // 未來在這裡調用 RAG API
    // String response = await ragService.getResponse(question);
    // _showAIResponse(question, response);
  }
}

// ====================================================================
// ----- [pages/home/home_page.dart] 結束 -----

// ----- [pages/analysis/body_analysis_page.dart] 開始 -----
// 身體素質分析頁面 (Body Analysis Page)
// ====================================================================
class BodyAnalysisPageContent extends StatefulWidget {
  const BodyAnalysisPageContent({super.key});

  @override
  State<BodyAnalysisPageContent> createState() =>
      _BodyAnalysisPageContentState();
}

class _BodyAnalysisPageContentState extends State<BodyAnalysisPageContent> {
  String selectedPeriod = '週';

  // 身體素質數據
  BodyMetrics bodyMetrics = BodyMetrics(
    sleepHours: 8,
    sleepChange: 10,
    height: 175,
    heightChange: 0,
    weight: 65,
    weightChange: -1.2,
    heartRate: 70,
    heartRateChange: -2,
    bloodPressure: '120/80',
    bloodPressureChange: 1,
  );

  // ====================================================================
  // 身體分析頁面主要 UI
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    // 鎖定身體分析頁面為豎螢幕
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '身體素質分析',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 頂部標籤區域
            _buildTopTags(),

            // 時間段選擇
            _buildPeriodSelector(),

            // 整體身體素質分析
            _buildOverallAnalysis(),

            // 身體指標卡片
            _buildMetricsCards(),

            // 年齡層級比較
            _buildAgeComparison(),

            // 建議
            _buildRecommendations(),

            // 測試功能區塊
            _buildTestSection(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // 身體分析頁面 UI 組件
  // ====================================================================

  // 頂部標籤
  Widget _buildTopTags() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildTag('優秀'),
          _buildTag('良好'),
          _buildTag('正常'),
          _buildTag('注意'),
          _buildTag('改善'),
          _buildTag('睡眠'),
          _buildTag('體重'),
          _buildTag('心率'),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // 時間段選擇器
  Widget _buildPeriodSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPeriodButton('天'),
          _buildPeriodButton('週'),
          _buildPeriodButton('月'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    bool isSelected = selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPeriod = period;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[300] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          period,
          style: TextStyle(
            fontSize: 16,
            color: isSelected ? Colors.black : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 整體分析
  Widget _buildOverallAnalysis() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '整體身體素質分析',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '您的身體素質分析顯示您在睡眠品質、身高、體重、心率和血壓方面的重要參數。您的身體素質在您的年齡層級中處於平均水平，特別是在睡眠品質方面表現出色。',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // 指標卡片組
  Widget _buildMetricsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  '睡眠品質',
                  '${bodyMetrics.sleepHours} 小時',
                  bodyMetrics.sleepChange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  '身高',
                  '${bodyMetrics.height} 公分',
                  bodyMetrics.heightChange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  '體重',
                  '${bodyMetrics.weight} 公斤',
                  bodyMetrics.weightChange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  '心率',
                  '${bodyMetrics.heartRate} 次/分鐘',
                  bodyMetrics.heartRateChange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBloodPressureCard(),
        ],
      ),
    );
  }

  // 單一指標卡片
  Widget _buildMetricCard(String title, String value, double change) {
    Color changeColor = change > 0
        ? Colors.green
        : change < 0
            ? Colors.red
            : Colors.grey;
    String changeText = change > 0
        ? '+${change.toStringAsFixed(change % 1 == 0 ? 0 : 1)}%'
        : change < 0
            ? '${change.toStringAsFixed(change % 1 == 0 ? 0 : 1)}%'
            : '${change.toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            changeText,
            style: TextStyle(
              fontSize: 14,
              color: changeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 血壓卡片
  Widget _buildBloodPressureCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '血壓',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${bodyMetrics.bloodPressure} 毫米汞柱',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+${bodyMetrics.bloodPressureChange}%',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 年齡比較區塊
  Widget _buildAgeComparison() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '與年齡層級的比較',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '您的睡眠品質高於同年齡級的平均水平，而身高、體重、心率和血壓則處於平均水平。這表示睡眠方面的優勢，但也提示在體重和脂肪百分比方面可能需要調整。',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // 建議區塊
  Widget _buildRecommendations() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '建議',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '為了維持睡眠品質並改善體重和脂肪百分比，可考慮增加肌力訓練、調整飲食以增加蛋白質攝取，並控制脂肪和糖分的攝取。',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // 測試功能區塊
  Widget _buildTestSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '測試功能 (Power BI 數據模擬)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '模擬數據更新：',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTestButton('更新睡眠數據', () => _updateSleepData()),
              _buildTestButton('更新體重數據', () => _updateWeightData()),
              _buildTestButton('更新心率數據', () => _updateHeartRateData()),
              _buildTestButton(
                  '模擬 Power BI 同步', () => _updateBodyMetricsFromPowerBI()),
              _buildTestButton('重置為默認值', () => _resetToDefault()),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '當前數據來源：$selectedPeriod統計',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.blue[700],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 11),
      ),
      child: Text(label),
    );
  }

  // ====================================================================
  // 身體分析功能方法
  // ====================================================================

  // 更新睡眠數據
  /// 更新睡眠數據 - 模擬從睡眠感測器獲取的睡眠時間數據
  void _updateSleepData() {
    setState(() {
      // 更新身體指標：設定新的睡眠時間為 9 小時，變化率為 +25%
      bodyMetrics = BodyMetrics(
        sleepHours: 9, // 設定睡眠時間為 9 小時
        sleepChange: 25.0, // 睡眠時間增加 25%
        height: bodyMetrics.height, // 保持原有身高數據
        heightChange: bodyMetrics.heightChange, // 保持原有身高變化數據
        weight: bodyMetrics.weight, // 保持原有體重數據
        weightChange: bodyMetrics.weightChange, // 保持原有體重變化數據
        heartRate: bodyMetrics.heartRate, // 保持原有心率數據
        heartRateChange: bodyMetrics.heartRateChange, // 保持原有心率變化數據
        bloodPressure: bodyMetrics.bloodPressure, // 保持原有血壓數據
        bloodPressureChange: bodyMetrics.bloodPressureChange, // 保持原有血壓變化數據
      );
    });
  }

  /// 更新體重數據 - 模擬從體重計感測器獲取的體重測量數據
  void _updateWeightData() {
    setState(() {
      // 更新身體指標：設定新的體重為 62 公斤，變化率為 -4.8%
      bodyMetrics = BodyMetrics(
        sleepHours: bodyMetrics.sleepHours, // 保持原有睡眠數據
        sleepChange: bodyMetrics.sleepChange, // 保持原有睡眠變化數據
        height: bodyMetrics.height, // 保持原有身高數據
        heightChange: bodyMetrics.heightChange, // 保持原有身高變化數據
        weight: 62, // 設定體重為 62 公斤
        weightChange: -4.8, // 體重減少 4.8%
        heartRate: bodyMetrics.heartRate, // 保持原有心率數據
        heartRateChange: bodyMetrics.heartRateChange, // 保持原有心率變化數據
        bloodPressure: bodyMetrics.bloodPressure, // 保持原有血壓數據
        bloodPressureChange: bodyMetrics.bloodPressureChange, // 保持原有血壓變化數據
      );
    });
  }

  /// 更新心率數據 - 模擬從心率感測器獲取的心跳監測數據
  void _updateHeartRateData() {
    setState(() {
      // 更新身體指標：準備設定新的心率數據
      bodyMetrics = BodyMetrics(
        sleepHours: bodyMetrics.sleepHours, // 保持原有睡眠數據
        sleepChange: bodyMetrics.sleepChange,
        height: bodyMetrics.height,
        heightChange: bodyMetrics.heightChange,
        weight: bodyMetrics.weight,
        weightChange: bodyMetrics.weightChange,
        heartRate: 75,
        heartRateChange: 7.1,
        bloodPressure: bodyMetrics.bloodPressure,
        bloodPressureChange: bodyMetrics.bloodPressureChange,
      );
    });
  }

  // 模擬 Power BI 同步
  void _updateBodyMetricsFromPowerBI() {
    setState(() {
      bodyMetrics = BodyMetrics(
        sleepHours: 8,
        sleepChange: 15.0,
        height: 175,
        heightChange: 0,
        weight: 63,
        weightChange: -3.1,
        heartRate: 68,
        heartRateChange: -2.9,
        bloodPressure: '118/78',
        bloodPressureChange: -1.5,
      );
    });
  }

  // 重置為默認值
  void _resetToDefault() {
    setState(() {
      bodyMetrics = BodyMetrics(
        sleepHours: 8,
        sleepChange: 10,
        height: 175,
        heightChange: 0,
        weight: 65,
        weightChange: -1.2,
        heartRate: 70,
        heartRateChange: -2,
        bloodPressure: '120/80',
        bloodPressureChange: 1,
      );
    });
  }
}

// ====================================================================
// ----- [pages/analysis/body_analysis_page.dart] 結束 -----

// ----- [pages/diary/food_diary_page.dart] 開始 -----
// 飲食記錄頁面 (Food Diary Page)
// ====================================================================
class FoodDiaryPageContent extends StatefulWidget {
  const FoodDiaryPageContent({super.key});

  @override
  State<FoodDiaryPageContent> createState() => _FoodDiaryPageContentState();
}

class _FoodDiaryPageContentState extends State<FoodDiaryPageContent> {
  DateTime selectedDate = DateTime.now();

  // 滾輪控制器
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  // 年月日選項
  List<int> years =
      List.generate(10, (index) => DateTime.now().year - 5 + index);
  List<int> months = List.generate(12, (index) => index + 1);
  late List<int> days;

  @override
  void initState() {
    super.initState();
    _updateDaysInMonth();

    // 初始化控制器，設定為當前日期
    _yearController = FixedExtentScrollController(
      initialItem: years.indexOf(selectedDate.year),
    );
    _monthController = FixedExtentScrollController(
      initialItem: selectedDate.month - 1,
    );
    _dayController = FixedExtentScrollController(
      initialItem: selectedDate.day - 1,
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  // 更新該月份的天數
  void _updateDaysInMonth() {
    int daysInMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    days = List.generate(daysInMonth, (index) => index + 1);
  }

  // 模擬飲食記錄數據
  Map<String, List<FoodEntry>> get foodEntries {
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return {
      // 今天的數據
      todayKey: [
        FoodEntry(
          name: 'Grilled Salmon',
          chineseName: '烤鮭魚',
          mealType: '午餐',
          calories: 350,
          imageUrls: [
            'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400',
            'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400',
            'https://images.unsplash.com/photo-1574781330855-d0db2293d3b3?w=400',
          ],
          servingInfo: '150g',
        ),
        FoodEntry(
          name: 'Greek Salad',
          chineseName: '希臘沙拉',
          mealType: '晚餐',
          calories: 180,
          imageUrls: [
            'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400',
            'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
            'https://images.unsplash.com/photo-1551248429-40975aa4de74?w=400',
          ],
          servingInfo: '200g',
        ),
      ],
      // 示例日期數據
      '2024-07-15': [
        FoodEntry(
          name: 'Oatmeal with Berries',
          chineseName: '燕麥莓果',
          mealType: '早餐',
          calories: 250,
          imageUrls: [
            'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400',
            'https://images.unsplash.com/photo-1559847844-5315695dadae?w=400',
            'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400',
          ],
          servingInfo: '1杯',
        ),
        FoodEntry(
          name: 'Chicken Salad Sandwich',
          chineseName: '雞肉沙拉三明治',
          mealType: '午餐',
          calories: 450,
          imageUrls: [
            'https://images.unsplash.com/photo-1553909489-cd47e0ef937f?w=400',
            'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
            'https://images.unsplash.com/photo-1571091655789-405eb7a3a3a8?w=400',
          ],
          servingInfo: '1份',
        ),
        FoodEntry(
          name: 'Salmon with Roasted Vegetables',
          chineseName: '烤蔬菜鮭魚',
          mealType: '晚餐',
          calories: 600,
          imageUrls: [
            'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400',
            'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400',
            'https://images.unsplash.com/photo-1574781330855-d0db2293d3b3?w=400',
          ],
          servingInfo: '1份',
        ),
      ],
      // 昨天的數據示例
      '${DateTime.now().subtract(Duration(days: 1)).year}-${DateTime.now().subtract(Duration(days: 1)).month.toString().padLeft(2, '0')}-${DateTime.now().subtract(Duration(days: 1)).day.toString().padLeft(2, '0')}':
          [
        FoodEntry(
          name: 'Avocado Toast',
          chineseName: '酪梨吐司',
          mealType: '早餐',
          calories: 280,
          imageUrls: [
            'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=400',
            'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=400',
            'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400',
          ],
          servingInfo: '2片',
        ),
      ],
    };
  }

  // ====================================================================
  // 飲食記錄頁面主要 UI
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    // 鎖定飲食記錄頁面為豎螢幕
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '飲食記錄',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 日期選擇器
          _buildDateSelector(),

          // 選中日期顯示
          _buildSelectedDate(),

          // 飲食記錄列表
          Expanded(
            child: _buildFoodList(),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 飲食記錄頁面 UI 組件
  // ====================================================================

  // 日期選擇器 - 三個垂直滾輪
  Widget _buildDateSelector() {
    return Container(
      color: Colors.white,
      height: 200,
      child: Row(
        children: [
          // 年份滾輪
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '年',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _yearController,
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedDate = DateTime(
                          years[index],
                          selectedDate.month,
                          math.min(
                              selectedDate.day,
                              DateTime(years[index], selectedDate.month + 1, 0)
                                  .day),
                        );
                        _updateDaysInMonth();
                        // 如果當前選中的日期超出新月份的天數，則調整日期滾輪
                        if (selectedDate.day > days.length) {
                          _dayController.jumpToItem(days.length - 1);
                        }
                      });
                    },
                    children: years
                        .map((year) => Center(
                              child: Text(
                                year.toString(),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // 月份滾輪
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '月',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _monthController,
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedDate = DateTime(
                          selectedDate.year,
                          months[index],
                          math.min(
                              selectedDate.day,
                              DateTime(selectedDate.year, months[index] + 1, 0)
                                  .day),
                        );
                        _updateDaysInMonth();
                        // 如果當前選中的日期超出新月份的天數，則調整日期滾輪
                        if (selectedDate.day > days.length) {
                          _dayController.jumpToItem(days.length - 1);
                        }
                      });
                    },
                    children: months
                        .map((month) => Center(
                              child: Text(
                                month.toString(),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // 日期滾輪
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '日',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _dayController,
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          days[index],
                        );
                      });
                    },
                    children: days
                        .map((day) => Center(
                              child: Text(
                                day.toString(),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 獲取星期幾的中文名稱
  String _getWeekday(DateTime date) {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return '週${weekdays[date.weekday % 7]}';
  }

  // 選中日期顯示
  Widget _buildSelectedDate() {
    String formattedDate =
        '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_getWeekday(selectedDate)} • ${_getTotalCalories()} kcal',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // 獲取該日期的總熱量（示例）
  int _getTotalCalories() {
    final dateKey =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    final entries = foodEntries[dateKey] ?? [];
    return entries.fold(0, (sum, entry) => sum + entry.calories);
  }

  // 飲食記錄列表
  Widget _buildFoodList() {
    final dateKey =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    final entries = foodEntries[dateKey] ?? [];

    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('尚無飲食記錄', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return _buildFoodCard(entries[index]);
      },
    );
  }

  // 飲食卡片
  Widget _buildFoodCard(FoodEntry entry) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NutritionDetailPage(
              foodName: entry.name,
              servingSize: 250, // 預設份量
              nutritionInfo: NutritionInfo(
                calories: entry.calories,
                protein: 25,
                carbohydrates: 30,
                fat: 15,
                fiber: 5,
                sugar: 8,
                sodium: 200,
                cholesterol: 50,
                vitaminA: 100,
                vitaminC: 20,
                calcium: 150,
                iron: 3,
              ),
              ingredients: ["有機蔬菜", "全穀物", "植物蛋白"],
              allergens: ["麩質 / Gluten", "大豆 / Soy"],
              imageUrl:
                  entry.imageUrls.isNotEmpty ? entry.imageUrls.first : null,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 多張食物圖片輪播
            _buildImageCarousel(entry.imageUrls),

            // 食物資訊
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.mealType,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${entry.calories} kcal',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          entry.servingInfo,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 建構圖片輪播組件
  Widget _buildImageCarousel(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return _buildPlaceholderImage();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          // 圖片輪播
          SizedBox(
            height: 200,
            width: double.infinity,
            child: PageView.builder(
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                );
              },
            ),
          ),

          // 頁面指示器
          if (imageUrls.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 建構佔位圖片
  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Icon(
        Icons.restaurant,
        size: 64,
        color: Colors.grey,
      ),
    );
  }
}

class NutritionDetailPage extends StatelessWidget {
  final String foodName;
  final int servingSize;
  final NutritionInfo nutritionInfo;
  final List<String> ingredients;
  final List<String> allergens;
  final String? imageUrl;

  const NutritionDetailPage({
    super.key,
    required this.foodName,
    required this.servingSize,
    required this.nutritionInfo,
    required this.ingredients,
    required this.allergens,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '餐點詳細資訊',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 食物圖片
            if (imageUrl != null) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B9A7A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF8B9A7A),
                      child: const Icon(
                        Icons.fastfood,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 食物名稱
            _buildInfoSection(
              '食物名稱 / Food Name',
              foodName,
            ),

            // 份量
            _buildInfoSection(
              '份量 / Serving Size (g)',
              '${servingSize}g',
            ),

            // 營養素資訊
            _buildNutritionSection(),

            // 食材來源/烹調方式
            _buildInfoSection(
              '食材來源/烹調方式 / Ingredients & Preparation',
              ingredients.join(', '),
            ),

            // 過敏原
            _buildAllergensSection(),

            // 營養師評估/建議
            _buildInfoSection(
              '營養師評估/建議 / Dietitian\'s Assessment/Recommendations',
              '', // 空白區域，可以根據需要填入內容
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '營養素資訊 / Nutrition Info',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // 營養素網格
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 16,
            children: [
              _buildNutritionItem(
                  '卡路里 / Calories', '${nutritionInfo.calories}卡路里'),
              _buildNutritionItem('蛋白質 / Protein', '${nutritionInfo.protein}克'),
              _buildNutritionItem(
                  '碳水化合物 / Carbohydrates', '${nutritionInfo.carbohydrates}克'),
              _buildNutritionItem('脂肪 / Fat', '${nutritionInfo.fat}克'),
              _buildNutritionItem(
                  '膳食纖維 / Dietary Fiber', '${nutritionInfo.fiber}克'),
              _buildNutritionItem('糖 / Sugar', '${nutritionInfo.sugar}克'),
              _buildNutritionItem('鈉 / Sodium', '${nutritionInfo.sodium}毫克'),
              _buildNutritionItem(
                  '膽固醇 / Cholesterol', '${nutritionInfo.cholesterol}毫克'),
              _buildNutritionItem(
                  '維生素A / Vitamin A', '${nutritionInfo.vitaminA}微克'),
              _buildNutritionItem(
                  '維生素C / Vitamin C', '${nutritionInfo.vitaminC}毫克'),
              _buildNutritionItem('鈣 / Calcium', '${nutritionInfo.calcium}毫克'),
              _buildNutritionItem('鐵 / Iron', '${nutritionInfo.iron}毫克'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildAllergensSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '過敏原 / Allergens',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergens
                .map((allergen) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Text(
                        allergen,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// 營養資訊數據類
class NutritionInfo {
  final int calories;
  final int protein;
  final int carbohydrates;
  final int fat;
  final int fiber;
  final int sugar;
  final int sodium;
  final int cholesterol;
  final int vitaminA;
  final int vitaminC;
  final int calcium;
  final int iron;

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.cholesterol,
    required this.vitaminA,
    required this.vitaminC,
    required this.calcium,
    required this.iron,
  });
}

// 使用範例
class ExampleUsage extends StatelessWidget {
  const ExampleUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return NutritionDetailPage(
      foodName: "健康蔬食碗",
      servingSize: 250,
      nutritionInfo: NutritionInfo(
        calories: 350,
        protein: 25,
        carbohydrates: 15,
        fat: 20,
        fiber: 5,
        sugar: 5,
        sodium: 200,
        cholesterol: 50,
        vitaminA: 100,
        vitaminC: 15,
        calcium: 100,
        iron: 2,
      ),
      ingredients: ["有機蔬菜", "全穀物", "植物蛋白", "橄欖油"],
      allergens: [
        "花生 / Peanuts",
        "牛奶 / Milk",
        "蛋 / Eggs",
        "麩質 / Gluten",
        "大豆 / Soy",
        "堅果 / Tree Nuts",
        "魚 / Fish",
        "甲殼類 / Shellfish"
      ],
      imageUrl: "https://example.com/food-image.jpg",
    );
  }
}
// ----- [pages/diary/food_diary_page.dart] 結束 -----

// ====================================================================
// 相機頁面 (Camera Screen)
// ====================================================================
/*
模組化建議：【頁面模組 - pages/camera/camera_screen.dart】
CameraScreen 和 _CameraScreenState 是核心的相機功能模組。
包含相機控制、拍照、圖像處理等複雜邏輯，適合獨立成為相機模組。
可能需要額外的子模組：
- widgets/camera_controls.dart (相機控制元件)
- utils/image_processing.dart (圖像處理工具)
*/

// ----- [pages/camera/camera_screen.dart] 開始 -----
// 相機螢幕頁面 - 提供食物拍攝功能，支援前後鏡頭切換、閃光燈控制和圖庫選取
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

// 相機頁面狀態類別 (Camera Screen State Class)
class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  // 相機控制相關變數 (Camera Control Variables)
  CameraController? _controller; // 相機控制器
  List<CameraDescription>? cameras; // 可用相機列表
  bool _isInitialized = false; // 相機是否已初始化
  bool _isFlashOn = false; // 閃光燈是否開啟
  bool _hasError = false; // 是否有錯誤發生
  String _errorMessage = ''; // 錯誤訊息
  final ImagePicker _picker = ImagePicker(); // 圖片選擇器

  // 設備方向檢測相關變數 (Device Orientation Detection Variables)
  bool _isDeviceLandscape = false; // 設備是否處於橫向
  bool _isDevicePortraitUp = true; // 檢測是否為正常豎螢幕（長邊在上）
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription; // 加速度計訂閱

  // 容積計算相關變數 (Volume Calculation Variables)
  bool _isVolumeMode = false; // 是否處於容積計算模式
  List<Offset> _detectedEdges = []; // 檢測到的邊緣座標點
  double _calculatedVolume = 0.0; // 計算出的容積
  String _containerShape = '長方體'; // 容器形狀類型
  bool _showVolumeResult = false; // 是否顯示容積結果

  // 容器尺寸輸入變數 (Container Dimension Input Variables)
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  // 參考物體測量相關變數 (Reference Object Measurement Variables)
  final MeasurementMethod _selectedMeasurementMethod =
      MeasurementMethod.automatic; // 選中的測量方法
  MeasurementMode _currentMeasurementMode =
      MeasurementMode.calibration; // 當前測量模式
  bool _isInMeasurementMode = false; // 是否處於測量模式
  String? _capturedImagePath; // 已拍攝的照片路徑

  // 校準相關變數
  ReferenceObject? _selectedReferenceObject; // 選中的參考物體
  Offset? _referenceStartPoint; // 參考線起點
  Offset? _referenceEndPoint; // 參考線終點
  final double _measurementScale = 1.0; // 測量比例 (像素/厘米)
  final bool _isCalibrated = false; // 是否已校準

  // 測量繪圖相關變數
  final List<MeasurementPoint> _measurementPoints = []; // 測量點列表

  // 可拖拽測量框架相關變數
  double _framePosX = 50.0; // 測量框架X位置 (將在initState中重新計算)
  double _framePosY = 100.0; // 測量框架Y位置 (將在initState中重新計算)
  final double _frameWidth = 200.0; // 測量框架寬度
  final double _frameHeight = 150.0; // 測量框架高度
  bool _showMeasurementFrame = true; // 是否顯示測量框架

  // 邊界檢查常數
  static const double _BOTTOM_SAFE_ZONE = 250.0; // 底部安全區域
  static const double _TOP_SAFE_ZONE = 100.0; // 頂部安全區域
  static const double _SIDE_MARGIN = 15.0; // 左右邊距
  static const double _MIN_FRAME_SIZE = 80.0; // 最小框架尺寸
  List<MeasurementResult> _measurementResults = []; // 測量結果列表
  final bool _isDragging = false; // 是否正在拖拽
  int? _draggedPointIndex; // 被拖拽點的索引

  // 自定義參考物體尺寸控制器
  final TextEditingController _customWidthController = TextEditingController();

  // RAG 測試數據相關變數 (RAG Test Data Variables)
  ContainerAnalysisData? _testAnalysisData; // 測試用的分析數據
  final bool _showTestData = false; // 是否顯示測試數據
  Timer? _testDataTimer; // 測試數據更新計時器
  final TextEditingController _customHeightController = TextEditingController();

  /// 初始化相機頁面狀態 - 設定觀察器、螢幕方向並啟動相機
  @override
  void initState() {
    super.initState();
    // 註冊應用程式生命週期觀察器：監聽應用程式前景/背景狀態變化
    WidgetsBinding.instance.addObserver(this);

    // 鎖定豎螢幕：確保相機介面在豎屏模式下使用
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // 初始化相機：請求權限並設定相機控制器
    _initializeCamera();

    // 初始化測試數據：為 RAG 系統準備示例數據
    _initializeTestData();

    // 開始設備方向檢測：使用加速度計監測設備旋轉
    _startOrientationDetection();

    // 延遲初始化測量框架位置，等待widget構建完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMeasurementFramePosition();
    });
  }

  /// 初始化測量框架位置 - 將框架置中在相機預覽有效區域
  void _initializeMeasurementFramePosition() {
    if (!mounted) return;

    // 獲取螢幕尺寸
    final Size screenSize = MediaQuery.of(context).size;

    // 計算有效相機預覽區域（扣除頂部和底部安全區域）
    final double availableWidth = screenSize.width - (2 * _SIDE_MARGIN);
    final double availableHeight =
        screenSize.height - _TOP_SAFE_ZONE - _BOTTOM_SAFE_ZONE;

    // 計算居中位置
    final double centerX = (availableWidth - _frameWidth) / 2 + _SIDE_MARGIN;
    final double centerY =
        (availableHeight - _frameHeight) / 2 + _TOP_SAFE_ZONE;

    setState(() {
      _framePosX = centerX.clamp(
          _SIDE_MARGIN, screenSize.width - _frameWidth - _SIDE_MARGIN);
      _framePosY = centerY.clamp(
          _TOP_SAFE_ZONE, screenSize.height - _BOTTOM_SAFE_ZONE - _frameHeight);
    });

    print(
        '測量框架已初始化至居中位置: (${_framePosX.toStringAsFixed(1)}, ${_framePosY.toStringAsFixed(1)})');
  }

  /// 清理資源方法 - 移除觀察器、取消訂閱並釋放相機資源
  @override
  void dispose() {
    // 移除應用程式生命週期觀察器
    WidgetsBinding.instance.removeObserver(this);

    // 取消加速度計訂閱：停止方向檢測以節省電池
    _accelerometerSubscription?.cancel();

    // 釋放相機控制器：釋放相機硬體資源
    _controller?.dispose();

    // 恢復方向設定：允許其他頁面使用所有螢幕方向
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, // 正向直立
      DeviceOrientation.portraitDown, // 倒向直立
      DeviceOrientation.landscapeLeft, // 左側橫向
      DeviceOrientation.landscapeRight, // 右側橫向
    ]);

    // 呼叫父類別的 dispose 方法
    super.dispose();
  }

  // ====================================================================
  // 方向檢測功能 (Orientation Detection Function)
  // ====================================================================
  void _startOrientationDetection() {
    try {
      // 訂閱加速度計數據流，用於實時檢測設備物理方向
      _accelerometerSubscription = accelerometerEvents.listen(
        (AccelerometerEvent event) {
          if (!mounted) return; // 確保組件仍然掛載

          // 步驟1：獲取加速度計三軸數據
          // x軸: 左右傾斜, y軸: 前後傾斜, z軸: 上下
          double x = event.x;
          double y = event.y;

          // 步驟2：判斷設備是否橫向持握
          // 當x軸絕對值大於y軸且超過閾值3.0時，判定為橫螢幕
          bool isLandscape = x.abs() > y.abs() && x.abs() > 3.0;

          // 步驟3：判斷是否為正常豎螢幕
          // 當不是橫螢幕且y軸負值小於-2.0時，判定為正常豎螢幕（重力向下）
          bool isPortraitUp = !isLandscape && y < -2.0;

          // 步驟4：檢查狀態是否需要更新
          bool needsUpdate = false;
          if (isLandscape != _isDeviceLandscape) {
            _isDeviceLandscape = isLandscape;
            needsUpdate = true;
          }

          if (isPortraitUp != _isDevicePortraitUp) {
            _isDevicePortraitUp = isPortraitUp;
            needsUpdate = true;
          }

          // 步驟5：如果方向有變化，記錄並更新UI
          if (needsUpdate) {
            log('方向檢測: 橫螢幕=$_isDeviceLandscape, 正常豎螢幕=$_isDevicePortraitUp (x=$x, y=$y)');
            setState(() {
              // UI 更新，日誌已在上方記錄
            });
          }
        },
        onError: (error) {
          log('加速度計錯誤: $error');
          setState(() {
            _isDeviceLandscape = false;
            _isDevicePortraitUp = true;
          });
        },
      );
    } catch (e) {
      log('加速度計初始化失敗: $e');
    }
  }

  // ====================================================================
  // 權限處理函數 (Permission Handling Functions)
  // ====================================================================
  // 只檢查相機權限，在相機初始化時調用
  Future<bool> _requestCameraPermission() async {
    try {
      // 只檢查並請求相機權限
      PermissionStatus cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        cameraStatus = await Permission.camera.request();
      }

      // 驗證相機權限狀態
      if (cameraStatus.isDenied) {
        setState(() {
          _hasError = true;
          _errorMessage = '需要相機權限才能使用拍照功能\n請點擊允許以繼續';
        });
        return false;
      }

      if (cameraStatus.isPermanentlyDenied) {
        await _showPermissionDialog('相機');
        return false;
      }

      return cameraStatus.isGranted;
    } catch (e) {
      log('權限請求錯誤: $e'); // 記錄錯誤詳情
      setState(() {
        _hasError = true;
        _errorMessage = '權限請求失敗，請重新嘗試';
      });
      return false; // 發生異常，返回失敗
    }
  }

  Future<void> _requestAndInitializeCamera() async {
    try {
      // 重置錯誤狀態
      if (mounted) {
        setState(() {
          _hasError = false;
          _errorMessage = '';
        });
      }

      // 只請求相機權限
      final cameraResult = await Permission.camera.request();

      // 檢查相機權限結果
      if (cameraResult.isDenied) {
        setState(() {
          _hasError = true;
          _errorMessage = '需要相機權限才能使用拍照功能\n請點擊「重新嘗試」並允許權限';
        });
        return;
      }

      if (cameraResult.isPermanentlyDenied) {
        await _showPermissionDialog('相機');
        return;
      }

      // 繼續初始化相機（只要相機權限即可開始預覽）
      await _initializeCameraDevice();
    } catch (e) {
      log('權限請求錯誤: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '權限請求失敗：${e.toString()}';
        });
      }
    }
  }

  // ====================================================================
  // 相機初始化函數 (Camera Initialization Function)
  // ====================================================================
  Future<void> _initializeCamera() async {
    try {
      // 步驟1：只請求相機權限
      final hasPermissions = await _requestCameraPermission();
      if (!hasPermissions) {
        return; // 相機權限未獲得，終止初始化
      }

      // 步驟2：初始化相機設備
      await _initializeCameraDevice();
    } catch (e) {
      log('相機初始化錯誤: $e'); // 記錄錯誤到日誌
      if (mounted) {
        // 根據錯誤類型設定不同的錯誤訊息
        String errorMsg = '相機初始化失敗';
        if (e.toString().contains('permission')) {
          errorMsg = '沒有相機權限，請點擊重新嘗試以授權';
        }
        setState(() {
          _hasError = true;
          _errorMessage = errorMsg;
        });
      }
    }
  }

  // 相機設備初始化函數 (Camera Device Initialization Function)
  Future<void> _initializeCameraDevice() async {
    try {
      // 步驟1：檢查系統中可用的相機設備
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = '未找到可用的相機設備';
        });
        return; // 沒有相機設備，終止初始化
      }

      // 步驟2：創建相機控制器
      _controller = CameraController(
        cameras![0], // 使用第一個相機（通常是後置鏡頭）
        ResolutionPreset.high, // 設定高畫質
        enableAudio: false, // 不啟用音訊錄製
      );

      // 步驟3：初始化相機控制器
      await _controller!.initialize();

      // 步驟4：更新UI狀態（僅在組件仍然掛載時）
      if (mounted) {
        setState(() {
          _isInitialized = true; // 標記為已初始化
          _hasError = false; // 清除錯誤狀態
        });
      }
    } catch (e) {
      log('相機設備初始化錯誤: $e'); // 記錄詳細錯誤信息
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '相機設備初始化失敗：${e.toString()}';
        });
      }
    }
  }

  /// 初始化 RAG 系統測試數據
  void _initializeTestData() {
    // 創建模擬的容器分析數據，用於測試 RAG 系統
    _testAnalysisData = ContainerAnalysisData(
      imagePath: '/data/user/0/app_flutter/test_container.jpg',
      timestamp: DateTime.now().toIso8601String(),
      container: ContainerInfo(
        shape: '圓柱體',
        material: '塑膠',
        color: '透明',
        features: ['密封蓋', '測量刻度', '防滑底部'],
      ),
      measurements: MeasurementResults(
        volume: 450.75,
        confidence: 0.85,
        method: '智能視覺測量',
        dimensions: {
          '直徑': 8.2,
          '高度': 12.5,
          '底部厚度': 0.8,
        },
      ),
      metadata: AnalysisMetadata(
        deviceModel: 'RMX3867',
        appVersion: '1.0.0',
        processingTime: 2.3,
        settings: {
          '分辨率': 'HIGH',
          '閃光燈': false,
          '對焦模式': 'AUTO',
          'ISO': 'AUTO',
        },
      ),
    );

    // 設置定時器，每5秒更新一次測試數據（模擬即時分析）
    _testDataTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _updateTestData();
      }
    });
  }

  /// 更新測試數據（模擬即時分析結果變化）
  void _updateTestData() {
    if (_testAnalysisData != null && mounted) {
      // 隨機生成新的容積值（在基準值附近波動）
      final random = math.Random();
      final baseVolume = 450.0;
      final newVolume = baseVolume + (random.nextDouble() - 0.5) * 50.0;
      final newConfidence = 0.75 + random.nextDouble() * 0.2;

      // 創建新的測量結果
      final newMeasurements = MeasurementResults(
        volume: double.parse(newVolume.toStringAsFixed(2)),
        confidence: double.parse(newConfidence.toStringAsFixed(2)),
        method: '智能視覺測量',
        dimensions: {
          '直徑': 8.0 + random.nextDouble() * 0.5,
          '高度': 12.0 + random.nextDouble(),
          '底部厚度': 0.7 + random.nextDouble() * 0.2,
        },
      );

      // 更新分析數據
      setState(() {
        _testAnalysisData = ContainerAnalysisData(
          imagePath: _testAnalysisData!.imagePath,
          timestamp: DateTime.now().toIso8601String(),
          container: _testAnalysisData!.container,
          measurements: newMeasurements,
          metadata: AnalysisMetadata(
            deviceModel: _testAnalysisData!.metadata.deviceModel,
            appVersion: _testAnalysisData!.metadata.appVersion,
            processingTime: 1.5 + random.nextDouble() * 2.0,
            settings: _testAnalysisData!.metadata.settings,
          ),
        );
      });
    }
  }

  /// 生成 RAG 系統數據，先傳到 Flask 再存到 Firebase
  Future<void> _generateRagData(String imagePath, double volume) async {
    try {
      // 創建容器分析數據
      final ragData = ContainerAnalysisData(
        imagePath: imagePath,
        timestamp: DateTime.now().toIso8601String(),
        container: ContainerInfo(
          shape: _containerShape,
          material: '推測材質',
          color: '推測顏色',
          features: ['自動檢測特徵'],
        ),
        measurements: MeasurementResults(
          volume: volume,
          confidence: 0.85,
          method: '智能視覺測量',
          dimensions: {
            '長度': 10.0,
            '寬度': 8.0,
            '高度': 12.0,
          },
        ),
        metadata: AnalysisMetadata(
          deviceModel: 'RMX3867',
          appVersion: '1.0.0',
          processingTime: 2.1,
          settings: {
            '分辨率': 'HIGH',
            '閃光燈': _isFlashOn,
            '檢測方法': '邊緣檢測',
          },
        ),
      );

      // 轉換為 JSON
      final jsonData = ragData.toJson();

      // 步驟1: 先傳送到 Flask 後端
      await _sendRagDataToFlask(jsonData);

      // 步驟2: 再存儲到 Firebase Firestore
      await _saveToFirestore(ragData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('數據處理失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 傳送 RAG 數據到 Flask 後端
  Future<void> _sendRagDataToFlask(Map<String, dynamic> ragData) async {
    try {
      // Flask 後端 URL - 您需要根據實際部署修改這個 URL
      const String flaskUrl =
          'http://localhost:5000/api/rag/container-analysis';

      final response = await http
          .post(
            Uri.parse(flaskUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(ragData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Flask 傳送成功，不顯示訊息避免干擾用戶
      } else {
        // 只在錯誤時顯示訊息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Flask 後端回應錯誤: ${response.statusCode}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Flask 連接失敗時顯示訊息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('無法連接到 Flask 後端'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 將 RAG 數據存儲到 Firebase Firestore
  Future<void> _saveToFirestore(ContainerAnalysisData ragData) async {
    try {
      // 取得 Firestore 實例
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // 創建文檔 ID（使用時間戳）
      String docId = DateTime.now().millisecondsSinceEpoch.toString();

      // 將數據存儲到 'container_measurements' 集合
      await firestore
          .collection('container_measurements')
          .doc(docId)
          .set(ragData.toJson());

      // 顯示成功訊息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 測量數據已成功保存到 Firebase'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // 如果 Firebase 保存失敗，顯示錯誤但不中斷流程
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Firebase 保存失敗: $e'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showPermissionDialog(String permissionName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('需要$permissionName權限'),
          content: Text('此應用需要$permissionName權限才能正常運作。請在設置中手動開啟權限。'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('去設置'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // ====================================================================
  // 拍照功能函數 (Take Picture Function)
  // ====================================================================
  Future<void> _takePicture() async {
    await log('_takePicture 函數開始執行'); // 記錄函數開始執行

    try {
      await log('=== 開始新的權限請求流程 ===');

      // 步驟1：檢查相機權限（必需）
      await log('檢查相機權限狀態...');
      PermissionStatus currentCameraStatus = await Permission.camera.status;
      await log('當前相機權限狀態: $currentCameraStatus');

      // 如果相機權限未授權，先請求相機權限
      if (!currentCameraStatus.isGranted) {
        await log('請求相機權限...');
        PermissionStatus cameraResult = await Permission.camera.request();
        await log('相機權限請求結果: $cameraResult');

        if (cameraResult.isPermanentlyDenied) {
          await log('相機權限被永久拒絕，引導到設置');
          await _showPermissionDialog('相機');
          return;
        }

        if (cameraResult.isDenied) {
          await log('相機權限被拒絕');
          await _showPermissionDialog('相機');
          return;
        }
      }

      // 步驟2：檢查拍照存檔所需權限（智能檢查）
      await log('=== 開始拍照前的存儲權限檢查 ===');

      bool hasStoragePermission = false;

      // 優先檢查照片權限 (Android 13+)
      try {
        PermissionStatus photosStatus = await Permission.photos.status;
        await log('照片權限狀態: $photosStatus');

        if (photosStatus.isGranted) {
          hasStoragePermission = true;
          await log('照片權限已授權');
        } else if (!photosStatus.isPermanentlyDenied) {
          // 嘗試請求照片權限
          photosStatus = await Permission.photos.request();
          if (photosStatus.isGranted) {
            hasStoragePermission = true;
            await log('照片權限請求成功');
          }
        }
      } catch (e) {
        await log('照片權限檢查失敗: $e');
      }

      // 如果照片權限不可用，檢查傳統存儲權限
      if (!hasStoragePermission) {
        try {
          PermissionStatus storageStatus = await Permission.storage.status;
          await log('存儲權限狀態: $storageStatus');

          if (storageStatus.isGranted) {
            hasStoragePermission = true;
            await log('存儲權限已授權');
          } else if (!storageStatus.isPermanentlyDenied) {
            // 嘗試請求存儲權限
            storageStatus = await Permission.storage.request();
            if (storageStatus.isGranted) {
              hasStoragePermission = true;
              await log('存儲權限請求成功');
            }
          }
        } catch (e) {
          await log('存儲權限檢查失敗: $e');
        }
      }

      // 如果沒有任何存儲權限，顯示提示但不阻止拍照
      if (!hasStoragePermission) {
        await log('沒有存儲權限，將保存到應用內部目錄');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('將保存照片到應用內部目錄'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await log('拍照權限檢查完成，開始拍照...');

      // 如果有相機控制器且已初始化，才進行拍照
      if (_controller != null && _controller!.value.isInitialized) {
        await log('開始執行拍照邏輯...');

        // 先保存到應用程式目錄（確保基本功能正常）
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = path.join(
          directory.path,
          '${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        final XFile image = await _controller!.takePicture();
        await image.saveTo(imagePath);

        await log('照片已保存到: ${path.basename(imagePath)}');

        try {
          // 嘗試複製到相簿（如果失敗不影響基本功能）
          await log('開始嘗試保存到相簿...');
          final imageBytes = await image.readAsBytes();
          await log('圖片資料讀取完成，大小: ${imageBytes.length} bytes');

          try {
            // 使用 ImageGallerySaver 的正確方式 (簡化版本)
            final result = await ImageGallerySaver.saveImage(imageBytes);

            // 簡化的結果檢查
            if (result != null && result['isSuccess'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ 照片已成功保存到相簿！'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('⚠️ 照片保存失敗: ${result?['errorMessage'] ?? '未知錯誤'}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } catch (e) {
            await log('❌ 相簿保存失敗: $e');
          }
        } catch (e, stackTrace) {
          await log('❌ 相簿保存發生例外: $e');
          await log('詳細錯誤堆疊: $stackTrace');
        }

        // 拍照成功，跳轉到營養標籤確認頁面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NutritionLabelScreen(
              imagePath: imagePath,
              onRetakePhoto: () {
                Navigator.of(context).pop(); // 關閉營養標籤頁面，回到相機頁面
              },
              onSelectFromGallery: () async {
                Navigator.of(context).pop(); // 先關閉營養標籤頁面
                await _selectImageFromGallery(); // 選擇相簿圖片
              },
            ),
          ),
        );
      } else {
        await log('相機尚未初始化完成，請稍後再試');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('相機尚未初始化完成，請稍後再試'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      await log('拍照錯誤: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('拍照失敗: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 容積計算模式下的拍照功能
  Future<void> _takeVolumePhoto() async {
    if (!_controller!.value.isInitialized) return;

    try {
      await log('開始容積計算拍照...');

      // 拍照
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = path.join(
        directory.path,
        'volume_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final XFile image = await _controller!.takePicture();
      await image.saveTo(imagePath);

      // 保存照片到相簿，供後續YOLO處理使用
      try {
        final imageBytes = await image.readAsBytes();
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          name: 'volume_${DateTime.now().millisecondsSinceEpoch}',
          quality: 100,
        );

        if (result != null && result['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 容積計算照片已保存到相簿'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          await log('✅ 容積計算照片已保存到相簿: ${result['filePath']}');
        } else {
          await log('⚠️ 容積計算照片保存失敗: ${result?['errorMessage']}');
        }
      } catch (e) {
        await log('保存容積計算照片到相簿失敗: $e');
      }

      // 立即進行邊緣檢測和容積計算
      await _performAutoVolumeCalculation(imagePath);
    } catch (e) {
      await log('容積計算拍照錯誤: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('拍照失敗: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 智慧拍照方法 - 自動嘗試兩種測量方式並選擇最佳結果
  Future<void> _takeSmartVolumePhoto() async {
    if (!_controller!.value.isInitialized) return;

    try {
      await log('開始智慧容積測量拍照...');

      // 拍照前隱藏測量框
      setState(() {
        _showMeasurementFrame = false;
      });

      // 拍照
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = path.join(
        directory.path,
        'smart_volume_$timestamp.jpg',
      );

      final XFile image = await _controller!.takePicture();
      await image.saveTo(imagePath);

      // 保存照片到相簿，供後續YOLO處理使用
      try {
        final imageBytes = await image.readAsBytes();
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          name: 'smart_volume_${DateTime.now().millisecondsSinceEpoch}',
          quality: 100,
        );

        if (result != null && result['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 智慧測量照片已保存到相簿'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          await log('✅ 智慧測量照片已保存到相簿: ${result['filePath']}');
        } else {
          await log('⚠️ 智慧測量照片保存失敗: ${result?['errorMessage']}');
        }
      } catch (e) {
        await log('保存智慧測量照片到相簿失敗: $e');
      }

      // 同時嘗試兩種測量方法並選擇最佳結果
      await _performSmartVolumeCalculation(imagePath);
    } catch (e) {
      await log('智慧拍照錯誤: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('拍照失敗: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // 計算完成後（無論成功或失敗）延遲重新顯示測量框
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showMeasurementFrame = true;
          });
        }
      });
    }
  }

  /// 執行智慧容積計算 - 自動選擇最適合的測量方式
  Future<void> _performSmartVolumeCalculation(String imagePath) async {
    await log('開始智慧容積計算分析...');

    // 方法1: 嘗試自動容積計算
    double autoVolume = 0.0;
    bool autoSuccess = false;

    try {
      await log('嘗試方法1: 自動容積計算');
      await _performAutoVolumeCalculation(imagePath);
      autoVolume = _calculatedVolume;
      autoSuccess = _calculatedVolume > 0;
      await log('自動計算結果: $_calculatedVolume cm³, 成功: $autoSuccess');
    } catch (e) {
      await log('自動計算失敗: $e');
    }

    // 方法2: 嘗試參考物體測量
    double referenceVolume = 0.0;
    bool referenceSuccess = false;

    try {
      await log('嘗試方法2: 參考物體智慧識別');
      referenceVolume = await _performAutomaticReferenceDetection(imagePath);
      referenceSuccess = referenceVolume > 0;
      await log('參考物體計算結果: $referenceVolume cm³, 成功: $referenceSuccess');
    } catch (e) {
      await log('參考物體計算失敗: $e');
    }

    // 選擇最佳結果
    await _selectBestMeasurementResult(
        autoVolume, autoSuccess, referenceVolume, referenceSuccess);
  }

  /// 自動參考物體檢測和測量
  Future<double> _performAutomaticReferenceDetection(String imagePath) async {
    // 這裡實作自動檢測常見參考物體的邏輯
    // 例如：硬幣、信用卡、常見物品等

    await log('分析照片中的參考物體...');

    // 模擬檢測到參考物體（實際應用中這裡會有圖像處理邏輯）
    // 假設檢測到一個50元硬幣（直徑2.5cm）
    final detectedObjects = await _detectReferenceObjects(imagePath);

    if (detectedObjects.isNotEmpty) {
      final bestReference = detectedObjects.first;
      await log('檢測到參考物體: ${bestReference.name}');

      // 基於檢測到的參考物體計算容積
      return await _calculateVolumeWithReference(imagePath, bestReference);
    }

    await log('未檢測到合適的參考物體');
    return 0.0;
  }

  /// 檢測照片中的參考物體
  Future<List<ReferenceObject>> _detectReferenceObjects(
      String imagePath) async {
    // 這裡應該實作圖像識別邏輯
    // 目前簡化為返回一個假設的檢測結果

    await log('正在分析照片中的物體...');

    // 模擬檢測結果 - 實際應用中會使用機器學習模型
    final List<ReferenceObject> detectedObjects = [];

    // 假設檢測到台幣50元硬幣的機率較高
    if (math.Random().nextDouble() > 0.3) {
      // 70%機率檢測到
      detectedObjects.add(ReferenceObjectDatabase.coins['NT_50']!);
      await log('檢測到: 50元硬幣');
    }

    return detectedObjects;
  }

  /// 使用檢測到的參考物體計算容積
  Future<double> _calculateVolumeWithReference(
      String imagePath, ReferenceObject reference) async {
    await log('使用${reference.name}作為參考計算容積...');

    // 這裡應該實作基於參考物體的精確測量
    // 目前簡化為一個基於參考物體的估算

    // 模擬基於參考物體的測量結果
    final estimatedVolume =
        800 + math.Random().nextDouble() * 800; // 800-1600 cm³

    await log(
        '基於${reference.name}計算得出容積: ${estimatedVolume.toStringAsFixed(2)} cm³');
    return estimatedVolume;
  }

  /// 選擇最佳測量結果
  Future<void> _selectBestMeasurementResult(double autoVolume, bool autoSuccess,
      double referenceVolume, bool referenceSuccess) async {
    String selectedMethod = '';
    double finalVolume = 0.0;

    if (autoSuccess && referenceSuccess) {
      // 兩種方法都成功，選擇更可靠的結果
      final difference = (autoVolume - referenceVolume).abs();
      final averageVolume = (autoVolume + referenceVolume) / 2;
      final differencePercentage = difference / averageVolume * 100;

      if (differencePercentage < 20) {
        // 結果相近，取平均值
        finalVolume = averageVolume;
        selectedMethod = '混合測量（自動+參考）';
        await log('兩種方法結果相近，使用平均值: ${finalVolume.toStringAsFixed(2)} cm³');
      } else {
        // 結果差異較大，選擇參考物體測量（通常更準確）
        finalVolume = referenceVolume;
        selectedMethod = '參考物體測量';
        await log('選擇參考物體測量結果: ${finalVolume.toStringAsFixed(2)} cm³');
      }
    } else if (autoSuccess) {
      finalVolume = autoVolume;
      selectedMethod = '自動容積測量';
      await log('使用自動測量結果: ${finalVolume.toStringAsFixed(2)} cm³');
    } else if (referenceSuccess) {
      finalVolume = referenceVolume;
      selectedMethod = '參考物體測量';
      await log('使用參考物體測量結果: ${finalVolume.toStringAsFixed(2)} cm³');
    } else {
      // 都失敗，使用預設值
      finalVolume = 1000.0;
      selectedMethod = '估算值';
      await log('兩種測量都失敗，使用估算值: ${finalVolume.toStringAsFixed(2)} cm³');
    }

    // 更新UI顯示結果
    setState(() {
      _calculatedVolume = finalVolume;
      _containerShape = selectedMethod;
      _showVolumeResult = false; // 不顯示界面結果區域，避免按鍵移位
    });

    await log(
        '智慧測量完成: $selectedMethod - ${finalVolume.toStringAsFixed(2)} cm³');

    // 顯示結果通知
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '容積測量完成: ${finalVolume.toStringAsFixed(2)} cm³ ($selectedMethod)',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    // 生成 RAG 系統數據
    try {
      await _generateRagData('智慧測量照片', finalVolume);
    } catch (e) {
      await log('RAG 數據生成失敗: $e');
    }
  }

  /// 開始參考物體測量流程
  Future<void> _startReferenceMeasurement() async {
    if (!_controller!.value.isInitialized) return;

    try {
      await log('開始參考物體測量流程...');

      // 拍照
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = path.join(
        directory.path,
        'reference_measurement_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final XFile image = await _controller!.takePicture();
      await image.saveTo(imagePath);

      // 保存照片到相簿
      try {
        final imageBytes = await image.readAsBytes();
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          name:
              'reference_measurement_${DateTime.now().millisecondsSinceEpoch}',
          quality: 100,
        );

        if (result != null && result['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 參考測量照片已保存到相簿'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          await log('✅ 參考測量照片已保存到相簿: ${result['filePath']}');
        } else {
          await log('⚠️ 參考測量照片保存失敗: ${result?['errorMessage']}');
        }
      } catch (e) {
        await log('保存參考測量照片到相簿失敗: $e');
      }

      // 設置狀態並導航到測量頁面
      setState(() {
        _capturedImagePath = imagePath;
        _isInMeasurementMode = true;
        _currentMeasurementMode = MeasurementMode.calibration;
      });

      // 導航到參考物體測量頁面
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ReferenceMeasurementPage(
            imagePath: imagePath,
            onMeasurementComplete: _onMeasurementComplete,
          ),
        ),
      );
    } catch (e) {
      await log('參考物體測量拍照錯誤: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('拍照失敗: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 測量完成回調
  void _onMeasurementComplete(List<MeasurementResult> results) {
    setState(() {
      _measurementResults = results;
      _isInMeasurementMode = false;
    });

    // 顯示測量結果
    _showMeasurementResults(results);
  }

  /// 顯示測量結果對話框
  void _showMeasurementResults(List<MeasurementResult> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('測量結果'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: results
              .map((result) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(result.description),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('確定'),
          ),
        ],
      ),
    );
  }

  /// 自動執行容積計算流程
  Future<void> _performAutoVolumeCalculation(String imagePath) async {
    try {
      await log('開始自動容積計算流程...');

      // 1. 模擬圖像處理和邊緣檢測
      setState(() {
        _detectedEdges = _performEdgeDetection();
      });

      // 2. 自動辨識容器形狀
      final detectedShape = _detectContainerShape(_detectedEdges);
      setState(() {
        _containerShape = detectedShape;
      });

      // 3. 根據檢測到的邊緣估算尺寸（模擬）
      final estimatedDimensions = _estimateDimensionsFromEdges();

      // 4. 基於辨識的形狀自動計算容積
      final volume = _calculateVolumeFromDimensions(estimatedDimensions);

      setState(() {
        _calculatedVolume = volume;
        _showVolumeResult = false; // 不顯示界面結果區域，避免按鍵移位
      });

      await log('容積計算完成: ${volume.toStringAsFixed(2)} cm³');

      // 生成 RAG 系統數據
      await _generateRagData(imagePath, volume);

      // 4. 顯示結果
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '容積計算完成！\n${volume.toStringAsFixed(2)} cm³ (${(volume / 1000).toStringAsFixed(3)} L)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '查看詳細',
            textColor: Colors.white,
            onPressed: () => _showDetailedVolumeResult(),
          ),
        ),
      );
    } catch (e) {
      await log('自動容積計算錯誤: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('容積計算失敗: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 從檢測到的邊緣估算容器尺寸
  Map<String, double> _estimateDimensionsFromEdges() {
    if (_detectedEdges.length < 4) {
      return {'length': 10.0, 'width': 8.0, 'height': 12.0}; // 預設值
    }

    // 計算邊緣框的尺寸（簡化算法）
    double minX =
        _detectedEdges.map((e) => e.dx).reduce((a, b) => a < b ? a : b);
    double maxX =
        _detectedEdges.map((e) => e.dx).reduce((a, b) => a > b ? a : b);
    double minY =
        _detectedEdges.map((e) => e.dy).reduce((a, b) => a < b ? a : b);
    double maxY =
        _detectedEdges.map((e) => e.dy).reduce((a, b) => a > b ? a : b);

    // 將像素尺寸轉換為實際尺寸（假設比例）
    double pixelToCm = 0.05; // 假設 1 像素 = 0.05 公分

    double width = (maxX - minX) * pixelToCm;
    double height = (maxY - minY) * pixelToCm;
    double depth = width * 0.8; // 假設深度是寬度的80%

    return {
      'length': width,
      'width': depth,
      'height': height,
    };
  }

  /// 根據尺寸計算容積
  double _calculateVolumeFromDimensions(Map<String, double> dimensions) {
    switch (_containerShape) {
      case '長方體':
        return dimensions['length']! *
            dimensions['width']! *
            dimensions['height']!;

      case '圓柱體':
        double radius = dimensions['length']! / 2; // 假設直徑是檢測寬度
        return math.pi * radius * radius * dimensions['height']!;

      case '立方體':
        double side = (dimensions['length']! + dimensions['width']!) / 2; // 平均值
        return side * side * side;

      default:
        return 0.0;
    }
  }

  /// 顯示詳細的容積計算結果
  void _showDetailedVolumeResult() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.calculate, color: Colors.green),
              SizedBox(width: 8),
              Text('容積計算結果'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('容器形狀: $_containerShape',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('檢測到邊緣點: ${_detectedEdges.length} 個'),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    Text('計算結果',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                    SizedBox(height: 5),
                    Text('${_calculatedVolume.toStringAsFixed(2)} cm³',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(
                        '= ${(_calculatedVolume / 1000).toStringAsFixed(3)} 公升',
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('關閉'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearVolumeData(); // 重新測量
              },
              child: Text('重新測量'),
            ),
          ],
        );
      },
    );
  }

  // ====================================================================
  // 容積計算功能 (Volume Calculation Functions)
  // ====================================================================

  /// 切換容積計算模式
  void _toggleVolumeMode() {
    setState(() {
      _isVolumeMode = !_isVolumeMode;
      if (!_isVolumeMode) {
        _clearVolumeData();
      }
    });
  }

  /// 清除容積計算數據
  void _clearVolumeData() {
    setState(() {
      _detectedEdges.clear();
      _calculatedVolume = 0.0;
      _showVolumeResult = false;
    });
    _lengthController.clear();
    _widthController.clear();
    _heightController.clear();
    _radiusController.clear();
  }

  /// 測量框架位置更新方法 - 包含嚴格的邊界檢查
  void _updateMeasurementFramePosition(double deltaX, double deltaY) {
    // 獲取螢幕尺寸和安全區域
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    // 計算嚴格的邊界限制
    final double topLimit = safeArea.top + _TOP_SAFE_ZONE;
    final double bottomLimit =
        screenSize.height - _BOTTOM_SAFE_ZONE - _frameHeight;
    final double leftLimit = _SIDE_MARGIN;
    final double rightLimit = screenSize.width - _frameWidth - _SIDE_MARGIN;

    // 計算新位置
    double newX = _framePosX + deltaX;
    double newY = _framePosY + deltaY;

    // 應用邊界限制
    newX = newX.clamp(leftLimit, rightLimit);
    newY = newY.clamp(topLimit, bottomLimit);

    // 最終驗證：確保框架底部永遠不會超過安全區域
    final frameBottom = newY + _frameHeight;
    final maxAllowedBottom = screenSize.height - _BOTTOM_SAFE_ZONE;

    if (frameBottom > maxAllowedBottom) {
      newY = maxAllowedBottom - _frameHeight;
      print('🚨 強制限制：測量框架被限制在安全區域內');
    }

    // 更新位置
    _framePosX = newX;
    _framePosY = newY;

    // Debug輸出
    final actualBottom = _framePosY + _frameHeight;
    final distanceFromBottom = screenSize.height - actualBottom;

    print('📏 測量框架邊界檢查:');
    print('   螢幕尺寸: ${screenSize.width.toInt()}x${screenSize.height.toInt()}');
    print(
        '   SafeArea: top=${safeArea.top.toInt()}, bottom=${safeArea.bottom.toInt()}');
    print('   邊界限制: top=$topLimit, bottom=$bottomLimit');
    print(
        '   框架位置: (${_framePosX.toStringAsFixed(1)}, ${_framePosY.toStringAsFixed(1)})');
    print(
        '   框架底部: ${actualBottom.toStringAsFixed(1)} (距螢幕底部: ${distanceFromBottom.toStringAsFixed(1)}px)');
    print(
        '   安全狀態: ${distanceFromBottom >= _BOTTOM_SAFE_ZONE ? "✅ 安全" : "⚠️ 危險"}');
  }

  /// 初始化測量框架位置 - 確保在安全區域內
  // (已移除重複且未使用的 _initializeMeasurementFramePosition)

  /// 簡化的邊緣檢測（模擬）
  List<Offset> _performEdgeDetection() {
    // 簡化版邊緣檢測 - 模擬檢測到的容器邊緣點
    // 在實際應用中，這裡會使用圖像處理算法
    final screenSize = MediaQuery.of(context).size;
    return [
      Offset(screenSize.width * 0.2, screenSize.height * 0.3),
      Offset(screenSize.width * 0.8, screenSize.height * 0.3),
      Offset(screenSize.width * 0.8, screenSize.height * 0.7),
      Offset(screenSize.width * 0.2, screenSize.height * 0.7),
    ];
  }

  /// 計算容積 - 根據不同形狀計算體積
  double _calculateVolume() {
    try {
      switch (_containerShape) {
        case '長方體':
          final length = double.tryParse(_lengthController.text) ?? 0;
          final width = double.tryParse(_widthController.text) ?? 0;
          final height = double.tryParse(_heightController.text) ?? 0;
          return length * width * height;

        case '圓柱體':
          final radius = double.tryParse(_radiusController.text) ?? 0;
          final height = double.tryParse(_heightController.text) ?? 0;
          return math.pi * radius * radius * height;

        case '立方體':
          final side = double.tryParse(_lengthController.text) ?? 0;
          return side * side * side;

        default:
          return 0.0;
      }
    } catch (e) {
      return 0.0;
    }
  }

  /// 執行容積檢測和計算
  void _performVolumeCalculation() {
    setState(() {
      _detectedEdges = _performEdgeDetection();
      _calculatedVolume = _calculateVolume();
      _showVolumeResult = false; // 不顯示界面結果區域，避免按鍵移位
    });

    // 顯示結果通知
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('容積計算完成：${_calculatedVolume.toStringAsFixed(2)} 立方公分'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 自動辨識容器形狀
  String _detectContainerShape(List<Offset> edges) {
    if (edges.isEmpty) {
      return '未知形狀';
    }

    print('開始自動辨識容器形狀，邊緣點數: ${edges.length}');

    // 基於邊緣點數量和形狀特徵判斷容器類型
    if (edges.length >= 8) {
      // 多邊緣點，可能是長方體
      final aspectRatio = _calculateAspectRatio(edges);

      if (aspectRatio > 0.8 && aspectRatio < 1.2) {
        print('辨識為: 立方體 (長寬比: ${aspectRatio.toStringAsFixed(2)})');
        return '立方體';
      } else {
        print('辨識為: 長方體 (長寬比: ${aspectRatio.toStringAsFixed(2)})');
        return '長方體';
      }
    } else if (edges.length >= 4) {
      // 中等邊緣點，檢查是否為圓形特徵
      final roundness = _calculateRoundness(edges);

      if (roundness > 0.7) {
        print('辨識為: 圓柱體 (圓度: ${roundness.toStringAsFixed(2)})');
        return '圓柱體';
      } else {
        print('辨識為: 長方體 (圓度: ${roundness.toStringAsFixed(2)})');
        return '長方體';
      }
    } else {
      print('邊緣點太少，預設為: 長方體');
      return '長方體';
    }
  }

  /// 計算容器長寬比
  double _calculateAspectRatio(List<Offset> edges) {
    if (edges.isEmpty) return 1.0;

    double minX = edges.first.dx;
    double maxX = edges.first.dx;
    double minY = edges.first.dy;
    double maxY = edges.first.dy;

    for (final edge in edges) {
      minX = math.min(minX, edge.dx);
      maxX = math.max(maxX, edge.dx);
      minY = math.min(minY, edge.dy);
      maxY = math.max(maxY, edge.dy);
    }

    final width = maxX - minX;
    final height = maxY - minY;

    if (height == 0) return 1.0;
    return width / height;
  }

  /// 計算容器圓度（判斷是否為圓形）
  double _calculateRoundness(List<Offset> edges) {
    if (edges.length < 3) return 0.0;

    // 計算邊緣點的質心
    double centerX = 0;
    double centerY = 0;
    for (final edge in edges) {
      centerX += edge.dx;
      centerY += edge.dy;
    }
    centerX /= edges.length;
    centerY /= edges.length;

    final center = Offset(centerX, centerY);

    // 計算所有點到質心的距離
    final distances = edges
        .map((edge) => math.sqrt(
            math.pow(edge.dx - centerX, 2) + math.pow(edge.dy - centerY, 2)))
        .toList();

    if (distances.isEmpty) return 0.0;

    // 計算距離的標準差
    final meanDistance = distances.reduce((a, b) => a + b) / distances.length;
    final variance = distances
            .map((distance) => math.pow(distance - meanDistance, 2))
            .reduce((a, b) => a + b) /
        distances.length;
    final standardDeviation = math.sqrt(variance);

    // 圓度 = 1 - (標準差 / 平均距離)
    // 越接近1表示越圓
    final roundness = 1 - (standardDeviation / meanDistance);
    return math.max(0.0, roundness);
  }

  /// 顯示尺寸輸入對話框
  void _showDimensionInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('輸入$_containerShape尺寸 (公分)'),
          content: _buildDimensionInputs(),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performVolumeCalculation();
              },
              child: const Text('計算容積'),
            ),
          ],
        );
      },
    );
  }

  /// 根據選擇的形狀建立相應的尺寸輸入欄位
  Widget _buildDimensionInputs() {
    switch (_containerShape) {
      case '長方體':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _lengthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '長度',
                suffixText: 'cm',
              ),
            ),
            TextField(
              controller: _widthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '寬度',
                suffixText: 'cm',
              ),
            ),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '高度',
                suffixText: 'cm',
              ),
            ),
          ],
        );

      case '圓柱體':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _radiusController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '半徑',
                suffixText: 'cm',
              ),
            ),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '高度',
                suffixText: 'cm',
              ),
            ),
          ],
        );

      case '立方體':
        return TextField(
          controller: _lengthController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '邊長',
            suffixText: 'cm',
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _openGallery() async {
    try {
      // 直接開啟相簿，支援多選功能
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        await log('從相簿選擇了 ${images.length} 張圖片');

        if (images.length == 1) {
          // 如果只選擇了一張圖片，使用單張分析流程
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NutritionLabelScreen(
                imagePath: images.first.path,
                onRetakePhoto: () {
                  Navigator.of(context).pop(); // 關閉營養標籤頁面，回到相機頁面
                },
                onSelectFromGallery: () async {
                  Navigator.of(context).pop(); // 先關閉營養標籤頁面
                  await _openGallery(); // 重新選擇相簿圖片
                },
              ),
            ),
          );
        } else {
          // 如果選擇了多張圖片，使用批次分析流程
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MultiImageProcessingScreen(
                imagePaths: images.map((img) => img.path).toList(),
                onReturnToCamera: () {
                  Navigator.of(context).pop(); // 回到相機頁面
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      await log('選擇照片失敗: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('選擇照片失敗: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectImageFromGallery() async {
    await _openGallery(); // 複用現有的相簿選擇邏輯
  }

  void _toggleFlash() async {
    if (_controller != null) {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });

      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    }
  }

  void _switchCamera() async {
    if (!_isInitialized || cameras == null || cameras!.length <= 1) return;

    try {
      final newCamera =
          _controller!.description == cameras![0] ? cameras![1] : cameras![0];

      await _controller!.dispose();

      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      log('切換相機錯誤: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '切換相機失敗';
        });
      }
    }
  }

  // ====================================================================
  // UI建構函數 (UI Build Function)
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    // 步驟1：設定螢幕方向（拍照頁面鎖定為正常豎螢幕）
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // 步驟2：獲取螢幕尺寸和設備類型
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600; // 判斷是否為平板
    final isLargeScreen = screenSize.width > 900; // 判斷是否為大螢幕
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape; // 判斷系統方向

    // 步驟3：計算按鈕旋轉角度（根據設備實際物理方向決定）
    final double iconRotation = _isDeviceLandscape ? 90.0 : 0.0;
    logSync('按鈕旋轉角度: $_isDeviceLandscape -> $iconRotation度');

    // 步驟4：建構主要UI結構
    return Scaffold(
      backgroundColor: Colors.black, // 設定背景色為黑色
      body: Stack(
        children: [
          // 相機預覽或錯誤顯示
          if (_isInitialized)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _hasError = false;
                            _errorMessage = '';
                          });

                          // 主動請求所有權限並初始化相機
                          await _requestAndInitializeCamera();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('重新嘗試'),
                      ),
                      if (_errorMessage.contains('永久拒絕') ||
                          _errorMessage.contains('設定'))
                        const SizedBox(width: 16),
                      if (_errorMessage.contains('永久拒絕') ||
                          _errorMessage.contains('設定'))
                        ElevatedButton(
                          onPressed: () {
                            openAppSettings();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('開啟設定'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (!_isInitialized && !_hasError)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '正在初始化相機...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          // 頂部工具列
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + (isTablet ? 80 : 60),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 關閉按鈕
                    IconButton(
                      icon: Transform.rotate(
                        angle: iconRotation * math.pi / 180,
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: isTablet ? 32 : 28,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                    // 旋轉圖示 - 隨其他按鈕一起自動轉向
                    IconButton(
                      icon: Transform.rotate(
                        angle: iconRotation * math.pi / 180,
                        child: Icon(
                          Icons.screen_rotation,
                          color: Colors.orange,
                          size: isTablet ? 32 : 28,
                        ),
                      ),
                      onPressed: () {
                        // 移除手動測試功能，保留按鈕但不執行任何操作
                      },
                    ),

                    // 閃光燈按鈕
                    IconButton(
                      icon: Transform.rotate(
                        angle: iconRotation * math.pi / 180,
                        child: Icon(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                          size: isTablet ? 32 : 28,
                        ),
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 方向指示箭頭 (豎螢幕且長邊朝上時顯示)
          if (!_isDeviceLandscape && _isDevicePortraitUp)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '朝上',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 底部控制區域
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: 10,
                    top: isLandscape ? 10 : 20,
                    left: 20,
                    right: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 建議距離文字 (橫向模式下隱藏以節省空間)
                      if (!isLandscape)
                        Padding(
                          padding: EdgeInsets.only(bottom: 15),
                          child: Text(
                            '建議距離：20-30 公分',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: isTablet ? 16 : 14,
                            ),
                          ),
                        ),

                      // 底部按鈕列
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 相簿按鈕
                          GestureDetector(
                            onTap: _openGallery,
                            child: Container(
                              width: isTablet ? 60 : 50,
                              height: isTablet ? 60 : 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                shape: BoxShape.circle,
                              ),
                              child: Transform.rotate(
                                angle: iconRotation * math.pi / 180,
                                child: Icon(
                                  Icons.photo_library,
                                  color: Colors.white,
                                  size: isTablet ? 28 : 24,
                                ),
                              ),
                            ),
                          ),

                          // 智慧拍照按鈕
                          GestureDetector(
                            onTap: _takeSmartVolumePhoto,
                            child: Container(
                              width: isTablet ? 100 : 80,
                              height: isTablet ? 100 : 80,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Transform.rotate(
                                angle: iconRotation * math.pi / 180,
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: isTablet ? 40 : 32,
                                ),
                              ),
                            ),
                          ),

                          // 切換鏡頭按鈕
                          GestureDetector(
                            onTap: _switchCamera,
                            child: Container(
                              width: isTablet ? 60 : 50,
                              height: isTablet ? 60 : 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                shape: BoxShape.circle,
                              ),
                              child: Transform.rotate(
                                angle: iconRotation * math.pi / 180,
                                child: Icon(
                                  Icons.flip_camera_ios,
                                  color: Colors.white,
                                  size: isTablet ? 28 : 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (!isLandscape) SizedBox(height: 15),

                      // 容積計算控制界面 (拍照前設定)
                      if (!isLandscape) ...[
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          margin: const EdgeInsets.symmetric(horizontal: 30),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              // 自動辨識結果顯示
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.auto_awesome,
                                            color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          '辨識: $_containerShape',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '直接拍照，系統會自動辨識容器形狀並計算容積',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              // 顯示計算結果
                              if (_showVolumeResult) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.green, width: 1),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '計算結果',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${_calculatedVolume.toStringAsFixed(2)} cm³',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '(${(_calculatedVolume / 1000).toStringAsFixed(3)} 公升)',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 邊緣檢測疊加層（有檢測結果時顯示）
          if (_detectedEdges.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).size.height *
                  0.25, // 使用螢幕高度的25%作為底部安全區域
              child: CustomPaint(
                painter: EdgeDetectionPainter(_detectedEdges),
              ),
            ),

          // 可拖拽的紅色測量框架
          if (_showMeasurementFrame)
            Positioned(
              left: _framePosX,
              top: _framePosY,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final screenSize = MediaQuery.of(context).size;

                    // 使用預定義常數計算強化的安全區域
                    final double maxX =
                        screenSize.width - _frameWidth - _SIDE_MARGIN;
                    final double maxY =
                        screenSize.height - _BOTTOM_SAFE_ZONE - _frameHeight;
                    final double minX = _SIDE_MARGIN;
                    final double minY = _TOP_SAFE_ZONE;

                    // 計算新位置
                    double newX =
                        (_framePosX + details.delta.dx).clamp(minX, maxX);
                    double newY =
                        (_framePosY + details.delta.dy).clamp(minY, maxY);

                    // 多重安全檢查：確保測量框絕對不會覆蓋底部按鈕區域
                    final double frameBottom = newY + _frameHeight;
                    final double safeBottomLimit =
                        screenSize.height - _BOTTOM_SAFE_ZONE;

                    if (frameBottom > safeBottomLimit) {
                      newY = safeBottomLimit - _frameHeight;
                    }

                    // 最終邊界驗證
                    newX = newX.clamp(minX, maxX);
                    newY = newY.clamp(minY, maxY);

                    _framePosX = newX;
                    _framePosY = newY;

                    // Debug輸出檢查邊界
                    print(
                        '框架位置: (${newX.toStringAsFixed(1)}, ${newY.toStringAsFixed(1)}) 底部: ${(newY + _frameHeight).toStringAsFixed(1)} 安全限制: ${safeBottomLimit.toStringAsFixed(1)}');
                  });
                },
                child: Transform.rotate(
                  angle: iconRotation * math.pi / 180, // 使用與按鈕相同的旋轉角度
                  child: Container(
                    width: _frameWidth,
                    height: _frameHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.red,
                        width: 3.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '測量框架',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===== 【UI頁面模組】結束 =====

// ===== 【工具類模組】開始 =====
// ====================================================================
// ----- [pages/camera/camera_screen.dart] 結束 -----

// ----- [widgets/custom_painters.dart] 開始 -----
// 邊緣檢測繪畫器 (Edge Detection Painter)
// ====================================================================
/*
模組化建議：【工具類模組 - widgets/custom_painters.dart】
自定義繪製器類別可以獨立成為工具模組：
- EdgeDetectionPainter: 邊緣檢測繪畫器
- MeasurementPainter: 測量繪圖器
這些繪製器專責UI繪製邏輯，可復用性高。
*/
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
// 食物照片選擇器 (Food Photo Selector)
// ====================================================================
class FoodPhotoSelector extends StatefulWidget {
  const FoodPhotoSelector({super.key});

  @override
  State<FoodPhotoSelector> createState() => _FoodPhotoSelectorState();
}

class _FoodPhotoSelectorState extends State<FoodPhotoSelector> {
  Set<int> selectedItems = {0}; // 預設選中第一個

  // 模擬食物圖片資料
  final List<FoodItem> foodItems = [
    FoodItem(id: 0, imagePath: 'assets/food1.jpg', description: '早餐拼盤'),
    FoodItem(id: 1, imagePath: 'assets/food2.jpg', description: '意大利面'),
    FoodItem(id: 2, imagePath: 'assets/food3.jpg', description: '烤面包配菜'),
    FoodItem(id: 3, imagePath: 'assets/food4.jpg', description: '沙拉配面包'),
    FoodItem(id: 4, imagePath: 'assets/food5.jpg', description: '牛排配牛油果'),
    FoodItem(id: 5, imagePath: 'assets/food6.jpg', description: '意大利面条'),
    FoodItem(id: 6, imagePath: 'assets/food7.jpg', description: '番茄沙拉'),
    FoodItem(id: 7, imagePath: 'assets/food8.jpg', description: '煎蛋配蔬菜'),
    FoodItem(id: 8, imagePath: 'assets/food9.jpg', description: '鸡肉配番茄'),
    FoodItem(id: 9, imagePath: 'assets/food10.jpg', description: '燕麥配堅果'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '選擇照片',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 選擇指示器
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: selectedItems.isNotEmpty
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.blue,
                        )
                      : null,
                ),
              ],
            ),
          ),

          // 照片網格
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: foodItems.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedItems.contains(index);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedItems.remove(index);
                        } else {
                          selectedItems.add(index);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: Colors.blue, width: 2)
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 背景色
                            Container(
                              color: _getBackgroundColor(index),
                            ),

                            // 食物圖片佔位符
                            Center(
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(60),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: _buildFoodPlaceholder(index),
                                ),
                              ),
                            ),

                            // 選中狀態覆蓋層
                            if (isSelected)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.blue,
                                      child: Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 底部按鈕
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedItems.isNotEmpty
                        ? () {
                            // 確認選擇的邏輯
                            Navigator.of(context).pop(selectedItems);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text(
                      '確認',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '取消',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(int index) {
    final colors = [
      const Color(0xFFF5E6D3), // 米色
      const Color(0xFFD3E5E3), // 浅绿色
      const Color(0xFFF0F0F0), // 浅灰色
      const Color(0xFFD3E5E3), // 浅绿色
      const Color(0xFFD3E5E3), // 浅绿色
      const Color(0xFFD3E5E3), // 浅绿色
      const Color(0xFF8BA3A3), // 深绿色
      const Color(0xFFD3E5E3), // 浅绿色
      const Color(0xFFD3E5E3), // 浅绿色
      const Color(0xFFD3E5E3), // 浅绿色
    ];
    return colors[index % colors.length];
  }

  Widget _buildFoodPlaceholder(int index) {
    // 這裡可以替換為實際的食物圖片
    final icons = [
      Icons.breakfast_dining,
      Icons.lunch_dining,
      Icons.dinner_dining,
      Icons.local_pizza,
      Icons.restaurant,
      Icons.fastfood,
      Icons.local_cafe,
      Icons.cake,
      Icons.restaurant_menu,
      Icons.local_dining,
    ];

    return Container(
      color: Colors.grey.shade100,
      child: Icon(
        icons[index % icons.length],
        size: 40,
        color: Colors.grey.shade600,
      ),
    );
  }
}

class FoodItem {
  final int id;
  final String imagePath;
  final String description;

  FoodItem({
    required this.id,
    required this.imagePath,
    required this.description,
  });
}

// ====================================================================
// 營養標籤確認頁面
// ====================================================================
class NutritionLabelScreen extends StatelessWidget {
  final String? imagePath;
  final VoidCallback? onRetakePhoto;
  final VoidCallback? onSelectFromGallery;

  const NutritionLabelScreen({
    super.key,
    this.imagePath,
    this.onRetakePhoto,
    this.onSelectFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.black54),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 食材圖片區域
          Container(
            height: 200,
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: imagePath != null && imagePath!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(imagePath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            child: Icon(
                              Icons.restaurant,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      child: Icon(
                        Icons.restaurant,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 標題
                  Text(
                    '辨識結果',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),

                  // 總熱量
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_fire_department_outlined,
                            color: Colors.orange, size: 24),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('總熱量',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black87)),
                            Text('250 大卡',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // 六大類食物標題
                  Text(
                    '六大類食物',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),

                  // 食物分類列表
                  ...buildFoodCategoryList(),

                  SizedBox(height: 24),

                  // 詳細營養素標題
                  Text(
                    '詳細營養素',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),

                  // 營養素網格
                  buildNutritionGrid(),
                ],
              ),
            ),
          ),

          // 底部按鈕
          Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // 確認操作 - 返回首頁或飲食日記
                      Navigator.of(context).pop();
                      print('確認按鈕被點擊');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue[100],
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text('確認',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSelectFromGallery ??
                        () {
                          // 相簿操作
                          print('相簿按鈕被點擊');
                        },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text('相簿',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetakePhoto ??
                        () {
                          // 重拍操作
                          Navigator.of(context).pop();
                          print('重拍按鈕被點擊');
                        },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text('重拍',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> buildFoodCategoryList() {
    final categories = [
      {'icon': Icons.grain, 'title': '全穀類', 'subtitle': '精製麵粉'},
      {'icon': Icons.eco, 'title': '豆魚蛋肉類', 'subtitle': '蛋豆'},
      {'icon': Icons.local_drink, 'title': '乳品類', 'subtitle': '牛奶'},
      {'icon': Icons.park, 'title': '蔬菜類', 'subtitle': '蔬菜'},
      {'icon': Icons.apple, 'title': '水果類', 'subtitle': '水果'},
      {'icon': Icons.opacity, 'title': '油脂與堅果種子類', 'subtitle': '油脂'},
    ];

    return categories.map((category) {
      return Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(category['icon'] as IconData,
                color: Colors.grey[600], size: 24),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category['title'] as String,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
                Text(category['subtitle'] as String,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget buildNutritionGrid() {
    final nutritionData = [
      {'label': '蛋白質', 'value': '15克'},
      {'label': '碳水化合物', 'value': '30克'},
      {'label': '脂肪', 'value': '10克'},
      {'label': '膳食纖維', 'value': '5克'},
      {'label': '糖', 'value': '8克'},
      {'label': '鈉', 'value': '200毫克'},
      {'label': '膽固醇', 'value': '50毫克'},
      {'label': '鈣', 'value': '10毫克'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: nutritionData.length,
      itemBuilder: (context, index) {
        final item = nutritionData[index];
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item['label']!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
              Text(
                item['value']!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ====================================================================
// 參考物體測量頁面
// ====================================================================

/// 參考物體測量頁面
class ReferenceMeasurementPage extends StatefulWidget {
  final String imagePath;
  final Function(List<MeasurementResult>) onMeasurementComplete;

  const ReferenceMeasurementPage(
      {super.key,
      required this.imagePath,
      required this.onMeasurementComplete});

  @override
  State<ReferenceMeasurementPage> createState() =>
      _ReferenceMeasurementPageState();
}

class _ReferenceMeasurementPageState extends State<ReferenceMeasurementPage> {
  // 測量狀態變數
  MeasurementMode _currentMode = MeasurementMode.calibration;
  ReferenceObject? _selectedReference;
  double _measurementScale = 1.0;
  bool _isCalibrated = false;

  // 繪圖相關變數
  final List<MeasurementPoint> _referencePoints = [];
  final List<MeasurementPoint> _measurementPoints = [];
  final List<MeasurementResult> _results = [];

  // 圖片尺寸
  Size? _imageSize;
  final GlobalKey _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          _getModeTitle(),
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (_isCalibrated && _currentMode != MeasurementMode.calibration)
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: _clearMeasurements,
              tooltip: '清除測量',
            ),
        ],
      ),
      body: Column(
        children: [
          // 圖片顯示和繪圖區域
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  // 背景圖片
                  Center(
                    child: Image.file(
                      File(widget.imagePath),
                      key: _imageKey,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // 繪圖覆蓋層 - 限制在相機預覽區域，不覆蓋底部控制面板
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.of(context).size.height *
                        0.25, // 保留底部25%給控制面板
                    child: GestureDetector(
                      onTapDown: _handleTapDown,
                      child: CustomPaint(
                        painter: MeasurementPainter(
                          referencePoints: _referencePoints,
                          measurementPoints: _measurementPoints,
                          currentMode: _currentMode,
                          isCalibrated: _isCalibrated,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 底部控制面板
          _buildControlPanel(),
        ],
      ),
    );
  }

  /// 取得當前模式標題
  String _getModeTitle() {
    switch (_currentMode) {
      case MeasurementMode.calibration:
        return '校準參考物體';
      case MeasurementMode.length:
        return '長度測量';
      case MeasurementMode.area:
        return '面積測量';
      case MeasurementMode.volume:
        return '體積測量';
    }
  }

  /// 處理點擊事件
  void _handleTapDown(TapDownDetails details) {
    // 檢查點擊位置是否在允許的測量區域內（不在底部控制面板區域）
    final screenHeight = MediaQuery.of(context).size.height;
    final maxAllowedY = screenHeight * 0.75; // 只允許在螢幕上方75%區域點擊

    if (details.localPosition.dy > maxAllowedY) {
      // 點擊位置在底部控制面板區域，忽略此次點擊
      return;
    }

    if (_currentMode == MeasurementMode.calibration) {
      _handleCalibrationTap(details.localPosition);
    } else if (_isCalibrated) {
      _handleMeasurementTap(details.localPosition);
    }
  }

  /// 處理校準模式的點擊
  void _handleCalibrationTap(Offset position) {
    setState(() {
      if (_referencePoints.length < 2) {
        _referencePoints.add(MeasurementPoint(
          position: position,
          index: _referencePoints.length,
        ));

        // 如果有兩個點，進行校準
        if (_referencePoints.length == 2 && _selectedReference != null) {
          _performCalibration();
        }
      }
    });
  }

  /// 處理測量模式的點擊
  void _handleMeasurementTap(Offset position) {
    setState(() {
      _measurementPoints.add(MeasurementPoint(
        position: position,
        index: _measurementPoints.length,
      ));

      // 根據模式執行不同測量
      _performMeasurement();
    });
  }

  /// 執行校準
  void _performCalibration() {
    if (_referencePoints.length >= 2 && _selectedReference != null) {
      final double realSize = math.max(
        _selectedReference!.width,
        _selectedReference!.height,
      );

      _measurementScale = MeasurementCalculator.calculateScale(
        _referencePoints[0].position,
        _referencePoints[1].position,
        realSize,
      );

      setState(() {
        _isCalibrated = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('校準完成！比例: ${_measurementScale.toStringAsFixed(2)} px/cm'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// 執行測量
  void _performMeasurement() {
    if (!_isCalibrated || _measurementPoints.isEmpty) return;

    switch (_currentMode) {
      case MeasurementMode.length:
        if (_measurementPoints.length >= 2) {
          _measureLength();
        }
        break;
      case MeasurementMode.area:
        if (_measurementPoints.length >= 3) {
          _measureArea();
        }
        break;
      case MeasurementMode.volume:
        if (_measurementPoints.length >= 3) {
          _measureVolume();
        }
        break;
      default:
        break;
    }
  }

  /// 測量長度
  void _measureLength() {
    final points = _measurementPoints.length >= 2
        ? _measurementPoints.sublist(_measurementPoints.length - 2)
        : _measurementPoints;
    final distance = MeasurementCalculator.calculateRealDistance(
      points[0].position,
      points[1].position,
      _measurementScale,
    );

    final result = MeasurementResult(
      mode: MeasurementMode.length,
      value: distance,
      unit: 'cm',
      points: points,
      scale: _measurementScale,
    );

    setState(() {
      _results.add(result);
    });
  }

  /// 測量面積
  void _measureArea() {
    final area = MeasurementCalculator.calculatePolygonArea(
      _measurementPoints.map((p) => p.position).toList(),
      _measurementScale,
    );

    final result = MeasurementResult(
      mode: MeasurementMode.area,
      value: area,
      unit: 'cm',
      points: List.from(_measurementPoints),
      scale: _measurementScale,
    );

    setState(() {
      _results.add(result);
    });
  }

  /// 測量體積
  void _measureVolume() {
    final volume = MeasurementCalculator.estimateVolume(
      _measurementPoints.map((p) => p.position).toList(),
      _measurementScale,
    );

    final result = MeasurementResult(
      mode: MeasurementMode.volume,
      value: volume,
      unit: 'cm',
      points: List.from(_measurementPoints),
      scale: _measurementScale,
    );

    setState(() {
      _results.add(result);
    });
  }

  /// 清除測量結果
  void _clearMeasurements() {
    setState(() {
      _measurementPoints.clear();
      _results.clear();
    });
  }

  /// 建構控制面板
  Widget _buildControlPanel() {
    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 校準階段
          if (!_isCalibrated) ...[
            _buildReferenceSelector(),
            SizedBox(height: 12),
            Text(
              _getReferenceInstruction(),
              style: TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
          // 測量階段
          if (_isCalibrated) ...[
            _buildModeSelector(),
            SizedBox(height: 12),
            _buildInstructions(),
            if (_results.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildResultsDisplay(),
            ],
          ],
          SizedBox(height: 16),
          // 操作按鈕
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// 建構參考物體選擇器
  Widget _buildReferenceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '選擇參考物體:',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ReferenceObjectDatabase.getAllObjects()
              .map((obj) => _buildReferenceButton(obj))
              .toList(),
        ),
      ],
    );
  }

  /// 建構參考物體按鈕
  Widget _buildReferenceButton(ReferenceObject obj) {
    final isSelected = _selectedReference == obj;
    return GestureDetector(
      onTap: () => setState(() => _selectedReference = obj),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[700],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          obj.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 取得參考物體指示文字
  String _getReferenceInstruction() {
    if (_selectedReference == null) {
      return '請先選擇一個參考物體';
    } else if (_referencePoints.isEmpty) {
      return '點擊參考物體的兩個端點進行校準';
    } else if (_referencePoints.length == 1) {
      return '點擊參考物體的另一個端點';
    } else {
      return '校準中...';
    }
  }

  /// 建構測量模式選擇器
  Widget _buildModeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildModeButton(MeasurementMode.length, '長度', Icons.straighten),
        _buildModeButton(MeasurementMode.area, '面積', Icons.crop_square),
        _buildModeButton(MeasurementMode.volume, '體積', Icons.view_in_ar),
      ],
    );
  }

  /// 建構模式按鈕
  Widget _buildModeButton(MeasurementMode mode, String label, IconData icon) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _currentMode = mode;
        _measurementPoints.clear();
        _results.clear();
      }),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 建構指示文字
  Widget _buildInstructions() {
    String instruction;
    switch (_currentMode) {
      case MeasurementMode.length:
        instruction = '點擊兩個端點測量長度';
        break;
      case MeasurementMode.area:
        instruction = '點擊多個點圍成區域測量面積';
        break;
      case MeasurementMode.volume:
        instruction = '點擊多個點圍成底面估算體積';
        break;
      default:
        instruction = '';
    }

    return Text(
      instruction,
      style: TextStyle(color: Colors.white70, fontSize: 14),
      textAlign: TextAlign.center,
    );
  }

  /// 建構結果顯示
  Widget _buildResultsDisplay() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '測量結果:',
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ..._results.map((result) => Text(
                result.description,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              )),
        ],
      ),
    );
  }

  /// 建構操作按鈕
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (_isCalibrated)
          ElevatedButton(
            onPressed: _results.isNotEmpty ? _saveResults : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('完成測量'),
          ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
          child: Text('取消'),
        ),
        if (_isCalibrated)
          ElevatedButton(
            onPressed: _resetCalibration,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('重新校準'),
          ),
      ],
    );
  }

  /// 保存結果
  void _saveResults() {
    widget.onMeasurementComplete(_results);
    Navigator.of(context).pop();
  }

  /// 重置校準
  void _resetCalibration() {
    setState(() {
      _isCalibrated = false;
      _referencePoints.clear();
      _measurementPoints.clear();
      _results.clear();
      _currentMode = MeasurementMode.calibration;
    });
  }
}

// ====================================================================
// 自定義繪圖器 - 用於繪製測量點和線條
// ====================================================================
// ----- [widgets/custom_painters.dart] 結束 -----

// ----- [utils/image_processing.dart] 開始 -----
/// 測量繪圖器
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
    // 設定繪製邊界，避免繪製到底部控制面板區域
    final maxY = size.height * 0.75; // 只在上方75%區域繪製
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, maxY));

    // 繪製參考線
    _drawReferencePoints(canvas);

    // 繪製測量點和線條
    if (isCalibrated) {
      _drawMeasurementPoints(canvas);
    }
  }

  /// 繪製參考點
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ====================================================================
// 多圖片處理螢幕 (Multi-Image Processing Screen)
// ====================================================================

/// 多圖片處理結果數據
class ImageProcessingResult {
  final String imagePath;
  final String containerShape;
  final double volume;
  final String status;
  final DateTime processedAt;

  ImageProcessingResult({
    required this.imagePath,
    required this.containerShape,
    required this.volume,
    required this.status,
    required this.processedAt,
  });

  String get displayName =>
      'IMG_${processedAt.millisecondsSinceEpoch % 100000}';
  String get volumeText => '${volume.toStringAsFixed(2)} cm³';
  String get literText => '${(volume / 1000).toStringAsFixed(3)} L';
}

class MultiImageProcessingScreen extends StatefulWidget {
  final List<String> imagePaths;
  final VoidCallback? onReturnToCamera;

  const MultiImageProcessingScreen({
    super.key,
    required this.imagePaths,
    this.onReturnToCamera,
  });

  @override
  State<MultiImageProcessingScreen> createState() =>
      _MultiImageProcessingScreenState();
}

class _MultiImageProcessingScreenState
    extends State<MultiImageProcessingScreen> {
  final List<ImageProcessingResult> _results = [];
  bool _isProcessing = false;
  int _currentProcessingIndex = 0;

  @override
  void initState() {
    super.initState();
    _startBatchProcessing();
  }

  /// 開始批次處理所有圖片
  Future<void> _startBatchProcessing() async {
    if (widget.imagePaths.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _currentProcessingIndex = 0;
      _results.clear();
    });

    for (int i = 0; i < widget.imagePaths.length; i++) {
      setState(() {
        _currentProcessingIndex = i;
      });

      await _processImage(widget.imagePaths[i]);

      // 短暫延遲以提供視覺反饋
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() {
      _isProcessing = false;
    });

    print('批次處理完成: ${_results.length} 張圖片');
  }

  /// 處理單張圖片
  Future<void> _processImage(String imagePath) async {
    try {
      print('開始處理圖片: $imagePath');

      // 模擬智慧容積計算流程
      await Future.delayed(const Duration(milliseconds: 800));

      // 模擬邊緣檢測和形狀辨識
      final shapes = ['長方體', '圓柱體', '立方體'];
      final randomShape = shapes[math.Random().nextInt(shapes.length)];

      // 模擬容積計算結果
      final baseVolume =
          800.0 + math.Random().nextDouble() * 1200.0; // 800-2000 cm³
      final volume = double.parse(baseVolume.toStringAsFixed(2));

      final result = ImageProcessingResult(
        imagePath: imagePath,
        containerShape: randomShape,
        volume: volume,
        status: 'success',
        processedAt: DateTime.now(),
      );

      setState(() {
        _results.add(result);
      });

      print('圖片處理完成: $randomShape, ${volume.toStringAsFixed(2)} cm³');
    } catch (e) {
      print('處理圖片失敗: $e');

      final result = ImageProcessingResult(
        imagePath: imagePath,
        containerShape: '未知',
        volume: 0.0,
        status: 'failed',
        processedAt: DateTime.now(),
      );

      setState(() {
        _results.add(result);
      });
    }
  }

  /// 計算總容積
  double get _totalVolume {
    return _results
        .where((result) => result.status == 'success')
        .fold(0.0, (sum, result) => sum + result.volume);
  }

  /// 計算平均容積
  double get _averageVolume {
    final successResults =
        _results.where((result) => result.status == 'success').toList();
    if (successResults.isEmpty) return 0.0;
    return _totalVolume / successResults.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('批次處理 (${widget.imagePaths.length} 張照片)'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (!_isProcessing)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareResults,
            ),
        ],
      ),
      body: Column(
        children: [
          // 處理進度指示器
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green.withOpacity(0.1),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: widget.imagePaths.isNotEmpty
                        ? (_currentProcessingIndex + 1) /
                            widget.imagePaths.length
                        : 0.0,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '正在處理: ${_currentProcessingIndex + 1} / ${widget.imagePaths.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // 統計資訊
          if (!_isProcessing && _results.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                      '處理成功',
                      '${_results.where((r) => r.status == 'success').length}',
                      Icons.check_circle,
                      Colors.green),
                  _buildStatCard(
                      '總容積',
                      '${_totalVolume.toStringAsFixed(1)} cm³',
                      Icons.analytics,
                      Colors.blue),
                  _buildStatCard(
                      '平均容積',
                      '${_averageVolume.toStringAsFixed(1)} cm³',
                      Icons.calculate,
                      Colors.orange),
                ],
              ),
            ),

          // 結果列表
          Expanded(
            child: _results.isEmpty && !_isProcessing
                ? const Center(
                    child: Text(
                      '尚無處理結果',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return _buildResultCard(result, index);
                    },
                  ),
          ),

          // 底部按鈕
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onReturnToCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('返回相機'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _reprocessAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('重新處理'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建構統計卡片
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 建構結果卡片
  Widget _buildResultCard(ImageProcessingResult result, int index) {
    final isSuccess = result.status == 'success';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuccess ? Colors.green : Colors.red,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(result.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('形狀: ${result.containerShape}'),
            if (isSuccess) ...[
              Text('容積: ${result.volumeText} (${result.literText})'),
            ] else ...[
              const Text('處理失敗', style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
        trailing: isSuccess
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.error, color: Colors.red),
        onTap: () => _showImageDetail(result),
      ),
    );
  }

  /// 顯示圖片詳細資訊
  void _showImageDetail(ImageProcessingResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.file(
              File(result.imagePath),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            Text('容器形狀: ${result.containerShape}'),
            if (result.status == 'success') ...[
              Text('容積: ${result.volumeText}'),
              Text('公升: ${result.literText}'),
            ],
            Text('處理時間: ${result.processedAt.toString().substring(11, 19)}'),
            Text('狀態: ${result.status == 'success' ? '成功' : '失敗'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  /// 重新處理所有圖片
  void _reprocessAll() {
    _startBatchProcessing();
  }

  /// 分享結果
  void _shareResults() {
    final successCount = _results.where((r) => r.status == 'success').length;
    final totalCount = _results.length;

    final summary = '''
容積測量批次處理結果

處理照片數量: $totalCount 張
成功處理: $successCount 張
總容積: ${_totalVolume.toStringAsFixed(2)} cm³ (${(_totalVolume / 1000).toStringAsFixed(3)} L)
平均容積: ${_averageVolume.toStringAsFixed(2)} cm³

詳細結果:
${_results.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final result = entry.value;
      return '$index. ${result.displayName}: ${result.containerShape} - ${result.volumeText}';
    }).join('\n')}

📱 由智慧容積測量 App 生成
    ''';

    print('分享結果摘要: $summary');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('結果已準備分享'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
// ----- [utils/image_processing.dart] 結束 -----

// ===== 【工具類模組】結束 =====
