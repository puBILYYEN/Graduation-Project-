import '../../../../core/services/camera_service.dart';

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../viewmodels/camera_view_model.dart';
import '../../../measurement/presentation/widgets/custom_painters.dart';
import '../../domain/usecases/get_available_cameras_usecase.dart';
import '../../domain/usecases/initialize_camera_usecase.dart';
import '../../domain/usecases/take_picture_usecase.dart';
import '../../domain/usecases/toggle_flash_usecase.dart';
import '../../domain/usecases/switch_camera_usecase.dart';
import '../../domain/usecases/pick_images_from_gallery_usecase.dart';
import '../../domain/usecases/analyze_image_usecase.dart';
import '../../domain/usecases/perform_volume_calculation_usecase.dart';

/// 智慧相機頁面 - 現在是一個輕量級的視圖
class SmartCameraScreen extends StatelessWidget {
  const SmartCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 ChangeNotifierProvider 來建立和提供 CameraViewModel
    return ChangeNotifierProvider(
      create: (context) => CameraViewModel(
        getAvailableCamerasUseCase: context.read<GetAvailableCamerasUseCase>(),
        initializeCameraUseCase: context.read<InitializeCameraUseCase>(),
        takePictureUseCase: context.read<TakePictureUseCase>(),
        toggleFlashUseCase: context.read<ToggleFlashUseCase>(),
        pickImagesFromGalleryUseCase: context.read<PickImagesFromGalleryUseCase>(),
        analyzeImageUseCase: context.read<AnalyzeImageUseCase>(),
        performVolumeCalculationUseCase: context.read<PerformVolumeCalculationUseCase>(),
        cameraService: context.read<CameraService>(),
      ),
      child: const _SmartCameraView(),
    );
  }
}

/// 智慧相機的 UI 視圖實現 - 現在支援橫拿模式
class _SmartCameraView extends StatefulWidget {
  const _SmartCameraView();

  @override
  State<_SmartCameraView> createState() => _SmartCameraViewState();
}

class _SmartCameraViewState extends State<_SmartCameraView> {
  // 橫拿模式相關狀態
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _iconRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _startOrientationDetection();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  /// 開始偵測設備方向
  void _startOrientationDetection() {
    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        if (!mounted) return;

        double x = event.x;
        double y = event.y;

        // 根據加速度決定圖示旋轉角度
        double newRotation = 0.0;
        if (x.abs() > y.abs()) { // 橫向
          newRotation = x > 0 ? 90.0 : -90.0;
        } // 縱向則為 0.0

        if ((_iconRotation - newRotation).abs() > 1) { // 避免頻繁重繪
          setState(() {
            _iconRotation = newRotation;
          });
        }
      },
      onError: (error) {
        print('加速度計錯誤: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 從 Provider 獲取 ViewModel 的實例
    // 使用 .watch() 會在 notifyListeners() 被調用時自動重建此 Widget
    final viewModel = context.watch<CameraViewModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // 使用標準的返回方法
        ),
        title: const Text('智慧拍照測量', style: TextStyle(color: Colors.white)),
        actions: [
          // 容積模式切換按鈕
          IconButton(
            icon: Icon(
              viewModel.isVolumeMode ? Icons.view_in_ar : Icons.straighten,
              color: viewModel.isVolumeMode ? Colors.yellow : Colors.white,
            ),
            onPressed: () => context.read<CameraViewModel>().toggleVolumeMode(),
          ),
          // 閃光燈控制
          IconButton(
            icon: Icon(
              viewModel.isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () => context.read<CameraViewModel>().toggleFlash(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 相機預覽
          if (viewModel.isInitialized && viewModel.controller != null)
            Positioned.fill(child: CameraPreview(viewModel.controller!))
          else
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 相機圖示 + 載入動畫
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // 外圈載入動畫
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        // 中間相機圖示
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    // 載入文字
                    Text(
                      '正在啟動智慧相機...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '請稍候，相機正在初始化',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 32),
                    // 點狀載入指示器 - 動畫效果
                    _LoadingDots(),
                  ],
                ),
              ),
            ),

          // 邊緣檢測繪圖
          if (viewModel.detectedEdges.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(painter: EdgeDetectionPainter(viewModel.detectedEdges)),
            ),

          // TODO: 測量框架和繪圖邏輯需要進一步與 ViewModel 整合
          // MeasurementFrame(...),

          // 載入指示器
          if (viewModel.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),

          // 底部控制按鈕 - 支援旋轉
          _BottomControls(iconRotation: _iconRotation),
        ],
      ),
    );
  }
}

/// 底部控制按鈕區域 - 支援旋轉
class _BottomControls extends StatelessWidget {
  final double iconRotation;

  const _BottomControls({required this.iconRotation});

  @override
  Widget build(BuildContext context) {
    // 使用 .select() 來精確監聽特定狀態的變化，避免不必要的重建
    final isLoading = context.select((CameraViewModel vm) => vm.isLoading);
    final isVolumeMode = context.select((CameraViewModel vm) => vm.isVolumeMode);
    final viewModel = context.read<CameraViewModel>(); // 用於調用方法

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.black.withOpacity(0.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 相簿按鈕（支援多選）- 支援旋轉
            GestureDetector(
              onTap: isLoading ? null : () => viewModel.pickFromGallery(context),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Transform.rotate(
                  angle: iconRotation * (3.14159 / 180), // 轉換為弧度
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 28,
                      ),
                      // 多選指示器
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 拍照按鈕 - 支援旋轉
            GestureDetector(
              onTap: isLoading
                  ? null
                  : () => isVolumeMode
                      ? viewModel.takeVolumePhoto(context)
                      : viewModel.takePictureAndNavigate(context),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: isLoading ? Colors.grey : (isVolumeMode ? Colors.yellow : Colors.white),
                ),
                child: Transform.rotate(
                  angle: iconRotation * (3.14159 / 180), // 轉換為弧度
                  child: Icon(
                    isVolumeMode ? Icons.view_in_ar : Icons.camera_alt,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
              ),
            ),

            // 切換相機按鈕 - 支援旋轉
            GestureDetector(
              onTap: isLoading ? null : () => viewModel.switchCamera(),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Transform.rotate(
                  angle: iconRotation * (3.14159 / 180), // 轉換為弧度
                  child: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 載入點動畫 Widget
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // 依序啟動動畫，形成波浪效果
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_animations[index].value),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}