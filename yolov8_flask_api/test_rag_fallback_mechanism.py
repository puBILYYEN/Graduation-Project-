"""
測試 RAG Fallback 機制
測試向量資料庫找不到資料時，是否能使用 Gemini 自身知識庫回答
"""
import sys
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

from services.rag_service_chroma import rag_service_chroma

def test_rag_fallback():
    print("\n" + "="*70)
    print("測試 RAG Fallback 機制")
    print("="*70 + "\n")

    # 測試問題列表
    test_cases = [
        {
            "query": "雞肉的營養成分有哪些？",
            "expected": "應該從向量資料庫找到",
            "type": "資料庫內問題"
        },
        {
            "query": "白飯的熱量是多少？",
            "expected": "應該從向量資料庫找到",
            "type": "資料庫內問題"
        },
        {
            "query": "什麼是生酮飲食？",
            "expected": "可能使用 Gemini 自身知識庫",
            "type": "一般營養知識"
        },
        {
            "query": "如何計算每日所需熱量？",
            "expected": "可能使用 Gemini 自身知識庫",
            "type": "一般營養知識"
        },
        {
            "query": "間歇性斷食對健康有什麼影響？",
            "expected": "應該使用 Gemini 自身知識庫",
            "type": "資料庫外問題"
        }
    ]

    # 檢查 RAG 服務是否可用
    if not rag_service_chroma.is_available():
        print("❌ RAG 服務不可用")
        return

    print("✅ RAG 服務已初始化\n")

    # 測試向量資料庫載入
    if not rag_service_chroma.load_vector_store():
        print("❌ 無法載入向量資料庫")
        return

    print("✅ 向量資料庫已載入\n")
    print("-"*70 + "\n")

    # 執行測試
    for i, test_case in enumerate(test_cases, 1):
        query = test_case['query']
        expected = test_case['expected']
        test_type = test_case['type']

        print(f"測試 {i}/{len(test_cases)}: {test_type}")
        print(f"問題: {query}")
        print(f"預期: {expected}\n")

        # 先檢查向量資料庫是否有相關文檔
        docs = rag_service_chroma.similarity_search(query, k=3)

        if docs and len(docs) > 0:
            print(f"📊 向量資料庫找到 {len(docs)} 個相關文檔")
            print(f"   最相關: {docs[0].metadata.get('name', '未知')}")
        else:
            print(f"⚠️ 向量資料庫未找到相關文檔 → 將使用 Gemini 自身知識庫")

        print(f"\n💬 生成回答中...")

        # 生成回答
        answer = rag_service_chroma.generate_answer_with_rag(query, k=3)

        print(f"\n✅ 回答:")
        print(f"{answer[:200]}..." if len(answer) > 200 else answer)

        print("\n" + "-"*70 + "\n")

    print("="*70)
    print("測試完成！")
    print("="*70)

if __name__ == "__main__":
    try:
        test_rag_fallback()
    except KeyboardInterrupt:
        print("\n\n⚠️ 測試被使用者中斷")
    except Exception as e:
        print(f"\n❌ 測試失敗: {e}")
        import traceback
        traceback.print_exc()
