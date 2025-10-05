// AK47 風格精簡版：拍照預覽頁面
import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../core/logger.dart';
import 'nutrition_detail.dart';

class PreviewPage extends StatefulWidget {
  final String imagePath;

  const PreviewPage({super.key, required this.imagePath});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: const Text('拍照預覽', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.black,
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
    ),
    body: Column(
      children: [
        // 圖片預覽區域
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.m),
            child: ClipRRect(
              borderRadius: AppBorders.radius,
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.white, size: 48),
                        SizedBox(height: AppSpacing.m),
                        Text('無法載入圖片',
                          style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 底部控制區域
        Container(
          color: Colors.black,
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              if (_isAnalyzing) ...[
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: AppSpacing.m),
                const Text('正在分析營養成分...',
                  style: TextStyle(color: Colors.white)),
                const SizedBox(height: AppSpacing.l),
              ],

              Row(
                children: [
                  // 重新拍照按鈕
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text('重新拍照',
                        style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),

                  // 確認分析按鈕
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzeImage,
                      icon: _isAnalyzing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.black),
                            ),
                          )
                        : const Icon(Icons.analytics, color: Colors.black),
                      label: Text(
                        _isAnalyzing ? '分析中...' : '分析營養',
                        style: const TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _analyzeImage() async {
    setState(() => _isAnalyzing = true);

    try {
      await log('開始分析圖片: ${widget.imagePath}');

      // 模擬分析過程
      await Future.delayed(const Duration(seconds: 3));

      await log('圖片分析完成');

      if (mounted) {
        setState(() => _isAnalyzing = false);

        // 導航到營養詳細頁面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NutritionDetailPage(
              imagePath: widget.imagePath,
            ),
          ),
        );
      }
    } catch (e) {
      await log('分析失敗: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _showError('分析失敗，請重試');
      }
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