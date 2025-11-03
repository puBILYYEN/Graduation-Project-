// ====================================================================
// 應用程式路由 - AppRouter
// ====================================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 導入我們的頁面
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/profile_setup_page.dart';
import '../../features/home/presentation/pages/main_frame.dart';
import '../../features/camera/presentation/pages/smart_camera_page.dart';
import '../../features/nutrition/presentation/pages/nutrition_label_screen.dart';
import '../../features/measurement/presentation/pages/reference_measurement_page.dart';
import '../../features/camera/presentation/pages/multiple_images_processing_page.dart';
import '../../features/food_diary/presentation/pages/food_diary_page.dart';
import '../../test_google_login.dart';


import 'package:provider/provider.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Replaced by AuthRepository

class AppRouter {
  // 建立 GoRouter 的靜態實例
  static final GoRouter router = GoRouter(
    // 初始路由位置
    initialLocation: '/',

    // 路由重新導向邏輯 (導航守衛)
    // redirect: (context, state) {
    //   final AuthRepository authRepository = context.read<AuthRepository>();
    //   final bool loggedIn = authRepository.currentUser != null;
    //
    //   final bool loggingIn = state.matchedLocation == '/' || state.matchedLocation == '/register';
    //
    //   if (!loggedIn && !loggingIn) {
    //     return '/';
    //   }
    //
    //   if (loggedIn && loggingIn) {
    //     return '/home';
    //   }
    //
    //   return null;
    // },

    // 路由列表
    routes: [
      // 登入頁面
      GoRoute(
        path: '/', // 根路徑
        builder: (context, state) => const LoginPage(),
        routes: [
          // 註冊頁面 (作為登入頁的子路由)
          GoRoute(
            path: 'register', // -> /register
            builder: (context, state) => const RegisterPage(),
          ),
        ],
      ),

      // 個人資料完善頁面
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupPage(),
      ),

      // 主框架頁面
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainFrame(),
      ),

      // Google 登入測試頁面
      GoRoute(
        path: '/test-google-login',
        builder: (context, state) => const TestGoogleLoginPage(),
      ),

      // 飲食日記頁面
      GoRoute(
        path: '/diary',
        builder: (context, state) => const FoodDiaryPageContent(),
      ),

      // 智慧相機頁面
      GoRoute(
        path: '/camera',
        builder: (context, state) => const SmartCameraScreen(),
        routes: [
          // 營養標籤頁面
          GoRoute(
            path: 'nutrition-label', // -> /camera/nutrition-label
            builder: (context, state) {
              // 修正：接收 Map 而不是 String
              final data = state.extra as Map<String, dynamic>?;
              if (data == null || data['imagePath'] == null || data['analysis'] == null) {
                return const Scaffold(body: Center(child: Text('錯誤：缺少圖片或分析資料')));
              }
              return NutritionLabelScreen(
                imagePath: data['imagePath'],
                analysis: data['analysis'],
              );
            },
          ),
          // 參考測量頁面
          GoRoute(
            path: 'reference-measurement', // -> /camera/reference-measurement
            builder: (context, state) {
              final params = state.extra as Map<String, dynamic>?;
              if (params == null || params['imagePath'] == null || params['onMeasurementComplete'] == null) {
                return const Text('錯誤：缺少必要參數');
              }
              return ReferenceMeasurementPage(
                imagePath: params['imagePath'],
                onMeasurementComplete: params['onMeasurementComplete'],
              );
            },
          ),
          // 多圖處理頁面
          GoRoute(
            path: 'process-multiple', // -> /camera/process-multiple
            builder: (context, state) {
              final params = state.extra as Map<String, dynamic>?;
              if (params == null || params['images'] == null) {
                return const Text('錯誤：缺少圖片列表');
              }
              return MultipleImagesProcessingPage(
                images: params['images'],
                onRetakePhoto: params['onRetakePhoto'],
                onSelectFromGallery: params['onSelectFromGallery'],
              );
            },
          ),
        ]
      ),
    ],

    // 路由錯誤處理 (可選)
    // errorBuilder: (context, state) => const ErrorPage(),
  );
}