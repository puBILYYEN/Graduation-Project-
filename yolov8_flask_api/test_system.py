# -*- coding: utf-8 -*-
"""
系統測試腳本 - 測試所有組件是否正常
"""
import os
import sys

# 設置 UTF-8 輸出
if sys.platform == 'win32':
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')

print("="*60)
print("系統組件測試")
print("="*60)
print()

# 測試 1: 環境變數
print("[TEST 1] 測試環境變數...")
try:
    from dotenv import load_dotenv
    load_dotenv()

    gemini_key = os.getenv('GEMINI_API_KEY')
    if gemini_key:
        print(f"  [OK] GEMINI_API_KEY: {gemini_key[:20]}...")
    else:
        print("  [ERROR] GEMINI_API_KEY 未設置")

    print()
except Exception as e:
    print(f"  [ERROR] {e}")
    print()

# 測試 2: YOLO 模型
print("[TEST 2] 測試 YOLO 模型...")
try:
    from ultralytics import YOLO
    model = YOLO('a11171200.pt')
    print("  [OK] YOLO 模型載入成功")
    print()
except Exception as e:
    print(f"  [ERROR] {e}")
    print()

# 測試 3: Gemini API
print("[TEST 3] 測試 Gemini API...")
try:
    import google.generativeai as genai
    genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
    model = genai.GenerativeModel('gemini-2.0-flash-exp')
    response = model.generate_content("測試")
    print("  [OK] Gemini API 連接成功")
    print()
except Exception as e:
    print(f"  [ERROR] {e}")
    print()

# 測試 4: 營養資料載入
print("[TEST 4] 測試營養資料載入...")
try:
    sys.path.insert(0, os.path.dirname(__file__))
    from services.nutrition_data_manager import nutrition_manager

    success = nutrition_manager.load_nutrition_database()
    if success:
        print(f"  [OK] 營養資料載入成功，共 {len(nutrition_manager.nutrition_data)} 筆")
    else:
        print("  [WARNING] 營養資料載入失敗")
    print()
except Exception as e:
    print(f"  [ERROR] {e}")
    print()

# 測試 5: Chroma 向量資料庫
print("[TEST 5] 測試 Chroma 嵌入模型...")
try:
    from services.rag_service_chroma import rag_service_chroma

    if rag_service_chroma.is_available():
        print("  [OK] RAG 服務可用")
    else:
        print("  [WARNING] RAG 服務不可用")
    print()
except Exception as e:
    print(f"  [ERROR] {e}")
    print()

# 測試 6: Firebase（選用）
print("[TEST 6] 測試 Firebase...")
try:
    from services.firebase_service import firebase_service

    if firebase_service.is_available():
        print("  [OK] Firebase 服務可用")
    else:
        print("  [WARNING] Firebase 服務不可用（這是正常的如果沒有憑證）")
    print()
except Exception as e:
    print(f"  [ERROR] {e}")
    print()

print("="*60)
print("測試完成！")
print("="*60)
