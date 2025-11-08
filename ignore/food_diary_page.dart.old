import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/firestore_service.dart';

/// 飲食日記頁面
class FoodDiaryPage extends StatelessWidget {
  const FoodDiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的飲食日記'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: const _FoodDiaryView(),
    );
  }
}

/// 飲食日記的 UI 視圖
class _FoodDiaryView extends StatelessWidget {
  const _FoodDiaryView();

  @override
  Widget build(BuildContext context) {
    // 從 Provider 獲取 FirestoreService 的實例
    final firestoreService = Provider.of<FirestoreService>(context);

    return StreamBuilder<QuerySnapshot>(
      // 監聽飲食日記的資料流
      stream: firestoreService.getFoodDiaryStream(),
      builder: (context, snapshot) {
        // 狀態 1: 正在載入中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 狀態 2: 發生錯誤
        if (snapshot.hasError) {
          return Center(child: Text('讀取資料時發生錯誤: ${snapshot.error}'));
        }

        // 狀態 3: 沒有資料
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('您的飲食日記是空的', style: TextStyle(fontSize: 18, color: Colors.grey)),
                Text('試著去拍張照片來新增第一筆紀錄吧！', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // 狀態 4: 成功獲取資料
        final documents = snapshot.data!.docs;

        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            final data = doc.data() as Map<String, dynamic>;

            // 安全地獲取資料
            final String foodName = data.containsKey('name') ? data['name'] : '未知食物';
            final Timestamp? timestamp = data.containsKey('timestamp') ? data['timestamp'] : null;
            
            String formattedDate = '未知時間';
            if (timestamp != null) {
              // 使用 intl 套件來格式化日期和時間
              formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.fastfood, color: Colors.blue),
                title: Text(foodName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(formattedDate),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {
                  // TODO: 可以導航到紀錄的詳細頁面
                },
              ),
            );
          },
        );
      },
    );
  }
}
