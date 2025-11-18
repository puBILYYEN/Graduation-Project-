"""
從食品營養成分資料庫 CSV 重建 ChromaDB 向量資料庫
參考 Chatbot_Chroma.ipynb 的實作方式
"""
import os
import sys
import pandas as pd
from typing import List

# 設置 UTF-8 輸出
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

from langchain_chroma import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.docstore.document import Document

# CSV 檔案路徑
CSV_PATH = r"C:\Users\pop90\OneDrive\桌面\食物資料庫\資料庫\食品營養成分資料庫2024_UPDATE1.csv"

# 向量資料庫配置（與 Chatbot_Chroma 一致）
PERSIST_DIRECTORY = "knowledge-base"
COLLECTION_NAME = "nutrition-knowledge"
COLLECTION_METADATA = {"hnsw:space": "cosine"}

def load_nutrition_csv(csv_path: str) -> pd.DataFrame:
    """載入營養資料庫 CSV"""
    print(f"\n📊 正在讀取 CSV 檔案: {csv_path}")

    # 嘗試不同的編碼
    encodings = ['utf-8', 'big5', 'cp950', 'gbk', 'utf-8-sig']

    for encoding in encodings:
        try:
            df = pd.read_csv(csv_path, encoding=encoding)
            print(f"✅ 成功使用編碼: {encoding}")
            print(f"✅ 載入 {len(df)} 筆營養資料")
            print(f"\n欄位名稱: {list(df.columns[:10])}...")
            return df
        except Exception as e:
            print(f"⚠️ 編碼 {encoding} 失敗: {e}")
            continue

    raise Exception("無法讀取 CSV 檔案，所有編碼都失敗")

def format_nutrition_to_text(row) -> str:
    """將營養資料轉換為文本格式"""
    parts = []

    # 基本資訊（根據 CSV 欄位調整）
    try:
        # 假設欄位名稱（需根據實際 CSV 調整）
        if '樣品名稱' in row and pd.notna(row['樣品名稱']):
            parts.append(f"食物名稱：{row['樣品名稱']}")

        if '俗名' in row and pd.notna(row['俗名']):
            parts.append(f"別名：{row['俗名']}")

        if '內容物描述' in row and pd.notna(row['內容物描述']):
            parts.append(f"描述：{row['內容物描述']}")

        # 營養成分（每100克）
        parts.append("\n營養成分（每100克）：")

        nutrients = {
            '熱量(kcal)': '熱量',
            '粗蛋白(g)': '蛋白質',
            '總碳水化合物(g)': '碳水化合物',
            '粗脂肪(g)': '脂肪',
            '膳食纖維(g)': '膳食纖維',
            '鈉(mg)': '鈉',
            '鉀(mg)': '鉀',
            '鈣(mg)': '鈣',
            '鐵(mg)': '鐵',
            '維生素A總量(IU)': '維生素A',
            '維生素C(mg)': '維生素C',
        }

        for csv_col, display_name in nutrients.items():
            if csv_col in row and pd.notna(row[csv_col]):
                try:
                    value = float(row[csv_col])
                    if value > 0:
                        parts.append(f"- {display_name}：{value}")
                except:
                    pass

    except Exception as e:
        print(f"⚠️ 格式化資料時發生錯誤: {e}")
        # 如果格式化失敗，至少返回基本資訊
        return str(row.to_dict())

    return "\n".join(parts) if parts else str(row.to_dict())

def create_documents_from_csv(df: pd.DataFrame) -> List[Document]:
    """從 DataFrame 建立 LangChain Document 列表"""
    print(f"\n📝 正在將資料轉換為文檔格式...")

    documents = []

    for idx, row in df.iterrows():
        # 格式化為文本
        text_content = format_nutrition_to_text(row)

        # 建立 metadata
        metadata = {
            'source': 'nutrition_database_2024',
            'row_index': idx,
        }

        # 嘗試添加食物名稱到 metadata
        try:
            if '樣品名稱' in row and pd.notna(row['樣品名稱']):
                metadata['name'] = str(row['樣品名稱'])
        except:
            pass

        # 建立 Document
        doc = Document(page_content=text_content, metadata=metadata)
        documents.append(doc)

        # 每 1000 筆顯示進度
        if (idx + 1) % 1000 == 0:
            print(f"   已處理 {idx + 1} 筆...")

    print(f"✅ 已建立 {len(documents)} 個文檔")
    return documents

def build_chroma_db(documents: List[Document]):
    """建立 ChromaDB 向量資料庫"""

    # 1. 初始化嵌入模型（使用 HuggingFace，與專案一致）
    print(f"\n🤖 正在初始化嵌入模型...")
    embeddings = HuggingFaceEmbeddings(
        model_name="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
        model_kwargs={'device': 'cpu'},
        encode_kwargs={'normalize_embeddings': True}
    )
    print(f"✅ 嵌入模型初始化成功")

    # 2. 文本分割（參考 Chatbot_Chroma: chunk_size=1000, chunk_overlap=0）
    print(f"\n✂️ 正在分割文檔...")
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=0
    )
    split_docs = text_splitter.split_documents(documents)
    print(f"✅ 文檔分割完成，共 {len(split_docs)} 個片段")

    # 3. 刪除舊的向量資料庫
    import shutil
    if os.path.exists(PERSIST_DIRECTORY):
        print(f"\n⚠️ 刪除舊的向量資料庫: {PERSIST_DIRECTORY}")
        shutil.rmtree(PERSIST_DIRECTORY)

    # 4. 建立 ChromaDB 向量資料庫（參考 Chatbot_Chroma 的配置）
    print(f"\n🔨 正在建立 ChromaDB 向量資料庫...")
    print(f"   這可能需要幾分鐘時間...")

    vector_store = Chroma.from_documents(
        split_docs,
        embeddings,
        persist_directory=PERSIST_DIRECTORY,
        collection_metadata=COLLECTION_METADATA,
        collection_name=COLLECTION_NAME,
    )

    print(f"\n✅ ChromaDB 向量資料庫建立成功！")
    print(f"   - 持久化目錄: {PERSIST_DIRECTORY}")
    print(f"   - 集合名稱: {COLLECTION_NAME}")
    print(f"   - 度量方式: cosine")
    print(f"   - 文檔片段數: {len(split_docs)}")

    return vector_store

def test_search(vector_store):
    """測試搜尋功能"""
    print(f"\n🔍 測試搜尋功能...")

    test_queries = [
        "雞肉的營養成分",
        "高蛋白質食物",
        "白飯的熱量"
    ]

    for query in test_queries:
        print(f"\n查詢：{query}")
        results = vector_store.similarity_search(query, k=3)

        if results:
            print(f"✅ 找到 {len(results)} 個結果")
            for i, doc in enumerate(results[:2], 1):
                name = doc.metadata.get('name', '未知')
                content_preview = doc.page_content[:100].replace('\n', ' ')
                print(f"   {i}. {name}")
                print(f"      {content_preview}...")
        else:
            print(f"⚠️ 未找到結果")

def main():
    print("\n" + "="*60)
    print("從食品營養成分資料庫重建 ChromaDB 向量資料庫")
    print("="*60)

    try:
        # 1. 載入 CSV
        if not os.path.exists(CSV_PATH):
            print(f"\n❌ CSV 檔案不存在: {CSV_PATH}")
            return

        df = load_nutrition_csv(CSV_PATH)

        # 2. 轉換為 Documents
        documents = create_documents_from_csv(df)

        # 3. 建立向量資料庫
        vector_store = build_chroma_db(documents)

        # 4. 測試搜尋
        test_search(vector_store)

        print("\n" + "="*60)
        print("✅ 向量資料庫重建完成！")
        print("="*60)

    except Exception as e:
        print(f"\n❌ 發生錯誤: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️ 操作被使用者中斷")
