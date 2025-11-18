"""
Google Search 服務 - 使用 Langchain Tools
支援 Gemini 和 Gemma（LM Studio）透過 Langchain 使用 Google Search
"""
import os
from typing import Optional, List, Dict
from langchain_community.utilities import GoogleSerperAPIWrapper
from langchain.agents import Tool, AgentType, initialize_agent
from langchain.schema import SystemMessage
from utils.logger import logger


class GoogleSearchService:
    """Google Search 服務（使用 Langchain）"""

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(GoogleSearchService, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if self._initialized:
            return

        self._initialized = True
        self.serper_api_key = os.getenv('SERPER_API_KEY')
        self.search_wrapper = None
        self.search_tool = None
        self._initialize_search()

    def _initialize_search(self):
        """初始化 Google Search 工具"""
        try:
            if not self.serper_api_key:
                logger.warning("⚠️ SERPER_API_KEY 未設置，Google Search 功能將被禁用")
                logger.info("💡 提示：前往 https://serper.dev 註冊免費 API Key")
                return

            # 初始化 Serper API Wrapper
            self.search_wrapper = GoogleSerperAPIWrapper(
                serper_api_key=self.serper_api_key,
                k=5  # 返回前 5 個搜尋結果
            )

            # 創建 Langchain Tool
            self.search_tool = Tool(
                name="google_search",
                description="搜尋 Google 以取得最新資訊。當你需要回答關於當前事件、最新資料或你不確定的問題時，使用此工具。輸入應該是一個搜尋查詢。",
                func=self.search_wrapper.run
            )

            logger.info("✅ Google Search 服務初始化成功")

        except Exception as e:
            logger.log_error_with_trace(e, "初始化 Google Search 服務")
            self.search_wrapper = None
            self.search_tool = None

    def is_available(self) -> bool:
        """檢查 Google Search 是否可用"""
        return self.search_tool is not None

    def search(self, query: str, num_results: int = 5) -> List[Dict]:
        """
        執行 Google 搜尋

        Args:
            query: 搜尋查詢
            num_results: 返回結果數量

        Returns:
            搜尋結果列表
        """
        if not self.is_available():
            logger.warning("Google Search 服務不可用")
            return []

        try:
            # 使用 Serper API 搜尋
            results = self.search_wrapper.results(query)

            # 格式化結果
            formatted_results = []

            # 處理有機搜尋結果
            if 'organic' in results:
                for item in results['organic'][:num_results]:
                    formatted_results.append({
                        'title': item.get('title', ''),
                        'link': item.get('link', ''),
                        'snippet': item.get('snippet', ''),
                    })

            logger.info(f"✅ Google Search 完成，找到 {len(formatted_results)} 個結果")
            return formatted_results

        except Exception as e:
            logger.log_error_with_trace(e, f"Google Search 失敗 (query: {query})")
            return []

    def get_search_tool(self) -> Optional[Tool]:
        """獲取 Langchain Search Tool（供 Agent 使用）"""
        return self.search_tool

    def search_and_summarize(self, query: str, context: str = "營養建議") -> str:
        """
        搜尋並返回摘要文本

        Args:
            query: 搜尋查詢
            context: 內容上下文

        Returns:
            格式化的搜尋結果摘要
        """
        results = self.search(query)

        if not results:
            return f"無法找到關於「{query}」的相關資訊。"

        # 組合搜尋結果為文本
        summary_parts = [f"根據 Google 搜尋「{query}」的結果：\n"]

        for i, result in enumerate(results, 1):
            summary_parts.append(f"{i}. {result['title']}")
            summary_parts.append(f"   {result['snippet']}")
            summary_parts.append(f"   來源: {result['link']}\n")

        return "\n".join(summary_parts)


# 全域實例
google_search_service = GoogleSearchService()
