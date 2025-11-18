"""
分析 ChromaDB 中的資料來源
"""
import sys
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

try:
    from langchain_chroma import Chroma
    from langchain_community.embeddings import HuggingFaceEmbeddings
    from collections import Counter

    print("\n" + "="*60)
    print("分析 ChromaDB 資料來源")
    print("="*60 + "\n")

    # 初始化
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

    # 獲取所有文檔
    collection = vector_store._collection
    results = collection.get()

    print(f"📊 總文檔數: {len(results['ids'])}\n")

    # 分析 metadata
    print("📝 分析 Metadata 欄位...")
    all_metadata = results['metadatas']

    # 統計 source 欄位
    sources = [m.get('source', '未知') for m in all_metadata]
    source_counts = Counter(sources)

    print(f"\n資料來源統計:")
    for source, count in source_counts.most_common():
        print(f"  • {source}: {count} 個文檔")

    # 檢查前幾個文檔的完整 metadata
    print(f"\n🔍 前 5 個文檔的 Metadata 範例:")
    for i in range(min(5, len(all_metadata))):
        print(f"\n文檔 {i+1}:")
        for key, value in all_metadata[i].items():
            print(f"  {key}: {value}")

    # 分析文檔內容格式
    print(f"\n📄 文檔內容格式分析:")
    documents = results['documents']

    # 檢查前幾個文檔
    print(f"\n範例文檔 1:")
    print(documents[0][:300])
    print("...\n")

    print(f"範例文檔 2:")
    print(documents[1][:300])
    print("...\n")

    # 統計文檔長度
    doc_lengths = [len(d) for d in documents]
    avg_length = sum(doc_lengths) / len(doc_lengths)

    print(f"\n📏 文檔長度統計:")
    print(f"  • 平均長度: {avg_length:.0f} 字元")
    print(f"  • 最短: {min(doc_lengths)} 字元")
    print(f"  • 最長: {max(doc_lengths)} 字元")

    print("\n" + "="*60)

except Exception as e:
    print(f"\n❌ 錯誤: {e}")
    import traceback
    traceback.print_exc()
