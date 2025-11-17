/// ==========================================================================
/// @檔案: main.dart
/// @描述: 應用程式主入口點，負責初始化、設定依賴注入(DI)和啟動應用。
/// ==========================================================================
import 'dart:io';  // 用於 HttpOverrides

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:camera/camera.dart'; // Currently unused
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// 導入新的路由和服務管理
import 'core/router/app_router.dart';
import 'core/services/camera_service.dart';
import 'core/services/firestore_service.dart';

// 認證相關
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/datasources/firebase_auth_datasource.dart';

// 相機相關
import 'features/camera/data/datasources/camera_datasource.dart';
import 'features/camera/data/datasources/image_processing_datasource.dart';
import 'features/camera/domain/repositories/camera_repository.dart';
import 'features/camera/data/repositories/camera_repository_impl.dart';

// 飲食日記相關
import 'features/food_diary/domain/repositories/food_diary_repository.dart';
import 'features/food_diary/data/repositories/mock_food_diary_repository_impl.dart';

// 身體分析相關
import 'features/analysis/domain/repositories/analysis_repository.dart';
import 'features/analysis/data/repositories/mock_analysis_repository_impl.dart';

// 統計相關
import 'features/statistics/domain/repositories/statistics_repository.dart';
import 'features/statistics/data/repositories/statistics_repository_impl.dart';
import 'features/statistics/domain/usecases/get_daily_nutrition_usecase.dart';
import 'features/statistics/domain/usecases/get_weekly_nutrition_usecase.dart';
import 'features/statistics/domain/usecases/get_weight_history_usecase.dart';
import 'features/statistics/domain/usecases/get_meal_distribution_usecase.dart';

// 運動相關
import 'features/exercise/domain/repositories/exercise_repository.dart';
import 'features/exercise/data/repositories/firebase_exercise_repository.dart';

// Use Cases
import 'features/food_diary/domain/usecases/get_food_entries_usecase.dart';
import 'features/food_diary/domain/usecases/add_food_entry_usecase.dart';
import 'features/analysis/domain/usecases/get_body_metrics_usecase.dart';
import 'features/analysis/domain/usecases/update_body_metrics_usecase.dart';
import 'features/camera/domain/usecases/get_available_cameras_usecase.dart';
import 'features/camera/domain/usecases/initialize_camera_usecase.dart';
import 'features/camera/domain/usecases/take_picture_usecase.dart';
import 'features/camera/domain/usecases/toggle_flash_usecase.dart';
import 'features/camera/domain/usecases/switch_camera_usecase.dart';
import 'features/camera/domain/usecases/pick_images_from_gallery_usecase.dart';
import 'features/camera/domain/usecases/analyze_image_usecase.dart';
import 'features/camera/domain/usecases/perform_volume_calculation_usecase.dart';

// ViewModels
import 'features/food_diary/presentation/viewmodels/food_diary_viewmodel.dart';
import 'features/camera/presentation/viewmodels/camera_view_model.dart';
import 'features/analysis/presentation/viewmodels/body_analysis_viewmodel.dart';
import 'features/statistics/presentation/viewmodels/statistics_viewmodel.dart';
import 'features/exercise/presentation/viewmodels/exercise_viewmodel.dart';

import 'firebase_options.dart';
import 'core/services/app_logger.dart';

/// --------------------------------------------------------------------
/// @類別: MyHttpOverrides
/// @描述: 處理 HTTPS 證書驗證問題的自訂類別。
///        主要用於開發環境，以允許不受信任的證書(例如 ngrok)。
/// --------------------------------------------------------------------
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // 開發模式下，總是返回 true，表示接受任何（包括自簽名的）證書。
        // 警告：這在生產環境中是不安全的，應移除或限制在特定 host。
        return true;
      };
  }
}

/// --------------------------------------------------------------------
/// @函數: main
/// @描述: Flutter 應用程式的入口函數，程式從這裡開始執行。
/// --------------------------------------------------------------------
Future<void> main() async {
  // 步驟 1: 確保 Flutter 引擎的綁定已經初始化。
  // 這是呼叫原生程式碼前必須執行的第一步。
  WidgetsFlutterBinding.ensureInitialized();

  // 步驟 2: 設定 HttpOverrides (僅限非 Web 平台)。
  // 這允許在開發時信任自簽名的 HTTPS 證書，例如 ngrok。
  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }

  // 步驟 3: 初始化自訂的日誌系統。
  await AppLogger.initialize();

  // 步驟 4: 設定系統頂部狀態欄的 UI 風格。
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // 狀態欄背景透明
      statusBarIconBrightness: Brightness.dark, // 狀態欄圖示為深色
    ),
  );

  // 步驟 5: 啟動 Flutter 應用程式的根組件 (Root Widget)。
  runApp(const MyApp());
}

/// --------------------------------------------------------------------
/// @類別: MyApp
/// @描述: 應用程式的根組件 (Root Widget)，使用 StatefulWidget 以便
///        在 initState 中執行非同步的服務初始化。
/// --------------------------------------------------------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// [_initializationFuture]: 用於儲存服務初始化過程的 Future。
  /// 將其定義為一個屬性，可以防止在每次 build 時重複執行初始化。
  late final Future<CameraService?> _initializationFuture;

  @override
  void initState() {
    super.initState();
    // 在 initState 中僅執行一次初始化函數，並將返回的 Future 賦值給屬性。
    _initializationFuture = _initializeServices();
  }

  /// ------------------------------------------------------------------
  /// @方法: _initializeServices
  /// @描述: 執行所有必要的非同步服務初始化，例如 Firebase。
  ///        此方法被設計為在 FutureBuilder 中呼叫，並處理初始化過程中的錯誤。
  /// @返回: Future<CameraService?> - 返回一個可選的 CameraService 實例。
  /// ------------------------------------------------------------------
  Future<CameraService?> _initializeServices() async {
    try {
      debugPrint('🚀 開始初始化服務...');

      // 初始化 Firebase。使用 try-catch 來處理可能已經初始化過的 "duplicate-app" 情況。
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ Firebase 初始化成功');
      } catch (e) {
        // 如果 Firebase 實例已存在，這不是一個致命錯誤，僅記錄資訊。
        if (e.toString().contains('duplicate-app')) {
          debugPrint('ℹ️ Firebase 已經初始化，跳過');
        } else {
          // 對於其他 Firebase 初始化錯誤，則記錄警告。
          debugPrint('⚠️ Firebase 初始化警告: $e');
        }
      }

      // 全局相機初始化邏輯已被移至相機頁面內部處理，以避免資源衝突和優化啟動。
      // 因此，這裡僅打印一條資訊，並返回 null。
      debugPrint('ℹ️ 跳過全局相機初始化（由相機頁面獨立管理）');
      return null;

    } catch (e, stackTrace) {
      // 如果在初始化過程中發生任何其他未捕獲的錯誤，記錄下來。
      debugPrint('❌ 服務初始化失敗: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      // 即使初始化失敗，也返回 null，讓應用程式能夠啟動並可能顯示一個錯誤頁面。
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 MyApp.build 被調用');

    // 使用 FutureBuilder 來監聽初始化過程，並根據狀態顯示不同的 UI。
    return FutureBuilder<CameraService?>(
      future: _initializationFuture,  // 監聽在 initState 中創建的 Future
      builder: (context, snapshot) {
        debugPrint('📊 FutureBuilder 狀態: ${snapshot.connectionState}');

        // 案例 1: 初始化正在進行中 (Future 尚未完成)。
        // 顯示一個簡單的載入畫面，提供友好的用戶體驗。
        if (snapshot.connectionState != ConnectionState.done) {
          debugPrint('⏳ 顯示初始化畫面');
          return MaterialApp(
            title: '智慧營養追蹤應用程式',
            debugShowCheckedModeBanner: false,
            home: const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在初始化應用程式...'),
                  ],
                ),
              ),
            ),
          );
        }

        // 案例 2: 初始化完成 (Future 已完成)。
        debugPrint('✅ 初始化完成，建構 MultiProvider');
        final cameraService = snapshot.data; // 獲取初始化結果 (在此案例中為 null)

        // 使用 MultiProvider 來進行全域的依賴注入 (Dependency Injection)。
        // 所有在這裡提供的服務、倉儲、用例和視圖模型都可以在其子組件中被存取。
        return MultiProvider(
          providers: [
            // =======================================
            // 核心服務 (Services)
            // =======================================
            Provider<FirestoreService>(create: (_) => FirestoreService()),

            // =======================================
            // 資料來源 (Datasources) - 資料層的最底層，直接與外部(如Firebase)互動
            // =======================================
            Provider<FirebaseAuthDatasource>(create: (_) => FirebaseAuthDatasource()),
            Provider<CameraDatasource>(create: (_) => CameraDatasource()),
            Provider<ImageProcessingDatasource>(create: (_) => ImageProcessingDatasource()),

            // =======================================
            // 資料倉儲 (Repositories) - 實作 Domain 層的抽象介面，連接 Datasources
            // =======================================
            Provider<AuthRepository>(
              create: (context) => AuthRepositoryImpl(context.read<FirebaseAuthDatasource>()),
            ),
            Provider<FoodDiaryRepository>(
              create: (_) => MockFoodDiaryRepositoryImpl(), // 注意：這裡是使用 Mock 實作
            ),
            Provider<AnalysisRepository>(
              create: (_) => MockAnalysisRepositoryImpl(), // 注意：這裡是使用 Mock 實作
            ),
            Provider<CameraRepository>(
              create: (context) => CameraRepositoryImpl(
                context.read<CameraDatasource>(),
                context.read<ImageProcessingDatasource>(),
              ),
            ),
            Provider<StatisticsRepository>(
              create: (context) => StatisticsRepositoryImpl(
                foodDiaryRepository: context.read<FoodDiaryRepository>(),
                analysisRepository: context.read<AnalysisRepository>(),
              ),
            ),
            Provider<ExerciseRepository>(
              create: (_) => FirebaseExerciseRepository(),
            ),

            // =======================================
            // 用例 (UseCases) - 封裝單一的業務邏輯，由 ViewModel 呼叫
            // =======================================
            // Food Diary
            Provider<GetFoodEntriesUseCase>(
              create: (context) => GetFoodEntriesUseCase(context.read<FoodDiaryRepository>()),
            ),
            Provider<AddFoodEntryUseCase>(
              create: (context) => AddFoodEntryUseCase(context.read<FoodDiaryRepository>()),
            ),
            // Analysis
            Provider<GetBodyMetricsUseCase>(
              create: (context) => GetBodyMetricsUseCase(context.read<AnalysisRepository>()),
            ),
            Provider<UpdateBodyMetricsUseCase>(
              create: (context) => UpdateBodyMetricsUseCase(context.read<AnalysisRepository>()),
            ),
            // Camera
            Provider<GetAvailableCamerasUseCase>(
              create: (context) => GetAvailableCamerasUseCase(context.read<CameraRepository>()),
            ),
            Provider<InitializeCameraUseCase>(
              create: (context) => InitializeCameraUseCase(context.read<CameraRepository>()),
            ),
            Provider<TakePictureUseCase>(
              create: (context) => TakePictureUseCase(context.read<CameraRepository>()),
            ),
            Provider<ToggleFlashUseCase>(
              create: (context) => ToggleFlashUseCase(context.read<CameraRepository>()),
            ),
            Provider<SwitchCameraUseCase>(
              create: (context) => SwitchCameraUseCase(context.read<CameraRepository>()),
            ),
            Provider<PickImagesFromGalleryUseCase>(
              create: (context) => PickImagesFromGalleryUseCase(context.read<CameraRepository>()),
            ),
            Provider<AnalyzeImageUseCase>(
              create: (context) => AnalyzeImageUseCase(context.read<CameraRepository>()),
            ),
            Provider<PerformVolumeCalculationUseCase>(
              create: (context) => PerformVolumeCalculationUseCase(context.read<CameraRepository>()),
            ),
            // Statistics
            Provider<GetDailyNutritionUseCase>(
              create: (context) => GetDailyNutritionUseCase(context.read<StatisticsRepository>()),
            ),
            Provider<GetWeeklyNutritionUseCase>(
              create: (context) => GetWeeklyNutritionUseCase(context.read<StatisticsRepository>()),
            ),
            Provider<GetWeightHistoryUseCase>(
              create: (context) => GetWeightHistoryUseCase(context.read<StatisticsRepository>()),
            ),
            Provider<GetMealDistributionUseCase>(
              create: (context) => GetMealDistributionUseCase(context.read<StatisticsRepository>()),
            ),

            // =======================================
            // 視圖模型 (ViewModels) - 處理 UI 狀態和業務邏輯，讓 Widget 保持乾淨
            // =======================================
            ChangeNotifierProvider<FoodDiaryViewModel>(
              create: (context) => FoodDiaryViewModel(
                context.read<GetFoodEntriesUseCase>(),
                context.read<AddFoodEntryUseCase>(),
              ),
            ),
            ChangeNotifierProvider<BodyAnalysisViewModel>(
              create: (context) => BodyAnalysisViewModel(
                context.read<GetBodyMetricsUseCase>(),
                context.read<UpdateBodyMetricsUseCase>(),
              ),
            ),
            ChangeNotifierProvider<StatisticsViewModel>(
              create: (context) => StatisticsViewModel(
                getDailyNutritionUseCase: context.read<GetDailyNutritionUseCase>(),
                getWeeklyNutritionUseCase: context.read<GetWeeklyNutritionUseCase>(),
                getWeightHistoryUseCase: context.read<GetWeightHistoryUseCase>(),
                getMealDistributionUseCase: context.read<GetMealDistributionUseCase>(),
              ),
            ),
            ChangeNotifierProvider<ExerciseViewModel>(
              create: (context) => ExerciseViewModel(
                context.read<ExerciseRepository>(),
              )..initialize(),
            ),
            // =======================================
            // Camera ViewModel - 恢復相機功能
            // =======================================
            ChangeNotifierProvider<CameraViewModel>(
              create: (context) {
                // 創建一個 CameraService 實例
                final cameraService = CameraService();

                return CameraViewModel(
                  getAvailableCamerasUseCase: context.read<GetAvailableCamerasUseCase>(),
                  initializeCameraUseCase: context.read<InitializeCameraUseCase>(),
                  takePictureUseCase: context.read<TakePictureUseCase>(),
                  toggleFlashUseCase: context.read<ToggleFlashUseCase>(),
                  switchCameraUseCase: context.read<SwitchCameraUseCase>(),
                  pickImagesFromGalleryUseCase: context.read<PickImagesFromGalleryUseCase>(),
                  analyzeImageUseCase: context.read<AnalyzeImageUseCase>(),
                  performVolumeCalculationUseCase: context.read<PerformVolumeCalculationUseCase>(),
                  cameraService: cameraService,
                );
              },
            ),
          ],
          // MultiProvider 的 child 是 MaterialApp.router，表示整個應用都將使用 GoRouter 進行路由管理。
          child: MaterialApp.router(
            title: '智慧營養追蹤應用程式',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
            ),
            routerConfig: AppRouter.router, // 指定 GoRouter 的設定
          ),
        );
      },
    );
  }
}