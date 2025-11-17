import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/services/firestore_service.dart';

/// 營養標籤螢幕 - 顯示食物辨識結果和營養資訊
class NutritionLabelScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> analysis;

  const NutritionLabelScreen({
    super.key,
    required this.imagePath,
    required this.analysis,
  });

  @override
  State<NutritionLabelScreen> createState() => _NutritionLabelScreenState();
}

class _NutritionLabelScreenState extends State<NutritionLabelScreen> {
  bool _isSaving = false;

  /// ✅ Phase 2: 上傳照片到 Firebase Storage
  Future<String> _uploadImageToStorage() async {
    try {
      print('[NutritionLabel] 開始上傳照片到 Firebase Storage...');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('使用者未登入');
      }

      final File file = File(widget.imagePath);
      if (!await file.exists()) {
        throw Exception('照片檔案不存在');
      }

      // 建立唯一檔名
      final String fileName = 'food_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      // 上傳檔案
      final Reference ref = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;

      // 獲取下載 URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('[NutritionLabel] ✅ 照片上傳成功: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('[NutritionLabel] ❌ 照片上傳失敗: $e');
      return ''; // 上傳失敗時返回空字串
    }
  }

  /// ✅ Phase 3: 確認並加入飲食日記（包含完整 YOLO 預測資料）
  Future<void> _confirmAndSaveToDiary() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // 1. 從 Provider 獲取 FirestoreService
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      // 2. 上傳照片到 Firebase Storage
      final String imageUrl = await _uploadImageToStorage();

      // 3. 準備要儲存的完整資料
      final foodItems = widget.analysis['food_items'] as List? ?? [];
      final foodName = foodItems.isNotEmpty
          ? foodItems.map((item) => item['name'] as String).join(', ')
          : '未知食物';

      // ✅ 儲存完整的 YOLO 預測結果
      final foodData = {
        'name': foodName,
        'imageUrl': imageUrl, // ✅ 修復：儲存實際的照片 URL
        'timestamp': Timestamp.now(),

        // ✅ Phase 3: 儲存完整 YOLO 預測資料
        'food_items': foodItems.map((item) => {
          'name': item['name'] ?? '',
          'confidence': item['confidence'] ?? 0.0,
          'class_id': item['class_id'] ?? -1,
        }).toList(),

        // ✅ 儲存 Gemini AI 建議
        'gemini_reply': widget.analysis['gemini_reply'] ?? '',
        'diet_advice': widget.analysis['diet_advice'] ?? '',
        'analysis_time': widget.analysis['analysis_time'] ?? DateTime.now().toIso8601String(),
      };

      // 4. 呼叫服務進行儲存
      await firestoreService.addFoodDiaryEntry(foodData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 已成功加入飲食日記！'),
          backgroundColor: Colors.green,
        ),
      );

      // 4. 完成後回到主頁
      context.go('/home');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('儲存失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Debug: 列印接收到的 analysis 資料
    print('[NutritionLabel] 接收到的 analysis 資料:');
    print('  - 完整內容: ${widget.analysis}');
    print('  - food_items: ${widget.analysis['food_items']}');
    print('  - gemini_reply: ${widget.analysis['gemini_reply']}');
    print('  - diet_advice: ${widget.analysis['diet_advice']}');

    // 從 widget.analysis 解析結果
    final foodItems = widget.analysis['food_items'] as List? ?? [];
    final geminiReply = widget.analysis['gemini_reply'] as String? ?? '';
    final dietAdvice = widget.analysis['diet_advice'] as String? ?? '';

    print('[NutritionLabel] 解析後的資料:');
    print('  - foodItems 數量: ${foodItems.length}');
    print('  - geminiReply 長度: ${geminiReply.length}');
    print('  - dietAdvice 長度: ${dietAdvice.length}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 營養分析'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顯示圖片
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.imagePath),
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),

            // ✅ 顯示辨識出的食物（帶信心度）
            Text(
              '🍽️ 辨識出的食物',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 12),
            ...foodItems.map((item) {
              final name = item['name'] as String? ?? '未知';
              final confidence = item['confidence'] as double? ?? 0.0;
              final confidencePercent = (confidence * 100).toStringAsFixed(1);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      '$confidencePercent%',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 24),

            // ✅ 顯示 Gemini AI 建議
            if (geminiReply.isNotEmpty) ...[
              Text(
                '🤖 AI 營養分析',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Text(
                  geminiReply,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ✅ 顯示飲食建議
            if (dietAdvice.isNotEmpty) ...[
              Text(
                '💡 飲食建議',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(
                  dietAdvice,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
      // 底部儲存按鈕（避免被 Android 導航欄遮擋）
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
            label: Text(_isSaving ? '儲存中...' : '儲存到飲食日記'),
            onPressed: _isSaving ? null : _confirmAndSaveToDiary,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}