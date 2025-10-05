// AK47 風格精簡版：圖片選擇器
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../ui/widgets.dart';
import '../utils/constants.dart';
import '../core/logger.dart';
import 'preview.dart';
import 'camera.dart';

class PhotoSelector extends StatefulWidget {
  const PhotoSelector({super.key});

  @override
  State<PhotoSelector> createState() => _PhotoSelectorState();
}

class _PhotoSelectorState extends State<PhotoSelector> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('選擇照片方式', style: AppTextStyles.title),
      backgroundColor: AppColors.background,
      elevation: 0,
    ),
    body: Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 說明文字
          const Text(
            '請選擇獲取照片的方式',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // 拍照選項
          _OptionCard(
            icon: Icons.camera_alt,
            title: '拍照',
            subtitle: '使用相機即時拍攝食物照片',
            color: Colors.blue,
            onTap: _isProcessing ? null : _takePhoto,
          ),
          const SizedBox(height: AppSpacing.m),

          // 相簿選項
          _OptionCard(
            icon: Icons.photo_library,
            title: '從相簿選擇',
            subtitle: '從設備相簿中選擇現有照片',
            color: Colors.green,
            onTap: _isProcessing ? null : _pickFromGallery,
          ),
          const SizedBox(height: AppSpacing.xl),

          if (_isProcessing) ...[
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.m),
            const Text('正在處理照片...', style: AppTextStyles.body),
          ],
        ],
      ),
    ),
  );

  Widget _OptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) => CardContainer(
    child: InkWell(
      onTap: onTap,
      borderRadius: AppBorders.radius,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: AppBorders.radius,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.subtitle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _takePhoto() async {
    setState(() => _isProcessing = true);

    try {
      await log('啟動相機拍照');

      // 直接導航到相機頁面
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CameraPage()),
      );

      if (result != null && result is String) {
        // 如果有返回照片路徑，導航到預覽頁面
        await _navigateToPreview(result);
      }
    } catch (e) {
      await log('拍照失敗: $e');
      _showError('拍照失敗，請重試');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isProcessing = true);

    try {
      await log('從相簿選擇照片');

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await log('相簿照片選擇成功: ${image.path}');
        await _navigateToPreview(image.path);
      } else {
        await log('用戶取消選擇照片');
      }
    } catch (e) {
      await log('相簿選擇失敗: $e');
      _showError('選擇照片失敗，請檢查權限設定');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _navigateToPreview(String imagePath) async {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewPage(imagePath: imagePath),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}