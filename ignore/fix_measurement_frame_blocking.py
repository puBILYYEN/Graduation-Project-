#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修復測量框架阻擋按鈕的問題
將 _showMeasurementFrame 預設值從 true 改為 false
"""

import re

def fix_measurement_frame():
    file_path = 'lib/pages/camera/camera_screen_full.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 修改預設值從 true 改為 false
    content = re.sub(
        r'bool _showMeasurementFrame = true; // 是否顯示測量框架',
        'bool _showMeasurementFrame = false; // 是否顯示測量框架 (預設關閉以避免阻擋按鈕)',
        content
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print("[OK] 已修復測量框架阻擋問題")
    print("    變更: _showMeasurementFrame = true → false")
    print("    原因: 測量框架的 GestureDetector 在 Stack 中位於按鈕上層")
    print("    效果: 按鈕現在應該可以正常點擊了")

if __name__ == '__main__':
    import os
    os.chdir('C:/Users/pop90/flutter_code/flutter_application_1')
    fix_measurement_frame()
