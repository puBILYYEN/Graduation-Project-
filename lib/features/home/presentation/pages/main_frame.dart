import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_pages.dart';
import 'home_page.dart';
import '../../../../core/services/app_logger.dart';

/// 統一主框架 Widget - 應用程式的主要容器，管理頁面切換和底部導航
class MainFrame extends StatefulWidget {
  const MainFrame({super.key});

  @override
  State<MainFrame> createState() => _MainFrameState();
}

/// 頁面枚舉 - 定義應用程式中所有可用的主要頁面
enum AppPage {
  home,        // 首頁
  foodDiary,   // 飲食記錄
  exercise,    // 運動
  analysis,    // 身體分析
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
      case 3: // 索引 3 對應運動
        return AppPage.exercise;
      case 4: // 索引 4 對應身體分析
        return AppPage.analysis;
      default: // 預設返回首頁
        return AppPage.home;
    }
  }

  /// 根據當前頁面枚舉建構對應的 Widget
  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case AppPage.home: // 顯示首頁內容
        return AppPages.getHomePage();
      case AppPage.foodDiary: // 顯示飲食記錄頁面
        return AppPages.getFoodDiaryPage();
      case AppPage.exercise: // 顯示運動頁面
        return AppPages.getExercisePage();
      case AppPage.analysis: // 顯示身體分析頁面
        return AppPages.getAnalysisPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 主體內容區域 - 根據當前選中的頁面顯示對應內容
      body: _buildCurrentPage(),

      // 底部導航欄 - 提供頁面切換功能
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 固定模式，所有標籤都會顯示
        currentIndex: _getNavigationIndex(), // 目前選中的導航項目索引

        // 導航項目點擊處理
        onTap: (index) async {
          await AppLogger.logButtonClick('底部導航按鈕 index=$index');
          await AppLogger.logEvent('[NAV_DEBUG] 當前頁面: $_currentPage');
          await AppLogger.logEvent('[NAV_DEBUG] 點擊索引: $index');

          if (index == 2) { // 如果點擊的是相機按鈕（索引 2）
            await AppLogger.logNavigation('MainFrame', '/camera');
            await AppLogger.logEvent('[NAV_DEBUG] 準備導航到相機頁面');
            // 導航到相機頁面，而不是更新底部導航狀態
            context.push('/camera');
            await AppLogger.logEvent('[NAV_DEBUG] 導航已執行');
          } else {
            // 更新當前頁面狀態，觸發頁面重建
            setState(() {
              AppPage newPage = _getPageFromNavigationIndex(index);
              AppLogger.logNavigation(_currentPage.toString(), newPage.toString());
              _currentPage = newPage;
            });
          }
        },

        // 導航項目列表
        items: const [
          // 首頁導航項目
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), // 未選中時的圖示
            activeIcon: Icon(Icons.home), // 選中時的圖示
            label: '首頁', // 標籤文字
          ),
          // 飲食記錄導航項目
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: '飲食記錄',
          ),
          // 相機導航項目（特殊處理）
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: '相機',
          ),
          // 運動導航項目
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: '運動',
          ),
          // 身體分析導航項目
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: '身體分析',
          ),
        ],
      ),
    );
  }
}