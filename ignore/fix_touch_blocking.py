#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修復相機頁面觸控阻擋問題
"""

def fix_edge_detection_overlay():
    """將 EdgeDetectionPainter 包裝在 IgnorePointer 中，使觸控事件能穿透"""
    file_path = 'lib/pages/camera/camera_screen_full.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 修復 EdgeDetectionPainter 阻擋觸控的問題
    old_code = '''          // 邊緣檢測疊加層（有檢測結果時顯示）
          if (_detectedEdges.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).size.height *
                  0.25, // 使用螢幕高度的25%作為底部安全區域
              child: CustomPaint(
                painter: EdgeDetectionPainter(_detectedEdges),
              ),
            ),'''

    new_code = '''          // 邊緣檢測疊加層（有檢測結果時顯示）
          if (_detectedEdges.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).size.height *
                  0.25, // 使用螢幕高度的25%作為底部安全區域
              child: IgnorePointer(
                child: CustomPaint(
                  painter: EdgeDetectionPainter(_detectedEdges),
                ),
              ),
            ),'''

    if old_code in content:
        content = content.replace(old_code, new_code)
        print("[OK] 已將 EdgeDetectionPainter 包裝在 IgnorePointer 中")
    else:
        print("[SKIP] EdgeDetectionPainter 可能已經被修改過")

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def disable_measurement_frame_auto_enable():
    """註解掉拍照後自動重新啟用測量框架的代碼"""
    file_path = 'lib/pages/camera/camera_screen_full.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 註解掉自動重新啟用測量框架的代碼
    old_code = '''      // 計算完成後（無論成功或失敗）延遲重新顯示測量框
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showMeasurementFrame = true;
          });
        }
      });'''

    new_code = '''      // 計算完成後（無論成功或失敗）延遲重新顯示測量框
      // 註解：自動重新啟用會阻擋按鈕，已停用
      /*
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showMeasurementFrame = true;
          });
        }
      });
      */'''

    if old_code in content:
        content = content.replace(old_code, new_code)
        print("[OK] 已停用拍照後自動重新啟用測量框架")
    else:
        print("[SKIP] 測量框架自動啟用代碼可能已經被修改過")

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    import os
    os.chdir('C:/Users/pop90/flutter_code/flutter_application_1')

    print("=" * 60)
    print("修復相機頁面觸控阻擋問題")
    print("=" * 60)

    fix_edge_detection_overlay()
    disable_measurement_frame_auto_enable()

    print("\n" + "=" * 60)
    print("[OK] 修復完成")
    print("=" * 60)
    print("\n修復內容:")
    print("1. EdgeDetectionPainter 覆蓋層已用 IgnorePointer 包裝，觸控事件能穿透")
    print("2. 已停用拍照後自動重新啟用測量框架，避免阻擋按鈕")
    print("\n請執行:")
    print("  flutter clean")
    print("  flutter run --device-id RMX3867 --release")

if __name__ == '__main__':
    main()
