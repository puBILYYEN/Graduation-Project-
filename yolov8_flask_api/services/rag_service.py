# ==========================================================================
# @檔案: rag_service.py
# @描述: RAG (Retrieval-Augmented Generation) 服務模組。
#        封裝了向量資料庫的建立、查詢以及與大型語言模型(LLM)的互動。
# ==========================================================================
import os
import json
from typing import List, Dict, Optional
from langchain_community.vectorstores import FAISS
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.docstore.document import Document
# import google.generativeai as genai  # 已註解：改用 LLM Manager 實現自動切換
from services.llm_provider import get_llm_manager
from utils.logger import logger

# --------------------------------------------------------------------
# @類別: RAGService
# @描述: RAG 服務管理器，採用單例模式 (Singleton Pattern) 以確保
#        整個應用程式中只有一個實例，避免重複載入模型和資料庫。
# --------------------------------------------------------------------
class RAGService:
    """RAG 服務管理器"""

    _instance = None

    # 實作單例模式
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(RAGService, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    # 初始化服務
    def __init__(self):
        if self._initialized:
            return

        self._initialized = True
        
        self.vector_store = None # 將用於儲存 FAISS 向量資料庫
        self.embeddings = None   # 將用於儲存 HuggingFace 嵌入模型
        self.llm_manager = get_llm_manager() # 獲取 LLM 管理器實例

        self._initialize_embeddings()
        # self._initialize_gemini()  # 已註解：改用 LLM Manager

    # ------------------------------------------------------------------
    # @方法: _initialize_embeddings (私有)
    # @描述: 初始化將文字轉換為向量的嵌入模型。
    # ------------------------------------------------------------------
    def _initialize_embeddings(self):
        """初始化嵌入模型"""
        try:
            logger.info("正在初始化向量嵌入模型...")
            # 使用一個輕量級、支援多語言的句子轉換模型。
            # 'cpu' 強制在 CPU 上運行，避免在沒有 GPU 的環境中出錯。
            # 'normalize_embeddings': True 將向量長度標準化，有助於相似度計算。
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

    # ------------------------------------------------------------------
    # @方法: is_available
    # @描述: 檢查 RAG 服務是否所有元件都已準備就緒。
    # ------------------------------------------------------------------
    def is_available(self) -> bool:
        """檢查 RAG 服務是否可用"""
        return self.embeddings is not None and self.llm_manager.current_provider is not None

    # ------------------------------------------------------------------
    # @方法: build_vector_store
    # @描述: 根據提供的營養資料，建立一個 FAISS 向量資料庫並儲存到本地。
    # ------------------------------------------------------------------
    def build_vector_store(self, nutrition_data: List[Dict], custom_data: Optional[List[Dict]] = None):
        """
        建立向量資料庫

        Args:
            nutrition_data: 從 Firebase 獲取的營養資料
            custom_data: 自訂的額外營養資料
        """
        if not self.embeddings:
            logger.error("嵌入模型未初始化，無法建立向量資料庫")
            return False

        try:
            logger.info("正在建立向量資料庫...")

            # 步驟 1: 將從 Firebase 或其他來源獲取的結構化資料 (Dict) 轉換為 Langchain 的 Document 物件。
            documents = []
            for item in nutrition_data:
                content = self._format_nutrition_document(item)
                doc = Document(page_content=content, metadata=item)
                documents.append(doc)
            if custom_data:
                for item in custom_data:
                    content = self._format_nutrition_document(item)
                    doc = Document(page_content=content, metadata=item)
                    documents.append(doc)

            # 步驟 2: 對於較長的文檔，進行切割，以符合嵌入模型的輸入長度限制。
            text_splitter = RecursiveCharacterTextSplitter(
                chunk_size=500,
                chunk_overlap=50,
                length_function=len
            )
            split_docs = text_splitter.split_documents(documents)

            # 步驟 3: 使用 FAISS (Facebook AI Similarity Search) 從切割後的文檔和嵌入模型建立向量索引。
            self.vector_store = FAISS.from_documents(split_docs, self.embeddings)

            # 步驟 4: 將建立好的索引儲存到本地磁碟，以便下次啟動時能快速載入。
            self.vector_store.save_local("faiss_index")

            logger.info(f"向量資料庫建立成功，共 {len(split_docs)} 個文檔片段")
            return True

        except Exception as e:
            logger.log_error_with_trace(e, "建立向量資料庫")
            return False

    # ------------------------------------------------------------------
    # @方法: load_vector_store
    # @描述: 從本地磁碟載入先前已建立的 FAISS 向量資料庫。
    # ------------------------------------------------------------------
    def load_vector_store(self) -> bool:
        """從本地載入向量資料庫"""
        try:
            if os.path.exists("faiss_index"):
                self.vector_store = FAISS.load_local(
                    "faiss_index",
                    self.embeddings,
                    allow_dangerous_deserialization=True # FAISS 載入 pickle 檔案需要此參數
                )
                logger.info("向量資料庫載入成功")
                return True
            else:
                logger.warning("向量資料庫檔案不存在")
                return False
        except Exception as e:
            logger.log_error_with_trace(e, "載入向量資料庫")
            return False

    # ------------------------------------------------------------------
    # @方法: _format_nutrition_document (私有)
    # @描述: 將一個營養資料的 Dictionary 格式化為一段易於閱讀和嵌入的純文字。
    # ------------------------------------------------------------------
    def _format_nutrition_document(self, nutrition_data: Dict) -> str:
        """格式化營養資料為文檔內容"""
        parts = []

        # 基本資訊
        if 'name' in nutrition_data:
            parts.append(f"食物名稱：{nutrition_data['name']}")

        # 營養成分
        nutrients = ['calories', 'protein', 'carbs', 'fat', 'fiber', 'sodium']
        nutrient_names = {
            'calories': '熱量(kcal)',
            'protein': '蛋白質(g)',
            'carbs': '碳水化合物(g)',
            'fat': '脂肪(g)',
            'fiber': '纖維(g)',
            'sodium': '鈉(mg)'
        }

        for nutrient in nutrients:
            if nutrient in nutrition_data:
                name = nutrient_names.get(nutrient, nutrient)
                parts.append(f"{name}：{nutrition_data[nutrient]}")

        # 描述
        if 'description' in nutrition_data:
            parts.append(f"描述：{nutrition_data['description']}")

        # 健康益處
        if 'health_benefits' in nutrition_data:
            parts.append(f"健康益處：{nutrition_data['health_benefits']}")

        return "\n".join(parts)

    # ------------------------------------------------------------------
    # @方法: query_nutrition (RAG 中的 "Retrieval" 環節)
    # @描述: 接收一個文字查詢，在向量資料庫中進行相似度搜尋，找出最相關的營養資料。
    # @返回: List[Dict] - 包含最相關文件元數據 (metadata) 的列表。
    # ------------------------------------------------------------------
    def query_nutrition(self, query: str, k: int = 5) -> List[Dict]:
        """
        查詢相關的營養資料

        Args:
            query: 查詢文本
            k: 返回最相關的 k 個結果

        Returns:
            相關營養資料列表
        """
        if not self.vector_store:
            logger.warning("向量資料庫未初始化")
            return []

        try:
            # 核心步驟：使用向量資料庫的 similarity_search 方法來尋找最相似的 k 個文檔。
            docs = self.vector_store.similarity_search(query, k=k)

            # 從返回的 Document 物件中僅提取我們需要的元數據 (原始的營養資料)。
            results = []
            for doc in docs:
                results.append(doc.metadata)

            logger.info(f"查詢完成，找到 {len(results)} 個相關結果")
            return results

        except Exception as e:
            logger.log_error_with_trace(e, f"查詢營養資料 (query: {query})")
            return []

    # ------------------------------------------------------------------
    # @方法: generate_personalized_advice (RAG 中的 "Generation" 環節)
    # @描述: 結合辨識的食物、使用者資料和從向量資料庫檢索到的知識，
    #        建構一個詳細的提示(Prompt)，並交給 LLM 生成個人化建議。
    # ------------------------------------------------------------------
    def generate_personalized_advice(
        self,
        detected_foods: List[str],
        user_profile: Optional[Dict] = None,
        meal_history: Optional[List[Dict]] = None
    ) -> str:
        """
        生成個性化營養建議

        Args:
            detected_foods: 辨識到的食物列表
            user_profile: 使用者個人資料（身高、體重、目標等）
            meal_history: 使用者用餐歷史

        Returns:
            個性化營養建議
        """
        if not self.llm_manager.current_provider:
            return "LLM 服務未配置或不可用，無法生成建議"

        try:
            # 步驟 1 (Retrieval): 為每種辨識出的食物，查詢相關的營養知識。
            nutrition_context = []
            for food in detected_foods:
                relevant_data = self.query_nutrition(food, k=2)
                nutrition_context.extend(relevant_data)

            # 步驟 2 (Prompt Engineering): 建構一個結構化的、資訊豐富的提示詞。
            prompt = self._build_advice_prompt(
                detected_foods,
                nutrition_context,
                user_profile,
                meal_history
            )

            # 步驟 3 (Generation): 使用 LLM Manager (會自動選擇可用的 LLM 服務) 來生成最終的回答。
            advice = self.llm_manager.generate_content(
                prompt,
                temperature=0.7,
                max_tokens=2048
            )

            if advice:
                logger.log_rag_query(prompt[:100], len(advice))
                current_provider = self.llm_manager.get_current_provider_name()
                logger.info(f"✅ 使用 {current_provider} 生成建議成功")
                return advice
            else:
                return "所有 LLM 服務都不可用，無法生成建議"

        except Exception as e:
            logger.log_error_with_trace(e, "生成個性化建議")
            return f"生成建議時發生錯誤：{str(e)}"

    # ------------------------------------------------------------------
    # @方法: _build_advice_prompt (私有)
    # @描述: 提示詞工程 (Prompt Engineering) 的核心，負責將所有上下文資訊
    #        組合成一個高品質的、結構化的提示詞，以引導 LLM 產生期望的輸出。
    # ------------------------------------------------------------------
    def _build_advice_prompt(
        self,
        detected_foods: List[str],
        nutrition_context: List[Dict],
        user_profile: Optional[Dict],
        meal_history: Optional[List[Dict]]
    ) -> str:
        """構建 Gemini 提示詞"""
        prompt_parts = [
            "你是一位專業的營養師，請根據以下資訊提供個性化的營養建議：",
            "",
            "=== 本餐辨識到的食物 ===",
        ]

        prompt_parts.append(", ".join(detected_foods))
        prompt_parts.append("")

        # 添加營養資料上下文
        if nutrition_context:
            prompt_parts.append("=== 相關營養資訊 ===")
            for item in nutrition_context[:3]:  # 只取前3個最相關的
                prompt_parts.append(self._format_nutrition_document(item))
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
            for i, meal in enumerate(meal_history[:3], 1):  # 只顯示最近3餐
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

# --- 區塊: 全域實例 ---
# 建立 RAGService 的單例，讓應用程式的其他部分可以直接導入和使用。
rag_service = RAGService()
