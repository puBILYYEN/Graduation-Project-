import '../../../../core/services/camera_service.dart';

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:gal/gal.dart';  // Temporarily disabled due to Android compatibility issues
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../../core/services/api/api_services.dart';
import '../../../analysis/data/models/container_analysis.dart';
import '../../../measurement/data/models/measurement.dart';
import '../../../../data/models/reference_object.dart';
import '../../../../core/services/logging/logger.dart';

import '../../domain/usecases/get_available_cameras_usecase.dart';
import '../../domain/usecases/initialize_camera_usecase.dart';
import '../../domain/usecases/take_picture_usecase.dart';
import '../../domain/usecases/toggle_flash_usecase.dart';
import '../../domain/usecases/switch_camera_usecase.dart';
import '../../domain/usecases/pick_images_from_gallery_usecase.dart';
import '../../domain/usecases/analyze_image_usecase.dart';
import '../../domain/usecases/perform_volume_calculation_usecase.dart';


/// CameraViewModel: 負責處理所有與相機、拍照、計算相關的業務邏輯
class CameraViewModel extends ChangeNotifier {
  // ====================================================================
  // 狀態變數
  // ====================================================================

  // 相機控制相關
  CameraController? _controller;
  CameraController? get controller => _controller;

  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isFlashOn = false;
  bool get isFlashOn => _isFlashOn;

  int _currentCameraIndex = 0;

  // 容積計算相關
  bool _isVolumeMode = false;
  bool get isVolumeMode => _isVolumeMode;

  List<Offset> _detectedEdges = [];
  List<Offset> get detectedEdges => _detectedEdges;

  double _calculatedVolume = 0.0;
  double get calculatedVolume => _calculatedVolume;

  String _containerShape = '長方體';
  String get containerShape => _containerShape;

  bool _showVolumeResult = false;
  bool get showVolumeResult => _showVolumeResult;

  // 設備方向
  bool _isDeviceLandscape = false;
  bool get isDeviceLandscape => _isDeviceLandscape;

  // Use Cases
  final GetAvailableCamerasUseCase _getAvailableCamerasUseCase;
  final InitializeCameraUseCase _initializeCameraUseCase;
  final TakePictureUseCase _takePictureUseCase;
  final ToggleFlashUseCase _toggleFlashUseCase;
  final SwitchCameraUseCase _switchCameraUseCase;
  final PickImagesFromGalleryUseCase _pickImagesFromGalleryUseCase;
  final AnalyzeImageUseCase _analyzeImageUseCase;
  final PerformVolumeCalculationUseCase _performVolumeCalculationUseCase;
  final CameraService _cameraService;

  // Add mounted state tracking
  bool _mounted = true;
  bool get mounted => _mounted;

  // ====================================================================
  // 初始化和資源釋放
  // ====================================================================

  CameraViewModel({
    required GetAvailableCamerasUseCase getAvailableCamerasUseCase,
    required InitializeCameraUseCase initializeCameraUseCase,
    required TakePictureUseCase takePictureUseCase,
    required ToggleFlashUseCase toggleFlashUseCase,
    required SwitchCameraUseCase switchCameraUseCase,
    required PickImagesFromGalleryUseCase pickImagesFromGalleryUseCase,
    required AnalyzeImageUseCase analyzeImageUseCase,
    required PerformVolumeCalculationUseCase performVolumeCalculationUseCase,
    required CameraService cameraService, // Added this parameter
  })  : _getAvailableCamerasUseCase = getAvailableCamerasUseCase,
        _initializeCameraUseCase = initializeCameraUseCase,
        _takePictureUseCase = takePictureUseCase,
        _toggleFlashUseCase = toggleFlashUseCase,
        _switchCameraUseCase = switchCameraUseCase,
        _pickImagesFromGalleryUseCase = pickImagesFromGalleryUseCase,
        _analyzeImageUseCase = analyzeImageUseCase,
        _performVolumeCalculationUseCase = performVolumeCalculationUseCase,
        _cameraService = cameraService;

  /// 分階段初始化，避免資源競爭
  Future<void> initialize() async {
    try {
      debugPrint('🚀 [ViewModel] 開始初始化相機...');

      // 第一階段：初始化相機
      await _initializeCamera();
      debugPrint('✅ [ViewModel] 相機初始化完成');

      // 第二階段：立即啟動方向偵測（不延遲）
      if (mounted) {
        debugPrint('🧭 [ViewModel] 啟動方向偵測');
        _startOrientationDetection();

        // 在背景異步啟動穩定性監控，不阻塞UI
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            debugPrint('📊 [ViewModel] 啟動穩定性監控');
            _startStabilityMonitoring();
          }
        });
      }
    } catch (e) {
      logSync('分階段初始化失敗: $e');
      debugPrint('❌ [ViewModel] 初始化失敗: $e');
    }
  }

  /// 穩定性監控
  Timer? _stabilityTimer;
  int _stabilityCheckCount = 0;

  void _startStabilityMonitoring() {
    _stabilityTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _stabilityCheckCount++;
      logSync('穩定性檢查 #$_stabilityCheckCount - 相機狀態: ${_controller?.value.isInitialized ?? false}');

      // 檢查相機狀態
      if (_controller?.value.hasError == true) {
        logSync('檢測到相機錯誤，嘗試重新初始化');
        _handleCameraError();
      }

      // 10次檢查後停止監控
      if (_stabilityCheckCount >= 10) {
        timer.cancel();
        logSync('穩定性監控完成');
      }
    });
  }

  void _handleCameraError() async {
    try {
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      if (mounted) {
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          await _initializeCameraController(_currentCameraIndex);
        }
      }
    } catch (e) {
      logSync('處理相機錯誤失敗: $e');
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _stabilityTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  // ====================================================================
  // 核心方法
  // ====================================================================

  /// 初始化相機 - 異步執行，避免阻塞 UI
  Future<void> _initializeCamera() async {
    _setLoading(true);

    try {
      // 先初始化 CameraService 以獲取可用相機列表
      debugPrint('   [ViewModel] 初始化 CameraService...');

      // 添加整體超時保護
      await _cameraService.initializeCameras().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('   ❌ [ViewModel] CameraService 初始化超時');
          throw Exception('CameraService 初始化超時');
        },
      );

      // 再設置相機列表
      _cameras = _cameraService.cameras;
      if (_cameras.isEmpty) {
        debugPrint('   ❌ [ViewModel] 未找到可用的相機設備');
        _isInitialized = false;
        if (mounted) notifyListeners();
        return;
      }

      debugPrint('   ✅ [ViewModel] 找到 ${_cameras.length} 個可用相機');

      // 直接初始化相機控制器，移除不必要的延遲
      await _initializeCameraController(_currentCameraIndex);

    } catch (e) {
      debugPrint('   ❌ [ViewModel] 相機初始化失敗: $e');
      _isInitialized = false;
      if (mounted) notifyListeners();
      rethrow; // 重新拋出異常，讓上層處理
    } finally {
      _setLoading(false);
    }
  }

  /// 初始化相機控制器 - 改良版本，加強錯誤處理
  Future<void> _initializeCameraController(int cameraIndex) async {
    if (!mounted || _cameras.isEmpty || cameraIndex >= _cameras.length) {
      debugPrint('   ❌ [ViewModel] 無法初始化：mounted=$mounted, cameras=${_cameras.length}, index=$cameraIndex');
      return;
    }

    _isInitialized = false;
    if (mounted) notifyListeners();

    // 安全地釋放舊的控制器
    try {
      await _controller?.dispose();
      _controller = null;
    } catch (e) {
      debugPrint('   ⚠️ [ViewModel] 釋放舊控制器時出錯: $e');
    }

    try {
      debugPrint('   🎥 [ViewModel] 初始化相機控制器: ${_cameras[cameraIndex].name}');

      // 初始化新的控制器
      _controller = await _initializeCameraUseCase(_cameras[cameraIndex]);

      if (!mounted) {
        // 如果在初始化過程中組件被釋放，立即清理
        await _controller?.dispose();
        _controller = null;
        debugPrint('   ⚠️ [ViewModel] 組件已釋放，取消初始化');
        return;
      }

      _isInitialized = true;
      _currentCameraIndex = cameraIndex;
      debugPrint('   ✅ [ViewModel] 相機控制器初始化成功');
      debugPrint('   📢 [ViewModel] isInitialized=$_isInitialized, controller=${_controller != null}');

      // 立即通知UI更新，不等待額外延遲
      if (mounted) {
        debugPrint('   📢 [ViewModel] 通知 UI 更新...');
        notifyListeners();
      }

      // 設置閃光燈（如果需要）- 在背景異步執行
      if (_isFlashOn && _controller != null) {
        Future.microtask(() async {
          try {
            await _toggleFlashUseCase(_controller!, FlashMode.torch);
            debugPrint('   💡 [ViewModel] 閃光燈已設置');
          } catch (e) {
            debugPrint('   ⚠️ [ViewModel] 設置閃光燈失敗: $e');
          }
        });
      }

    } catch (e) {
      debugPrint('   ❌ [ViewModel] 相機控制器初始化失敗: $e');
      _isInitialized = false;
      _controller = null;
      if (mounted) notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    debugPrint('   [ViewModel] setLoading($loading), notifying listeners...');
    notifyListeners();
  }

  /// 切換前後相機
  Future<void> switchCamera() async {
    await AppLogger.logCameraAction('切換相機');
    debugPrint('🔄 switchCamera 被調用');
    debugPrint('   相機數量: ${_cameras.length}, isLoading: $_isLoading');

    if (_cameras.length <= 1) {
      debugPrint('   ❌ 只有一個相機，無法切換');
      return;
    }

    if (_isLoading) {
      debugPrint('   ⚠️ 正在載入中，無法切換');
      return;
    }

    final nextCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    debugPrint('   切換到相機 $nextCameraIndex');
    await _initializeCameraController(nextCameraIndex);
  }

  /// 切換閃光燈
  Future<void> toggleFlash() async {
    await AppLogger.logCameraAction('切換閃光燈');
    debugPrint('💡 toggleFlash 被調用');
    debugPrint('   controller: ${_controller != null}, 當前狀態: $_isFlashOn');

    if (_controller == null) {
      debugPrint('   ❌ 相機控制器為 null');
      return;
    }

    _isFlashOn = !_isFlashOn;
    debugPrint('   新狀態: $_isFlashOn');
    await _toggleFlashUseCase(_controller!, _isFlashOn ? FlashMode.torch : FlashMode.off);
    notifyListeners();
  }

  /// 切換容積計算模式
  void toggleVolumeMode() {
    _isVolumeMode = !_isVolumeMode;
    if (!_isVolumeMode) {
      _clearVolumeData();
    }
    notifyListeners();
  }

  void _clearVolumeData() {
    _detectedEdges = [];
    _calculatedVolume = 0.0;
    _showVolumeResult = false;
    notifyListeners();
  }

  /// 一般拍照，分析後進入營養標籤頁
  Future<void> takePictureAndNavigate(BuildContext context) async {
    debugPrint('📷 takePictureAndNavigate 被調用');
    debugPrint('   controller: ${_controller != null}');
    debugPrint('   isInitialized: ${_controller?.value.isInitialized ?? false}');
    debugPrint('   isLoading: $_isLoading');

    if (_controller == null) {
      debugPrint('   ❌ 相機控制器為 null');
      return;
    }

    if (!_controller!.value.isInitialized) {
      debugPrint('   ❌ 相機控制器未初始化');
      return;
    }

    _setLoading(true);
    try {
      debugPrint('   開始拍照...');
      final image = await _takePictureUseCase(_controller!);
      logSync('拍照成功，圖片路徑: ${image.path}');

      if (!context.mounted) return;

      logSync('正在上傳圖片至後端進行分析...');
      final analysisResult = await _analyzeImageUseCase(image.path);
      logSync('後端分析完成');

      if (context.mounted) {
        context.push('/camera/nutrition-label', extra: {
          'imagePath': image.path,
          'analysis': analysisResult,
        });
      }
    } catch (e) {
      logSync('拍照或分析過程中發生錯誤: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('圖片分析失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  /// 從相簿選擇圖片
  final ImagePicker _picker = ImagePicker(); // Added _picker

  Future<void> pickFromGallery(BuildContext context) async {
    debugPrint('🖼️ pickFromGallery 被調用');
    debugPrint('   isLoading: $_isLoading');

    try {
      debugPrint('   打開相簿選擇器...');
      final images = await _picker.pickMultiImage(
        imageQuality: 80,
        limit: 10,
      );

      debugPrint('   選擇了 ${images.length} 張圖片');
      if (images.isEmpty) {
        debugPrint('   ⚠️ 未選擇圖片');
        return;
      }

      if (!context.mounted) return;
      if (images.length == 1) {
        debugPrint('   處理單張圖片: ${images.first.path}');
        _processImage(context, images.first.path);
      } else {
        debugPrint('   處理多張圖片');
        _processMultipleImages(context, images);
      }
    } catch (e) {
      logSync('選擇圖片失敗: $e');
      debugPrint('❌ 選擇圖片失敗: $e');
    }
  }

  void _processImage(BuildContext context, String imagePath) {
    context.push('/camera/nutrition-label', extra: imagePath);
  }

  void _processMultipleImages(BuildContext context, List<XFile> images) {
    context.push('/camera/process-multiple', extra: {
      'images': images,
    });
  }

  // ====================================================================
  // 容積計算相關方法
  // ====================================================================

  Future<void> takeVolumePhoto(BuildContext context) async {
    debugPrint('📸 takeVolumePhoto 被調用');
    debugPrint('   controller: ${_controller != null}');
    debugPrint('   isInitialized: ${_controller?.value.isInitialized ?? false}');
    debugPrint('   isLoading: $_isLoading');

    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('   ❌ 相機未準備好');
      return;
    }

    _setLoading(true);

    try {
      debugPrint('   開始拍照...');
      final image = await _controller!.takePicture();
      debugPrint('   拍照成功: ${image.path}');
      await _performAutoVolumeCalculation(context, image.path);
    } catch (e) {
      logSync('容積計算拍照錯誤: $e');
      debugPrint('   ❌ 錯誤: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _performAutoVolumeCalculation(BuildContext context, String imagePath) async {
    try {
      debugPrint('📐 開始自動容積計算');
      _detectedEdges = _performEdgeDetection();
      _containerShape = _detectContainerShape(_detectedEdges);
      final estimatedDimensions = _estimateDimensionsFromEdges();
      _calculatedVolume = _calculateVolumeFromDimensions(estimatedDimensions);
      _showVolumeResult = true;
      debugPrint('   計算結果: $_calculatedVolume cm³');
      notifyListeners();

      await _generateRagData(imagePath, _calculatedVolume);

      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('容積計算完成！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logSync('自動容積計算錯誤: $e');
      debugPrint('❌ 自動容積計算錯誤: $e');
    }
  }

  List<Offset> _performEdgeDetection() {
    // Mock implementation
    debugPrint('   執行邊緣檢測（模擬）');
    return const [
      Offset(100, 100),
      Offset(300, 100),
      Offset(300, 400),
      Offset(100, 400),
    ];
  }

  String _detectContainerShape(List<Offset> edges) {
    // Mock implementation
    return '長方體';
  }

  Map<String, double> _estimateDimensionsFromEdges() {
    // Mock implementation
    return {'length': 10.0, 'width': 8.0, 'height': 12.0};
  }

  double _calculateVolumeFromDimensions(Map<String, double> dimensions) {
    // Mock implementation
    return dimensions['length']! * dimensions['width']! * dimensions['height']!;
  }

  Future<void> _generateRagData(String imagePath, double volume) async {
    try {
      final ragData = ContainerAnalysis(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Assuming an ID is needed
        imagePath: imagePath,
        containerType: _containerShape, // Using containerShape as containerType
        confidence: 0.85, // Placeholder confidence
        dimensions: ContainerDimensions( // Placeholder dimensions
          width: 10.0,
          height: 8.0,
          depth: 12.0,
          volume: volume,
          unit: 'cm',
        ),
        analyzedAt: DateTime.now(),
        detectedObjects: [], // Placeholder for detected objects
      );
      
      await _saveToFirestore(ragData);
    } catch (e) {
      logSync('RAG 數據生成失敗: $e');
    }
  }

  Future<void> _saveToFirestore(ContainerAnalysis ragData) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String docId = DateTime.now().millisecondsSinceEpoch.toString();
      await firestore
          .collection('container_measurements')
          .doc(docId)
          .set(ragData.toMap()); // Use toMap() for ContainerAnalysis
    } catch (e) {
      logSync('Firebase 保存失敗: $e');
    }
  }


  // ====================================================================
  // 方向檢測
  // ====================================================================
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  void _startOrientationDetection() {
    try {
      debugPrint('🧭 開始方向偵測');
      _accelerometerSubscription?.cancel();
      _accelerometerSubscription = accelerometerEvents.listen(
        (AccelerometerEvent event) {
          if (!mounted) return;

          // 優化判斷邏輯：使用更大的閾值避免誤判
          final isLandscape = event.x.abs() > event.y.abs() + 1.0;

          if (isLandscape != _isDeviceLandscape) {
            _isDeviceLandscape = isLandscape;
            debugPrint('🔄 設備方向改變: ${isLandscape ? "橫向" : "縱向"}');
            debugPrint('   加速度計數據: x=${event.x.toStringAsFixed(2)}, y=${event.y.toStringAsFixed(2)}');
            if (mounted) notifyListeners();
          }
        },
        onError: (error) {
          logSync('加速度計錯誤: $error');
          debugPrint('❌ 加速度計錯誤: $error');
        },
        cancelOnError: false, // 改為 false，避免錯誤後停止偵測
      );
    } catch (e) {
      logSync('加速度計初始化失敗: $e');
      debugPrint('❌ 加速度計初始化失敗: $e');
    }
  }
}