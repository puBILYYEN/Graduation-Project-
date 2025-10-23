import 'dart:io';
import 'api_client.dart';
import 'api_endpoints.dart';

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

/// YOLO Flask API 服務
class YoloApiService {
  /// 檢查 API 服務是否可用
  static Future<bool> isServiceAvailable() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.health);
      return ApiClient.isSuccessResponse(response);
    } catch (e) {
      print('YOLO API 服務連接失敗: $e');
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

      print('正在向 YOLO API 發送圖片分析請求...');

      // 使用 ApiClient 發送多部分表單請求
      final streamedResponse = await ApiClient.multipartRequest(
        ApiEndpoints.predict,
        'POST',
        files: {'image': imageFile.path},
      );

      final response = await ApiClient.responseFromStream(streamedResponse);

      if (ApiClient.isSuccessResponse(response)) {
        final jsonData = ApiClient.parseJsonResponse(response);
        print('YOLO API 分析成功完成');
        return AIAnalysisResult.fromJson(jsonData);
      } else {
        print('YOLO API 分析失敗: ${response.statusCode} - ${response.body}');
        throw ApiException('YOLO API 分析失敗: ${response.statusCode}');
      }
    } catch (e) {
      print('YOLO API 分析錯誤: $e');
      return null;
    }
  }

  /// 取得分析後的圖片 URL
  static String getAnalyzedImageUrl(String imagePath) {
    return ApiEndpoints.getStaticFileUrl(imagePath);
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