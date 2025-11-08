import 'package:flutter/material.dart';

// Import feature pages
import 'package:flutter_application_1/features/home/presentation/home_page.dart';
import 'package:flutter_application_1/features/food_diary/presentation/food_diary_page.dart';
import 'package:flutter_application_1/features/analysis/presentation/body_analysis_page.dart';
import 'package:flutter_application_1/features/camera/presentation/camera_screen.dart';

// 主要頁面選項 - 列出App裡可以切換的主要頁面(不包含相機頁面)
enum AppPage {
  home, // 首頁 - 編號0，顯示營養資訊和AI建議
  foodDiary, // 飲食記錄 - 編號1，管理每天吃了什麼
  exercise, // 運動 - 編號3(跳過相機的編號2)，記錄運動狀況
  analysis, // 身體分析 - 編號4，分析健康數據和報告
}

// 統一主框架Widget - App的主要容器，負責管理頁面切換和底部選單
class MainFrame extends StatefulWidget {
  const MainFrame({super.key}); // 建構函數

  @override
  State<MainFrame> createState() => _MainFrameState(); // 建立狀態物件
}

// MainFrame的狀態管理類別(用來記錄目前顯示哪一頁)
class _MainFrameState extends State<MainFrame> {
  AppPage _currentPage = AppPage.home; // 目前選中的頁面(預設是首頁)

  // 導航索引對應方法 - 把頁面選項轉換成底部選單的編號
  int _getNavigationIndex() {
    switch (_currentPage) {
      case AppPage.home: // 首頁對應編號0
        return 0;
      case AppPage.foodDiary: // 飲食記錄對應編號1
        return 1;
      case AppPage.exercise: // 運動對應編號3(跳過相機的編號2)
        return 3;
      case AppPage.analysis: // 身體分析對應編號4
        return 4;
    }
  }

  // 從編號轉換為頁面選項 - 把底部選單的編號轉換成頁面選項
  AppPage _getPageFromNavigationIndex(int index) {
    switch (index) {
      case 0: // 編號0對應首頁
        return AppPage.home;
      case 1: // 編號1對應飲食記錄
        return AppPage.foodDiary;
      case 3: // 編號3對應運動(跳過編號2的相機)
        return AppPage.exercise;
      case 4: // 編號4對應身體分析
        return AppPage.analysis;
      default: // 預設情況回到首頁
        return AppPage.home;
    }
  }

  // 建立目前頁面的Widget - 根據目前選的頁面顯示對應的內容
  Widget _buildCurrentPage() {
    // print('構建頁面: $_currentPage'); // 輸出除錯訊息
    switch (_currentPage) {
      case AppPage.home: // 首頁情況
        // print('返回首頁內容'); // 除錯訊息
        return const HomePageContent(); // 回傳首頁內容Widget
      case AppPage.foodDiary: // 飲食記錄情況
        // print('返回飲食日記內容'); // 除錯訊息
        return const FoodDiaryPageContent(); // 回傳飲食記錄內容Widget
      case AppPage.exercise: // 運動頁面情況
        // print('返回運動頁面內容'); // 除錯訊息
        return const Center(
            child: Text('運動頁面開發中...',
                style: TextStyle(fontSize: 18))); // 暫時顯示開發中的提示
      case AppPage.analysis: // 身體分析情況
        // print('返回身體分析內容'); // 除錯訊息
        return const BodyAnalysisPageContent(); // 回傳身體分析內容Widget
    }
  }

  @override
  Widget build(BuildContext context) {
    // print('MainFrame build() 被調用，當前頁面: $_currentPage');
    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getNavigationIndex(),
        onTap: (index) {
          // print('導航欄點擊 - index: $index, 當前頁面: $_currentPage');
          if (index == 2) {
            // print('跳轉到相機頁面');
            // 相機頁面特殊處理 - 用push開啟相機頁面(而不是切換tab)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CameraScreen()),
            );
          } else {
            // 對應編號到頁面選項
            final newPage = _getPageFromNavigationIndex(index);
            // print('切換頁面: $_currentPage -> $newPage');
            setState(() {
              _currentPage = newPage;
            });
            // print('setState 完成，當前頁面: $_currentPage');
          }
        },
        backgroundColor: Colors.white, // 底部選單背景色是白色
        selectedItemColor: Colors.black87, // 選中的項目顏色是深灰色
        unselectedItemColor: Colors.grey[400], // 沒選中的項目顏色是淺灰色
        selectedFontSize: 12, // 選中的項目字體大小
        unselectedFontSize: 12, // 沒選中的項目字體大小
        elevation: 0, // 陰影效果設為0(沒有陰影)
        items: const [
          // 底部選單項目列表(定義所有選項)
          BottomNavigationBarItem(
            // 首頁選項(編號0)
            icon: Icon(Icons.home_outlined), // 沒選中時的空心家圖示
            activeIcon: Icon(Icons.home), // 選中時的實心家圖示
            label: '首頁', // 項目文字
          ),
          BottomNavigationBarItem(
            // 飲食記錄選項(編號1)
            icon: Icon(Icons.restaurant_menu_outlined), // 沒選中時的空心餐廳圖示
            activeIcon: Icon(Icons.restaurant_menu), // 選中時的實心餐廳圖示
            label: '飲食記錄', // 項目文字
          ),
          BottomNavigationBarItem(
            // 相機拍照選項(編號2)
            icon: Icon(Icons.camera_alt_outlined), // 沒選中時的空心相機圖示
            activeIcon: Icon(Icons.camera_alt), // 選中時的實心相機圖示
            label: '拍照辨識', // 項目文字
          ),
          BottomNavigationBarItem(
            // 運動選項(編號3)
            icon: Icon(Icons.fitness_center_outlined), // 沒選中時的空心健身圖示
            activeIcon: Icon(Icons.fitness_center), // 選中時的實心健身圖示
            label: '運動', // 項目文字
          ),
          BottomNavigationBarItem(
            // 身體分析選項(編號4)
            icon: Icon(Icons.analytics_outlined), // 沒選中時的空心分析圖示
            activeIcon: Icon(Icons.analytics), // 選中時的實心分析圖示
            label: '分析', // 項目文字
          ),
        ],
      ),
    );
  }
}