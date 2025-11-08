// ====================================================================
// 營養標籤確認頁面 (Nutrition Label Screen)
// ====================================================================
// 此模組包含食物辨識結果的營養標籤顯示頁面

import 'package:flutter/material.dart';
import 'dart:io';

class NutritionLabelScreen extends StatelessWidget {
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
              child: imagePath != null && imagePath!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(imagePath!),
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
                    '辨識結果',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),

                  // 總熱量
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_fire_department_outlined,
                            color: Colors.orange, size: 24),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('總熱量',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black87)),
                            Text('250 大卡',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // 六大類食物標題
                  Text(
                    '六大類食物',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),

                  // 食物分類列表
                  ...buildFoodCategoryList(),

                  SizedBox(height: 24),

                  // 詳細營養素標題
                  Text(
                    '詳細營養素',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),

                  // 營養素網格
                  buildNutritionGrid(),
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
                    onPressed: () {
                      // 確認操作 - 返回首頁或飲食日記
                      Navigator.of(context).pop();
                      print('確認按鈕被點擊');
                    },
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
                    onPressed: onSelectFromGallery ??
                        () {
                          // 相簿操作
                          print('相簿按鈕被點擊');
                        },
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
                    onPressed: onRetakePhoto ??
                        () {
                          // 重拍操作
                          Navigator.of(context).pop();
                          print('重拍按鈕被點擊');
                        },
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

  List<Widget> buildFoodCategoryList() {
    final categories = [
      {'icon': Icons.grain, 'title': '全穀類', 'subtitle': '精製麵粉'},
      {'icon': Icons.eco, 'title': '豆魚蛋肉類', 'subtitle': '蛋豆'},
      {'icon': Icons.local_drink, 'title': '乳品類', 'subtitle': '牛奶'},
      {'icon': Icons.park, 'title': '蔬菜類', 'subtitle': '蔬菜'},
      {'icon': Icons.apple, 'title': '水果類', 'subtitle': '水果'},
      {'icon': Icons.opacity, 'title': '油脂與堅果種子類', 'subtitle': '油脂'},
    ];

    return categories.map((category) {
      return Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(category['icon'] as IconData,
                color: Colors.grey[600], size: 24),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category['title'] as String,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
                Text(category['subtitle'] as String,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget buildNutritionGrid() {
    final nutritionData = [
      {'label': '蛋白質', 'value': '15克'},
      {'label': '碳水化合物', 'value': '30克'},
      {'label': '脂肪', 'value': '10克'},
      {'label': '膳食纖維', 'value': '5克'},
      {'label': '糖', 'value': '8克'},
      {'label': '鈉', 'value': '200毫克'},
      {'label': '膽固醇', 'value': '50毫克'},
      {'label': '鈣', 'value': '10毫克'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: nutritionData.length,
      itemBuilder: (context, index) {
        final item = nutritionData[index];
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item['label']!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
              Text(
                item['value']!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
