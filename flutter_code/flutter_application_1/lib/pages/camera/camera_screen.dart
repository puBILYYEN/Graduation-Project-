import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'widgets/camera_controls.dart';
import 'utils/edge_detection_painter.dart';
import '../nutrition/nutrition_label_screen.dart';
// Make sure that NutritionLabelScreen is defined in ../nutrition/nutrition_label_screen.dart
import '../multi_image/multi_image_processing_screen.dart';
import '../../models/reference_object.dart';
import '../../models/container_analysis.dart' as ca;
import '../../models/measurement.dart';
import 'package:flutter_application_1/features/measurement/presentation/widgets/custom_painters.dart';
import 'package:flutter_application_1/core/services/api/api_services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool _showMeasurementFrame = true; // 是否顯示測量框架

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
  ca.ContainerAnalysisData? _testAnalysisData; // 測試用的分析數據
  bool _showTestData = false; // 是否顯示測試數據
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
    _testAnalysisData = ca.ContainerAnalysisData(
      imagePath: '/data/user/0/app_flutter/test_container.jpg',
      timestamp: DateTime.now().toIso8601String(),
      container: ca.ContainerInfo(
        shape: '圓柱體',
        material: '塑膡',
        color: '透明',
        features: ['密封蓋', '測量刻度', '防滑底部'],
      ),
      measurements: ca.MeasurementResults(
        volume: 450.75,
        confidence: 0.85,
        method: '智能視覺測量',
        dimensions: {
          '直徑': 8.2,
          '高度': 12.5,
          '底部厚度': 0.8,
        },
      ),
      metadata: ca.AnalysisMetadata(
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
      final newMeasurements = ca.MeasurementResults(
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
        _testAnalysisData = ca.ContainerAnalysisData(
          imagePath: _testAnalysisData!.imagePath,
          timestamp: DateTime.now().toIso8601String(),
          container: _testAnalysisData!.container,
          measurements: newMeasurements,
          metadata: ca.AnalysisMetadata(
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
      final ragData = ca.ContainerAnalysisData(
        imagePath: imagePath,
        timestamp: DateTime.now().toIso8601String(),
        container: ca.ContainerInfo(
          shape: _containerShape,
          material: '推測材質',
          color: '推測顏色',
          features: ['自動檢測特徵'],
        ),
        measurements: ca.MeasurementResults(
          volume: volume,
          confidence: 0.85,
          method: '智能視覺測量',
          dimensions: {
            '長度': 10.0,
            '寬度': 8.0,
            '高度': 12.0,
          },
        ),
        metadata: ca.AnalysisMetadata(
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
      await RagApiService.sendRagData(jsonData);

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
  Future<void> _saveToFirestore(ca.ContainerAnalysisData ragData) async {
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
      await log('自動計算結果: ${_calculatedVolume} cm³, 成功: $autoSuccess');
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
                        style: const TextStyle(
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
            },
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
                  await _selectImageFromGallery(); // 選擇相簿圖片
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

  // 修正參考測量頁面 placeholder
  Widget ReferenceMeasurementPage({
    required String imagePath,
    required Function(List<MeasurementResult>) onMeasurementComplete,
  }) {
    // 臨時實現，後續需要建立完整的參考測量頁面
    return Scaffold(
      body: Center(
        child: Text('參考測量頁面開發中...'),
      ),
    );
  }
}

/// Log utility function
Future<void> log(String message) async {
  // 簡單的日誌函數
  print('📸 $message');
}

/// Sync log utility function
void logSync(String message) {
  print('📸 $message');
}

// ===== 【UI頁面模組】結束 =====

// ===== 【工具類模組】開始 =====
// ====================================================================
// ----- [pages/camera/camera_screen.dart] 結束 -----