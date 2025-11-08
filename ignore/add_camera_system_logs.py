#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
添加完整日誌到相機系統
包括 smart_camera_page 和 camera_view_model
"""

import re
import os

def add_logs_to_smart_camera_page():
    """添加日誌到智慧相機頁面"""
    file_path = 'lib/features/camera/presentation/pages/smart_camera_page.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 添加 import
    if "import '../../../../core/services/app_logger.dart';" not in content:
        content = content.replace(
            "import '../viewmodels/camera_view_model.dart';",
            "import '../viewmodels/camera_view_model.dart';\nimport '../../../../core/services/app_logger.dart';"
        )

    # 添加頁面初始化日誌
    content = content.replace(
        "// 延遲到下一幀執行，避免在 build 期間觸發 setState\n      WidgetsBinding.instance.addPostFrameCallback((_) {",
        "// 延遲到下一幀執行，避免在 build 期間觸發 setState\n      AppLogger.logEvent('智慧相機頁面初始化');\n      WidgetsBinding.instance.addPostFrameCallback((_) {"
    )

    # 添加相機初始化日誌
    content = content.replace(
        "// 初始化相機（如果還沒初始化）\n          if (!viewModel.isInitialized) {\n            debugPrint('🎬 開始初始化 CameraViewModel');\n            viewModel.initialize();",
        "// 初始化相機（如果還沒初始化）\n          if (!viewModel.isInitialized) {\n            debugPrint('🎬 開始初始化 CameraViewModel');\n            await AppLogger.logCameraAction('開始初始化 CameraViewModel');\n            viewModel.initialize();"
    )

    # 添加初始化失敗日誌
    content = content.replace(
        "} catch (e) {\n          debugPrint('❌ 獲取或初始化 CameraViewModel 失敗: $e');",
        "} catch (e) {\n          debugPrint('❌ 獲取或初始化 CameraViewModel 失敗: $e');\n          await AppLogger.logEvent('[ERROR] 相機初始化失敗: $e');"
    )

    # 將 addPostFrameCallback 改為 async
    content = content.replace(
        "WidgetsBinding.instance.addPostFrameCallback((_) {",
        "WidgetsBinding.instance.addPostFrameCallback((_) async {"
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"[OK] 已修改: {file_path}")

def add_logs_to_camera_viewmodel():
    """添加日誌到相機 ViewModel"""
    file_path = 'lib/features/camera/presentation/viewmodels/camera_view_model.dart'

    if not os.path.exists(file_path):
        print(f"[WARNING] 文件不存在: {file_path}")
        return

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 添加 import
    if "import '../../../../core/services/app_logger.dart';" not in content:
        # 在第一個 import 後添加
        import_match = re.search(r"(import 'package:flutter/[^']+';)", content)
        if import_match:
            first_import = import_match.group(1)
            content = content.replace(
                first_import,
                first_import + "\nimport '../../../../core/services/app_logger.dart';"
            )

    # 添加拍照日誌
    content = re.sub(
        r"(Future<void> takePicture\(\) async \{\s*)",
        r"\1await AppLogger.logCameraAction('開始拍照');\n    ",
        content
    )

    # 添加切換相機日誌
    content = re.sub(
        r"(Future<void> switchCamera\(\) async \{\s*)",
        r"\1await AppLogger.logCameraAction('切換相機');\n    ",
        content
    )

    # 添加閃光燈切換日誌
    content = re.sub(
        r"(Future<void> toggleFlash\(\) async \{\s*)",
        r"\1await AppLogger.logCameraAction('切換閃光燈');\n    ",
        content
    )

    # 添加從相簿選擇日誌
    content = re.sub(
        r"(Future<void> pickImagesFromGallery\(\) async \{\s*)",
        r"\1await AppLogger.logCameraAction('開啟相簿');\n    ",
        content
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"[OK] 已修改: {file_path}")

def add_logs_to_camera_datasource():
    """添加日誌到相機數據源"""
    file_path = 'lib/features/camera/data/datasources/camera_datasource.dart'

    if not os.path.exists(file_path):
        print(f"[WARNING] 文件不存在: {file_path}")
        return

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 添加 import
    if "import '../../../../core/services/app_logger.dart';" not in content:
        import_match = re.search(r"(import 'package:camera/camera\.dart';)", content)
        if import_match:
            first_import = import_match.group(1)
            content = content.replace(
                first_import,
                first_import + "\nimport '../../../../core/services/app_logger.dart';"
            )

    # 添加權限請求日誌
    if "AppLogger.logCameraAction('請求相機權限')" not in content:
        content = re.sub(
            r"(Future<bool> requestCameraPermission\(\) async \{\s*)",
            r"\1await AppLogger.logCameraAction('請求相機權限');\n    ",
            content
        )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"[OK] 已修改: {file_path}")

def main():
    print("=" * 60)
    print("開始添加相機系統完整日誌")
    print("=" * 60)

    try:
        os.chdir('C:/Users/pop90/flutter_code/flutter_application_1')

        add_logs_to_smart_camera_page()
        add_logs_to_camera_viewmodel()
        add_logs_to_camera_datasource()

        print("\n" + "=" * 60)
        print("[OK] 相機系統日誌添加完成！")
        print("=" * 60)

    except Exception as e:
        print(f"\n[ERROR] 錯誤: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()
