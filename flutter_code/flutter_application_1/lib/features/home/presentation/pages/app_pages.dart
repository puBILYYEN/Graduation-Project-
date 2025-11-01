import 'package:flutter/material.dart';
import '../../../analysis/presentation/pages/body_analysis_page.dart';
import '../../../food_diary/presentation/pages/food_diary_page.dart';
import '../../../camera/presentation/pages/smart_camera_page.dart';
import 'home_page.dart';

class AppPages {
  static Widget getHomePage() => const HomePageContent();
  static Widget getFoodDiaryPage() => const FoodDiaryPageContent();
  static Widget getAnalysisPage() => const BodyAnalysisPageContent();
  static Widget getSmartCameraPage() => const SmartCameraScreen();
  static Widget getExercisePage() => const Center(
      child: Text('運動頁面開發中...', style: TextStyle(fontSize: 18)));
}
