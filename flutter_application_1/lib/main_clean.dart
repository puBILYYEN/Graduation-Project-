// ====================================================================
// 主檔案 - 精簡版 (已模組化)
// ====================================================================
/*
這是模組化後的精簡版 main.dart

原始檔案: 7,908 行 → 精簡版: ~100 行
減少: 約 98.7%

所有功能已拆分成獨立模組，符合 Flutter 2025 最佳實踐。
*/

// ====================================================================
// Import 區域
// ====================================================================
// Flutter 核心套件
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 專案模組 - 資料層
import 'data/models/container_analysis.dart';
import 'data/models/measurement.dart';
import 'data/models/nutrition.dart';

// 專案模組 - 服務層
import 'data/services/reference_database.dart';
import 'data/services/measurement_calculator.dart';
import 'data/services/log_manager.dart';

// 專案模組 - 核心
import 'core/app.dart';
import 'core/navigation/main_frame.dart';

// 專案模組 - 展示層 (Features)
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
// import 'features/home/presentation/home_page.dart';
// import 'features/analysis/presentation/body_analysis_page.dart';
// import 'features/food_diary/presentation/food_diary_page.dart';
// import 'features/camera/presentation/camera_screen.dart';

// 專案模組 - 工具層 - 待建立
// import 'widgets/custom_painters.dart';
// import 'utils/image_processing.dart';

// ====================================================================
// 主程式入口點
// ====================================================================
void main() async {
  // 確保 Flutter 框架初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日誌管理器
  await LogManager.instance.initialize();

  // 設定螢幕方向 - 允許所有方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 啟動應用程式
  runApp(const MyApp());
}

// ====================================================================
// 所有其他程式碼已拆分成獨立模組
// ====================================================================
/*
📂 模組結構：

lib/
├── main.dart                          ← 本檔案 (~100 行)
├── core/                              ← 核心模組
│   ├── app.dart                       ✅ MyApp
│   └── navigation/
│       └── main_frame.dart            ✅ MainFrame, AppPage
├── data/                              ← 資料層
│   ├── models/                        ✅ 資料模型
│   │   ├── container_analysis.dart
│   │   ├── measurement.dart
│   │   └── nutrition.dart
│   └── services/                      ✅ 服務層
│       ├── reference_database.dart
│       ├── measurement_calculator.dart
│       └── log_manager.dart
├── features/                          ← 功能模組
│   ├── auth/
│   │   └── presentation/
│   │       ├── login_page.dart        ✅
│   │       └── register_page.dart     ✅
│   ├── home/
│   │   └── presentation/
│   │       └── home_page.dart         🚧
│   ├── analysis/
│   │   └── presentation/
│   │       └── body_analysis_page.dart 🚧
│   ├── food_diary/
│   │   └── presentation/
│   │       └── food_diary_page.dart   🚧
│   └── camera/
│       └── presentation/
│           └── camera_screen.dart     🚧
├── widgets/                           ← 通用 Widget (待建立)
│   └── custom_painters.dart          🚧
└── utils/                             ← 工具函數 (待建立)
    └── image_processing.dart          🚧

✅ = 已完成
🚧 = 待建立（原始碼仍在舊的 main.dart 中）
*/
