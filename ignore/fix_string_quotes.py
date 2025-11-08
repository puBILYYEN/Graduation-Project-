#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修復字串中的引號問題
"""

def fix_quotes():
    file_path = 'lib/features/home/presentation/pages/main_frame.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 修復兩處引號問題
    content = content.replace(
        "await AppLogger.logEvent('[NAV_DEBUG] 準備執行 context.push('/camera')');",
        "await AppLogger.logEvent('[NAV_DEBUG] 準備執行 context.push(/camera)');"
    )

    content = content.replace(
        "await AppLogger.logEvent('[NAV_DEBUG] context.push('/camera') 已執行');",
        "await AppLogger.logEvent('[NAV_DEBUG] context.push(/camera) 已執行');"
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print("[OK] 引號問題已修復")

if __name__ == '__main__':
    import os
    os.chdir('C:/Users/pop90/flutter_code/flutter_application_1')
    fix_quotes()
