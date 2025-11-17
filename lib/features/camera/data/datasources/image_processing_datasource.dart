import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../../core/services/api/yolo_api_service.dart';

class ImageProcessingDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _firebaseStorage;

  ImageProcessingDatasource({
    FirebaseFirestore? firestore,
    FirebaseStorage? firebaseStorage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance;

  /// ✅ 修復：使用真實的 YOLO API 而非假資料
  Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    try {
      print('[ImageProcessing] 開始分析圖片: $imagePath');

      // 檢查 YOLO 服務是否可用
      final isAvailable = await YoloApiService.isServiceAvailable();
      if (!isAvailable) {
        print('[ImageProcessing] ⚠️ YOLO 服務不可用，使用備用資料');
        return _getFallbackData();
      }

      // 呼叫真實的 YOLO API
      final File imageFile = File(imagePath);
      final AIAnalysisResult? result = await YoloApiService.analyzeImage(imageFile);

      if (result == null || result.predictions.isEmpty) {
        print('[ImageProcessing] ⚠️ YOLO 未檢測到任何食物，使用備用資料');
        return _getFallbackData();
      }

      // 轉換 YOLO 結果為相容格式
      print('[ImageProcessing] ✅ YOLO 分析成功，檢測到 ${result.predictions.length} 項食物');
      return {
        'food_items': result.predictions.map((pred) => {
          'name': pred.className,
          'confidence': pred.confidence,
          'class_id': pred.classId,
        }).toList(),
        'gemini_reply': result.geminiReply,
        'diet_advice': result.dietAdvice,
        'image_path': result.imagePath,
        'analysis_time': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('[ImageProcessing] ❌ YOLO 分析錯誤: $e');
      // 發生錯誤時返回備用資料
      return _getFallbackData();
    }
  }

  /// 備用資料（當 YOLO API 失敗時使用）
  Map<String, dynamic> _getFallbackData() {
    return {
      'food_items': [
        {'name': '無法辨識', 'confidence': 0.0, 'class_id': -1},
      ],
      'gemini_reply': '目前無法連接到 AI 分析服務，請稍後再試。',
      'diet_advice': '請確保網路連線正常。',
      'analysis_time': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> performVolumeCalculation(String imagePath) async {
    // Mock implementation for volume calculation
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    return {
      'volume': 500.0,
      'unit': 'cm³',
      'shape': '長方體',
      'confidence': 0.90,
    };
  }

  Future<String> uploadImageToStorage(String imagePath, String userId) async {
    File file = File(imagePath);
    String fileName = 'images/$userId/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    UploadTask uploadTask = _firebaseStorage.ref().child(fileName).putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> saveAnalysisResultToFirestore(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).collection('food_analysis').add(data);
  }
}