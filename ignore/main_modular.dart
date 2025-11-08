// ====================================================================
// 主檔案 - 模組化版本 (Modular Version)
// ====================================================================
/*
這是模組化後的主檔案示範
原本 7900+ 行的程式碼已經拆分成以下模組：

📁 lib/
├── main.dart (本檔案 - 只保留程式入口和應用程式根節點)
├── data/
│   ├── models/          ✅ 已完成
│   │   ├── container_analysis.dart
│   │   ├── measurement.dart
│   │   └── nutrition.dart
│   └── services/        🚧 待拆分
│       ├── reference_database.dart
│       ├── measurement_calculator.dart
│       └── log_manager.dart
├── features/            🚧 待拆分
│   ├── auth/
│   │   └── presentation/
│   │       ├── login_page.dart
│   │       └── register_page.dart
│   ├── home/
│   │   └── presentation/
│   │       └── home_page.dart
│   ├── analysis/
│   │   └── presentation/
│   │       └── body_analysis_page.dart
│   ├── food_diary/
│   │   └── presentation/
│   │       └── food_diary_page.dart
│   └── camera/
│       └── presentation/
│           └── camera_screen.dart
├── widgets/             🚧 待拆分
│   └── custom_painters.dart
└── utils/               🚧 待拆分
    └── image_processing.dart
*/

// ====================================================================
// Import 區域
// ====================================================================
// Flutter 核心套件
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

// 第三方套件
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Dart 核心函式庫
import 'dart:math' as math;
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

// 專案模組 - 資料層
import 'data/models/container_analysis.dart';
import 'data/models/measurement.dart';
import 'data/models/nutrition.dart';

// 專案模組 - 服務層 (待建立)
// import 'data/services/reference_database.dart';
// import 'data/services/measurement_calculator.dart';
// import 'data/services/log_manager.dart';

// 專案模組 - 展示層 (待建立)
// import 'features/auth/presentation/login_page.dart';
// import 'features/auth/presentation/register_page.dart';
// import 'features/home/presentation/home_page.dart';
// import 'features/analysis/presentation/body_analysis_page.dart';
// import 'features/food_diary/presentation/food_diary_page.dart';
// import 'features/camera/presentation/camera_screen.dart';

// 專案模組 - 工具層 (待建立)
// import 'widgets/custom_painters.dart';
// import 'utils/image_processing.dart';

// ====================================================================
// 主程式入口點
// ====================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase (如果需要)
  // await Firebase.initializeApp();

  // 初始化日誌管理器
  // await LogManager.instance.initialize();

  // 設定螢幕方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

// ====================================================================
// 應用程式根節點
// ====================================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '登入系統',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // home: const LoginPage(), // 待模組建立後啟用
      home: const Scaffold(
        body: Center(
          child: Text(
            '模組化進行中...\n請繼續拆分其他模組',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// 📌 接下來的步驟
// ====================================================================
/*
1. ✅ 資料模型已拆分完成 (3個檔案)
   - container_analysis.dart
   - measurement.dart
   - nutrition.dart

2. 🚧 繼續拆分服務層
   需要從 main.dart 剪貼以下類別：
   - ReferenceObjectDatabase
   - MeasurementCalculator
   - DevicePhysicalOrientation (enum)
   - LogManager

3. 🚧 繼續拆分展示層 (最大的部分)
   需要建立以下頁面檔案：
   - LoginPage + _LoginPageState
   - RegisterPage + _RegisterPageState
   - HomePageContent + _HomePageContentState
   - BodyAnalysisPageContent + _BodyAnalysisPageContentState
   - FoodDiaryPageContent + _FoodDiaryPageContentState
   - CameraScreen + _CameraScreenState

4. 🚧 繼續拆分工具層
   - EdgeDetectionPainter
   - FoodPhotoSelector
   - NutritionLabelScreen
   - ReferenceMeasurementPage
   - MeasurementPainter
   - ImageProcessingResult
   - MultiImageProcessingScreen

5. 🔄 更新 main.dart
   將所有已拆分的模組從 main.dart 移除
   只保留 main() 函數、MyApp 和 MainFrame

6. ✅ 測試編譯
   確保所有模組都能正確 import 和運作
*/
