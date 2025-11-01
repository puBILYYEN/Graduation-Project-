import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../nutrition/presentation/pages/nutrition_label_screen.dart';

/// 相機螢幕 - 拍照和圖片選擇功能
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  /// 初始化相機
  Future<void> _initializeCamera() async {
    try {
      // 請求相機權限
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showPermissionDialog();
        return;
      }

      // 獲取可用相機
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras[0],
          ResolutionPreset.high,
        );

        await _controller!.initialize();
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('相機初始化失敗: $e');
      _showErrorDialog('相機初始化失敗: $e');
    }
  }

  /// 拍照
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final image = await _controller!.takePicture();
      await _processImage(image.path);
    } catch (e) {
      print('拍照失敗: $e');
      _showErrorDialog('拍照失敗: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 從相簿選擇圖片
  Future<void> _pickFromGallery() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        await _processImage(image.path);
      }
    } catch (e) {
      print('選擇圖片失敗: $e');
      _showErrorDialog('選擇圖片失敗: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 處理圖片並導航到營養標籤頁面
  Future<void> _processImage(String imagePath) async {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NutritionLabelScreen(
          imagePath: imagePath,
          onRetakePhoto: () {
            Navigator.pop(context); // 回到相機頁面
          },
          onSelectFromGallery: _pickFromGallery,
        ),
      ),
    );
  }

  /// 顯示權限對話框
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要相機權限'),
        content: const Text('此功能需要相機權限才能使用，請在設定中開啟相機權限。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('開啟設定'),
          ),
        ],
      ),
    );
  }

  /// 顯示錯誤對話框
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('錯誤'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '拍照辨識',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // 相機預覽或佔位符
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
            const Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 80,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '正在初始化相機...',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // 載入指示器
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),

          // 底部控制按鈕
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 相簿按鈕
                  IconButton(
                    onPressed: _isLoading ? null : _pickFromGallery,
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),

                  // 拍照按鈕
                  GestureDetector(
                    onTap: _isLoading ? null : _takePicture,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isLoading ? Colors.grey : Colors.white,
                      ),
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 32,
                            ),
                    ),
                  ),

                  // 切換相機按鈕（預留）
                  IconButton(
                    onPressed: null, // 暫時不實作
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white54,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}