import '../entities/app_navigation.dart';

/// 導航 Repository 介面 - 定義應用導航的資料操作契約
abstract class NavigationRepository {
  /// 獲取導航配置
  ///
  /// 返回應用的導航配置信息
  Future<AppNavigation> getNavigationConfig();

  /// 保存當前頁面狀態
  ///
  /// [page] 當前頁面
  /// 返回保存是否成功
  Future<bool> saveCurrentPage(AppPage page);

  /// 獲取上次訪問的頁面
  ///
  /// 返回上次用戶訪問的頁面，如果沒有則返回首頁
  Future<AppPage> getLastVisitedPage();

  /// 記錄頁面訪問歷史
  ///
  /// [page] 訪問的頁面
  /// [timestamp] 訪問時間
  /// 返回記錄是否成功
  Future<bool> recordPageVisit(AppPage page, DateTime timestamp);

  /// 獲取頁面訪問統計
  ///
  /// [days] 統計天數
  /// 返回各頁面的訪問次數統計
  Future<Map<AppPage, int>> getPageVisitStats({int days = 30});

  /// 清除導航歷史
  ///
  /// 返回清除是否成功
  Future<bool> clearNavigationHistory();

  /// 檢查功能是否可用
  ///
  /// [page] 要檢查的頁面
  /// 返回該功能是否可用
  Future<bool> isFeatureAvailable(AppPage page);

  /// 獲取頁面配置
  ///
  /// [page] 目標頁面
  /// 返回該頁面的配置信息
  Future<Map<String, dynamic>> getPageConfig(AppPage page);
}