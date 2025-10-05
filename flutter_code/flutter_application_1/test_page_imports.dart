// 測試所有頁面模組的 import
import 'lib/pages/auth/login_page.dart';
import 'lib/pages/auth/register_page.dart';
import 'lib/pages/home/home_page.dart';
import 'lib/pages/analysis/body_analysis_page.dart';
import 'lib/pages/diary/food_diary_page.dart';
import 'lib/pages/camera/camera_screen.dart';

void main() {
  // 測試所有頁面類別是否能正常導入和實例化

  // 認證頁面
  final loginPage = LoginPage();
  final registerPage = RegisterPage();

  // 主要頁面
  final homePage = HomePage();
  final analysisPage = BodyAnalysisPage();
  final diaryPage = FoodDiaryPage();
  final cameraScreen = CameraScreen();

  // 簡單檢查類型
  if (loginPage.runtimeType != Null &&
      registerPage.runtimeType != Null &&
      homePage.runtimeType != Null &&
      analysisPage.runtimeType != Null &&
      diaryPage.runtimeType != Null &&
      cameraScreen.runtimeType != Null) {
    // 所有頁面模組都能正常 import！
  }
}