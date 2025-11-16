import 'package:flutter/material.dart';
import '../../../core/services/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';  // Firebase Firestore 資料庫

// 引入相機支援類別
import '../../features/nutrition/presentation/pages/nutrition_label_screen.dart';  // 營養標籤頁面
import '../../features/measurement/presentation/pages/reference_measurement_page.dart';  // 參考測量頁面
import '../../features/camera/presentation/pages/multiple_images_processing_page.dart';  // 多圖處理頁面
import '../../core/widgets/edge_detection_painter.dart';  // 邊緣檢測繪圖器
// import 'camera_models.dart';  // 已註解：改用項目原有的模型檔案
import '../../data/models/container_analysis.dart';  // 容器分析數據模型
import '../../data/models/measurement.dart' hide ReferenceObject, MeasurementMode, MeasurementPoint, MeasurementResult;  // 測量枚舉（僅 MeasurementMethod, ReferenceObjectType）
import '../../data/models/measurement_models.dart';  // 測量類別（MeasurementResult 等）
import '../../data/models/reference_object.dart';  // 參考物體資料庫
import '../../data/services/log_manager.dart';  // 日誌管理服務
import '../../core/services/app_logger.dart';

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
  MeasurementMethod _selectedMeasurementMethod =
      MeasurementMethod.automatic; // 選中的測量方法
  MeasurementMode _currentMeasurementMode =
      MeasurementMode.calibration; // 當前測量模式
  bool _isInMeasurementMode = false; // 是否處於測量模式
  String? _capturedImagePath; // 已拍攝的照片路徑

  // 校準相關變數
  ReferenceObject? _selectedReferenceObject; // 選中的參考物體
  Offset? _referenceStartPoint; // 參考線起點
  Offset? _referenceEndPoint; // 參考線終點
  double _measurementScale = 1.0; // 測量比例 (像素/厘米)
  bool _isCalibrated = false; // 是否已校準

  // 測量繪圖相關變數
  List<MeasurementPoint> _measurementPoints = []; // 測量點列表

  // 可拖拽測量框架相關變數
  double _framePosX = 50.0; // 測量框架X位置 (將在initState中重新計算)
  double _framePosY = 100.0; // 測量框架Y位置 (將在initState中重新計算)
  double _frameWidth = 200.0; // 測量框架寬度
  double _frameHeight = 150.0; // 測量框架高度
  bool _showMeasurementFrame = false; // 是否顯示測量框架 (預設關閉以避免阻擋按鈕)

  // 邊界檢查常數
  static const double _BOTTOM_SAFE_ZONE = 250.0; // 底部安全區域
  static const double _TOP_SAFE_ZONE = 100.0; // 頂部安全區域
  static const double _SIDE_MARGIN = 15.0; // 左右邊距
  static const double _MIN_FRAME_SIZE = 80.0; // 最小框架尺寸
  List<MeasurementResult> _measurementResults = []; // 測量結果列表
  bool _isDragging = false; // 是否正在拖拽
  int? _draggedPointIndex; // 被拖拽點的索引

  // 自定義參考物體尺寸控制器
  final TextEditingController _customWidthController = TextEditingController();

  // RAG 測試數據相關變數 (RAG Test Data Variables)
  ContainerAnalysisData? _testAnalysisData; // 測試用的分析數據
  bool _showTestData = false; // 是否顯示測試數據
  Timer? _testDataTimer; // 測試數據更新計時器
  final TextEditingController _customHeightController = TextEditingController();

  /// 初始化相機頁面狀態 - 設定觀察器、螢幕方向並啟動相機
  @override
  void initState() {
    super.initState();
    print('[CAMERA DEBUG] 相機頁面 initState 開始');
    // ✅ 暫時移除 AppLogger 調用，避免可能的死鎖
    // AppLogger.logEvent('[CAMERA] 相機頁面 initState 開始');

    // 註冊應用程式生命週期觀察器：監聽應用程式前景/背景狀態變化
    WidgetsBinding.instance.addObserver(this);

    // 鎖定豎螢幕：確保相機介面在豎屏模式下使用
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // ✅ 修復：完全跳過相機初始化，避免 ColorOS 死鎖
    // ColorOS/OPPO 設備在調用 availableCameras() 時會導致整個應用凍結
    // 改為直接設置錯誤狀態，使用降級方案（ImagePicker）
    print('[CAMERA DEBUG] ⚠️ 跳過相機初始化，使用降級方案');

    // 直接設置為未初始化狀態，顯示降級界面
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[CAMERA DEBUG] PostFrameCallback 開始');
      if (mounted) {
        print('[CAMERA DEBUG] 設置錯誤狀態');
        setState(() {
          _hasError = true;
          _errorMessage = '相機預覽功能暫時無法使用\n\n✅ 您仍可使用以下功能：\n• 點擊「拍照」按鈕直接拍照\n• 點擊「相簿」按鈕選擇照片';
        });
        print('[CAMERA DEBUG] 錯誤狀態設置完成');
      }
    });

    // ✅ 暫時移除這些可能導致死鎖的功能
    // _initializeTestData();
    // _startOrientationDetection();
    // _initializeMeasurementFramePosition();

    print('[CAMERA DEBUG] initState 完成');
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
    print('[CAMERA DEBUG] 相機頁面 dispose 開始');
    // ✅ 暫時移除 AppLogger 調用，避免可能的死鎖
    // AppLogger.logEvent('[CAMERA] 相機頁面 dispose 開始');
    // 移除應用程式生命週期觀察器
    WidgetsBinding.instance.removeObserver(this);

    // 取消加速度計訂閱：停止方向檢測以節省電池
    _accelerometerSubscription?.cancel();

    // 釋放相機控制器：釋放相機硬體資源
    // ColorOS 修復：先保存引用，立即設為 null，再釋放
    final cameraController = _controller;
    if (cameraController != null) {
      _controller = null;
      cameraController.dispose();
    }

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

  /// 監聽應用程式生命週期變化 - 處理相機資源釋放與重新初始化
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('[CAMERA DEBUG] App lifecycle state changed to: $state');
    // ✅ 暫時移除 AppLogger 調用，避免可能的死鎖
    // AppLogger.logEvent('[CAMERA] App lifecycle state changed to: $state');

    // 當 App 進入背景或不活躍時，釋放相機控制器
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final cameraController = _controller;
      if (cameraController != null) {
        _controller = null; // 立即設為 null
        cameraController.dispose();
        if (mounted) {
          setState(() {
            _isInitialized = false; // 更新UI為未初始化狀態
          });
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // 當 App 返回前景時，如果控制器為 null，則重新初始化
      if (_controller == null) {
        _initializeCamera();
      }
    }
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
  // ⚠️ 以下權限請求方法已棄用，因為會在某些設備上導致 MethodChannel 死鎖
  // 權限已在 AndroidManifest.xml 中聲明，直接初始化相機即可

  /* ❌ 已棄用：會導致死鎖
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
  */

  // ====================================================================
  // 相機初始化函數 (Camera Initialization Function)
  // ====================================================================
  Future<void> _initializeCamera() async {
    print('[CAMERA DEBUG] Step 1: 方法開始');
    // ✅ 暫時移除 AppLogger 調用，避免可能的死鎖
    // await AppLogger.logEvent('[CAMERA] _initializeCamera 方法開始執行');

    print('[CAMERA DEBUG] Step 2: try block 開始');
    try {
      print('[CAMERA DEBUG] Step 3: 跳過權限請求（已在 AndroidManifest 中聲明）');
      // ✅ 暫時移除 AppLogger 調用，避免可能的死鎖
      // await AppLogger.logEvent('[CAMERA] 跳過 permission_handler 調用以避免死鎖');

      // ✅ 修復：直接初始化相機設備，不調用 permission_handler
      // 權限已在 AndroidManifest.xml 中聲明，系統會自動處理
      // 這樣可以避免在 Realme/OPPO/Xiaomi 設備上的 MethodChannel 死鎖問題

      print('[CAMERA DEBUG] Step 4: 準備初始化設備');
      // 直接初始化相機設備
      await _initializeCameraDevice();
      print('[CAMERA DEBUG] Step 5: 設備初始化完成');
    } catch (e, stackTrace) {
      print('[CAMERA DEBUG] ERROR: 捕獲異常 - $e');
      print('[CAMERA DEBUG] StackTrace: $stackTrace');
      log('相機初始化錯誤: $e'); // 記錄錯誤到日誌
      // ✅ 暫時移除 AppLogger 調用，避免可能的死鎖
      // await AppLogger.logEvent('[CAMERA] ❌ _initializeCamera 異常: $e');
      if (mounted) {
        // 根據錯誤類型設定不同的錯誤訊息
        String errorMsg = '相機初始化失敗';
        if (e.toString().contains('permission')) {
          errorMsg = '沒有相機權限，請在系統設置中手動授權';
        }
        setState(() {
          _hasError = true;
          _errorMessage = errorMsg;
        });
      }
    }
    print('[CAMERA DEBUG] Step 6: _initializeCamera 方法結束');
  }

  // 相機設備初始化函數 (Camera Device Initialization Function)
  Future<void> _initializeCameraDevice() async {
    try {
      print('[CAMERA DEBUG] Step 4.1: 開始獲取可用相機列表（3秒超時）');
      // 步驟1：檢查系統中可用的相機設備（添加超時保護）
      // ✅ 修復：將超時時間從 10 秒改為 3 秒，快速失敗
      cameras = await availableCameras().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('[CAMERA DEBUG] ⚠️ 獲取相機列表超時，使用降級方案');
          throw TimeoutException('獲取相機列表超時');
        },
      );
      print('[CAMERA DEBUG] Step 4.2: 找到 ${cameras?.length ?? 0} 個相機');

      if (cameras == null || cameras!.isEmpty) {
        print('[CAMERA DEBUG] ERROR: 未找到可用的相機設備');
        setState(() {
          _hasError = true;
          _errorMessage = '未找到可用的相機設備';
        });
        return; // 沒有相機設備，終止初始化
      }

      print('[CAMERA DEBUG] Step 4.3: 創建相機控制器');
      // 步驟2：創建相機控制器
      _controller = CameraController(
        cameras![0], // 使用第一個相機（通常是後置鏡頭）
        ResolutionPreset.medium, // ✅ 改為中等畫質，提高兼容性
        enableAudio: false, // 不啟用音訊錄製
      );
      print('[CAMERA DEBUG] Step 4.4: 相機控制器已創建，準備初始化...');

      print('[CAMERA DEBUG] Step 4.5: 開始初始化相機控制器（最多等待 15 秒）');
      // 步驟3：初始化相機控制器（添加超時保護）
      await _controller!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('[CAMERA DEBUG] ERROR: 相機初始化超時！');
          throw TimeoutException('相機初始化超時');
        },
      );
      print('[CAMERA DEBUG] Step 4.6: 相機控制器初始化完成！');

      print('[CAMERA DEBUG] Step 4.7: 準備更新 UI 狀態');
      // 步驟4：更新UI狀態（僅在組件仍然掛載時）
      if (mounted) {
        setState(() {
          _isInitialized = true; // 標記為已初始化
          _hasError = false; // 清除錯誤狀態
        });
        print('[CAMERA DEBUG] Step 4.8: ✅ UI 狀態已更新，_isInitialized = true');
      } else {
        print('[CAMERA DEBUG] WARNING: 組件已卸載，跳過 UI 更新');
      }
    } catch (e) {
      print('[CAMERA DEBUG] ERROR: 相機設備初始化錯誤: $e');
      log('相機設備初始化錯誤: $e'); // 記錄詳細錯誤信息
      // ✅ 暫時移除 AppLogger 調用，避免可能的死鎖
      // await AppLogger.logEvent('[CAMERA] ❌ 相機設備初始化錯誤: $e');
      if (mounted) {
        print('[CAMERA DEBUG] 正在設置錯誤狀態（使用降級方案）');
        setState(() {
          _hasError = true;
          // ✅ 提示用戶使用替代方案
          if (e is TimeoutException) {
            _errorMessage = '相機預覽初始化超時\n\n您仍可使用「拍照」或「相簿」功能';
          } else {
            _errorMessage = '相機預覽暫時無法使用\n\n您仍可使用「拍照」或「相簿」功能\n\n錯誤: ${e.toString()}';
          }
        });
      } else {
        print('[CAMERA DEBUG] WARNING: 組件已卸載，無法設置錯誤狀態');
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
          title: Text('需要${permissionName}權限'),
          content: Text('此應用需要${permissionName}權限才能正常運作。請在設置中手動開啟權限。'),
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
      await log('✅ 跳過權限檢查（避免死鎖），直接拍照');

      // ✅ 修復：移除所有 permission_handler 調用
      // 原因：
      // 1. 相機權限：如果能進入這個頁面，說明相機已初始化，權限已授予
      // 2. 存儲權限：AndroidManifest.xml 中已聲明，系統會自動處理
      // 3. 如果保存失敗，會降級保存到應用內部目錄

      /* ❌ 已移除：會導致 MethodChannel 死鎖
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
      */

      await log('開始拍照...');

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
            // 使用 ImageGallerySaverPlus 的正確方式 (簡化版本)
            final result = await ImageGallerySaverPlus.saveImage(imageBytes);

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
              analysis: {
                'food_name': '未分析',
                'nutrition': {},
              }, // TODO: 需要實作圖片分析功能
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
        final result = await ImageGallerySaverPlus.saveImage(
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
    // ✅ 暫時移除 AppLogger 調用，避免可能的死鎖
    // await AppLogger.logCameraAction('[OK][OK][OK] 智慧拍照按鈕點擊');
    print('[CAMERA] 智慧拍照按鈕被點擊');

    // ✅ 修復：如果相機未初始化，改用 ImagePicker 拍照
    if (_controller == null || !_controller!.value.isInitialized) {
      print('[CAMERA] 相機未初始化，使用 ImagePicker 降級方案');
      await _takePhotoWithImagePicker();
      return;
    }

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
        final result = await ImageGallerySaverPlus.saveImage(
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
      // 註解：自動重新啟用會阻擋按鈕，已停用
      /*
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showMeasurementFrame = true;
          });
        }
      });
      */
    }
  }

  /// 執行智慧容積計算 - 自動選擇最適合的測量方式
  Future<void> _performSmartVolumeCalculation(String imagePath) async {
    // 執行智慧容積計算的核心異步函數：結合多種測量方法自動選擇最佳結果
    // 參數imagePath：要分析的圖片檔案路徑
    // 返回值：Future<void>，異步完成容積計算並更新UI狀態
    await log('開始智慧容積計算分析...'); // 記錄計算流程開始

    // 第一種方法：嘗試基於邊緣檢測的自動容積計算
    double autoVolume = 0.0;   // 初始化自動計算結果變數
    bool autoSuccess = false;  // 初始化自動計算成功標誌

    try { // 使用try-catch捕捉自動計算過程中的異常
      await log('嘗試方法1: 自動容積計算'); // 記錄方法1開始執行
      await _performAutoVolumeCalculation(imagePath); // 呼叫自動容積計算函數
      autoVolume = _calculatedVolume;           // 取得計算結果
      autoSuccess = _calculatedVolume > 0;      // 判斷計算是否成功（容積大於0）
      await log('自動計算結果: ${_calculatedVolume} cm³, 成功: $autoSuccess'); // 記錄方法1結果
    } catch (e) { // 捕捉自動計算異常
      await log('自動計算失敗: $e'); // 記錄異常訊息
    }

    // 第二種方法：嘗試基於參考物體的智慧識別測量
    double referenceVolume = 0.0;   // 初始化參考物體計算結果變數
    bool referenceSuccess = false;  // 初始化參考物體計算成功標誌

    try { // 使用try-catch捕捉參考物體計算過程中的異常
      await log('嘗試方法2: 參考物體智慧識別'); // 記錄方法2開始執行
      referenceVolume = await _performAutomaticReferenceDetection(imagePath); // 呼叫自動參考物體檢測函數
      referenceSuccess = referenceVolume > 0;  // 判斷參考物體計算是否成功
      await log('參考物體計算結果: $referenceVolume cm³, 成功: $referenceSuccess'); // 記錄方法2結果
    } catch (e) { // 捕捉參考物體計算異常
      await log('參考物體計算失敗: $e'); // 記錄異常訊息
    }

    // 智慧選擇最佳測量結果：比較兩種方法的結果並選擇最可靠的
    await _selectBestMeasurementResult(
        autoVolume, autoSuccess, referenceVolume, referenceSuccess); // 傳入兩種方法的結果進行智慧選擇
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
    // 智慧選擇最佳測量結果的決策函數：根據多種測量方法的成功狀態和結果差異進行最優選擇
    // 參數autoVolume：自動邊緣檢測計算的容積值
    // 參數autoSuccess：自動檢測是否成功的布林值
    // 參數referenceVolume：參考物體測量計算的容積值
    // 參數referenceSuccess：參考物體測量是否成功的布林值
    // 返回值：Future<void>，異步完成結果選擇並更新UI
    String selectedMethod = ''; // 初始化選中的測量方法名稱
    double finalVolume = 0.0;   // 初始化最終選定的容積值

    if (autoSuccess && referenceSuccess) { // 情況1：兩種測量方法都成功時的智慧選擇邏輯
      // 計算兩種方法結果的差異程度來決定採用策略
      final difference = (autoVolume - referenceVolume).abs();        // 計算絕對差值
      final averageVolume = (autoVolume + referenceVolume) / 2;       // 計算平均容積
      final differencePercentage = difference / averageVolume * 100;  // 計算差異百分比

      if (differencePercentage < 20) { // 當兩種方法結果差異小於20%時
        // 結果相近表示測量可靠，取兩者平均值提升準確度
        finalVolume = averageVolume;                   // 使用平均值作為最終結果
        selectedMethod = '混合測量（自動+參考）';        // 標記為混合測量方法
        await log('兩種方法結果相近，使用平均值: ${finalVolume.toStringAsFixed(2)} cm³'); // 記錄選擇邏輯
      } else { // 當兩種方法結果差異大於20%時
        // 結果差異較大時，偏好參考物體測量因為通常更準確
        finalVolume = referenceVolume;        // 採用參考物體測量結果
        selectedMethod = '參考物體測量';       // 標記為參考物體測量方法
        await log('選擇參考物體測量結果: ${finalVolume.toStringAsFixed(2)} cm³'); // 記錄選擇邏輯
      }
    } else if (autoSuccess) { // 情況2：僅自動檢測成功時
      finalVolume = autoVolume;          // 使用自動檢測結果
      selectedMethod = '自動容積測量';    // 標記為自動測量方法
      await log('使用自動測量結果: ${finalVolume.toStringAsFixed(2)} cm³'); // 記錄選擇邏輯
    } else if (referenceSuccess) { // 情況3：僅參考物體測量成功時
      finalVolume = referenceVolume;     // 使用參考物體測量結果
      selectedMethod = '參考物體測量';    // 標記為參考物體測量方法
      await log('使用參考物體測量結果: ${finalVolume.toStringAsFixed(2)} cm³'); // 記錄選擇邏輯
    } else { // 情況4：兩種測量都失敗時的降級處理
      // 提供合理的預設估算值避免系統無法運作
      finalVolume = 1000.0;             // 使用1000cm³作為預設估算值
      selectedMethod = '估算值';         // 標記為估算方法
      await log('兩種測量都失敗，使用估算值: ${finalVolume.toStringAsFixed(2)} cm³'); // 記錄降級邏輯
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
        final result = await ImageGallerySaverPlus.saveImage(
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
    // 根據容器形狀和尺寸參數計算容積的自定義函數
    // 參數dimensions：包含長度、寬度、高度等尺寸資料的Map集合
    // 返回值：double型別的容積值（立方公分）
    switch (_containerShape) { // 根據事先偵測到的容器形狀進行不同的計算方式
      case '長方體': // 長方體容積 = 長 × 寬 × 高
        return dimensions['length']! * // 取得長度值（!表示確定不為null）
            dimensions['width']! *     // 取得寬度值
            dimensions['height']!;     // 取得高度值，三者相乘得出容積

      case '圓柱體': // 圓柱體容積 = π × 半徑² × 高
        double radius = dimensions['length']! / 2; // 將偵測到的長度除以2作為半徑（假設length為直徑）
        return math.pi * radius * radius * dimensions['height']!; // π × r² × h 的圓柱體容積公式

      case '立方體': // 立方體容積 = 邊長³
        double side = (dimensions['length']! + dimensions['width']!) / 2; // 取長寬的平均值作為邊長
        return side * side * side; // 邊長的三次方得出立方體容積

      default: // 未知形狀或無法計算的情況
        return 0.0; // 返回0作為預設值
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
    // 容器形狀自動偵測函數：根據邊緣點分析容器的幾何形狀
    // 參數edges：包含容器邊緣座標點的列表
    // 返回值：String型別的形狀名稱（立方體、長方體、圓柱體、未知形狀）
    if (edges.isEmpty) { // 檢查邊緣點列表是否為空
      return '未知形狀'; // 沒有邊緣點時返回未知形狀
    }

    print('開始自動辨識容器形狀，邊緣點數: ${edges.length}'); // 輸出偵測開始訊息和邊緣點數量

    // 基於邊緣點數量和形狀特徵進行容器類型判斷的演算法
    if (edges.length >= 8) { // 當邊緣點數量大於等於8個時
      // 多邊緣點通常表示矩形或方形容器，需要計算長寬比來區分
      final aspectRatio = _calculateAspectRatio(edges); // 呼叫自定義函數計算長寬比

      if (aspectRatio > 0.8 && aspectRatio < 1.2) { // 長寬比接近1（0.8-1.2之間）表示接近正方形
        print('辨識為: 立方體 (長寬比: ${aspectRatio.toStringAsFixed(2)})'); // 輸出辨識結果和長寬比數值
        return '立方體'; // 返回立方體形狀
      } else { // 長寬比差異較大表示為長方形
        print('辨識為: 長方體 (長寬比: ${aspectRatio.toStringAsFixed(2)})'); // 輸出辨識結果和長寬比數值
        return '長方體'; // 返回長方體形狀
      }
    } else if (edges.length >= 4) { // 當邊緣點數量在4-7個之間時
      // 中等數量的邊緣點，需要檢查圓形特徵來判斷是否為圓柱體
      final roundness = _calculateRoundness(edges); // 呼叫自定義函數計算圓度值

      if (roundness > 0.7) { // 圓度值大於0.7表示接近圓形
        print('辨識為: 圓柱體 (圓度: ${roundness.toStringAsFixed(2)})'); // 輸出辨識結果和圓度數值
        return '圓柱體'; // 返回圓柱體形狀
      } else { // 圓度值較低表示仍為矩形特徵
        print('辨識為: 長方體 (圓度: ${roundness.toStringAsFixed(2)})'); // 輸出辨識結果和圓度數值
        return '長方體'; // 返回長方體形狀
      }
    } else { // 當邊緣點數量少於4個時
      print('邊緣點太少，預設為: 長方體'); // 輸出邊緣點不足的警告訊息
      return '長方體'; // 預設返回長方體形狀
    }
  }

  /// 計算容器長寬比
  double _calculateAspectRatio(List<Offset> edges) {
    // 計算容器長寬比的自定義函數：分析邊緣點座標來確定容器的寬高比例
    // 參數edges：包含容器邊緣座標點的列表
    // 返回值：double型別的長寬比值（寬度除以高度）
    if (edges.isEmpty) return 1.0; // 如果沒有邊緣點，返回1.0表示正方形比例

    // 初始化邊界值：使用第一個點的座標作為初始的最小值和最大值
    double minX = edges.first.dx; // 初始化X軸最小值（最左邊）
    double maxX = edges.first.dx; // 初始化X軸最大值（最右邊）
    double minY = edges.first.dy; // 初始化Y軸最小值（最上方）
    double maxY = edges.first.dy; // 初始化Y軸最大值（最下方）

    // 遍歷所有邊緣點找出邊界框的四個極值
    for (final edge in edges) { // 逐一檢查每個邊緣點座標
      minX = math.min(minX, edge.dx); // 更新X軸最小值（找出最左邊的點）
      maxX = math.max(maxX, edge.dx); // 更新X軸最大值（找出最右邊的點）
      minY = math.min(minY, edge.dy); // 更新Y軸最小值（找出最上方的點）
      maxY = math.max(maxY, edge.dy); // 更新Y軸最大值（找出最下方的點）
    }

    // 計算邊界框的寬度和高度
    final width = maxX - minX;   // 寬度 = 最右邊X座標 - 最左邊X座標
    final height = maxY - minY;  // 高度 = 最下方Y座標 - 最上方Y座標

    if (height == 0) return 1.0; // 防止除以零的錯誤，高度為0時返回1.0
    return width / height;       // 返回長寬比：寬度除以高度
  }

  /// 計算容器圓度（判斷是否為圓形）
  double _calculateRoundness(List<Offset> edges) {
    // 計算容器圓度的自定義函數：透過統計分析判斷邊緣點是否形成圓形
    // 參數edges：包含容器邊緣座標點的列表
    // 返回值：double型別的圓度值（0.0-1.0，越接近1.0越圓）
    if (edges.length < 3) return 0.0; // 少於3個點無法形成有效形狀，返回0.0

    // 第一步：計算所有邊緣點的質心（幾何中心點）
    double centerX = 0; // 初始化X軸質心累加器
    double centerY = 0; // 初始化Y軸質心累加器
    for (final edge in edges) { // 遍歷所有邊緣點
      centerX += edge.dx; // 累加所有點的X座標
      centerY += edge.dy; // 累加所有點的Y座標
    }
    centerX /= edges.length; // 計算X軸質心：總和除以點數
    centerY /= edges.length; // 計算Y軸質心：總和除以點數

    final center = Offset(centerX, centerY); // 建立質心座標物件

    // 第二步：計算所有邊緣點到質心的歐氏距離
    final distances = edges
        .map((edge) => math.sqrt( // 使用歐氏距離公式：√((x2-x1)² + (y2-y1)²)
            math.pow(edge.dx - centerX, 2) + math.pow(edge.dy - centerY, 2))) // 計算每個點到質心的距離
        .toList(); // 轉換為距離列表

    if (distances.isEmpty) return 0.0; // 防禦性程式設計：確保距離列表不為空

    // 第三步：計算距離的統計特徵（平均值和標準差）
    final meanDistance = distances.reduce((a, b) => a + b) / distances.length; // 計算平均距離：所有距離的總和除以數量
    final variance = distances
            .map((distance) => math.pow(distance - meanDistance, 2)) // 計算每個距離與平均距離的差的平方
            .reduce((a, b) => a + b) / // 累加所有平方差
        distances.length; // 除以數量得到變異數
    final standardDeviation = math.sqrt(variance); // 計算標準差：變異數的平方根

    // 第四步：計算圓度指標
    // 圓度公式：1 - (標準差 / 平均距離)
    // 理論基礎：圓形的所有邊緣點到中心距離相等，標準差接近0，圓度接近1
    final roundness = 1 - (standardDeviation / meanDistance); // 計算圓度值
    return math.max(0.0, roundness); // 確保圓度值不小於0.0
  }

  /// 顯示尺寸輸入對話框
  void _showDimensionInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('輸入${_containerShape}尺寸 (公分)'),
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

  /// 使用 ImagePicker 拍照（降級方案）
  Future<void> _takePhotoWithImagePicker() async {
    print('[CAMERA] 使用 ImagePicker 拍照');
    try {
      // 使用 ImagePicker 的相機功能
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        print('[CAMERA] 拍照成功: ${photo.path}');
        // 導航到營養標籤頁面
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NutritionLabelScreen(
                imagePath: photo.path,
                analysis: {
                  'predictions': [], // 提供空的分析結果，在標籤頁面中再分析
                  'status': 'pending',
                },
              ),
            ),
          );
        }
      } else {
        print('[CAMERA] 使用者取消拍照');
      }
    } catch (e) {
      print('[CAMERA] ImagePicker 拍照錯誤: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('拍照失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openGallery() async {
    // ✅ 暫時移除 AppLogger 調用，避免可能的死鎖
    // await AppLogger.logCameraAction('[OK][OK][OK] 開啟相簿按鈕點擊');
    print('[CAMERA] 相簿按鈕被點擊');
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
                analysis: {
                  'predictions': [], // 提供空的分析結果，在標籤頁面中再分析
                  'status': 'pending',
                },
              ),
            ),
          );
        } else {
          // 如果選擇了多張圖片，使用批次分析流程
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MultipleImagesProcessingPage(
                images: images,
                onRetakePhoto: () {
                  Navigator.of(context).pop();
                },
                onSelectFromGallery: () async {
                  Navigator.of(context).pop();
                  await _openGallery();
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
    await AppLogger.logCameraAction('[OK][OK][OK] 切換鏡頭按鈕點擊');
    print('[CAMERA] 切換鏡頭按鈕被點擊');
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
    print('[CAMERA DEBUG] build 方法開始');

    // 步驟1：設定螢幕方向（拍照頁面鎖定為正常豎螢幕）
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    print('[CAMERA DEBUG] build - 步驟1完成');

    // 步驟2：獲取螢幕尺寸和設備類型
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600; // 判斷是否為平板
    final isLargeScreen = screenSize.width > 900; // 判斷是否為大螢幕
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape; // 判斷系統方向
    print('[CAMERA DEBUG] build - 步驟2完成，screenSize: $screenSize');

    // 步驟3：計算按鈕旋轉角度（根據設備實際物理方向決定）
    final double iconRotation = _isDeviceLandscape ? 90.0 : 0.0;
    print('[CAMERA DEBUG] build - 步驟3完成，iconRotation: $iconRotation');

    // 步驟4：建構主要UI結構
    print('[CAMERA DEBUG] build - 開始建構 Scaffold');
    return Scaffold(
      backgroundColor: Colors.black, // 設定背景色為黑色
      body: Stack(
        children: [
          // 相機預覽或錯誤顯示
          if (_isInitialized)
            Positioned.fill(
              child: IgnorePointer(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
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

                          // ✅ 修復：直接初始化相機，不請求權限
                          await _initializeCamera();
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
              child: IgnorePointer(
                child: CustomPaint(
                  painter: EdgeDetectionPainter(_detectedEdges),
                ),
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
