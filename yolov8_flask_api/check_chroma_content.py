"""
檢查 ChromaDB 向量資料庫內容
"""
import sys
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

try:
    from langchain_chroma import Chroma
    from langchain_community.embeddings import HuggingFaceEmbeddings

    print("\n" + "="*60)
    print("檢查 ChromaDB 向量資料庫內容")
    print("="*60 + "\n")

    # 初始化嵌入模型
    print("1. 正在初始化嵌入模型...")
    embeddings = HuggingFaceEmbeddings(
        model_name="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
        model_kwargs={'device': 'cpu'},
        encode_kwargs={'normalize_embeddings': True}
    )
    print("✅ 嵌入模型初始化成功\n")

    # 載入向量資料庫
    print("2. 正在載入向量資料庫...")
    vector_store = Chroma(
        collection_name="nutrition-knowledge",
        embedding_function=embeddings,
        persist_directory="knowledge-base",
        collection_metadata={"hnsw:space": "cosine"}
    )
    print("✅ 向量資料庫載入成功\n")

    # 檢查文檔數量
    print("3. 檢查資料庫內容...")
    collection = vector_store._collection
    doc_count = collection.count()

    print(f"✅ 文檔數量: {doc_count:,} 個\n")

    if doc_count > 0:
        print("4. 測試搜尋功能...")
        test_queries = ["雞肉", "白飯", "高蛋白"]

        for query in test_queries:
            print(f"\n查詢: {query}")
            results = vector_store.similarity_search(query, k=3)

            if results:
                print(f"✅ 找到 {len(results)} 個結果")
                for i, doc in enumerate(results[:2], 1):
                    name = doc.metadata.get('name', '未知')
                    preview = doc.page_content[:80].replace('\n', ' ')
                    print(f"   {i}. {name}")
                    print(f"      {preview}...")
            else:
                print("⚠️ 未找到結果")
    else:
        print("❌ 資料庫是空的！")

    print("\n" + "="*60)

except Exception as e:
    print(f"\n❌ 錯誤: {e}")
    import traceback
    traceback.print_exc()
