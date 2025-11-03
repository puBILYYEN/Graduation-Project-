import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// 確認並加入飲食日記
  Future<void> _confirmAndSaveToDiary() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // 1. 從 Provider 獲取 FirestoreService
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      // 2. 準備要儲存的資料
      // 我們從分析結果中提取最重要的資訊：食物名稱
      // 假設分析結果的格式是 {'predictions': [{'class': 'apple', ...}]}
      final predictions = widget.analysis['predictions'] as List?;
      final foodName = predictions?.isNotEmpty ?? false
          ? predictions!.map((p) => p['class'] as String).join(', ')
          : '未知食物';

      final foodData = {
        'name': foodName,
        'imageUrl': '' , // TODO: 未來可以將圖片上傳到 Firebase Storage 並保存 URL
        'timestamp': Timestamp.now(),
        // 您可以從 widget.analysis 中加入更多詳細資訊
        // 'calories': widget.analysis['nutrition']?['calories'] ?? 0,
      };

      // 3. 呼叫服務進行儲存
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
    // 從 widget.analysis 解析結果
    final predictions = widget.analysis['predictions'] as List? ?? [];
    final summary = predictions.map((p) => p['class']).join(', ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('辨識結果'),
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
              child: Image.file(File(widget.imagePath)),
            ),
            const SizedBox(height: 24),

            // 顯示分析結果
            Text(
              '辨識出的食物',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              summary.isNotEmpty ? summary : '未能辨識出任何食物',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // 顯示原始 JSON (方便除錯)
            const Text(
              '原始分析資料 (JSON)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Text(widget.analysis.toString()),
            ),
          ],
        ),
      ),
      // 底部儲存按鈕
      bottomNavigationBar: Padding(
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
    );
  }
}