import '../entities/app_navigation.dart';
import '../repositories/navigation_repository.dart';

/// 獲取導航配置用例
class GetNavigationConfigUseCase {
  final NavigationRepository _repository;

  const GetNavigationConfigUseCase(this._repository);

  /// 執行獲取導航配置
  ///
  /// 業務規則：
  /// 1. 獲取基礎導航配置
  /// 2. 檢查各功能可用性
  /// 3. 恢復上次訪問的頁面
  /// 4. 生成完整的導航狀態
  Future<AppNavigation> call() async {
    try {
      // 獲取基礎導航配置
      var navigation = await _repository.getNavigationConfig();

      // 恢復上次訪問的頁面
      final lastVisitedPage = await _repository.getLastVisitedPage();

      // 檢查上次訪問的頁面是否仍然可用
      final isLastPageAvailable = await _repository.isFeatureAvailable(lastVisitedPage);

      // 決定初始頁面
      final initialPage = isLastPageAvailable ? lastVisitedPage : AppPage.home;

      // 更新導航狀態
      navigation = navigation.copyWith(currentPage: initialPage);

      return navigation;
    } catch (e) {
      // 如果獲取配置失敗，返回預設配置
      return _getDefaultNavigation();
    }
  }

  /// 獲取預設導航配置
  AppNavigation _getDefaultNavigation() {
    return AppNavigation(
      navigationItems: [
        const NavigationItem(
          page: AppPage.home,
          label: '首頁',
          iconName: 'home_outlined',
          activeIconName: 'home',
        ),
        const NavigationItem(
          page: AppPage.foodDiary,
          label: '飲食記錄',
          iconName: 'restaurant_menu_outlined',
          activeIconName: 'restaurant_menu',
        ),
        const NavigationItem(
          page: AppPage.camera,
          label: '拍照辨識',
          iconName: 'camera_alt_outlined',
          activeIconName: 'camera_alt',
          isSpecial: true,
        ),
        const NavigationItem(
          page: AppPage.exercise,
          label: '運動',
          iconName: 'fitness_center_outlined',
          activeIconName: 'fitness_center',
        ),
        const NavigationItem(
          page: AppPage.analysis,
          label: '分析',
          iconName: 'analytics_outlined',
          activeIconName: 'analytics',
        ),
      ],
      currentPage: AppPage.home,
      pageRoutes: {
        AppPage.home: '/home',
        AppPage.foodDiary: '/food-diary',
        AppPage.camera: '/camera',
        AppPage.exercise: '/exercise',
        AppPage.analysis: '/analysis',
      },
    );
  }
}