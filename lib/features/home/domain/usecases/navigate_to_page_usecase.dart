import '../entities/app_navigation.dart';
import '../repositories/navigation_repository.dart';

/// 導航到頁面用例
class NavigateToPageUseCase {
  final NavigationRepository _repository;

  const NavigateToPageUseCase(this._repository);

  /// 執行導航到指定頁面
  ///
  /// [targetPage] 目標頁面
  /// [currentNavigation] 當前導航狀態
  ///
  /// 業務規則：
  /// 1. 檢查目標功能是否可用
  /// 2. 記錄頁面訪問歷史
  /// 3. 保存當前頁面狀態
  /// 4. 相機頁面使用特殊導航方式
  Future<AppNavigation> call({
    required AppPage targetPage,
    required AppNavigation currentNavigation,
  }) async {
    try {
      // 檢查目標功能是否可用
      final isAvailable = await _repository.isFeatureAvailable(targetPage);
      if (!isAvailable) {
        throw Exception('${targetPage.displayName}功能暫時不可用');
      }

      // 相機頁面使用特殊處理（不改變底部導航狀態）
      if (targetPage == AppPage.camera) {
        await _recordPageVisit(targetPage);
        return currentNavigation; // 保持當前導航狀態
      }

      // 一般頁面導航
      final newNavigation = currentNavigation.copyWith(currentPage: targetPage);

      // 記錄頁面訪問
      await _recordPageVisit(targetPage);

      // 保存當前頁面狀態
      await _repository.saveCurrentPage(targetPage);

      return newNavigation;
    } catch (e) {
      throw Exception('導航失敗: $e');
    }
  }

  /// 記錄頁面訪問
  Future<void> _recordPageVisit(AppPage page) async {
    try {
      await _repository.recordPageVisit(page, DateTime.now());
    } catch (e) {
      // 記錄失敗不影響導航，僅記錄錯誤
      print('記錄頁面訪問失敗: $e');
    }
  }
}