import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

// 假設的 RAG 數據模型和日誌服務
// 在實際應用中，這些應該是真實的導入
Future<void> log(String message) async => print(message);
class ContainerAnalysisData {
  final String imagePath;
  final String timestamp;
  final ContainerInfo container;
  final MeasurementResults measurements;
  final AnalysisMetadata metadata;
  ContainerAnalysisData({required this.imagePath, required this.timestamp, required this.container, required this.measurements, required this.metadata});
  Map<String, dynamic> toJson() => {};
}
class ContainerInfo {
  final String shape;
  final String material;
  final String color;
  final List<String> features;
  ContainerInfo({required this.shape, required this.material, required this.color, required this.features});
}
class MeasurementResults {
  final double volume;
  final double confidence;
  final String method;
  final Map<String, double> dimensions;
  MeasurementResults({required this.volume, required this.confidence, required this.method, required this.dimensions});
}
class AnalysisMetadata {
  final String deviceInfo;
  final String algorithm;
  final double processingTime;
  final String notes;
  AnalysisMetadata({required this.deviceInfo, required this.algorithm, required this.processingTime, required this.notes});
}


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

  // 圖片選擇相關
  final ImagePicker _picker = ImagePicker();

  // 容積計算相關
  bool _isVolumeMode = false;
  bool get isVolumeMode => _isVolumeMode;

  List<Offset> _detectedEdges = [];
  List<Offset> get detectedEdges => _detectedEdges;

  double _calculatedVolume = 0.0;
  String _containerShape = '長方體';
  bool _showVolumeResult = false;
  bool get showVolumeResult => _showVolumeResult;

  // ====================================================================
  // 初始化和資源釋放
  // ====================================================================

  CameraViewModel() {
    _initializeCamera();
  }

  @override
  void dispose() async {
    try {
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }
    } catch (e) {
      await log('釋放相機控制器時發生錯誤: $e');
    }
    super.dispose();
  }

  // ====================================================================
  // 核心方法 (從 smart_camera_page.dart 遷移過來)
  // ====================================================================

  /// 步驟 1: 初始化相機
  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        // TODO: 處理權限被拒絕的情況 (例如顯示一個對話框)
        await log("相機權限被拒絕");
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _initializeCameraController(_currentCameraIndex);
      }
    } catch (e) {
      await log('相機初始化失敗: $e');
    }
  }

  /// 初始化相機控制器
  Future<void> _initializeCameraController(int cameraIndex) async {
    if (_cameras.isEmpty || cameraIndex >= _cameras.length) {
      await log('無效的相機索引: $cameraIndex (總數: ${_cameras.length})');
      return;
    }

    try {
      // 釋放舊的控制器，並等待完全釋放
      if (_controller != null) {
        await log('正在釋放舊的相機控制器...');
        await _controller!.dispose();
        _controller = null;
        await log('舊的相機控制器已釋放');
      }

      // 創建新的控制器
      _controller = CameraController(
        _cameras[cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await log('正在初始化相機控制器 $cameraIndex...');
      await _controller!.initialize();

      // 初始化成功後更新狀態
      _isInitialized = true;
      _currentCameraIndex = cameraIndex;
      await log('相機 $cameraIndex 初始化成功: ${_cameras[cameraIndex].name}');

      // 如果之前有設定閃光燈，重新設定
      if (_isFlashOn) {
        try {
          await _controller!.setFlashMode(FlashMode.torch);
          await log('已恢復閃光燈設定');
        } catch (e) {
          await log('設定閃光燈失敗: $e');
          _isFlashOn = false;
        }
      }
    } catch (e) {
      _isInitialized = false;
      _controller = null;
      await log('相機控制器初始化失敗: $e');
      rethrow; // 重新拋出異常，讓調用者處理
    } finally {
      notifyListeners();
    }
  }

  /// 切換前後相機
  Future<void> switchCamera() async {
    if (_cameras.length <= 1 || _isLoading) return;

    _setLoading(true);
    _isInitialized = false;
    notifyListeners(); // 關鍵一步：先通知 UI 移除 CameraPreview

    // 等待一小段時間確保 UI 完成重建
    await Future.delayed(const Duration(milliseconds: 100));

    final nextCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _initializeCameraController(nextCameraIndex);
    
    // _initializeCameraController 內部會再次 notifyListeners()，所以這裡不用再通知
    _setLoading(false);
  }

  /// 切換閃光燈
  Future<void> toggleFlash() async {
    if (_controller == null) return;
    _isFlashOn = !_isFlashOn;
    await _controller!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 步驟 2: 主要拍照功能入口 (容積計算模式)
  Future<void> takeVolumePhoto(BuildContext context) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _setLoading(true);

    try {
      await log('開始容積計算拍照...');
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = path.join(
        directory.path,
        'volume_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final XFile image = await _controller!.takePicture();
      await image.saveTo(imagePath);

      try {
        final result = await ImageGallerySaver.saveFile(imagePath);
        await log('容積計算照片保存結果: $result');
      } catch (e) {
        await log('保存照片到相簿失敗: $e');
      }

      await _performAutoVolumeCalculation(context, imagePath);

    } catch (e) {
      await log('容積計算拍照錯誤: $e');
      // TODO: 顯示錯誤訊息給用戶
    } finally {
      _setLoading(false);
    }
  }
  
  /// 一般拍照，拍完進入營養標籤頁
  Future<void> takePictureAndNavigate(BuildContext context) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    _setLoading(true);
    try {
      final image = await _controller!.takePicture();
      if (context.mounted) {
        context.push('/camera/nutrition-label', extra: image.path);
      }
    } catch (e) {
      await log('拍照失敗: $e');
    } finally {
      _setLoading(false);
    }
  }


  /// 步驟 3: 自動容積計算核心功能
  Future<void> _performAutoVolumeCalculation(BuildContext context, String imagePath) async {
    try {
      await log('開始自動容積計算流程...');
      _detectedEdges = _performEdgeDetection();
      final detectedShape = _detectContainerShape(_detectedEdges);
      _containerShape = detectedShape;
      final estimatedDimensions = _estimateDimensionsFromEdges();
      final volume = _calculateVolumeFromDimensions(estimatedDimensions);
      _calculatedVolume = volume;
      _showVolumeResult = false; // 根據舊程式碼，不直接顯示結果區域
      notifyListeners();

      await log('容積計算完成: ${volume.toStringAsFixed(2)} cm³');
      await _generateRagData(imagePath, volume);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('容積計算完成！\n${volume.toStringAsFixed(2)} cm³ (${(volume / 1000).toStringAsFixed(3)} L)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '查看詳細',
              textColor: Colors.white,
              onPressed: () {
                // TODO: 實現顯示詳細結果的功能
              },
            ),
          ),
        );
      }
    } catch (e) {
      await log('自動容積計算錯誤: $e');
    }
  }

  /// 步驟 4: 尺寸估算函數 (模擬)
  Map<String, double> _estimateDimensionsFromEdges() {
    if (_detectedEdges.isEmpty) {
      return {'length': 10.0, 'width': 8.0, 'height': 12.0};
    }
    double minX = _detectedEdges.map((e) => e.dx).reduce(math.min);
    double maxX = _detectedEdges.map((e) => e.dx).reduce(math.max);
    double minY = _detectedEdges.map((e) => e.dy).reduce(math.min);
    double maxY = _detectedEdges.map((e) => e.dy).reduce(math.max);

    double pixelToCm = 0.05;
    double width = (maxX - minX) * pixelToCm;
    double height = (maxY - minY) * pixelToCm;
    double depth = width * 0.8;

    return {'length': width, 'width': depth, 'height': height};
  }

  /// 步驟 5: 容積計算函數
  double _calculateVolumeFromDimensions(Map<String, double> dimensions) {
    switch (_containerShape) {
      case '長方體':
        return dimensions['length']! * dimensions['width']! * dimensions['height']!;
      case '圓柱體':
        double radius = dimensions['length']! / 2;
        return math.pi * radius * radius * dimensions['height']!;
      case '立方體':
        double side = (dimensions['length']! + dimensions['width']!) / 2;
        return side * side * side;
      default:
        return dimensions['length']! * dimensions['width']! * dimensions['height']!;
    }
  }

  /// 步驟 6: RAG數據生成函數
  Future<void> _generateRagData(String imagePath, double volume) async {
    try {
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
          dimensions: {'長度': 10.0, '寬度': 8.0, '高度': 12.0},
        ),
        metadata: AnalysisMetadata(
          deviceInfo: '智能手機',
          algorithm: 'EdgeDetection+ShapeRecognition',
          processingTime: 1.5,
          notes: '自動容積計算完成',
        ),
      );
      final jsonData = ragData.toJson();
      await log('RAG 數據已生成: ${jsonData.toString()}');
    } catch (e) {
      await log('RAG 數據生成失敗: $e');
    }
  }

  // 模擬邊緣檢測和形狀識別
  List<Offset> _performEdgeDetection() {
    // 這是一個模擬實現
    return [
      const Offset(100, 100),
      const Offset(300, 100),
      const Offset(300, 400),
      const Offset(100, 400),
    ];
  }

  String _detectContainerShape(List<Offset> edges) {
    // 這是一個模擬實現
    return '長方體';
  }

  /// 從相簿選擇圖片（支援多選）
  Future<void> pickFromGallery(BuildContext context) async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 80,
        limit: 10,
      );

      if (images.isEmpty) return;

      if (images.length == 1) {
        // 單張圖片直接處理
        await _processImage(context, images.first.path);
      } else {
        // 多張圖片導航到處理頁面
        await _processMultipleImages(context, images);
      }
    } catch (e) {
      await log('選擇圖片失敗: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('選擇圖片失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 處理單張圖片
  Future<void> _processImage(BuildContext context, String imagePath) async {
    if (context.mounted) {
      context.push('/camera/nutrition-label', extra: imagePath);
    }
  }

  /// 處理多張圖片
  Future<void> _processMultipleImages(BuildContext context, List<XFile> images) async {
    if (context.mounted) {
      context.push('/camera/process-multiple', extra: {
        'images': images,
        'onRetakePhoto': () => context.pop(),
        'onSelectFromGallery': () => pickFromGallery(context),
      });
    }
  }

  /// 返回上一頁
  void goBack(BuildContext context) {
    context.pop();
  }
}