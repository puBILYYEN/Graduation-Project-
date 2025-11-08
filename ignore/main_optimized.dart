// ====================================================================
// 主應用程式入口點 - 優化啟動速度版本
// ====================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

// ====================================================================
// 主函數 - 應用程式入口點（優化版）
// ====================================================================
Future<void> main() async {
  // 確保Flutter綁定初始化完成
  WidgetsFlutterBinding.ensureInitialized();

  // 設定系統UI風格（同步執行）
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ⚡ 優化：只初始化關鍵服務，其他延遲載入
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('✅ Firebase 初始化完成');

  // ⚡ 優化：先啟動應用程式，背景初始化相機
  runApp(const MyApp());
}

// ====================================================================
// 主應用程式類別（優化版）
// ====================================================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  CameraService? _cameraService;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    // ⚡ 優化：背景初始化相機，不阻塞首屏
    _initializeCameraInBackground();
  }

  /// 背景初始化相機服務（不阻塞 UI）
  Future<void> _initializeCameraInBackground() async {
    if (kIsWeb) {
      debugPrint('Web 平台：跳過相機初始化');
      return;
    }

    try {
      // 延遲 500ms 再初始化，讓首屏先渲染
      await Future.delayed(const Duration(milliseconds: 500));

      _cameraService = CameraService();
      await _cameraService!.initializeCameras();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        debugPrint('✅ 相機服務初始化完成（背景）');
      }
    } catch (e) {
      debugPrint('⚠️ 相機初始化失敗: $e');
      // 不影響 APP 啟動
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⚡ 優化：直接返回 APP，不等待相機初始化
    return MultiProvider(
      providers: _buildProviders(),
      child: MaterialApp.router(
        title: '智慧營養追蹤應用程式',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }

  /// 構建 Providers（延遲創建）
  List<Provider> _buildProviders() {
    return [
      // =======================================
      // Core Services（關鍵服務，立即創建）
      // =======================================
      if (_cameraService != null)
        Provider<CameraService>.value(value: _cameraService!),

      // ⚡ 優化：使用 lazy 創建
      ProxyProvider0<FirestoreService>(
        lazy: true,
        update: (_, __) => FirestoreService(),
      ),

      // =======================================
      // Datasources（延遲創建）
      // =======================================
      ProxyProvider0<FirebaseAuthDatasource>(
        lazy: true,
        update: (_, __) => FirebaseAuthDatasource(),
      ),
      ProxyProvider0<CameraDatasource>(
        lazy: true,
        update: (_, __) => CameraDatasource(),
      ),
      ProxyProvider0<ImageProcessingDatasource>(
        lazy: true,
        update: (_, __) => ImageProcessingDatasource(),
      ),

      // =======================================
      // Repositories（延遲創建，只在需要時創建）
      // =======================================
      ProxyProvider<FirebaseAuthDatasource, AuthRepository>(
        lazy: true,
        update: (_, authDatasource, __) => AuthRepositoryImpl(authDatasource),
      ),
      ProxyProvider0<FoodDiaryRepository>(
        lazy: true,
        update: (_, __) => MockFoodDiaryRepositoryImpl(),
      ),
      ProxyProvider0<AnalysisRepository>(
        lazy: true,
        update: (_, __) => MockAnalysisRepositoryImpl(),
      ),
      ProxyProvider2<CameraDatasource, ImageProcessingDatasource, CameraRepository>(
        lazy: true,
        update: (_, cameraDatasource, imageDatasource, __) =>
            CameraRepositoryImpl(cameraDatasource, imageDatasource),
      ),
      ProxyProvider<FoodDiaryRepository, StatisticsRepository>(
        lazy: true,
        update: (_, foodDiaryRepository, __) => StatisticsRepositoryImpl(
          foodDiaryRepository: foodDiaryRepository,
          analysisRepository: null, // 延遲載入
        ),
      ),
      ProxyProvider0<ExerciseRepository>(
        lazy: true,
        update: (_, __) => FirebaseExerciseRepository(),
      ),

      // ⚡ 更多 Providers 可以類似方式優化...
    ];
  }

  @override
  void dispose() {
    _cameraService?.dispose();
    super.dispose();
  }
}
