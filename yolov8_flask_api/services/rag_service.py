"""
RAG (Retrieval-Augmented Generation) 服務模組
整合 Langchain + FAISS + LLM Manager (支援多 LLM 提供者)
"""
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

class RAGService:
    """RAG 服務管理器"""

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(RAGService, cls).__new__(cls)
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

        self._initialize_embeddings()
        # self._initialize_gemini()  # 已註解：改用 LLM Manager

    def _initialize_embeddings(self):
        """初始化嵌入模型"""
        try:
            logger.info("正在初始化向量嵌入模型...")
            # 使用輕量級的中文嵌入模型
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

            # 準備文檔
            documents = []

            # 處理 Firebase 營養資料
            for item in nutrition_data:
                content = self._format_nutrition_document(item)
                doc = Document(page_content=content, metadata=item)
                documents.append(doc)

            # 處理自訂資料
            if custom_data:
                for item in custom_data:
                    content = self._format_nutrition_document(item)
                    doc = Document(page_content=content, metadata=item)
                    documents.append(doc)

            # 文本分割（如果文檔太長）
            text_splitter = RecursiveCharacterTextSplitter(
                chunk_size=500,
                chunk_overlap=50,
                length_function=len
            )
            split_docs = text_splitter.split_documents(documents)

            # 建立 FAISS 向量存儲
            self.vector_store = FAISS.from_documents(split_docs, self.embeddings)

            # 保存向量存儲到本地
            self.vector_store.save_local("faiss_index")

            logger.info(f"向量資料庫建立成功，共 {len(split_docs)} 個文檔片段")
            return True

        except Exception as e:
            logger.log_error_with_trace(e, "建立向量資料庫")
            return False

    def load_vector_store(self) -> bool:
        """從本地載入向量資料庫"""
        try:
            if os.path.exists("faiss_index"):
                self.vector_store = FAISS.load_local(
                    "faiss_index",
                    self.embeddings,
                    allow_dangerous_deserialization=True
                )
                logger.info("向量資料庫載入成功")
                return True
            else:
                logger.warning("向量資料庫檔案不存在")
                return False
        except Exception as e:
            logger.log_error_with_trace(e, "載入向量資料庫")
            return False

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
            # 相似度搜尋
            docs = self.vector_store.similarity_search(query, k=k)

            results = []
            for doc in docs:
                results.append(doc.metadata)

            logger.info(f"查詢完成，找到 {len(results)} 個相關結果")
            return results

        except Exception as e:
            logger.log_error_with_trace(e, f"查詢營養資料 (query: {query})")
            return []

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
            # 查詢相關營養資料
            nutrition_context = []
            for food in detected_foods:
                relevant_data = self.query_nutrition(food, k=2)
                nutrition_context.extend(relevant_data)

            # 構建提示詞
            prompt = self._build_advice_prompt(
                detected_foods,
                nutrition_context,
                user_profile,
                meal_history
            )

            # 使用 LLM Manager 生成內容（自動切換機制）
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

# 全域 RAG 服務實例
rag_service = RAGService()
