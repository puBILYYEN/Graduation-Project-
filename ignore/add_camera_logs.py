#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""添加相機頁面按鈕日誌"""

import re

def add_camera_button_logs():
    file_path = 'lib/pages/camera/camera_screen_full.dart'

    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # 在特定行號後添加日誌
    modifications = [
        (866, "  Future<void> _takeSmartVolumePhoto() async {\n",
         "  Future<void> _takeSmartVolumePhoto() async {\n    await AppLogger.logCameraAction('[OK][OK][OK] 智慧拍照按鈕點擊');\n    print('[CAMERA] 智慧拍照按鈕被點擊');\n"),

        (1741, "  Future<void> _openGallery() async {\n",
         "  Future<void> _openGallery() async {\n    await AppLogger.logCameraAction('[OK][OK][OK] 開啟相簿按鈕點擊');\n    print('[CAMERA] 相簿按鈕被點擊');\n"),

        (1813, "  void _switchCamera() async {\n",
         "  void _switchCamera() async {\n    await AppLogger.logCameraAction('[OK][OK][OK] 切換鏡頭按鈕點擊');\n    print('[CAMERA] 切換鏡頭按鈕被點擊');\n"),
    ]

    # 從後往前修改，避免行號偏移
    for line_num, old_line, new_lines in reversed(modifications):
        if line_num - 1 < len(lines) and old_line.strip() == lines[line_num - 1].strip():
            lines[line_num - 1] = new_lines
            print(f"[OK] 已在第 {line_num} 行添加日誌")
        else:
            print(f"[WARNING] 第 {line_num} 行不匹配，跳過")

    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)

    print("\n[OK] 相機按鈕日誌已添加")

if __name__ == '__main__':
    add_camera_button_logs()
