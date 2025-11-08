// ====================================================================
// 主應用程式入口點 - Clean Architecture 版本
// ====================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
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

// Use Cases
import 'features/food_diary/domain/usecases/get_food_entries_usecase.dart';
import 'features/food_diary/domain/usecases/add_food_entry_usecase.dart';
import 'features/camera/domain/usecases/get_available_cameras_usecase.dart';
import 'features/camera/domain/usecases/initialize_camera_usecase.dart';
import 'features/camera/domain/usecases/take_picture_usecase.dart';
import 'features/camera/domain/usecases/toggle_flash_usecase.dart';
import 'features/camera/domain/usecases/pick_images_from_gallery_usecase.dart';
import 'features/camera/domain/usecases/analyze_image_usecase.dart';
import 'features/camera/domain/usecases/perform_volume_calculation_usecase.dart';

// ViewModels
import 'features/food_diary/presentation/viewmodels/food_diary_viewmodel.dart';
import 'features/camera/presentation/viewmodels/camera_view_model.dart';

import 'firebase_options.dart';

// ====================================================================
// 主函數 - 應用程式入口點
// ====================================================================
Future<void> main() async {
  // 確保Flutter綁定初始化完成
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase 初始化成功');
  } catch (e) {
    print('Firebase 初始化失敗: $e');
  }

  // 初始化相機服務
  final cameraService = CameraService();
  await cameraService.initializeCameras();

  // 設定系統UI風格
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 啟動Flutter應用程式
  runApp(MyApp(cameraService: cameraService));
}

// ====================================================================
// 主應用程式類別
// ====================================================================
class MyApp extends StatelessWidget {
  final CameraService cameraService;

  const MyApp({
    super.key,
    required this.cameraService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // =======================================
        // Core Services
        // =======================================
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
        Provider<CameraRepository>(
          create: (context) => CameraRepositoryImpl(
            context.read<CameraDatasource>(),
            context.read<ImageProcessingDatasource>(),
          ),
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
        Provider<PickImagesFromGalleryUseCase>(
          create: (context) => PickImagesFromGalleryUseCase(context.read<CameraRepository>()),
        ),
        Provider<AnalyzeImageUseCase>(
          create: (context) => AnalyzeImageUseCase(context.read<CameraRepository>()),
        ),
        Provider<PerformVolumeCalculationUseCase>(
          create: (context) => PerformVolumeCalculationUseCase(context.read<CameraRepository>()),
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
        ChangeNotifierProvider<CameraViewModel>(
          create: (context) => CameraViewModel(
            getAvailableCamerasUseCase: context.read<GetAvailableCamerasUseCase>(),
            initializeCameraUseCase: context.read<InitializeCameraUseCase>(),
            takePictureUseCase: context.read<TakePictureUseCase>(),
            toggleFlashUseCase: context.read<ToggleFlashUseCase>(),
            pickImagesFromGalleryUseCase: context.read<PickImagesFromGalleryUseCase>(),
            analyzeImageUseCase: context.read<AnalyzeImageUseCase>(),
            performVolumeCalculationUseCase: context.read<PerformVolumeCalculationUseCase>(),
            cameraService: context.read<CameraService>(),
          ),
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
  }
}