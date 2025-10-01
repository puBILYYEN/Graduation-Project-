// AK47 風格精簡版：相機功能
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import '../ui/widgets.dart' as ui_widgets;
import '../utils/constants.dart';
import '../core/logger.dart';
import '../core/sensors.dart';
import 'preview.dart';
import 'photo_selector.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _setOrientation();
    _initSensors();
  }

  Future<void> _initSensors() async {
    await SensorManager.i.init();
    SensorManager.i.setOrientationCallback((orientation) {
      // 根據方向變化更新 UI 或邏輯
      log('設備方向變化: ${SensorManager.i.getOrientationDescription()}');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: _buildBody(),
    bottomNavigationBar: _isInitialized ? _buildControls() : null,
  );

  Widget _buildBody() {
    if (_error != null) {
      return ui_widgets.ErrorWidget(
        message: _error!,
        onRetry: _initCamera,
      );
    }

    if (!_isInitialized) {
      return const ui_widgets.LoadingWidget();
    }

    return Stack(
      children: [
        // 相機預覽
        Positioned.fill(
          child: CameraPreview(_controller!),
        ),
        // 返回按鈕
        Positioned(
          top: MediaQuery.of(context).padding.top + AppSpacing.m,
          left: AppSpacing.m,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() => Container(
    color: Colors.black,
    padding: const EdgeInsets.all(AppSpacing.l),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 相簿按鈕
        IconButton(
          icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
          onPressed: _openGallery,
        ),
        // 拍照按鈕
        GestureDetector(
          onTap: _takePicture,
          child: Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, size: 30),
          ),
        ),
        // 切換相機按鈕
        IconButton(
          icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
          onPressed: _switchCamera,
        ),
      ],
    ),
  );

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        setState(() => _error = '未找到相機');
        return;
      }

      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _error = null;
        });
      }

      await log('Camera initialized');
    } catch (e) {
      await log('Camera init error: $e');
      if (mounted) {
        setState(() => _error = '相機初始化失敗: $e');
      }
    }
  }

  Future<void> _setOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      await log('Photo taken: ${image.path}');

      if (mounted) {
        // 導航到預覽頁面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewPage(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      await log('Take picture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('拍照失敗: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    try {
      final currentIndex = _cameras!.indexOf(_controller!.description);
      final newIndex = (currentIndex + 1) % _cameras!.length;

      await _controller!.dispose();

      _controller = CameraController(
        _cameras![newIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) setState(() {});
      await log('Camera switched');
    } catch (e) {
      await log('Switch camera error: $e');
    }
  }

  void _openGallery() {
    // 導航到圖片選擇器
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const PhotoSelector(),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }
}