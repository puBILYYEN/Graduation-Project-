"""
RAG (Retrieval-Augmented Generation) 服務模組 - Chroma 版本
整合 Langchain + Chroma + LLM Manager (支援備援切換 & 自動翻譯)
基於 Chatbot_Chroma.ipynb 改寫
"""
import os
from typing import List, Dict, Optional
from langchain_chroma import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.docstore.document import Document
from langchain_core.prompts import ChatPromptTemplate
from langchain.chains.combine_documents import create_stuff_documents_chain
# import google.generativeai as genai  # 已註解：改用 LLM Manager 實現備援和翻譯
from services.llm_provider import get_llm_manager
from utils.logger import logger

class RAGServiceChroma:
    """RAG 服務管理器 - 使用 Chroma"""

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(RAGServiceChroma, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if self._initialized:
            return

        self._initialized = True
        self.vector_store = None
        self.embeddings = None
        # self.gemini_api_key = os.getenv('GEMINI_API_KEY')  # 已註解：改用 LLM Manager
        self.llm_manager = get_llm_manager()

        # Chroma 設定
        self.persist_directory = "knowledge-base"
        self.collection_name = "nutrition-knowledge"

        # 重要：使用 cosine 作為度量方式
        self.collection_metadata = {"hnsw:space": "cosine"}  # 預設是 "l2"，這裡改用 "cosine"

        self._initialize_embeddings()
        # self._initialize_gemini()  # 已註解：改用 LLM Manager

    def _initialize_embeddings(self):
        """初始化嵌入模型（使用 HuggingFace，不用 OpenAI）"""
        try:
            logger.info("正在初始化向量嵌入模型...")
            # 使用輕量級的多語言嵌入模型
            # cache_folder 會自動從環境變數 HF_HOME 讀取（已在 Dockerfile 設置為 /app/models_cache）
            self.embeddings = HuggingFaceEmbeddings(
                model_name="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
                model_kwargs={'device': 'cpu'},
                encode_kwargs={'normalize_embeddings': True}
            )
            logger.info("向量嵌入模型初始化成功")
        except Exception as e:
            logger.log_error_with_trace(e, "初始化嵌入模型")
            self.embeddings = None

    # def _initialize_gemini(self):  # 已註解：改用 LLM Manager
    #     """初始化 Gemini API"""
    #     try:
    #         if self.gemini_api_key:
    #             genai.configure(api_key=self.gemini_api_key)
    #             logger.info("Gemini API 初始化成功")
    #         else:
    #             logger.warning("未設置 GEMINI_API_KEY，Gemini 功能將被禁用")
    #     except Exception as e:
    #         logger.log_error_with_trace(e, "初始化 Gemini API")

    def is_available(self) -> bool:
        """檢查 RAG 服務是否可用"""
        return self.embeddings is not None and self.llm_manager.current_provider is not None

    def build_vector_store(self, nutrition_data: List[Dict], custom_data: Optional[List[Dict]] = None):
        """
        建立 Chroma 向量資料庫

        Args:
            nutrition_data: 從營養資料管理器獲取的資料
            custom_data: 自訂的額外資料
        """
        if not self.embeddings:
            logger.error("嵌入模型未初始化，無法建立向量資料庫")
            return False

        try:
            logger.info("正在建立 Chroma 向量資料庫...")

            # 準備文檔
            documents = []

            # 處理營養資料
            for item in nutrition_data:
                # 使用格式化的文本內容
                content = item.get('text_content', '')
                if not content:
                    content = self._format_nutrition_document(item)

                metadata = item.get('metadata', {})
                metadata['source'] = 'nutrition_database'
                metadata['name'] = item.get('name', '')

                doc = Document(page_content=content, metadata=metadata)
                documents.append(doc)

            # 處理自訂資料
            if custom_data:
                for item in custom_data:
                    content = item.get('text_content', '')
                    if not content:
                        content = str(item)

                    metadata = item.get('metadata', {})
                    metadata['source'] = 'custom_data'

                    doc = Document(page_content=content, metadata=metadata)
                    documents.append(doc)

            # 文本分割（chunk_size=1000, chunk_overlap=0，參考 notebook）
            text_splitter = RecursiveCharacterTextSplitter(
                chunk_size=1000,
                chunk_overlap=0  # notebook 中使用 0
            )
            split_docs = text_splitter.split_documents(documents)

            logger.info(f"文檔分割完成，共 {len(split_docs)} 個片段")

            # 建立 Chroma 向量存儲
            # 使用 from_documents 建立新的向量資料庫
            self.vector_store = Chroma.from_documents(
                split_docs,
                self.embeddings,
                persist_directory=self.persist_directory,
                collection_metadata=self.collection_metadata,  # 使用 cosine 度量
                collection_name=self.collection_name,
            )

            logger.info(f"Chroma 向量資料庫建立成功")
            logger.info(f"- 持久化目錄: {self.persist_directory}")
            logger.info(f"- 集合名稱: {self.collection_name}")
            logger.info(f"- 度量方式: cosine")

            return True

        except Exception as e:
            logger.log_error_with_trace(e, "建立 Chroma 向量資料庫")
            return False

    def load_vector_store(self) -> bool:
        """從本地載入 Chroma 向量資料庫"""
        try:
            if os.path.exists(self.persist_directory):
                self.vector_store = Chroma(
                    collection_name=self.collection_name,
                    embedding_function=self.embeddings,
                    persist_directory=self.persist_directory,
                    collection_metadata=self.collection_metadata,  # 使用 cosine 度量
                )
                logger.info("Chroma 向量資料庫載入成功")
                return True
            else:
                logger.warning(f"向量資料庫目錄不存在: {self.persist_directory}")
                return False
        except Exception as e:
            logger.log_error_with_trace(e, "載入 Chroma 向量資料庫")
            return False

    def _format_nutrition_document(self, nutrition_data: Dict) -> str:
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

    def similarity_search(self, query: str, k: int = 3) -> List[Document]:
        """
        相似度搜尋（參考 notebook 的 similarity_search）

        Args:
            query: 查詢文本
            k: 返回最相關的 k 個結果

        Returns:
            相關文檔列表
        """
        if not self.vector_store:
            logger.warning("向量資料庫未初始化")
            return []

        try:
            # 使用 Chroma 的 similarity_search
            docs = self.vector_store.similarity_search(query, k)
            logger.info(f"相似度搜尋完成，找到 {len(docs)} 個相關結果")
            return docs

        except Exception as e:
            logger.log_error_with_trace(e, f"相似度搜尋 (query: {query})")
            return []

    def generate_answer_with_rag(
        self,
        query: str,
        k: int = 3
    ) -> str:
        """
        使用 RAG 生成回答（支援自動備援和翻譯）

        Args:
            query: 使用者問題
            k: 檢索的文檔數量

        Returns:
            生成的回答（繁體中文）
        """
        if not self.llm_manager.current_provider:
            return "LLM 服務未配置或不可用，無法生成回答"

        try:
            # 1. 相似度搜尋
            query_docs = self.similarity_search(query, k)

            if not query_docs:
                return "抱歉！我無法在知識庫中找到相關資訊來回答您的問題。"

            # 2. 準備提示詞（參考 notebook）
            prompt_text = """你是一位專業的營養師，你的目標是幫助使用者了解營養知識並提供健康的飲食建議。

你需要使用專業且友善的語氣，並以清晰易懂的方式解釋營養相關問題。

回答問題時要直接且實用，不須提到「根據所提供的資料」。

請依所提供的營養知識（下文）進行回答，若無法回答問題，請直接回覆：抱歉！我無法回答您這個問題，建議您諮詢專業營養師。

=========
{documents}
=========

回答下列問題：
{question}"""

            # 3. 組合文檔內容
            documents_text = "\n\n".join([doc.page_content for doc in query_docs])

            # 4. 生成最終提示
            final_prompt = prompt_text.format(
                documents=documents_text,
                question=query
            )

            # 5. 使用 LLM Manager 生成回答（支援自動備援和翻譯）
            result = self.llm_manager.generate_with_translation(
                final_prompt,
                context="營養建議",
                temperature=0.7,
                max_tokens=2048
            )

            if result['text']:
                answer = result['text']
                logger.log_rag_query(query, len(answer))

                # 記錄使用的提供者和是否翻譯
                provider_info = f"提供者: {result['provider']}"
                if result['translated']:
                    provider_info += f", 已翻譯 (翻譯器: {result['translator']})"
                logger.info(provider_info)

                return answer
            else:
                error_msg = result.get('error', '所有 LLM 服務都不可用')
                return f"生成回答失敗：{error_msg}"

        except Exception as e:
            logger.log_error_with_trace(e, "使用 RAG 生成回答")
            return f"生成回答時發生錯誤：{str(e)}"

    def generate_personalized_advice(
        self,
        detected_foods: List[str],
        user_profile: Optional[Dict] = None,
        meal_history: Optional[List[Dict]] = None
    ) -> str:
        """
        生成個性化營養建議（支援自動備援和翻譯）

        Args:
            detected_foods: 辨識到的食物列表
            user_profile: 使用者個人資料
            meal_history: 使用者用餐歷史

        Returns:
            個性化營養建議（繁體中文）
        """
        if not self.llm_manager.current_provider:
            return "LLM 服務未配置或不可用，無法生成建議"

        try:
            # 1. 為每個食物進行相似度搜尋
            all_relevant_docs = []
            for food in detected_foods:
                docs = self.similarity_search(food, k=2)
                all_relevant_docs.extend(docs)

            # 2. 構建提示詞
            prompt = self._build_personalized_advice_prompt(
                detected_foods,
                all_relevant_docs,
                user_profile,
                meal_history
            )

            # 3. 使用 LLM Manager 生成建議（支援自動備援和翻譯）
            result = self.llm_manager.generate_with_translation(
                prompt,
                context="個性化營養建議",
                temperature=0.7,
                max_tokens=2048
            )

            if result['text']:
                advice = result['text']
                logger.log_rag_query(f"個性化建議: {', '.join(detected_foods)}", len(advice))

                # 記錄使用的提供者和是否翻譯
                provider_info = f"提供者: {result['provider']}"
                if result['translated']:
                    provider_info += f", 已翻譯 (翻譯器: {result['translator']})"
                logger.info(provider_info)

                return advice
            else:
                error_msg = result.get('error', '所有 LLM 服務都不可用')
                return f"生成建議失敗：{error_msg}"

        except Exception as e:
            logger.log_error_with_trace(e, "生成個性化建議")
            return f"生成建議時發生錯誤：{str(e)}"

    def _build_personalized_advice_prompt(
        self,
        detected_foods: List[str],
        relevant_docs: List[Document],
        user_profile: Optional[Dict],
        meal_history: Optional[List[Dict]]
    ) -> str:
        """構建個性化建議的提示詞"""
        prompt_parts = [
            "你是一位專業的營養師，請根據以下資訊提供個性化的營養建議：",
            "",
            "=== 本餐辨識到的食物 ===",
        ]

        prompt_parts.append(", ".join(detected_foods))
        prompt_parts.append("")

        # 添加營養資料上下文
        if relevant_docs:
            prompt_parts.append("=== 相關營養資訊 ===")
            for doc in relevant_docs[:5]:  # 取前5個最相關的
                prompt_parts.append(doc.page_content)
                prompt_parts.append("---")
            prompt_parts.append("")

        # 添加使用者資料
        if user_profile:
            prompt_parts.append("=== 使用者資料 ===")
            if 'height' in user_profile:
                prompt_parts.append(f"身高：{user_profile['height']} cm")
            if 'weight' in user_profile:
                prompt_parts.append(f"體重：{user_profile['weight']} kg")
            if 'goal' in user_profile:
                prompt_parts.append(f"目標：{user_profile['goal']}")
            if 'dietary_restrictions' in user_profile:
                prompt_parts.append(f"飲食限制：{user_profile['dietary_restrictions']}")
            prompt_parts.append("")

        # 添加用餐歷史
        if meal_history and len(meal_history) > 0:
            prompt_parts.append("=== 最近用餐記錄 ===")
            for i, meal in enumerate(meal_history[:3], 1):
                if 'timestamp' in meal and 'foods' in meal:
                    prompt_parts.append(f"{i}. {meal['timestamp']}: {', '.join(meal['foods'])}")
            prompt_parts.append("")

        # 請求建議
        prompt_parts.append("=== 請提供 ===")
        prompt_parts.append("1. 本餐的營養評估（熱量、營養均衡性）")
        prompt_parts.append("2. 針對使用者目標的具體建議")
        prompt_parts.append("3. 飲食搭配改善建議")
        prompt_parts.append("4. 份量控制建議")
        prompt_parts.append("")
        prompt_parts.append("請用繁體中文回答，簡潔專業，約200-300字。")

        return "\n".join(prompt_parts)

# 全域 RAG 服務實例
rag_service_chroma = RAGServiceChroma()
