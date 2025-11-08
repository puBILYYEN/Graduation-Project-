#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
簡化日誌訊息，避免引號問題
"""

def simplify():
    file_path = 'lib/features/home/presentation/pages/main_frame.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 簡化為不包含特殊字符的訊息
    content = content.replace(
        "await AppLogger.logEvent('[NAV_DEBUG] 準備執行 context.push(/camera)');",
        "await AppLogger.logEvent('[NAV_DEBUG] 準備導航到相機頁面');"
    )

    content = content.replace(
        "await AppLogger.logEvent('[NAV_DEBUG] context.push(/camera) 已執行');",
        "await AppLogger.logEvent('[NAV_DEBUG] 導航已執行');"
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print("[OK] 日誌訊息已簡化")

if __name__ == '__main__':
    import os
    os.chdir('C:/Users/pop90/flutter_code/flutter_application_1')
    simplify()
