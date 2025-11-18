"""
重新建立向量資料庫
從 Firebase 載入營養資料並建立 ChromaDB 向量資料庫
"""
import os
import sys

# 設置 UTF-8 輸出
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

from services.firebase_service import firebase_service
from langchain_chroma import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.docstore.document import Document

def format_nutrition_document(nutrition_data: dict) -> str:
    """格式化營養資料為文檔內容"""
    parts = []

    # 基本資訊
    if 'name' in nutrition_data:
        parts.append(f"食物名稱：{nutrition_data['name']}")

    if 'category' in nutrition_data:
        parts.append(f"食品分類：{nutrition_data['category']}")

    # 營養成分
    if 'nutrients' in nutrition_data:
        nutrients = nutrition_data['nutrients']
        parts.append("\n營養成分（每100克）：")

        nutrient_mapping = {
            'calories': '熱量(kcal)',
            'protein': '蛋白質(g)',
            'carbs': '碳水化合物(g)',
            'fat': '脂肪(g)',
            'fiber': '膳食纖維(g)',
            'sodium': '鈉(mg)',
            'potassium': '鉀(mg)',
            'calcium': '鈣(mg)',
            'iron': '鐵(mg)',
            'vitamin_a': '維生素A(IU)',
            'vitamin_c': '維生素C(mg)',
        }

        for key, name in nutrient_mapping.items():
            if key in nutrients and nutrients[key]:
                parts.append(f"- {name}：{nutrients[key]}")

    # 描述
    if 'description' in nutrition_data:
        parts.append(f"\n描述：{nutrition_data['description']}")

    return "\n".join(parts)

def main():
    print("\n" + "="*60)
    print("重新建立向量資料庫")
    print("="*60 + "\n")

    # 1. 檢查 Firebase 連接
    if not firebase_service.is_available():
        print("❌ Firebase 服務不可用，請檢查憑證設定")
        return

    print("✅ Firebase 連接成功")

    # 2. 從 Firebase 載入營養資料
    print("\n📊 正在從 Firebase 載入營養資料...")
    nutrition_data = firebase_service.get_all_nutrition_data()

    if not nutrition_data:
        print("❌ 無法從 Firebase 載入資料")
        return

    print(f"✅ 已載入 {len(nutrition_data)} 筆營養資料")

    # 3. 初始化嵌入模型
    print("\n🤖 正在初始化嵌入模型...")
    embeddings = HuggingFaceEmbeddings(
        model_name="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
        model_kwargs={'device': 'cpu'},
        encode_kwargs={'normalize_embeddings': True}
    )
    print("✅ 嵌入模型初始化成功")

    # 4. 準備文檔
    print("\n📝 正在準備文檔...")
    documents = []

    for item in nutrition_data:
        # 格式化文本內容
        content = item.get('text_content', '')
        if not content:
            content = format_nutrition_document(item)

        metadata = item.get('metadata', {})
        metadata['source'] = 'nutrition_database'
        metadata['name'] = item.get('name', '')

        doc = Document(page_content=content, metadata=metadata)
        documents.append(doc)

    print(f"✅ 已準備 {len(documents)} 個文檔")

    # 5. 文本分割
    print("\n✂️ 正在分割文檔...")
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=0
    )
    split_docs = text_splitter.split_documents(documents)
    print(f"✅ 文檔分割完成，共 {len(split_docs)} 個片段")

    # 6. 建立向量資料庫
    print("\n🔨 正在建立 ChromaDB 向量資料庫...")
    persist_directory = "knowledge-base"
    collection_name = "nutrition-knowledge"
    collection_metadata = {"hnsw:space": "cosine"}

    # 如果目錄存在，先刪除舊資料
    import shutil
    if os.path.exists(persist_directory):
        print(f"⚠️ 刪除舊的向量資料庫...")
        shutil.rmtree(persist_directory)

    vector_store = Chroma.from_documents(
        split_docs,
        embeddings,
        persist_directory=persist_directory,
        collection_metadata=collection_metadata,
        collection_name=collection_name,
    )

    print(f"✅ ChromaDB 向量資料庫建立成功")
    print(f"   - 持久化目錄: {persist_directory}")
    print(f"   - 集合名稱: {collection_name}")
    print(f"   - 度量方式: cosine")
    print(f"   - 文檔片段數: {len(split_docs)}")

    # 7. 測試搜尋
    print("\n🔍 測試搜尋功能...")
    test_query = "雞肉的營養成分"
    results = vector_store.similarity_search(test_query, k=3)

    print(f"✅ 搜尋測試成功，找到 {len(results)} 個結果")
    if results:
        print(f"\n範例結果（查詢：{test_query}）:")
        for i, doc in enumerate(results[:2], 1):
            print(f"\n{i}. {doc.metadata.get('name', '未知')}")
            print(f"   內容片段: {doc.page_content[:100]}...")

    print("\n" + "="*60)
    print("✅ 向量資料庫重建完成！")
    print("="*60)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️ 操作被使用者中斷")
    except Exception as e:
        print(f"\n\n❌ 發生錯誤: {e}")
        import traceback
        traceback.print_exc()
