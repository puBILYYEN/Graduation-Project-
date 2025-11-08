#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
在 _initializeCamera 方法開頭添加日誌
"""

def add_init_start_log():
    file_path = 'lib/pages/camera/camera_screen_full.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 在 _initializeCamera 方法的 try 塊開頭添加日誌
    old_code = '''  Future<void> _initializeCamera() async {
    try {
      // 步驟1：只請求相機權限
      final hasPermissions = await _requestCameraPermission();'''

    new_code = '''  Future<void> _initializeCamera() async {
    await AppLogger.logEvent('[CAMERA] _initializeCamera 方法開始執行');
    try {
      await AppLogger.logEvent('[CAMERA] 準備請求相機權限...');
      // 步驟1：只請求相機權限
      final hasPermissions = await _requestCameraPermission();
      await AppLogger.logEvent('[CAMERA] 權限請求結果: $hasPermissions');'''

    # 在權限失敗返回時添加日誌
    old_code2 = '''      if (!hasPermissions) {
        return; // 相機權限未獲得，終止初始化
      }'''

    new_code2 = '''      if (!hasPermissions) {
        await AppLogger.logEvent('[CAMERA] ❌ 權限未獲得，終止初始化');
        return; // 相機權限未獲得，終止初始化
      }
      await AppLogger.logEvent('[CAMERA] ✅ 權限已獲得，繼續初始化設備');'''

    # 在 catch 塊添加 AppLogger
    old_code3 = '''    } catch (e) {
      log('相機初始化錯誤: $e'); // 記錄錯誤到日誌
      if (mounted) {'''

    new_code3 = '''    } catch (e) {
      log('相機初始化錯誤: $e'); // 記錄錯誤到日誌
      await AppLogger.logEvent('[CAMERA] ❌ _initializeCamera 異常: $e');
      if (mounted) {'''

    if old_code in content:
        content = content.replace(old_code, new_code)
        print("[OK] 已添加 _initializeCamera 開始日誌")
    else:
        print("[SKIP] _initializeCamera 方法可能已修改")

    if old_code2 in content:
        content = content.replace(old_code2, new_code2)
        print("[OK] 已添加權限檢查日誌")
    else:
        print("[SKIP] 權限檢查代碼可能已修改")

    if old_code3 in content:
        content = content.replace(old_code3, new_code3)
        print("[OK] 已添加異常日誌")
    else:
        print("[SKIP] catch 塊可能已修改")

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    import os
    os.chdir('C:/Users/pop90/flutter_code/flutter_application_1')

    print("=" * 60)
    print("添加 _initializeCamera 調試日誌")
    print("=" * 60)

    add_init_start_log()

    print("\n" + "=" * 60)
    print("[OK] 日誌添加完成")
    print("=" * 60)

if __name__ == '__main__':
    main()
