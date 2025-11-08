#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修復 CameraPreview 阻擋所有觸控的問題
"""

def fix_camera_preview():
    """用 IgnorePointer 包裝 CameraPreview"""
    file_path = 'lib/pages/camera/camera_screen_full.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    old_code = '''          // 相機預覽或錯誤顯示
          if (_isInitialized)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),'''

    new_code = '''          // 相機預覽或錯誤顯示
          if (_isInitialized)
            Positioned.fill(
              child: IgnorePointer(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),'''

    if old_code in content:
        content = content.replace(old_code, new_code)
        print("[OK] 已用 IgnorePointer 包裝 CameraPreview")
    else:
        print("[SKIP] CameraPreview 代碼可能已被修改")

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    import os
    os.chdir('C:/Users/pop90/flutter_code/flutter_application_1')

    print("=" * 60)
    print("修復 CameraPreview 觸控阻擋問題")
    print("=" * 60)

    fix_camera_preview()

    print("\n" + "=" * 60)
    print("[OK] 修復完成")
    print("=" * 60)
    print("\n說明:")
    print("CameraPreview 是原生 Android 視圖，會攔截所有觸控事件")
    print("用 IgnorePointer 包裝後，觸控會穿透到下方按鈕")
    print("\n請執行:")
    print("  flutter run --device-id RMX3867 --release")

if __name__ == '__main__':
    main()
