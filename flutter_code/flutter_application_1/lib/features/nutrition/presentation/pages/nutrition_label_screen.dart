import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../data/services/ai_analysis_service.dart';

/// 營養標籤螢幕 - 顯示食物辨識結果和營養資訊
class NutritionLabelScreen extends StatefulWidget {
  final String? imagePath;
  final VoidCallback? onRetakePhoto;
  final VoidCallback? onSelectFromGallery;

  const NutritionLabelScreen({
    super.key,
    this.imagePath,
    this.onRetakePhoto,
    this.onSelectFromGallery,
  });

  @override
  State<NutritionLabelScreen> createState() => _NutritionLabelScreenState();
}

class _NutritionLabelScreenState extends State<NutritionLabelScreen> {
  AIAnalysisResult? _analysisResult;
  bool _isAnalyzing = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  /// 分析圖片
  Future<void> _analyzeImage() async {
    if (widget.imagePath == null || widget.imagePath!.isEmpty) {
      setState(() {
        _errorMessage = '沒有提供圖片路徑';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final imageFile = File(widget.imagePath!);
      final result = await AIAnalysisService.analyzeImage(imageFile);

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      if (result == null) {
        setState(() {
          _errorMessage = 'AI 分析失敗，請稍後再試';
        });
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = '分析錯誤: $e';
      });
    }
  }

  /// 重新選擇照片（相簿功能）
  Future<void> _selectFromGallery() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 80,
        limit: 10,
      );

      if (images.isEmpty) return;

      if (images.length == 1) {
        // 單張圖片：直接替換當前分析
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => NutritionLabelScreen(
              imagePath: images.first.path,
            ),
          ),
        );
      } else {
        // 多張圖片：導航到批量處理頁面
        context.pushReplacement('/camera/process-multiple', extra: {
          'images': images,
          'onRetakePhoto': () => context.go('/camera'),
          'onSelectFromGallery': _selectFromGallery,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('選擇圖片失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 重拍照片（回到相機頁面）
  void _retakePhoto() {
    // 重拍的語意就是「重新拍照」，直接導航到相機頁面
    context.go('/camera');
  }

  /// 確認並加入飲食日記
  Future<void> _confirmAndSaveToDiary() async {
    if (_analysisResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('沒有分析結果可以儲存'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // TODO: 未來這裡會整合 Flask → Firebase 存入飲食日記
      // await DiaryService.saveMealRecord(_analysisResult!, widget.imagePath!);

      // 暫時顯示成功訊息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 已加入飲食日記！（未來將整合Flask→Firebase）'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // 記錄到控制台，方便開發時追蹤
      print('=== 飲食日記記錄 ===');
      print('圖片路徑: ${widget.imagePath}');
      print('檢測食物: ${_analysisResult!.predictions.map((p) => p.className).join(', ')}');
      print('AI 解釋: ${_analysisResult!.geminiReply}');
      print('飲食建議: ${_analysisResult!.dietAdvice}');
      print('時間戳記: ${DateTime.now().toIso8601String()}');
      print('==================');

      // 稍後自動關閉此頁面，回到首頁
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/home');
        }
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('儲存失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.black54),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 食材圖片區域
          Container(
            height: 200,
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: widget.imagePath != null && widget.imagePath!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(widget.imagePath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            child: Icon(
                              Icons.restaurant,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      child: Icon(
                        Icons.restaurant,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 標題
                  Text(
                    'AI 辨識結果',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),

                  // 分析狀態和結果
                  _buildAnalysisSection(),

                  SizedBox(height: 24),

                  // 條件式顯示 AI 建議
                  if (_analysisResult != null) ...[
                    SizedBox(height: 24),
                    _buildAIAdviceSection(),
                  ],
                ],
              ),
            ),
          ),

          // 底部按鈕
          Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmAndSaveToDiary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue[100],
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text('確認',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectFromGallery,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text('相簿',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _retakePhoto,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text('重拍',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建構分析結果區域
  Widget _buildAnalysisSection() {
    if (_isAnalyzing) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('AI 正在分析圖片...',
                style: TextStyle(fontSize: 16, color: Colors.blue[700])),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(_errorMessage!,
                  style: TextStyle(fontSize: 16, color: Colors.red[700])),
            ),
          ],
        ),
      );
    }

    if (_analysisResult == null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.image_search, color: Colors.grey[600], size: 24),
            SizedBox(width: 12),
            Text('等待分析結果...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    // 顯示檢測到的食物
    final highConfidencePredictions = AIAnalysisService.getHighConfidencePredictions(
        _analysisResult!.predictions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 檢測結果摘要
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  AIAnalysisService.generateSummary(_analysisResult!),
                  style: TextStyle(fontSize: 16, color: Colors.green[700]),
                ),
              ),
            ],
          ),
        ),

        // 詳細檢測結果
        if (highConfidencePredictions.isNotEmpty) ...[
          SizedBox(height: 16),
          Text(
            '檢測到的食物',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          ...highConfidencePredictions.map((prediction) => Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.className,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '信心度: ${AIAnalysisService.formatConfidence(prediction.confidence)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }

  /// 建構 AI 建議區域
  Widget _buildAIAdviceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI 解釋
        if (_analysisResult!.geminiReply.isNotEmpty) ...[
          Text(
            'AI 解釋',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _analysisResult!.geminiReply,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          SizedBox(height: 16),
        ],

        // 飲食建議
        if (_analysisResult!.dietAdvice.isNotEmpty) ...[
          Text(
            '飲食建議',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _analysisResult!.dietAdvice,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ],
    );
  }
}