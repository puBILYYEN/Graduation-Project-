// ====================================================================
// 主應用程式入口點 - 結構化版本
// ====================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// 導入新的路由和服務管理
import 'core/router/app_router.dart';
import 'core/services/camera_service.dart';

// ====================================================================
// 主函數 - 應用程式入口點
// ====================================================================
/// 應用程式主函數 - 初始化服務和啟動應用程式
Future<void> main() async {
  // 確保Flutter綁定初始化完成
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  try {
    await Firebase.initializeApp();
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

  // 啟動Flutter應用程式，並提供相機服務
  runApp(
    MyApp(
      cameraService: cameraService,
    ),
  );
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
    // 使用 MultiProvider 建立我們的「武器庫」
    return MultiProvider(
      providers: [
        // 1. 提供相機服務
        Provider<CameraService>.value(value: cameraService),
        // 之後可以加入其他的服務，例如認證服務
        // Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp.router(
        title: '智慧營養追蹤應用程式',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        // 使用 GoRouter 作為我們的「地圖」
        routerConfig: AppRouter.router,
      ),
    );
  }
}
