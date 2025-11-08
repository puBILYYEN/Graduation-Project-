# -*- coding: utf-8 -*-
"""
測試 Gemini API 連接
"""
import os
import sys
from dotenv import load_dotenv
import google.generativeai as genai

# 設置 UTF-8 輸出
if sys.platform == 'win32':
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')

# 載入環境變數
load_dotenv()

def test_gemini_api():
    """測試 Gemini API"""

    # 獲取 API Key
    api_key = os.getenv('GEMINI_API_KEY')

    if not api_key:
        print("[ERROR] 找不到 GEMINI_API_KEY")
        print("請確認 .env 文件中已設置 GEMINI_API_KEY")
        return False

    print(f"[OK] API Key 已載入: {api_key[:20]}...")

    try:
        # 配置 Gemini
        genai.configure(api_key=api_key)
        print("[OK] Gemini API 配置成功")

        # 測試基本查詢
        print("\n測試基本查詢...")
        model = genai.GenerativeModel('gemini-2.0-flash-exp')

        response = model.generate_content("請用繁體中文回答：1+1等於多少？")

        print(f"[OK] API 回應成功")
        print(f"\n問題: 1+1等於多少？")
        print(f"回答: {response.text}")

        # 測試營養相關查詢
        print("\n" + "="*60)
        print("測試營養知識查詢...")

        nutrition_query = "請用繁體中文簡單說明白米的主要營養成分。"
        response2 = model.generate_content(nutrition_query)

        print(f"[OK] 營養查詢成功")
        print(f"\n問題: {nutrition_query}")
        print(f"回答: {response2.text}")

        print("\n" + "="*60)
        print("[SUCCESS] 所有測試通過！Gemini API 運作正常！")
        return True

    except Exception as e:
        print(f"\n[ERROR] {e}")
        print("\n可能的原因:")
        print("1. API Key 無效或已過期")
        print("2. 網路連接問題")
        print("3. API 配額已用完")
        print("4. API Key 權限不足")
        return False

if __name__ == "__main__":
    print("="*60)
    print("Gemini API 測試腳本")
    print("="*60)
    print()

    success = test_gemini_api()

    if success:
        print("\n[SUCCESS] 系統已準備好使用 Gemini API！")
    else:
        print("\n[ERROR] 請修復上述問題後再試。")
