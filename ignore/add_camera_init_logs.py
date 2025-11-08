#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
添加相機初始化過程的詳細日誌
"""

def add_camera_init_logs():
    """在相機初始化的關鍵步驟添加日誌"""
    file_path = 'lib/pages/camera/camera_screen_full.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 修改 1: 在相機控制器創建後添加日誌
    old_code1 = '''      // 步驟2：創建相機控制器
      _controller = CameraController(
        cameras![0], // 使用第一個相機（通常是後置鏡頭）
        ResolutionPreset.high, // 設定高畫質
        enableAudio: false, // 不啟用音訊錄製
      );

      // 步驟3：初始化相機控制器
      await _controller!.initialize();'''

    new_code1 = '''      // 步驟2：創建相機控制器
      _controller = CameraController(
        cameras![0], // 使用第一個相機（通常是後置鏡頭）
        ResolutionPreset.high, // 設定高畫質
        enableAudio: false, // 不啟用音訊錄製
      );
      await AppLogger.logEvent('[CAMERA] 相機控制器已創建，準備初始化...');

      // 步驟3：初始化相機控制器
      await _controller!.initialize();
      await AppLogger.logEvent('[CAMERA] 相機控制器初始化完成');'''

    # 修改 2: 在成功更新狀態後添加日誌
    old_code2 = '''      // 步驟4：更新UI狀態（僅在組件仍然掛載時）
      if (mounted) {
        setState(() {
          _isInitialized = true; // 標記為已初始化
          _hasError = false; // 清除錯誤狀態
        });
      }'''

    new_code2 = '''      // 步驟4：更新UI狀態（僅在組件仍然掛載時）
      if (mounted) {
        setState(() {
          _isInitialized = true; // 標記為已初始化
          _hasError = false; // 清除錯誤狀態
        });
        await AppLogger.logEvent('[CAMERA] ✅ 相機初始化成功，UI 已更新');
      }'''

    # 修改 3: 在錯誤處理中添加更詳細的日誌
    old_code3 = '''    } catch (e) {
      log('相機設備初始化錯誤: $e'); // 記錄詳細錯誤信息
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '相機設備初始化失敗：${e.toString()}';
        });
      }
    }'''

    new_code3 = '''    } catch (e) {
      log('相機設備初始化錯誤: $e'); // 記錄詳細錯誤信息
      await AppLogger.logError('[CAMERA] ❌ 相機設備初始化錯誤: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '相機設備初始化失敗：${e.toString()}';
        });
      }
    }'''

    # 執行替換
    if old_code1 in content:
        content = content.replace(old_code1, new_code1)
        print("[OK] 已添加相機控制器創建和初始化日誌")
    else:
        print("[SKIP] 相機控制器創建代碼可能已修改")

    if old_code2 in content:
        content = content.replace(old_code2, new_code2)
        print("[OK] 已添加相機初始化成功日誌")
    else:
        print("[SKIP] UI 更新代碼可能已修改")

    if old_code3 in content:
        content = content.replace(old_code3, new_code3)
        print("[OK] 已添加相機初始化錯誤日誌")
    else:
        print("[SKIP] 錯誤處理代碼可能已修改")

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    import os
    os.chdir('C:/Users/pop90/flutter_code/flutter_application_1')

    print("=" * 60)
    print("添加相機初始化過程的詳細日誌")
    print("=" * 60)

    add_camera_init_logs()

    print("\n" + "=" * 60)
    print("[OK] 日誌添加完成")
    print("=" * 60)
    print("\n現在可以看到:")
    print("1. 相機控制器創建日誌")
    print("2. 相機控制器初始化完成日誌")
    print("3. 相機初始化成功日誌")
    print("4. 相機初始化錯誤日誌")
    print("\n請執行:")
    print("  flutter run --device-id RMX3867 --release")

if __name__ == '__main__':
    main()
