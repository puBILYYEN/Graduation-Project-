#!/usr/bin/env python3
"""
預先下載所需的機器學習模型
在 Docker 建置階段執行此腳本，確保模型已包含在映像中
"""
import os
from sentence_transformers import SentenceTransformer

def download_embedding_model():
    """下載 HuggingFace 嵌入模型"""
    model_name = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
    # 優先使用 HF_HOME (transformers v5 標準)，其次是 SENTENCE_TRANSFORMERS_HOME
    cache_folder = os.getenv('HF_HOME') or os.getenv('SENTENCE_TRANSFORMERS_HOME', '/app/models_cache')

    # 確保快取目錄存在
    os.makedirs(cache_folder, exist_ok=True)

    print(f"正在下載嵌入模型: {model_name}")
    print(f"快取目錄: {cache_folder}")

    try:
        # 下載模型到預設快取目錄
        model = SentenceTransformer(model_name)
        print(f"✓ 模型下載成功")
        print(f"模型維度: {model.get_sentence_embedding_dimension()}")

        # 測試編碼
        test_text = "這是一個測試句子"
        embedding = model.encode(test_text)
        print(f"✓ 模型測試成功，嵌入向量長度: {len(embedding)}")

        return True
    except Exception as e:
        print(f"✗ 模型下載失敗: {e}")
        return False

if __name__ == "__main__":
    print("=" * 60)
    print("開始預下載機器學習模型...")
    print("=" * 60)

    success = download_embedding_model()

    print("=" * 60)
    if success:
        print("✓ 所有模型下載完成")
        exit(0)
    else:
        print("✗ 模型下載失敗")
        exit(1)
