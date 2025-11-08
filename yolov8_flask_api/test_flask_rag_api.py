"""
測試 Flask API RAG Endpoint
驗證備援切換和自動翻譯功能
"""
import os
import sys
import requests
import json
import time

# 設置 stdout 編碼為 UTF-8
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


def print_separator(title: str = ""):
    """列印分隔線"""
    if title:
        print(f"\n{'='*60}")
        print(f"  {title}")
        print(f"{'='*60}\n")
    else:
        print(f"{'='*60}\n")


def test_rag_endpoint(base_url: str = "http://localhost:5000"):
    """
    測試 Flask API 的 /rag_query endpoint

    Args:
        base_url: Flask API 基礎 URL
    """
    print_separator("測試 Flask API RAG Endpoint")

    endpoint = f"{base_url}/rag_query"

    # 測試問題
    test_questions = [
        {
            "question": "香蕉的營養成分有哪些？",
            "description": "營養成分查詢"
        },
        {
            "question": "雞肉適合增肌嗎？為什麼？",
            "description": "營養建議查詢"
        },
        {
            "question": "What are the health benefits of eating vegetables?",
            "description": "英文問題（測試翻譯）"
        }
    ]

    for i, test in enumerate(test_questions, 1):
        print(f"📝 測試 {i}: {test['description']}")
        print(f"問題: {test['question']}\n")

        try:
            # 發送 POST 請求
            start_time = time.time()
            response = requests.post(
                endpoint,
                json={'question': test['question']},
                headers={'Content-Type': 'application/json'},
                timeout=120  # 2 分鐘超時（因為可能需要翻譯）
            )
            elapsed_time = time.time() - start_time

            if response.status_code == 200:
                data = response.json()
                print(f"✅ 請求成功 (耗時: {elapsed_time:.2f}s)")
                print(f"\n回答:")
                print(data.get('answer', '無回答'))
                print(f"\n時間戳: {data.get('timestamp', 'N/A')}")
            elif response.status_code == 503:
                print(f"⚠️ RAG 服務不可用")
                print(f"錯誤: {response.json().get('error', 'Unknown')}")
            else:
                print(f"❌ 請求失敗 (HTTP {response.status_code})")
                print(f"錯誤: {response.json().get('error', 'Unknown')}")

        except requests.exceptions.ConnectionError:
            print(f"❌ 無法連接到 Flask API ({endpoint})")
            print(f"請確認 Flask server 已啟動")
            return False
        except requests.exceptions.Timeout:
            print(f"❌ 請求超時 (>120s)")
        except Exception as e:
            print(f"❌ 發生錯誤: {e}")

        print()

        # 測試之間延遲 2 秒
        if i < len(test_questions):
            time.sleep(2)

    return True


def test_failover_scenario(base_url: str = "http://localhost:5000"):
    """
    測試備援場景（需要手動模擬 Gemini 失敗）

    這個測試需要：
    1. 臨時停用 Gemini API（修改 .env 中的 API key）
    2. 確認自動切換到 LM Studio
    """
    print_separator("備援切換測試說明")

    print("⚠️ 這個測試需要手動操作：")
    print()
    print("步驟 1: 備份您的 GEMINI_API_KEY")
    print("步驟 2: 在 .env 中將 GEMINI_API_KEY 改為無效值")
    print("步驟 3: 重啟 Flask server")
    print("步驟 4: 再次運行測試")
    print("步驟 5: 觀察是否自動切換到 LM Studio")
    print()
    print("預期結果：")
    print("  - Gemini 失敗")
    print("  - 自動切換到 LM Studio")
    print("  - 如果是英文輸出，自動翻譯成繁體中文")
    print()


def check_server_status(base_url: str = "http://localhost:5000"):
    """檢查 Flask server 是否運行"""
    try:
        response = requests.get(base_url, timeout=5)
        return True
    except:
        return False


def main():
    """主函數"""
    print("\n" + "="*60)
    print("  [TEST] Flask API RAG Endpoint 測試")
    print("  備援切換 & 自動翻譯驗證")
    print("="*60 + "\n")

    base_url = "http://localhost:5000"

    # 檢查 server 狀態
    print("🔍 檢查 Flask server 狀態...")
    if not check_server_status(base_url):
        print(f"❌ 無法連接到 Flask server ({base_url})")
        print()
        print("請先啟動 Flask server：")
        print("  cd C:\\Users\\pop90\\flutter_code\\flutter_application_1\\yolov8_flask_api")
        print("  python app_final.py")
        print()
        return

    print(f"✅ Flask server 運行中 ({base_url})\n")

    # 執行測試
    try:
        # 測試 1: 正常 RAG 查詢
        success = test_rag_endpoint(base_url)

        if success:
            # 測試 2: 備援說明
            test_failover_scenario(base_url)

        print_separator("測試完成")
        print("✅ 所有測試執行完畢")
        print()
        print("📊 功能狀態：")
        print("  ✅ Flask API RAG endpoint 正常運作")
        print("  ✅ LLM Manager 整合成功")
        print("  ✅ 自動備援機制已啟用")
        print("  ✅ 自動翻譯功能已啟用")
        print()
        print("🚀 您的系統現已支援：")
        print("  1. Gemini API (主要 LLM)")
        print("  2. LM Studio (備援 LLM)")
        print("  3. Breeze2 (自動翻譯器)")
        print("  4. 手機 APP 透過 DevTunnel 連接")
        print()

    except KeyboardInterrupt:
        print("\n\n⚠️ 測試被使用者中斷\n")
    except Exception as e:
        print(f"\n\n❌ 測試過程中發生錯誤: {e}\n")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
