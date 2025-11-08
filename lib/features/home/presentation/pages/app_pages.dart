import 'package:flutter/material.dart';
import '../../../food_diary/presentation/pages/food_diary_page.dart';
import '../../../camera/presentation/pages/smart_camera_page.dart';
import '../../../analysis/presentation/pages/body_analysis_page.dart';
import '../../../exercise/presentation/pages/exercise_page.dart';
import 'home_page.dart';

class AppPages {
  static Widget getHomePage() => const HomePageContent();
  static Widget getFoodDiaryPage() => const FoodDiaryPageContent();
  static Widget getAnalysisPage() {
    try {
      return const BodyAnalysisPage();
    } catch (e) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '身體分析功能暫時無法使用',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '請重新啟動應用程式',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }
  static Widget getSmartCameraPage() => const SmartCameraScreen();
  static Widget getExercisePage() => const ExercisePage();
}
