import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../viewmodels/camera_view_model.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/camera_service.dart';
import '../../domain/usecases/get_available_cameras_usecase.dart';
import '../../domain/usecases/initialize_camera_usecase.dart';
import '../../domain/usecases/take_picture_usecase.dart';
import '../../domain/usecases/toggle_flash_usecase.dart';
import '../../domain/usecases/pick_images_from_gallery_usecase.dart';
import '../../domain/usecases/analyze_image_usecase.dart';
import '../../domain/usecases/perform_volume_calculation_usecase.dart';
import '../../domain/usecases/switch_camera_usecase.dart';

/// 智慧相機頁面 - 無預覽版本，避免崩潰
class SmartCameraScreen extends StatefulWidget {
  const SmartCameraScreen({super.key});

  @override
  State<SmartCameraScreen> createState() => _SmartCameraScreenState();
}

class _SmartCameraScreenState extends State<SmartCameraScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 只在非網頁平台且未初始化時，初始化全局的 ViewModel
    if (!kIsWeb && !_isInitialized) {
      _isInitialized = true;

      // 延遲到下一幀執行，避免在 build 期間觸發 setState
      AppLogger.logEvent('智慧相機頁面初始化');
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // 使用全局的 CameraViewModel
          final viewModel = context.read<CameraViewModel>();
          debugPrint('✅ 獲取全局 CameraViewModel: ${viewModel != null}');

          // 初始化相機（如果還沒初始化）
          if (!viewModel.isInitialized) {
            debugPrint('🎬 開始初始化 CameraViewModel');
            await AppLogger.logCameraAction('開始初始化 CameraViewModel');
            viewModel.initialize();
          } else {
            debugPrint('✅ CameraViewModel 已經初始化');
          }
        } catch (e) {
          debugPrint('❌ 獲取或初始化 CameraViewModel 失敗: $e');
          await AppLogger.logEvent('[ERROR] 相機初始化失敗: $e');
        }
      });
    }
  }

  @override
  void dispose() {
    // 不要 dispose 全局的 ViewModel
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 網頁平台不支援相機功能
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            '智慧拍照測量',
            style: TextStyle(color: Colors.black87),
          ),
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 80,
                    color: Colors.blue[300],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  '📱 相機功能僅支援行動裝置',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Camera feature is only available on\nmobile devices (Android/iOS)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '請使用手機或平板電腦開啟本應用程式\n以使用智慧拍照和食物辨識功能',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber[900],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text(
                    '返回首頁',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 行動平台：直接使用全局的 CameraViewModel
    return const _StableCameraView();
  }
}

/// 穩定的相機視圖 - 不使用 CameraPreview
class _StableCameraView extends StatelessWidget {
  const _StableCameraView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CameraViewModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('智慧拍照測量', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(
              viewModel.isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () => viewModel.toggleFlash(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 模擬相機界面 - 不使用真實預覽以避免崩潰
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 相機狀態圖示
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      viewModel.isInitialized
                          ? Icons.camera_alt
                          : Icons.camera_alt_outlined,
                      color: viewModel.isInitialized
                          ? Colors.green
                          : Colors.white,
                      size: 60,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 狀態文字
                  Text(
                    viewModel.isInitialized
                        ? '相機已就緒'
                        : '正在初始化相機...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    viewModel.isInitialized
                        ? '點擊下方按鈕進行拍攝\n拍攝後將自動進行營養分析'
                        : '請稍候...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 相機信息
                  if (viewModel.isInitialized)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '使用後置相機拍攝效果更佳',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 簡化的控制按鈕
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 調試信息顯示
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '狀態: ${viewModel.isInitialized ? "已初始化" : "未初始化"} | ${viewModel.isLoading ? "載入中" : "就緒"}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 相簿按鈕
                    _CameraButton(
                      icon: Icons.photo_library,
                      label: '相簿',
                      onPressed: viewModel.isLoading
                          ? null
                          : () {
                              debugPrint('🖼️ 點擊相簿按鈕');
                              viewModel.pickFromGallery(context);
                            },
                    ),

                    // 拍照按鈕
                    _CameraButton(
                      icon: Icons.camera_alt,
                      label: '拍照',
                      size: 80,
                      isMain: true,
                      onPressed: (viewModel.isLoading || !viewModel.isInitialized)
                          ? null
                          : () {
                              debugPrint('📷 點擊拍照按鈕');
                              viewModel.takePictureAndNavigate(context);
                            },
                    ),

                    // 切換相機按鈕
                    _CameraButton(
                      icon: Icons.flip_camera_ios,
                      label: '切換',
                      onPressed: (viewModel.isLoading || !viewModel.isInitialized)
                          ? null
                          : () {
                              debugPrint('🔄 點擊切換相機按鈕');
                              viewModel.switchCamera();
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 載入指示器
          if (viewModel.isLoading)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      '處理中...',
                      style: TextStyle(color: Colors.white),
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

/// 自定義相機按鈕
class _CameraButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;
  final bool isMain;

  const _CameraButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.size = 60,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,  // 確保捕獲所有觸控事件
          onTap: () {
            debugPrint('🔘 GestureDetector 觸發: $label (enabled: $isEnabled)');
            if (isEnabled) {
              onPressed!();
            } else {
              debugPrint('⚠️ 按鈕已禁用');
            }
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isMain
                  ? Colors.white
                  : Colors.white.withOpacity(isEnabled ? 0.9 : 0.3),
              shape: BoxShape.circle,
              border: isMain
                  ? Border.all(color: Colors.grey.shade300, width: 3)
                  : Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
            ),
            child: Icon(
              icon,
              color: isMain ? Colors.black : Colors.black,
              size: size * 0.4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(isEnabled ? 1.0 : 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}