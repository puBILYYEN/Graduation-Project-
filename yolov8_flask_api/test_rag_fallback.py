"""
測試 RAG 三層備援機制
"""
import socketio
import time
import sys
import io

# 設置 UTF-8 輸出
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# 創建 Socket.IO 客戶端
sio = socketio.Client()

# 儲存回應
responses = []

@sio.on('connect')
def on_connect():
    print('✅ 已連接到 Flask Socket.IO 伺服器')
    print('=' * 60)

@sio.on('disconnect')
def on_disconnect():
    print('❌ 已斷開連接')

@sio.on('rag_response')
def on_rag_response(data):
    print('\n📥 收到 RAG 回應:')
    print(f"問題: {data.get('question', '')}")
    print(f"回答: {data.get('answer', '')}")
    print('=' * 60)
    responses.append(data)

@sio.on('rag_error')
def on_rag_error(data):
    print('\n❌ RAG 錯誤:')
    print(f"錯誤訊息: {data.get('message', '')}")
    print('=' * 60)
    responses.append({'error': True, 'message': data.get('message', '')})

def test_question(question, description):
    """測試一個問題"""
    print(f'\n🧪 測試: {description}')
    print(f'問題: {question}')
    print('-' * 60)

    responses.clear()
    sio.emit('rag_question', {'question': question})

    # 等待回應（最多 30 秒）
    start_time = time.time()
    while not responses and (time.time() - start_time) < 30:
        time.sleep(0.5)

    if not responses:
        print('⏱️ 等待超時，未收到回應')
        return None

    return responses[0]

def main():
    try:
        # 連接到伺服器
        print('🔌 正在連接到 Flask Socket.IO 伺服器...')
        sio.connect('http://localhost:5000')

        time.sleep(2)  # 等待連接穩定

        # ========== 測試案例 ==========

        # 測試 1: 本地向量資料庫應該有的資料（營養相關）
        print('\n' + '=' * 60)
        print('測試 1: 本地向量資料庫查詢')
        print('=' * 60)
        test_question(
            "米飯的營養成分有哪些？",
            "測試第一層：本地 Chroma RAG（應該找到資料）"
        )

        time.sleep(3)

        # 測試 2: 向量資料庫可能沒有的資料（需要 LLM 直接回答）
        print('\n' + '=' * 60)
        print('測試 2: LLM 自身知識回答')
        print('=' * 60)
        test_question(
            "什麼是生酮飲食？",
            "測試第三層：LLM 直接回答（向量庫可能沒資料）"
        )

        time.sleep(3)

        # 測試 3: 更廣泛的營養問題
        print('\n' + '=' * 60)
        print('測試 3: 混合測試')
        print('=' * 60)
        test_question(
            "我想減肥，應該如何安排飲食？",
            "測試備援機制（根據資料庫內容決定使用哪一層）"
        )

        time.sleep(3)

        # 測試結果總結
        print('\n' + '=' * 60)
        print('📊 測試總結')
        print('=' * 60)
        print('✅ 三層備援機制測試完成')
        print('\n說明：')
        print('- 第一層：如果本地向量資料庫有相關資料，使用 RAG')
        print('- 第二層：如果沒有資料且有 SERPER_API_KEY，使用 Google Search')
        print('- 第三層：直接使用 LLM（Gemini/Gemma）自身知識回答')
        print('\n⚠️ 注意：因為未設定 SERPER_API_KEY，第二層被跳過')
        print('💡 若要測試 Google Search，請前往 https://serper.dev 註冊並設定 API Key')

    except Exception as e:
        print(f'\n❌ 測試過程中發生錯誤: {e}')
        import traceback
        traceback.print_exc()

    finally:
        # 斷開連接
        print('\n🔌 正在斷開連接...')
        sio.disconnect()
        print('✅ 測試完成')

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('\n\n⚠️ 測試被使用者中斷')
        sio.disconnect()
