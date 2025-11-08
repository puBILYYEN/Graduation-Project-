#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
在導航相關位置添加調試日誌
追蹤「第二次點擊相機按鈕無響應」的問題
"""

import re

def add_camera_page_logs():
    """在相機頁面的 initState 和 dispose 添加日誌"""
    file_path = 'lib/pages/camera/camera_screen_full.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 檢查是否已經有 import
    if "import '../../../core/services/app_logger.dart';" not in content:
        # 在第一個 import 後添加
        content = re.sub(
            r"(import 'package:flutter/material\.dart';)",
            r"\1\nimport '../../../core/services/app_logger.dart';",
            content
        )

    # 在 initState 開頭添加日誌
    if "AppLogger.logEvent('[CAMERA] 相機頁面 initState 開始');" not in content:
        content = re.sub(
            r"(@override\s+void initState\(\) \{\s+super\.initState\(\);)",
            r"\1\n    AppLogger.logEvent('[CAMERA] 相機頁面 initState 開始');",
            content
        )

    # 在 dispose 開頭添加日誌
    if "AppLogger.logEvent('[CAMERA] 相機頁面 dispose 開始');" not in content:
        content = re.sub(
            r"(@override\s+void dispose\(\) \{)",
            r"\1\n    AppLogger.logEvent('[CAMERA] 相機頁面 dispose 開始');",
            content
        )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"[OK] 已添加相機頁面生命週期日誌")

def add_mainframe_detailed_logs():
    """在 MainFrame 的 onTap 添加更詳細的日誌"""
    file_path = 'lib/features/home/presentation/pages/main_frame.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 替換 onTap 處理，添加更詳細的日誌
    old_ontap = '''        onTap: (index) async {
          await AppLogger.logButtonClick('底部導航按鈕 index=$index');
          if (index == 2) { // 如果點擊的是相機按鈕（索引 2）
            await AppLogger.logNavigation('MainFrame', '/camera');
            // 導航到相機頁面，而不是更新底部導航狀態
            context.push('/camera');
          } else {
            // 更新當前頁面狀態，觸發頁面重建
            setState(() {
              AppPage newPage = _getPageFromNavigationIndex(index);
              AppLogger.logNavigation(_currentPage.toString(), newPage.toString());
              _currentPage = newPage;
            });
          }
        },'''

    new_ontap = '''        onTap: (index) async {
          await AppLogger.logButtonClick('底部導航按鈕 index=$index');
          await AppLogger.logEvent('[NAV_DEBUG] 當前頁面: $_currentPage');
          await AppLogger.logEvent('[NAV_DEBUG] 點擊索引: $index');

          if (index == 2) { // 如果點擊的是相機按鈕（索引 2）
            await AppLogger.logNavigation('MainFrame', '/camera');
            await AppLogger.logEvent('[NAV_DEBUG] 準備執行 context.push(\'/camera\')');
            // 導航到相機頁面，而不是更新底部導航狀態
            context.push('/camera');
            await AppLogger.logEvent('[NAV_DEBUG] context.push(\'/camera\') 已執行');
          } else {
            // 更新當前頁面狀態，觸發頁面重建
            setState(() {
              AppPage newPage = _getPageFromNavigationIndex(index);
              AppLogger.logNavigation(_currentPage.toString(), newPage.toString());
              _currentPage = newPage;
            });
          }
        },'''

    content = content.replace(old_ontap, new_ontap)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"[OK] 已添加 MainFrame 詳細導航日誌")

def main():
    import os
    os.chdir('C:/Users/pop90/flutter_code/flutter_application_1')

    print("=" * 60)
    print("添加導航調試日誌")
    print("=" * 60)

    add_camera_page_logs()
    add_mainframe_detailed_logs()

    print("\n" + "=" * 60)
    print("[OK] 日誌添加完成")
    print("=" * 60)
    print("\n請重新運行應用，然後:")
    print("1. 點擊底部導航欄的相機按鈕（第一次）")
    print("2. 點擊返回或其他導航按鈕離開相機")
    print("3. 再次點擊底部導航欄的相機按鈕（第二次）")
    print("4. 查看日誌輸出，找出第二次點擊失敗的原因")

if __name__ == '__main__':
    main()
