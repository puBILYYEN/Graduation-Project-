// ====================================================================
// 多圖片處理螢幕 (Multi-Image Processing Screen)
// ====================================================================
// 此模組包含批次圖片處理和結果顯示功能

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math' as math;

/// 多圖片處理結果數據
class ImageProcessingResult {
  final String imagePath;
  final String containerShape;
  final double volume;
  final String status;
  final DateTime processedAt;

  ImageProcessingResult({
    required this.imagePath,
    required this.containerShape,
    required this.volume,
    required this.status,
    required this.processedAt,
  });

  String get displayName =>
      'IMG_${processedAt.millisecondsSinceEpoch % 100000}';
  String get volumeText => '${volume.toStringAsFixed(2)} cm³';
  String get literText => '${(volume / 1000).toStringAsFixed(3)} L';
}

class MultiImageProcessingScreen extends StatefulWidget {
  final List<String> imagePaths;
  final VoidCallback? onReturnToCamera;

  const MultiImageProcessingScreen({
    super.key,
    required this.imagePaths,
    this.onReturnToCamera,
  });

  @override
  State<MultiImageProcessingScreen> createState() =>
      _MultiImageProcessingScreenState();
}

class _MultiImageProcessingScreenState
    extends State<MultiImageProcessingScreen> {
  final List<ImageProcessingResult> _results = [];
  bool _isProcessing = false;
  int _currentProcessingIndex = 0;

  @override
  void initState() {
    super.initState();
    _startBatchProcessing();
  }

  /// 開始批次處理所有圖片
  Future<void> _startBatchProcessing() async {
    if (widget.imagePaths.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _currentProcessingIndex = 0;
      _results.clear();
    });

    for (int i = 0; i < widget.imagePaths.length; i++) {
      setState(() {
        _currentProcessingIndex = i;
      });

      await _processImage(widget.imagePaths[i]);

      // 短暫延遲以提供視覺反饋
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() {
      _isProcessing = false;
    });

    print('批次處理完成: ${_results.length} 張圖片');
  }

  /// 處理單張圖片
  Future<void> _processImage(String imagePath) async {
    try {
      print('開始處理圖片: $imagePath');

      // 模擬智慧容積計算流程
      await Future.delayed(const Duration(milliseconds: 800));

      // 模擬邊緣檢測和形狀辨識
      final shapes = ['長方體', '圓柱體', '立方體'];
      final randomShape = shapes[math.Random().nextInt(shapes.length)];

      // 模擬容積計算結果
      final baseVolume =
          800.0 + math.Random().nextDouble() * 1200.0; // 800-2000 cm³
      final volume = double.parse(baseVolume.toStringAsFixed(2));

      final result = ImageProcessingResult(
        imagePath: imagePath,
        containerShape: randomShape,
        volume: volume,
        status: 'success',
        processedAt: DateTime.now(),
      );

      setState(() {
        _results.add(result);
      });

      print('圖片處理完成: $randomShape, ${volume.toStringAsFixed(2)} cm³');
    } catch (e) {
      print('處理圖片失敗: $e');

      final result = ImageProcessingResult(
        imagePath: imagePath,
        containerShape: '未知',
        volume: 0.0,
        status: 'failed',
        processedAt: DateTime.now(),
      );

      setState(() {
        _results.add(result);
      });
    }
  }

  /// 計算總容積
  double get _totalVolume {
    return _results
        .where((result) => result.status == 'success')
        .fold(0.0, (sum, result) => sum + result.volume);
  }

  /// 計算平均容積
  double get _averageVolume {
    final successResults =
        _results.where((result) => result.status == 'success').toList();
    if (successResults.isEmpty) return 0.0;
    return _totalVolume / successResults.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('批次處理 (${widget.imagePaths.length} 張照片)'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (!_isProcessing)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareResults,
            ),
        ],
      ),
      body: Column(
        children: [
          // 處理進度指示器
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green.withOpacity(0.1),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: widget.imagePaths.isNotEmpty
                        ? (_currentProcessingIndex + 1) /
                            widget.imagePaths.length
                        : 0.0,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '正在處理: ${_currentProcessingIndex + 1} / ${widget.imagePaths.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // 統計資訊
          if (!_isProcessing && _results.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                      '處理成功',
                      '${_results.where((r) => r.status == 'success').length}',
                      Icons.check_circle,
                      Colors.green),
                  _buildStatCard(
                      '總容積',
                      '${_totalVolume.toStringAsFixed(1)} cm³',
                      Icons.analytics,
                      Colors.blue),
                  _buildStatCard(
                      '平均容積',
                      '${_averageVolume.toStringAsFixed(1)} cm³',
                      Icons.calculate,
                      Colors.orange),
                ],
              ),
            ),

          // 結果列表
          Expanded(
            child: _results.isEmpty && !_isProcessing
                ? const Center(
                    child: Text(
                      '尚無處理結果',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return _buildResultCard(result, index);
                    },
                  ),
          ),

          // 底部按鈕
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onReturnToCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('返回相機'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _reprocessAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('重新處理'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建構統計卡片
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 建構結果卡片
  Widget _buildResultCard(ImageProcessingResult result, int index) {
    final isSuccess = result.status == 'success';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuccess ? Colors.green : Colors.red,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(result.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('形狀: ${result.containerShape}'),
            if (isSuccess) ...[
              Text('容積: ${result.volumeText} (${result.literText})'),
            ] else ...[
              const Text('處理失敗', style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
        trailing: isSuccess
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.error, color: Colors.red),
        onTap: () => _showImageDetail(result),
      ),
    );
  }

  /// 顯示圖片詳細資訊
  void _showImageDetail(ImageProcessingResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.file(
              File(result.imagePath),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            Text('容器形狀: ${result.containerShape}'),
            if (result.status == 'success') ...[
              Text('容積: ${result.volumeText}'),
              Text('公升: ${result.literText}'),
            ],
            Text('處理時間: ${result.processedAt.toString().substring(11, 19)}'),
            Text('狀態: ${result.status == 'success' ? '成功' : '失敗'}'),
          ],
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

  /// 重新處理所有圖片
  void _reprocessAll() {
    _startBatchProcessing();
  }

  /// 分享結果
  void _shareResults() {
    final successCount = _results.where((r) => r.status == 'success').length;
    final totalCount = _results.length;

    final summary = '''
容積測量批次處理結果

處理照片數量: $totalCount 張
成功處理: $successCount 張
總容積: ${_totalVolume.toStringAsFixed(2)} cm³ (${(_totalVolume / 1000).toStringAsFixed(3)} L)
平均容積: ${_averageVolume.toStringAsFixed(2)} cm³

詳細結果:
${_results.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final result = entry.value;
      return '$index. ${result.displayName}: ${result.containerShape} - ${result.volumeText}';
    }).join('\n')}

📱 由智慧容積測量 App 生成
    ''';

    print('分享結果摘要: $summary');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('結果已準備分享'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
