import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../../core/services/api/api_services.dart';

/// 多張圖片處理頁面
class MultipleImagesProcessingPage extends StatefulWidget {
  final List<XFile> images;
  final VoidCallback onRetakePhoto;
  final VoidCallback onSelectFromGallery;

  const MultipleImagesProcessingPage({
    super.key,
    required this.images,
    required this.onRetakePhoto,
    required this.onSelectFromGallery,
  });

  @override
  State<MultipleImagesProcessingPage> createState() => _MultipleImagesProcessingPageState();
}

class _MultipleImagesProcessingPageState extends State<MultipleImagesProcessingPage> {
  int _currentIndex = 0;
  bool _isProcessing = false;
  List<AIAnalysisResult?> _analysisResults = []; // 儲存每張圖片的分析結果

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '已選擇 ${widget.images.length} 張圖片',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
            onPressed: widget.onSelectFromGallery,
          ),
        ],
      ),
      body: Column(
        children: [
          // 圖片預覽區域
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.images[_currentIndex].path),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // 圖片索引指示器
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentIndex > 0 ? _previousImage : null,
                  icon: Icon(
                    Icons.chevron_left,
                    color: _currentIndex > 0 ? Colors.white : Colors.grey,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _currentIndex < widget.images.length - 1 ? _nextImage : null,
                  icon: Icon(
                    Icons.chevron_right,
                    color: _currentIndex < widget.images.length - 1 ? Colors.white : Colors.grey,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          // 縮圖列表
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _selectImage(index),
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: index == _currentIndex ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(widget.images[index].path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 操作按鈕區域
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 處理選項
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      '分析當前圖片',
                      Icons.analytics,
                      _processSingleImage,
                      Colors.blue,
                    ),
                    _buildActionButton(
                      '批量分析',
                      Icons.batch_prediction,
                      _processBatchImages,
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 其他操作
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      '刪除當前',
                      Icons.delete,
                      _deleteCurrentImage,
                      Colors.red,
                    ),
                    _buildActionButton(
                      '重新選擇',
                      Icons.refresh,
                      widget.onSelectFromGallery,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 上一張圖片
  void _previousImage() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  /// 下一張圖片
  void _nextImage() {
    if (_currentIndex < widget.images.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  /// 選擇指定圖片
  void _selectImage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// 處理單張圖片
  void _processSingleImage() async {
    final currentImage = widget.images[_currentIndex];

    context.push('/camera/nutrition-label', extra: currentImage.path);
  }

  /// 批量處理圖片
  void _processBatchImages() async {
    setState(() {
      _isProcessing = true;
      // 初始化分析結果列表
      _analysisResults = List.filled(widget.images.length, null);
    });

    // 用於追蹤處理進度的變數
    int processedCount = 0;
    int successCount = 0;
    final totalCount = widget.images.length;

    try {
      // 顯示批量處理對話框
      final dialogContext = context;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('批量處理'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('正在處理第 ${processedCount + 1} 張 / 共 $totalCount 張圖片...'),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: processedCount / totalCount,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ],
            ),
          ),
        ),
      );

      // 逐一處理每張圖片
      for (int i = 0; i < widget.images.length; i++) {
        try {
          final imageFile = File(widget.images[i].path);

          // 調用 Flask API 進行分析
          final result = await YoloApiService.analyzeImage(imageFile);

          // 保存分析結果
          _analysisResults[i] = result;

          if (result != null) {
            successCount++;
            print('圖片 ${i + 1} 分析成功: ${result.predictions.length} 個預測結果');
          } else {
            print('圖片 ${i + 1} 分析失敗');
          }
        } catch (e) {
          print('處理圖片 ${i + 1} 時出錯: $e');
          _analysisResults[i] = null;
        }

        processedCount++;
      }

      if (mounted) {
        Navigator.of(dialogContext).pop(); // 關閉對話框

        // 顯示完成對話框，提供查看選項
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('批量處理完成'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  successCount > 0 ? Icons.check_circle : Icons.warning,
                  color: successCount > 0 ? Colors.green : Colors.orange,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  '成功分析 $successCount / $totalCount 張圖片',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  '點擊下方按鈕查看各張圖片的分析結果',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('稍後查看'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showBatchResults();
                },
                child: const Text('查看結果'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 關閉對話框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('批量處理失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// 顯示批量處理結果選擇頁面
  void _showBatchResults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇要查看的圖片'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final result = _analysisResults[index];
              final hasResult = result != null;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: FileImage(File(widget.images[index].path)),
                  radius: 25,
                ),
                title: Text('圖片 ${index + 1}'),
                subtitle: Text(
                  hasResult
                    ? '已分析 - ${result.predictions.length} 個檢測結果'
                    : '分析失敗',
                  style: TextStyle(
                    color: hasResult ? Colors.green : Colors.red,
                  ),
                ),
                trailing: Icon(
                  hasResult ? Icons.check_circle : Icons.error,
                  color: hasResult ? Colors.green : Colors.red,
                ),
                onTap: hasResult ? () {
                  Navigator.of(context).pop();
                  _viewAnalysisResult(index);
                } : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  /// 查看指定圖片的分析結果
  void _viewAnalysisResult(int index) {
    final imagePath = widget.images[index].path;
    context.push('/camera/nutrition-label', extra: imagePath);
  }

  /// 刪除當前圖片
  void _deleteCurrentImage() {
    if (widget.images.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('至少需要保留一張圖片'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('確定要刪除這張圖片嗎？'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              setState(() {
                widget.images.removeAt(_currentIndex);
                if (_currentIndex >= widget.images.length) {
                  _currentIndex = widget.images.length - 1;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('圖片已刪除'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  /// 建立操作按鈕
  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: _isProcessing ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}