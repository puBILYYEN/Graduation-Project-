#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修復 AppLogger.logError 為 AppLogger.logEvent
"""

def fix_log_error():
    file_path = 'lib/pages/camera/camera_screen_full.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 替換 logError 為 logEvent
    content = content.replace('AppLogger.logError', 'AppLogger.logEvent')

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print("[OK] 已修復 AppLogger.logError → AppLogger.logEvent")

def main():
    import os
    os.chdir('C:/Users/pop90/flutter_code/flutter_application_1')

    fix_log_error()

if __name__ == '__main__':
    main()
