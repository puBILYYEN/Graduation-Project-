#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
批量添加日誌到 Flutter 應用程式
一次性修改所有需要的文件，避免檔案鎖定問題
"""

import re
import os

def add_logs_to_main_frame():
    """修改 main_frame.dart"""
    file_path = 'lib/features/home/presentation/pages/main_frame.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 替換 onTap 方法
    old_pattern = r"// 導航項目點擊處理\s*onTap: \(index\) \{"
    new_code = """// 導航項目點擊處理
        onTap: (index) async {
          await AppLogger.logButtonClick('底部導航按鈕 index=$index');"""

    content = re.sub(old_pattern, new_code, content)

    # 添加相機導航日誌
    content = content.replace(
        "if (index == 2) { // 如果點擊的是相機按鈕（索引 2）\n            // 導航到相機頁面，而不是更新底部導航狀態\n            context.push('/camera');",
        """if (index == 2) { // 如果點擊的是相機按鈕（索引 2）
            await AppLogger.logNavigation('MainFrame', '/camera');
            // 導航到相機頁面，而不是更新底部導航狀態
            context.push('/camera');"""
    )

    # 添加頁面切換日誌
    content = content.replace(
        "setState(() {\n              AppPage newPage = _getPageFromNavigationIndex(index);\n              _currentPage = newPage;\n            });",
        """setState(() {
              AppPage newPage = _getPageFromNavigationIndex(index);
              AppLogger.logNavigation(_currentPage.toString(), newPage.toString());
              _currentPage = newPage;
            });"""
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"[OK] 已修改: {file_path}")

def add_logs_to_login_page():
    """修改 login_page.dart"""
    file_path = 'lib/features/auth/presentation/pages/login_page.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 修改 _handleLogin 方法
    old_login = r"void _handleLogin\(LoginViewModel viewModel\) async \{\s*// 驗證所有表單輸入：檢查必填欄位和格式是否正確\s*if \(!_formKey\.currentState!\.validate\(\)\) return;"
    new_login = """void _handleLogin(LoginViewModel viewModel) async {
    await AppLogger.logButtonClick('登入按鈕');
    // 驗證所有表單輸入：檢查必填欄位和格式是否正確
    if (!_formKey.currentState!.validate()) {
      await AppLogger.logEvent('登入表單驗證失敗');
      return;
    }

    await AppLogger.logEvent('開始 Email 登入: ${_emailController.text.trim()}');"""

    content = re.sub(old_login, new_login, content, flags=re.DOTALL)

    # 添加登入成功/失敗日誌
    content = content.replace(
        "if (success && mounted) {\n      // 登入成功，導航到主頁面\n      context.go('/home');\n    }",
        """if (success && mounted) {
      await AppLogger.logEvent('[OK] Email 登入成功');
      await AppLogger.logNavigation('/login', '/home');
      // 登入成功，導航到主頁面
      context.go('/home');
    } else {
      await AppLogger.logEvent('[ERROR] Email 登入失敗');
    }"""
    )

    # 修改 Google 登入
    content = content.replace(
        "/// 處理 Google 登入\n  void _handleGoogleLogin(LoginViewModel viewModel) async {",
        """/// 處理 Google 登入
  void _handleGoogleLogin(LoginViewModel viewModel) async {
    await AppLogger.logButtonClick('Google 登入按鈕');
    await AppLogger.logEvent('開始 Google 登入');"""
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"[OK] 已修改: {file_path}")

def add_logs_to_home_page():
    """修改 home_page.dart"""
    file_path = 'lib/features/home/presentation/pages/home_page.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 在 initState 添加日誌
    content = content.replace(
        "@override\n  void initState() {\n    super.initState();\n    _initializeSocket();",
        """@override
  void initState() {
    super.initState();
    AppLogger.logEvent('首頁初始化');
    _initializeSocket();"""
    )

    # 添加側邊選單按鈕日誌
    content = content.replace(
        "onPressed: () {\n              Scaffold.of(context).openDrawer(); // 打開側邊選單\n            },",
        """onPressed: () async {
              await AppLogger.logButtonClick('側邊選單按鈕');
              Scaffold.of(context).openDrawer(); // 打開側邊選單
            },"""
    )

    # 添加設置按鈕日誌
    content = content.replace(
        "onPressed: () {\n              Navigator.of(context).push(\n                MaterialPageRoute(builder: (context) => const SettingsPage()),\n              );\n            },",
        """onPressed: () async {
              await AppLogger.logButtonClick('設置按鈕');
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },"""
    )

    # 添加統計卡片點擊日誌
    content = content.replace(
        "onTap: () {\n        context.push('/statistics');\n      },",
        """onTap: () async {
        await AppLogger.logButtonClick('營養統計入口');
        context.push('/statistics');
      },"""
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"[OK] 已修改: {file_path}")

def main():
    print("=" * 60)
    print("開始批量添加日誌到 Flutter 應用程式")
    print("=" * 60)

    try:
        add_logs_to_main_frame()
        add_logs_to_login_page()
        add_logs_to_home_page()

        print("\n" + "=" * 60)
        print("[OK] 所有日誌已成功添加！")
        print("=" * 60)
        print("\n接下來的步驟：")
        print("1. 重新運行應用程式: flutter run --device-id RMX3867 --release")
        print("2. 測試按鍵功能")
        print("3. 導出日誌: adb pull /data/user/0/com.foodtracker.nutritionapp/app_flutter/app_log.log ./app_log.log")

    except Exception as e:
        print(f"\n[ERROR] 錯誤: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()
