#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
添加覆蓋層狀態調試日誌
"""

def add_overlay_state_logging():
    """在 build 方法中添加覆蓋層狀態日誌"""
    file_path = 'lib/pages/camera/camera_screen_full.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 在 EdgeDetectionPainter 之前添加日誌
    old_code1 = '''          // 邊緣檢測疊加層（有檢測結果時顯示）
          if (_detectedEdges.isNotEmpty)
            Positioned('''

    new_code1 = '''          // 邊緣檢測疊加層（有檢測結果時顯示）
          if (_detectedEdges.isNotEmpty) ...[
            // Debug: 記錄邊緣檢測狀態
            Builder(builder: (context) {
              print('[OVERLAY_DEBUG] EdgeDetection 覆蓋層顯示中，邊緣點數: ${_detectedEdges.length}');
              return SizedBox.shrink();
            }),
            Positioned('''

    # 在測量框架之前添加日誌
    old_code2 = '''          // 可拖拽的紅色測量框架
          if (_showMeasurementFrame)
            Positioned('''

    new_code2 = '''          // 可拖拽的紅色測量框架
          if (_showMeasurementFrame) ...[
            // Debug: 記錄測量框架狀態
            Builder(builder: (context) {
              print('[OVERLAY_DEBUG] 測量框架顯示中');
              return SizedBox.shrink();
            }),
            Positioned('''

    if old_code1 in content:
        content = content.replace(old_code1, new_code1)
        print("[OK] 已添加 EdgeDetectionPainter 狀態日誌")
    else:
        print("[SKIP] EdgeDetectionPainter 代碼可能已修改")

    # 需要同時修復閉合括號
    # 找到 EdgeDetectionPainter 的結束位置並添加 ]
    # 這裡簡單處理：在原來的 Positioned 結束後添加 ]

    # 先處理測量框架
    if old_code2 in content:
        content = content.replace(old_code2, new_code2)
        print("[OK] 已添加測量框架狀態日誌")
    else:
        print("[SKIP] 測量框架代碼可能已修改")

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def add_build_start_logging():
    """在 build 方法開始處添加覆蓋層狀態日誌"""
    file_path = 'lib/pages/camera/camera_screen_full.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 在 build 方法開始處添加日誌
    old_code = '''  @override
  Widget build(BuildContext context) {
    // 螢幕尺寸'''

    new_code = '''  @override
  Widget build(BuildContext context) {
    // Debug: 輸出當前覆蓋層狀態
    print('[BUILD_DEBUG] _detectedEdges.isNotEmpty = ${_detectedEdges.isNotEmpty}, 邊緣點數 = ${_detectedEdges.length}');
    print('[BUILD_DEBUG] _showMeasurementFrame = $_showMeasurementFrame');

    // 螢幕尺寸'''

    if old_code in content:
        content = content.replace(old_code, new_code)
        print("[OK] 已添加 build 方法開始日誌")
    else:
        print("[SKIP] build 方法可能已修改")

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    import os
    os.chdir('C:/Users/pop90/flutter_code/flutter_application_1')

    print("=" * 60)
    print("添加覆蓋層狀態調試日誌")
    print("=" * 60)

    add_build_start_logging()
    # add_overlay_state_logging()  # 先不用這個，語法較複雜

    print("\n" + "=" * 60)
    print("[OK] 日誌添加完成")
    print("=" * 60)

if __name__ == '__main__':
    main()
