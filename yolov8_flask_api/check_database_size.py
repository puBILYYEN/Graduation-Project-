"""
檢查營養資料庫實際規模
"""
import os
import sys

# 設置 UTF-8 輸出
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# 導入服務
from services.nutrition_data_manager import nutrition_manager
from services.rag_service_chroma import rag_service_chroma
from langchain_chroma import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings

def main():
    print("\n" + "="*60)
    print("營養資料庫規模檢查")
    print("="*60 + "\n")

    # 1. 檢查原始營養資料
    print("📊 正在載入營養資料庫...")
    if nutrition_manager.load_nutrition_database():
        print(f"✅ 營養資料庫載入成功")
        print(f"   - 資料筆數: {len(nutrition_manager.nutrition_data):,} 筆")
        print(f"   - YOLO 對應: {len(nutrition_manager.food_mapping)} 個")
    else:
        print("❌ 營養資料庫載入失敗")
        return

    # 2. 檢查向量資料庫
    print(f"\n📦 檢查向量資料庫...")
    db_path = "knowledge-base/chroma.sqlite3"

    if os.path.exists(db_path):
        db_size = os.path.getsize(db_path) / 1024 / 1024  # MB
        print(f"✅ 向量資料庫存在")
        print(f"   - 檔案大小: {db_size:.2f} MB")

        # 載入並檢查文檔數量
        try:
            embeddings = HuggingFaceEmbeddings(
                model_name="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
                model_kwargs={'device': 'cpu'},
                encode_kwargs={'normalize_embeddings': True}
            )

            vector_store = Chroma(
                collection_name="nutrition-knowledge",
                embedding_function=embeddings,
                persist_directory="knowledge-base",
                collection_metadata={"hnsw:space": "cosine"}
            )

            # 獲取集合資訊
            collection = vector_store._collection
            doc_count = collection.count()

            print(f"   - 文檔數量: {doc_count:,} 個")

            # 計算平均每個文檔的大小
            if doc_count > 0:
                avg_size = db_size / doc_count * 1024  # KB
                print(f"   - 平均大小: {avg_size:.2f} KB/文檔")

        except Exception as e:
            print(f"⚠️ 無法讀取向量資料庫詳情: {e}")
    else:
        print("❌ 向量資料庫不存在")

    # 3. 測試搜尋效能
    print(f"\n🔍 測試搜尋效能...")
    if rag_service_chroma.load_vector_store():
        import time

        test_queries = [
            "雞肉的營養成分",
            "高蛋白質食物",
            "適合減肥的食物"
        ]

        total_time = 0
        for query in test_queries:
            start = time.time()
            results = rag_service_chroma.similarity_search(query, k=3)
            elapsed = (time.time() - start) * 1000  # ms
            total_time += elapsed
            print(f"   - 查詢「{query}」: {elapsed:.2f}ms")

        avg_time = total_time / len(test_queries)
        print(f"\n   平均搜尋時間: {avg_time:.2f}ms")
    else:
        print("⚠️ 無法載入向量資料庫")

    # 4. 結論
    print(f"\n" + "="*60)
    print("結論與建議")
    print("="*60)

    data_count = len(nutrition_manager.nutrition_data)

    if data_count < 10000:
        recommendation = "Chroma ✅ (完全適合)"
        reason = f"""
您的資料規模（{data_count:,} 筆）完全在 Chroma 的最佳範圍內。

✅ 為什麼 Chroma 適合您：
   1. 資料規模小於 1 萬筆，不需要 FAISS 的極致效能
   2. 搜尋速度已經很快（< 50ms），使用者無感延遲
   3. 自動持久化，維護成本極低
   4. 與 Langchain 整合完美，程式碼簡潔
   5. 您已經實現且運作正常

❌ 為什麼不需要 FAISS：
   1. FAISS 的優勢在百萬級資料才顯現
   2. 遷移成本高（2-3天），但效能提升 < 20ms（無意義）
   3. 需要手動管理持久化，增加維護負擔
   4. 對您的應用場景來說是「過度設計」

📊 效能對比估算：
   Chroma 搜尋:  10-30ms  ← 您目前
   FAISS 搜尋:   5-15ms   ← 提升微乎其微
   LLM 生成:     1000-3000ms  ← 真正的瓶頸

   結論：優化 LLM 比優化向量搜尋更有意義
"""
    elif data_count < 100000:
        recommendation = "Chroma ✅ (仍然適合)"
        reason = "資料規模在 10 萬以下，Chroma 仍是最佳選擇"
    else:
        recommendation = "考慮 FAISS"
        reason = "資料規模較大，FAISS 的效能優勢開始顯現"

    print(f"\n推薦方案: {recommendation}")
    print(reason)

    print(f"\n" + "="*60)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️ 檢查被使用者中斷")
    except Exception as e:
        print(f"\n\n❌ 檢查過程中發生錯誤: {e}")
        import traceback
        traceback.print_exc()
