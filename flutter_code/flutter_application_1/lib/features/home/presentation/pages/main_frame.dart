import 'package:flutter/material.dart';
import '../../../../data/models/health_models.dart';
import 'home_page.dart';
import '../../../analysis/presentation/pages/body_analysis_page.dart';
import '../../../food_diary/presentation/pages/food_diary_page.dart';
import '../../../camera/presentation/pages/smart_camera_page.dart';

/// 統一主框架 Widget - 應用程式的主要容器，管理頁面切換和底部導航
class MainFrame extends StatefulWidget {
  const MainFrame({super.key});

  @override
  State<MainFrame> createState() => _MainFrameState();
}

/// MainFrame 的狀態管理類別
class _MainFrameState extends State<MainFrame> {
  AppPage _currentPage = AppPage.home; // 目前選中的頁面，預設為首頁

  /// 導航索引映射方法 - 將頁面枚舉轉換為底部導航欄的索引
  int _getNavigationIndex() {
    switch (_currentPage) {
      case AppPage.home: // 首頁對應索引 0
        return 0;
      case AppPage.foodDiary: // 飲食記錄對應索引 1
        return 1;
      case AppPage.exercise: // 運動對應索引 3（跳過相機的索引 2）
        return 3;
      case AppPage.analysis: // 身體分析對應索引 4
        return 4;
    }
  }

  /// 從導航索引轉換為頁面枚舉 - 將底部導航欄的索引轉換為頁面枚舉
  AppPage _getPageFromNavigationIndex(int index) {
    switch (index) {
      case 0: // 索引 0 對應首頁
        return AppPage.home;
      case 1: // 索引 1 對應飲食記錄
        return AppPage.foodDiary;
      case 3: // 索引 3 對應運動（跳過索引 2 的相機）
        return AppPage.exercise;
      case 4: // 索引 4 對應身體分析
        return AppPage.analysis;
      default: // 預設情況返回首頁
        return AppPage.home;
    }
  }

  /// 建立目前頁面的 Widget - 根據目前選中的頁面返回對應的內容 Widget
  Widget _buildCurrentPage() {
    print('構建頁面: $_currentPage');
    switch (_currentPage) {
      case AppPage.home: // 首頁情況
        print('返回首頁內容');
        return const HomePageContent(); // 返回首頁內容 Widget
      case AppPage.foodDiary: // 飲食記錄情況
        print('返回飲食日記內容');
        return const FoodDiaryPageContent(); // 返回飲食記錄內容 Widget
      case AppPage.exercise: // 運動頁面情況
        print('返回運動頁面內容');
        return const Center(
            child: Text('運動頁面開發中...',
                style: TextStyle(fontSize: 18))); // 臨時顯示開發中的提示
      case AppPage.analysis: // 身體分析情況
        print('返回身體分析內容');
        return const BodyAnalysisPageContent(); // 返回身體分析內容 Widget
    }
  }

  @override
  Widget build(BuildContext context) {
    print('MainFrame build() 被調用，當前頁面: $_currentPage');
    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getNavigationIndex(),
        onTap: (index) {
          print('導航欄點擊 - index: $index, 當前頁面: $_currentPage');
          if (index == 2) {
            print('跳轉到相機頁面');
            // 相機頁面特殊處理 - 使用 push 而不是切換 tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SmartCameraScreen()),
            );
          } else {
            // 映射導航索引到頁面枚舉
            final newPage = _getPageFromNavigationIndex(index);
            print('切換頁面: $_currentPage -> $newPage');
            setState(() {
              _currentPage = newPage;
            });
            print('setState 完成，當前頁面: $_currentPage');
          }
        },
        backgroundColor: Colors.white, // 導航欄背景色為白色
        selectedItemColor: Colors.black87, // 選中項目的顏色為深灰色
        unselectedItemColor: Colors.grey[400], // 未選中項目的顏色為淺灰色
        selectedFontSize: 12, // 選中項目的字體大小
        unselectedFontSize: 12, // 未選中項目的字體大小
        elevation: 0, // 陰影效果設為 0，去除高度感
        items: const [
          // 導航欄項目列表，定義所有導航選項
          BottomNavigationBarItem(
            // 首頁導航項（索引 0）
            icon: Icon(Icons.home_outlined), // 未選中時的空心家庭圖示
            activeIcon: Icon(Icons.home), // 選中時的實心家庭圖示
            label: '首頁', // 項目標籤文字
          ),
          BottomNavigationBarItem(
            // 飲食記錄導航項（索引 1）
            icon: Icon(Icons.restaurant_menu_outlined), // 未選中時的空心餐廳選單圖示
            activeIcon: Icon(Icons.restaurant_menu), // 選中時的實心餐廳選單圖示
            label: '飲食記錄', // 項目標籤文字
          ),
          BottomNavigationBarItem(
            // 相機拍照導航項（索引 2）
            icon: Icon(Icons.camera_alt_outlined), // 未選中時的空心相機圖示
            activeIcon: Icon(Icons.camera_alt), // 選中時的實心相機圖示
            label: '拍照辨識', // 項目標籤文字
          ),
          BottomNavigationBarItem(
            // 運動導航項（索引 3）
            icon: Icon(Icons.fitness_center_outlined), // 未選中時的空心健身圖示
            activeIcon: Icon(Icons.fitness_center), // 選中時的實心健身圖示
            label: '運動', // 項目標籤文字
          ),
          BottomNavigationBarItem(
            // 身體分析導航項（索引 4）
            icon: Icon(Icons.analytics_outlined), // 未選中時的空心分析圖示
            activeIcon: Icon(Icons.analytics), // 選中時的實心分析圖示
            label: '分析', // 項目標籤文字
          ),
        ],
      ),
    );
  }
}