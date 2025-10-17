import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// AI 分析結果數據模型
class AIPrediction {
  final int classId;
  final String className;
  final double confidence;

  AIPrediction({
    required this.classId,
    required this.className,
    required this.confidence,
  });

  factory AIPrediction.fromJson(Map<String, dynamic> json) {
    return AIPrediction(
      classId: json['class_id'] ?? 0,
      className: json['class_name'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'class_name': className,
      'confidence': confidence,
    };
  }
}

/// AI 分析完整結果
class AIAnalysisResult {
  final List<AIPrediction> predictions;
  final String imagePath;
  final String geminiReply;
  final String dietAdvice;

  AIAnalysisResult({
    required this.predictions,
    required this.imagePath,
    required this.geminiReply,
    required this.dietAdvice,
  });

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) {
    final predictionsJson = json['predictions'] as List<dynamic>? ?? [];
    final predictions = predictionsJson
        .map((item) => AIPrediction.fromJson(item as Map<String, dynamic>))
        .toList();

    return AIAnalysisResult(
      predictions: predictions,
      imagePath: json['image_path'] ?? '',
      geminiReply: json['gemini_reply'] ?? '',
      dietAdvice: json['diet_advice'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predictions': predictions.map((p) => p.toJson()).toList(),
      'image_path': imagePath,
      'gemini_reply': geminiReply,
      'diet_advice': dietAdvice,
    };
  }
}

/// AI 分析服務 - 與 Flask API 進行通信
class AIAnalysisService {
  static const String _baseUrl = 'http://127.0.0.1:5000';
  static const Duration _timeout = Duration(seconds: 30);

  /// 檢查 API 服務是否可用
  static Future<bool> isServiceAvailable() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('AI 服務連接失敗: $e');
      return false;
    }
  }

  /// 分析圖片並取得 AI 辨識結果
  static Future<AIAnalysisResult?> analyzeImage(File imageFile) async {
    try {
      // 檢查文件是否存在
      if (!await imageFile.exists()) {
        throw Exception('圖片文件不存在');
      }

      // 準備多部分表單請求
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/predict'),
      );

      // 添加圖片文件
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      );
      request.files.add(multipartFile);

      // 設置請求標頭
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
      });

      print('正在向 AI 服務發送圖片分析請求...');

      // 發送請求並等待回應
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('AI 分析成功完成');
        return AIAnalysisResult.fromJson(jsonData);
      } else {
        print('AI 分析失敗: ${response.statusCode} - ${response.body}');
        throw Exception('AI 分析失敗: ${response.statusCode}');
      }
    } catch (e) {
      print('AI 分析錯誤: $e');
      return null;
    }
  }

  /// 取得分析後的圖片 URL
  static String getAnalyzedImageUrl(String imagePath) {
    if (imagePath.startsWith('/static/')) {
      return '$_baseUrl$imagePath';
    }
    return imagePath;
  }

  /// 格式化信心度百分比
  static String formatConfidence(double confidence) {
    return '${(confidence * 100).toStringAsFixed(1)}%';
  }

  /// 取得最高信心度的預測結果
  static AIPrediction? getBestPrediction(List<AIPrediction> predictions) {
    if (predictions.isEmpty) return null;

    return predictions.reduce((current, next) =>
        current.confidence > next.confidence ? current : next);
  }

  /// 篩選高信心度的預測結果（信心度 > 0.5）
  static List<AIPrediction> getHighConfidencePredictions(
      List<AIPrediction> predictions) {
    return predictions.where((p) => p.confidence > 0.5).toList();
  }

  /// 生成結果摘要
  static String generateSummary(AIAnalysisResult result) {
    final highConfidencePredictions = getHighConfidencePredictions(result.predictions);

    if (highConfidencePredictions.isEmpty) {
      return '未能檢測到明確的食物項目';
    }

    final foodNames = highConfidencePredictions
        .map((p) => '${p.className} (${formatConfidence(p.confidence)})')
        .join('、');

    return '檢測到: $foodNames';
  }
}

/// AI 分析異常類別
class AIAnalysisException implements Exception {
  final String message;
  final String? details;

  AIAnalysisException(this.message, [this.details]);

  @override
  String toString() {
    return details != null ? '$message: $details' : message;
  }
}