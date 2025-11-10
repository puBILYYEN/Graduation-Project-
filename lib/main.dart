// ====================================================================
// 主應用程式入口點 - Clean Architecture 版本
// ====================================================================
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

// ====================================================================
// HttpOverrides 類別 - 處理 HTTPS 證書問題（用於開發環境）
// ====================================================================
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // 在開發環境中允許所有證書（包括 ngrok 的證書）
        // 生產環境應該移除此代碼或只允許特定的 host
        return true;
      };
  }
}

// ====================================================================
// 主函數 - 應用程式入口點
// ====================================================================
Future<void> main() async {
  // 確保Flutter綁定初始化完成
  WidgetsFlutterBinding.ensureInitialized();

  // 設置 HttpOverrides 以處理 HTTPS 證書問題（開發環境）
  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }

  // 初始化日誌系統
  await AppLogger.initialize();
  // 設定系統UI風格（這個可以同步執行）
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 先啟動應用程式，背景初始化服務
  runApp(const MyApp());
}

// ====================================================================
// 主應用程式類別 - 使用 StatefulWidget + FutureBuilder 支援熱重載
// ====================================================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<CameraService?> _initializationFuture;

  @override
  void initState() {
    super.initState();
    // 在 initState 中初始化 Future，確保只執行一次
    _initializationFuture = _initializeServices();
  }

  /// 初始化服務並返回 CameraService（如果需要）
  /// 使用 Future 而非直接在 initState 中執行，確保 FutureBuilder 能正確追蹤狀態
  Future<CameraService?> _initializeServices() async {
    try {
      debugPrint('🚀 開始初始化服務...');

      // 初始化 Firebase（檢查是否已初始化，避免重複）
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ Firebase 初始化成功');
      } catch (e) {
        // Firebase 可能已經初始化，這不是錯誤
        if (e.toString().contains('duplicate-app')) {
          debugPrint('ℹ️ Firebase 已經初始化，跳過');
        } else {
          debugPrint('⚠️ Firebase 初始化警告: $e');
        }
      }

      // 只在非 Web 平台初始化相機服務
      if (!kIsWeb) {
        final cameraService = CameraService();
        await cameraService.initializeCameras();
        debugPrint('✅ 相機服務初始化成功');
        return cameraService;
      } else {
        debugPrint('ℹ️ Web 平台：跳過相機初始化');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 服務初始化失敗: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      // 即使初始化失敗，也返回 null 讓應用程式能夠啟動
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 MyApp.build 被調用');

    return FutureBuilder<CameraService?>(
      future: _initializationFuture,  // 使用緩存的 Future
      builder: (context, snapshot) {
        debugPrint('📊 FutureBuilder 狀態: ${snapshot.connectionState}');

        // 初始化中：顯示簡單的載入畫面
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

        // 初始化完成：建構完整的應用程式
        debugPrint('✅ 初始化完成，建構 MultiProvider');
        final cameraService = snapshot.data;

        return MultiProvider(
      providers: [
        // =======================================
        // Core Services
        // =======================================
        // 只在非 Web 平台提供 CameraService
        if (cameraService != null)
          Provider<CameraService>.value(value: cameraService),
        Provider<FirestoreService>(create: (_) => FirestoreService()),

        // =======================================
        // Datasources
        // =======================================
        Provider<FirebaseAuthDatasource>(create: (_) => FirebaseAuthDatasource()),
        Provider<CameraDatasource>(create: (_) => CameraDatasource()),
        Provider<ImageProcessingDatasource>(create: (_) => ImageProcessingDatasource()),

        // =======================================
        // Repositories
        // =======================================
        Provider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(context.read<FirebaseAuthDatasource>()),
        ),
        Provider<FoodDiaryRepository>(
          create: (_) => MockFoodDiaryRepositoryImpl(),
        ),
        Provider<AnalysisRepository>(
          create: (_) => MockAnalysisRepositoryImpl(),
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
        // UseCases
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
        // ViewModels
        // =======================================
        ChangeNotifierProvider<FoodDiaryViewModel>(
          create: (context) => FoodDiaryViewModel(
            context.read<GetFoodEntriesUseCase>(),
            context.read<AddFoodEntryUseCase>(),
          ),
        ),
        // 只在非 Web 平台提供 CameraViewModel
        if (!kIsWeb)
          ChangeNotifierProvider<CameraViewModel>(
            create: (context) => CameraViewModel(
              getAvailableCamerasUseCase: context.read<GetAvailableCamerasUseCase>(),
              initializeCameraUseCase: context.read<InitializeCameraUseCase>(),
              takePictureUseCase: context.read<TakePictureUseCase>(),
              toggleFlashUseCase: context.read<ToggleFlashUseCase>(),
              switchCameraUseCase: context.read<SwitchCameraUseCase>(),
              pickImagesFromGalleryUseCase: context.read<PickImagesFromGalleryUseCase>(),
              analyzeImageUseCase: context.read<AnalyzeImageUseCase>(),
              performVolumeCalculationUseCase: context.read<PerformVolumeCalculationUseCase>(),
              cameraService: context.read<CameraService>(),
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
      ],
      child: MaterialApp.router(
        title: '智慧營養追蹤應用程式',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
      ),
    );
      },
    );
  }
}