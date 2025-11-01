import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
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
  final PickImagesFromGalleryUseCase _pickImagesFromGalleryUseCase;
  final AnalyzeImageUseCase _analyzeImageUseCase;
  final PerformVolumeCalculationUseCase _performVolumeCalculationUseCase;

  // ====================================================================
  // 初始化和資源釋放
  // ====================================================================

  CameraViewModel({
    required GetAvailableCamerasUseCase getAvailableCamerasUseCase,
    required InitializeCameraUseCase initializeCameraUseCase,
    required TakePictureUseCase takePictureUseCase,
    required ToggleFlashUseCase toggleFlashUseCase,
    required PickImagesFromGalleryUseCase pickImagesFromGalleryUseCase,
    required AnalyzeImageUseCase analyzeImageUseCase,
    required PerformVolumeCalculationUseCase performVolumeCalculationUseCase,
  })  : _getAvailableCamerasUseCase = getAvailableCamerasUseCase,
        _initializeCameraUseCase = initializeCameraUseCase,
        _takePictureUseCase = takePictureUseCase,
        _toggleFlashUseCase = toggleFlashUseCase,
        _pickImagesFromGalleryUseCase = pickImagesFromGalleryUseCase,
        _analyzeImageUseCase = analyzeImageUseCase,
        _performVolumeCalculationUseCase = performVolumeCalculationUseCase {
    _initializeCamera();
    _startOrientationDetection();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  // ====================================================================
  // 核心方法
  // ====================================================================

  /// 初始化相機
  Future<void> _initializeCamera() async {
    _setLoading(true);
    try {
      _cameras = await _getAvailableCamerasUseCase();
      if (_cameras.isNotEmpty) {
        await _initializeCameraController(_currentCameraIndex);
      }
    } catch (e) {
      log('相機初始化失敗: $e');
    }
    _setLoading(false);
  }

  /// 初始化相機控制器
  Future<void> _initializeCameraController(int cameraIndex) async {
    if (_cameras.isEmpty || cameraIndex >= _cameras.length) {
      return;
    }

    _setLoading(true);
    _isInitialized = false;
    notifyListeners();

    await _controller?.dispose();

    try {
      _controller = await _initializeCameraUseCase(_cameras[cameraIndex]);
      _isInitialized = true;
      _currentCameraIndex = cameraIndex;
      if (_isFlashOn) {
        await _toggleFlashUseCase(_controller!, FlashMode.torch);
      }
    } catch (e) {
      log('相機控制器初始化失敗: $e');
      _isInitialized = false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 切換前後相機
  Future<void> switchCamera() async {
    if (_cameras.length <= 1 || _isLoading) return;
    final nextCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _initializeCameraController(nextCameraIndex);
  }

  /// 切換閃光燈
  Future<void> toggleFlash() async {
    if (_controller == null) return;
    _isFlashOn = !_isFlashOn;
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
    if (_controller == null || !_controller!.value.isInitialized) return;
    _setLoading(true);
    try {
      final image = await _takePictureUseCase(_controller!); 
      log('拍照成功，圖片路徑: ${image.path}');

      if (!context.mounted) return;

      log('正在上傳圖片至後端進行分析...');
      final analysisResult = await _analyzeImageUseCase(image.path);
      log('後端分析完成');

      if (context.mounted) {
        context.push('/camera/nutrition-label', extra: {
          'imagePath': image.path,
          'analysis': analysisResult,
        });
      }
    } catch (e) {
      log('拍照或分析過程中發生錯誤: $e');
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
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 80,
        limit: 10,
      );

      if (images.isEmpty) return;

      if (images.length == 1) {
        _processImage(context, images.first.path);
      } else {
        _processMultipleImages(context, images);
      }
    } catch (e) {
      log('選擇圖片失敗: $e');
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
    if (_controller == null || !_controller!.value.isInitialized) return;

    _setLoading(true);

    try {
      final image = await _controller!.takePicture();
      await _performAutoVolumeCalculation(context, image.path);
    } catch (e) {
      log('容積計算拍照錯誤: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _performAutoVolumeCalculation(BuildContext context, String imagePath) async {
    try {
      _detectedEdges = _performEdgeDetection();
      _containerShape = _detectContainerShape(_detectedEdges);
      final estimatedDimensions = _estimateDimensionsFromEdges();
      _calculatedVolume = _calculateVolumeFromDimensions(estimatedDimensions);
      _showVolumeResult = true;
      notifyListeners();

      await _generateRagData(imagePath, _calculatedVolume);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('容積計算完成！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      log('自動容積計算錯誤: $e');
    }
  }

  List<Offset> _performEdgeDetection() {
    // Mock implementation
    return [
      const Offset(100, 100),
      const Offset(300, 100),
      const Offset(300, 400),
      const Offset(100, 400),
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
      log('RAG 數據生成失敗: $e');
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
      log('Firebase 保存失敗: $e');
    }
  }


  // ====================================================================
  // 方向檢測
  // ====================================================================
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  void _startOrientationDetection() {
    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        final isLandscape = event.x.abs() > event.y.abs();
        if (isLandscape != _isDeviceLandscape) {
          _isDeviceLandscape = isLandscape;
          notifyListeners();
        }
      },
    );
  }
}