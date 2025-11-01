/// 應用導航實體 - 代表應用程式導航的核心業務物件
class AppNavigation {
  final List<NavigationItem> navigationItems;
  final AppPage currentPage;
  final Map<AppPage, String> pageRoutes;

  const AppNavigation({
    required this.navigationItems,
    required this.currentPage,
    required this.pageRoutes,
  });

  /// 複製並修改當前頁面
  AppNavigation copyWith({
    AppPage? currentPage,
  }) {
    return AppNavigation(
      navigationItems: navigationItems,
      currentPage: currentPage ?? this.currentPage,
      pageRoutes: pageRoutes,
    );
  }

  /// 獲取當前頁面的路由
  String get currentRoute => pageRoutes[currentPage] ?? '/home';

  /// 檢查是否為特殊頁面（相機）
  bool get isSpecialPage => currentPage == AppPage.camera;
}

/// 導航項目實體
class NavigationItem {
  final AppPage page;
  final String label;
  final String iconName;
  final String activeIconName;
  final bool isSpecial;

  const NavigationItem({
    required this.page,
    required this.label,
    required this.iconName,
    required this.activeIconName,
    this.isSpecial = false,
  });
}

/// 應用頁面枚舉
enum AppPage {
  home('首頁'),
  foodDiary('飲食記錄'),
  camera('拍照辨識'),
  exercise('運動'),
  analysis('分析');

  const AppPage(this.displayName);
  final String displayName;

  /// 獲取底部導航欄索引
  int get navigationIndex {
    switch (this) {
      case AppPage.home:
        return 0;
      case AppPage.foodDiary:
        return 1;
      case AppPage.camera:
        return 2;
      case AppPage.exercise:
        return 3;
      case AppPage.analysis:
        return 4;
    }
  }

  /// 從導航索引獲取頁面
  static AppPage fromNavigationIndex(int index) {
    switch (index) {
      case 0:
        return AppPage.home;
      case 1:
        return AppPage.foodDiary;
      case 2:
        return AppPage.camera;
      case 3:
        return AppPage.exercise;
      case 4:
        return AppPage.analysis;
      default:
        return AppPage.home;
    }
  }
}

/// 應用狀態實體
class AppState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic> globalSettings;

  const AppState({
    this.isLoading = false,
    this.errorMessage,
    this.globalSettings = const {},
  });

  /// 複製並修改狀態
  AppState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? globalSettings,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      globalSettings: globalSettings ?? this.globalSettings,
    );
  }

  /// 清除錯誤訊息
  AppState clearError() {
    return copyWith(errorMessage: null);
  }
}