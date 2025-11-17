# -*- coding: utf-8 -*-
"""
快速啟動腳本
"""
import os
import sys

# 設置 UTF-8 輸出
if sys.platform == 'win32':
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')

print("="*60)
print("營養知識 RAG 系統 - 啟動檢查")
print("="*60)
print()

# 檢查必要文件
checks = []

# 1. 檢查 YOLO 模型
if os.path.exists('a11171200.pt'):
    print("[OK] YOLO 模型文件存在")
    checks.append(True)
else:
    print("[ERROR] YOLO 模型文件不存在: a11171200.pt")
    checks.append(False)

# 2. 檢查類別文件
if os.path.exists('classes.txt'):
    print("[OK] 類別文件存在")
    checks.append(True)
else:
    print("[ERROR] 類別文件不存在: classes.txt")
    checks.append(False)

# 3. 檢查 .env 文件
if os.path.exists('.env'):
    print("[OK] .env 配置文件存在")
    checks.append(True)
else:
    print("[WARNING] .env 配置文件不存在，使用預設設定")
    checks.append(True)  # 不是必須的

# 4. 檢查 Firebase 憑證（選用）
if os.path.exists('firebase-credentials.json'):
    print("[OK] Firebase 憑證文件存在")
    firebase_available = True
else:
    print("[WARNING] Firebase 憑證文件不存在，Firebase 功能將被禁用")
    firebase_available = False

# 5. 檢查營養資料
nutrition_data1 = r"D:\靜宜大學資料夾\畢業專題\UTF-8\食品營養成分資料庫2024UPDATE2.csv"
nutrition_data2 = r"C:\Users\pop90\OneDrive\桌面\食物資料庫\食品營養成分資料庫2024_UPDATE1.csv"

nutrition_count = 0
if os.path.exists(nutrition_data1):
    print("[OK] 營養資料1存在")
    nutrition_count += 1
else:
    print("[WARNING] 營養資料1不存在")

if os.path.exists(nutrition_data2):
    print("[OK] 營養資料2存在")
    nutrition_count += 1
else:
    print("[WARNING] 營養資料2不存在")

if nutrition_count > 0:
    print(f"[OK] 找到 {nutrition_count} 個營養資料來源")
    checks.append(True)
else:
    print("[WARNING] 未找到任何營養資料來源")
    checks.append(True)  # 不是致命錯誤

print()
print("="*60)

# 檢查結果
if all(checks):
    print("[SUCCESS] 所有必要文件檢查通過！")
    print()
    print("正在啟動 Flask 應用...")
    print("="*60)
    print()

    # 啟動應用
    os.system('python app_final.py')
else:
    print("[ERROR] 部分必要文件不存在，請先修復後再啟動。")
    sys.exit(1)
