#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
批量添加完整日誌系統到所有剩餘頁面
確保對整個應用程式的運行狀態有完全掌握
"""

import re
import os

def add_logs_to_food_diary():
    """添加日誌到飲食記錄頁面"""
    file_path = 'lib/features/food_diary/presentation/pages/food_diary_page.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 添加 import
    if "import '../../../../core/services/app_logger.dart';" not in content:
        content = content.replace(
            "import '../viewmodels/food_diary_viewmodel.dart';",
            "import '../viewmodels/food_diary_viewmodel.dart';\nimport '../../../../core/services/app_logger.dart';"
        )

    # 添加頁面初始化日誌 (在 create 方法中)
    content = content.replace(
        "viewModel.fetchFoodEntries(); // Call fetchFoodEntries on the viewModel instance\n        return viewModel;",
        "AppLogger.logEvent('飲食記錄頁面初始化');\n        viewModel.fetchFoodEntries(); // Call fetchFoodEntries on the viewModel instance\n        return viewModel;"
    )

    # 添加測試資料按鈕日誌
    content = content.replace(
        "onPressed: () async {\n                  try {\n                    await viewModel.addTestData();",
        "onPressed: () async {\n                  await AppLogger.logButtonClick('添加測試資料按鈕');\n                  try {\n                    await viewModel.addTestData();\n                    await AppLogger.logEvent('[OK] 測試資料添加成功');"
    )

    # 添加測試資料失敗日誌
    content = content.replace(
        "} catch (e) {\n                    if (context.mounted) {",
        "} catch (e) {\n                    await AppLogger.logEvent('[ERROR] 測試資料添加失敗: $e');\n                    if (context.mounted) {"
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"[OK] 已修改: {file_path}")

def add_logs_to_exercise():
    """添加日誌到運動頁面 - 替換現有的 _logAction"""
    file_path = 'lib/features/exercise/presentation/pages/exercise_page.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 添加 import
    if "import '../../../../core/services/app_logger.dart';" not in content:
        content = content.replace(
            "import '../viewmodels/exercise_viewmodel.dart';",
            "import '../viewmodels/exercise_viewmodel.dart';\nimport '../../../../core/services/app_logger.dart';"
        )

    # 替換 initState 中的日誌
    content = content.replace(
        "_logAction('進入運動頁面');",
        "AppLogger.logEvent('運動頁面初始化');"
    )

    # 替換 dispose 中的日誌
    content = content.replace(
        "_logAction('離開運動頁面');",
        "AppLogger.logEvent('離開運動頁面');"
    )

    # 替換 Socket 連接日誌
    content = content.replace(
        "_logAction('Socket.IO 已連接');",
        "AppLogger.logEvent('運動頁面 Socket.IO 已連接');"
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"[OK] 已修改: {file_path}")

def add_logs_to_statistics():
    """添加日誌到統計頁面"""
    file_path = 'lib/features/statistics/presentation/pages/statistics_page.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 添加 import
    if "import '../../../../core/services/app_logger.dart';" not in content:
        content = content.replace(
            "import '../viewmodels/statistics_viewmodel.dart';",
            "import '../viewmodels/statistics_viewmodel.dart';\nimport '../../../../core/services/app_logger.dart';"
        )

    # 添加頁面初始化日誌
    content = content.replace(
        "// 載入今日統計數據\n    WidgetsBinding.instance.addPostFrameCallback((_) {",
        "// 載入今日統計數據\n    AppLogger.logEvent('營養統計頁面初始化');\n    WidgetsBinding.instance.addPostFrameCallback((_) {"
    )

    # 添加刷新按鈕日誌
    content = content.replace(
        "icon: const Icon(Icons.refresh),\n            onPressed: () {",
        "icon: const Icon(Icons.refresh),\n            onPressed: () async {\n              await AppLogger.logButtonClick('統計頁面刷新按鈕');"
    )

    # 添加重試按鈕日誌
    content = content.replace(
        "ElevatedButton(\n                    onPressed: () => viewModel.refresh(),",
        "ElevatedButton(\n                    onPressed: () async {\n                      await AppLogger.logButtonClick('統計頁面重試按鈕');\n                      await viewModel.refresh();\n                    },"
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"[OK] 已修改: {file_path}")

def add_logs_to_settings():
    """添加日誌到設定頁面"""
    file_path = 'lib/features/settings/presentation/pages/settings_page.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 添加 import
    if "import '../../../../core/services/app_logger.dart';" not in content:
        content = content.replace(
            "import '../../../auth/presentation/pages/login_page.dart';",
            "import '../../../auth/presentation/pages/login_page.dart';\nimport '../../../../core/services/app_logger.dart';"
        )

    # 添加頁面初始化日誌
    content = content.replace(
        "void initState() {\n    super.initState();\n    _loadUserData();",
        "void initState() {\n    super.initState();\n    AppLogger.logEvent('設定頁面初始化');\n    _loadUserData();"
    )

    # 添加載入資料日誌
    content = content.replace(
        "/// 載入使用者資料\n  Future<void> _loadUserData() async {\n    try {",
        "/// 載入使用者資料\n  Future<void> _loadUserData() async {\n    await AppLogger.logEvent('開始載入使用者資料');\n    try {"
    )

    # 添加載入成功日誌
    content = content.replace(
        "setState(() {\n        _isLoading = false;\n      });",
        "await AppLogger.logEvent('[OK] 使用者資料載入成功');\n      setState(() {\n        _isLoading = false;\n      });"
    )

    # 添加載入錯誤日誌
    content = content.replace(
        "print('載入資料錯誤: $e');",
        "await AppLogger.logEvent('[ERROR] 載入資料錯誤: $e');\n      print('載入資料錯誤: $e');"
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"[OK] 已修改: {file_path}")

def add_logs_to_body_analysis():
    """添加日誌到身體分析頁面"""
    file_path = 'lib/features/analysis/presentation/pages/body_analysis_page.dart'

    # 先檢查文件是否存在
    if not os.path.exists(file_path):
        print(f"[WARNING] 文件不存在: {file_path}")
        return

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 添加 import (找到第一個 import 後添加)
    if "import '../../../../core/services/app_logger.dart';" not in content:
        # 在第一個 import 語句後添加
        import_match = re.search(r"(import '[^']+';)", content)
        if import_match:
            first_import = import_match.group(1)
            content = content.replace(
                first_import,
                first_import + "\nimport '../../../../core/services/app_logger.dart';"
            )

    # 尋找 initState 方法並添加日誌
    content = re.sub(
        r"(@override\s+void initState\(\) \{\s+super\.initState\(\);)",
        r"\1\n    AppLogger.logEvent('身體分析頁面初始化');",
        content
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"[OK] 已修改: {file_path}")

def main():
    print("=" * 60)
    print("開始批量添加完整日誌系統")
    print("=" * 60)

    try:
        # 切換到項目根目錄
        os.chdir('C:/Users/pop90/flutter_code/flutter_application_1')

        add_logs_to_food_diary()
        add_logs_to_exercise()
        add_logs_to_statistics()
        add_logs_to_settings()
        add_logs_to_body_analysis()

        print("\n" + "=" * 60)
        print("[OK] 所有頁面日誌添加完成！")
        print("=" * 60)
        print("\n接下來的步驟：")
        print("1. 重新運行應用程式")
        print("2. 測試所有頁面的按鈕功能")
        print("3. 確認日誌完整性")

    except Exception as e:
        print(f"\n[ERROR] 錯誤: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()
