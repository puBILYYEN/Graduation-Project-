# flutter_application_1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

 🎯 Flutter 應用程式模組化重構 - 完整指引

  目標
  ⏵⏵ accept edits on (shift+tab to cycle)
  將 Flutter 單體應用程式（monolithic main.dart）重構為符合 Flutter 2025 最佳實踐的 Feature-First 模組化架構。

  核心原則

  1. 只註解，不刪除 - 遇到暫時不需要的 import 或程式碼，用註解標記而非刪除
  2. 保持功能完整 - 每次拆分後確保編譯通過且功能正常
  3. 漸進式拆分 - 按照依賴順序：資料層 → 服務層 → 核心層 → 展示層 → 工具層
  4. 自動執行 - 不需要每次都詢問確認，直接執行

  目標架構

  lib/
  ├── main.dart                          # 最終目標：~100 行
  ├── core/                              # 核心功能
  │   ├── app.dart                       # 應用程式根節點
  │   └── navigation/
  │       └── main_frame.dart            # 主框架導航
  ├── data/                              # 資料層
  │   ├── models/                        # 資料模型
  │   │   ├── container_analysis.dart
  │   │   ├── measurement.dart
  │   │   └── nutrition.dart
  │   └── services/                      # 服務層
  │       ├── reference_database.dart
  │       ├── measurement_calculator.dart
  │       └── log_manager.dart
  └── features/                          # 功能模組
      ├── auth/presentation/
      │   ├── login_page.dart
      │   └── register_page.dart
      ├── home/presentation/
      │   └── home_page.dart
      ├── analysis/presentation/
      │   └── body_analysis_page.dart
      ├── food_diary/presentation/
      │   └── food_diary_page.dart
      ├── camera/presentation/
      │   └── camera_screen.dart
      └── widgets/                       # 共用 UI 元件
          └── custom_painters.dart

  拆分順序（嚴格遵守）

  第 1 階段：資料模型層（3 個模組）
  1. data/models/nutrition.dart - BodyMetrics, FoodEntry, NutrientData
  2. data/models/measurement.dart - MeasurementMethod, MeasurementMode, ReferenceObject 等
  3. data/models/container_analysis.dart - ContainerAnalysisData, ContainerInfo 等

  第 2 階段：服務層（3 個模組）
  4. data/services/reference_database.dart - ReferenceObjectDatabase
  5. data/services/measurement_calculator.dart - MeasurementCalculator, DevicePhysicalOrientation
  6. data/services/log_manager.dart - LogManager, log(), logSync()

  第 3 階段：核心層（2 個模組）
  7. core/app.dart - MyApp
  8. core/navigation/main_frame.dart - AppPage, MainFrame

  第 4 階段：展示層 - 認證（2 個模組）
  9. features/auth/presentation/login_page.dart - LoginPage
  10. features/auth/presentation/register_page.dart - RegisterPage

  第 5 階段：展示層 - 功能頁面（4 個模組）
  11. features/home/presentation/home_page.dart - HomePageContent
  12. features/analysis/presentation/body_analysis_page.dart - BodyAnalysisPageContent
  13. features/food_diary/presentation/food_diary_page.dart - FoodDiaryPageContent
  14. features/camera/presentation/camera_screen.dart - CameraScreen

  第 6 階段：工具層（2 個模組）
  15. widgets/custom_painters.dart - 所有 CustomPainter 類別
  16. utils/image_processing.dart - 圖片處理工具

  每個模組拆分的標準流程

  1. 創建新檔案 - 建立對應的資料夾和檔案
  2. 複製程式碼 - 將相關類別和函數複製到新檔案
  3. 添加 imports - 在新檔案中添加所需的 import
  4. 從 main.dart 移除 - 刪除已拆分的程式碼
  5. 更新 main.dart imports - 在 main.dart 中 import 新模組
  6. 更新 main_frame.dart - 如果是展示層，更新導航引用
  7. 編譯測試 - 執行 flutter analyze 或 flutter build apk --debug
  8. 處理依賴問題：
    - 遇到缺少套件：添加到 pubspec.yaml（不刪除 import）
    - 遇到套件衝突：註解掉問題套件，尋找替代方案
    - 遇到版本問題：更新 Android SDK/NDK 配置

  特殊處理規則

  套件相容性問題：
  - 如果 image_gallery_saver 不相容 → 使用 gal 替代
  - API 遷移：ImageGallerySaver.saveImage() → Gal.putImageBytes()
  - 錯誤處理：Map 返回值 → 例外處理

  Android 配置更新（如需要）：
  // android/app/build.gradle.kts
  android {
      compileSdk = 36
      ndkVersion = "26.3.11579264"  // 或已安裝的最高版本
      minSdk = 23
  }

  導航連接修復：
  當 FoodDiary 或 Camera 與導航失聯時：
  1. 在 main_frame.dart 添加：import '../../main.dart';
  2. 啟用對應頁面：取消 FoodDiaryPageContent 和 CameraScreen 的註解
  3. 確保 onTap 的 Camera 導航正常（index == 2）

  進度追蹤

  每完成一個階段，輸出進度報告：
  - 已完成模組數 / 總模組數
  - main.dart 行數變化
  - 編譯狀態
  - 待處理問題

  執行指令

  請按照以上順序，自動執行所有模組拆分，遇到問題時：
  1. 先嘗試自動修復（添加套件、調整配置）
  2. 重大決策時才詢問確認
  3. 每個階段完成後報告進度

  開始執行 Flutter 應用程式模組化重構。

  ---
  使用方式：
  將以上完整提示詞複製貼上給 Claude Code，它就會按照這次的方式執行完整的模組化流程。
