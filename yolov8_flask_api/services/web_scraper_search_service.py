"""
Web Scraper Google Search 服務（免費，無需 API）
使用 requests + BeautifulSoup 抓取 Google 搜尋結果
類似 Puppeteer 的網頁抓取功能
"""
import requests
from bs4 import BeautifulSoup
from typing import List, Dict, Optional
import time
import random
from urllib.parse import quote_plus
from utils.logger import logger


class WebScraperSearchService:
    """Google Search 網頁抓取服務（免費替代方案）"""

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(WebScraperSearchService, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if self._initialized:
            return

        self._initialized = True

        # 模擬真實瀏覽器的 User-Agent
        self.user_agents = [
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
        ]

        logger.info("✅ Web Scraper Google Search 服務初始化成功（免費方案）")

    def is_available(self) -> bool:
        """檢查服務是否可用（網頁抓取總是可用）"""
        return True

    def _get_random_user_agent(self) -> str:
        """隨機選擇一個 User-Agent"""
        return random.choice(self.user_agents)

    def search(self, query: str, num_results: int = 5, lang: str = 'zh-TW') -> List[Dict]:
        """
        使用網頁抓取執行 Google 搜尋（免費，無需 API）

        Args:
            query: 搜尋查詢
            num_results: 返回結果數量
            lang: 語言設定

        Returns:
            搜尋結果列表
        """
        try:
            # 編碼搜尋查詢
            encoded_query = quote_plus(query)

            # Google 搜尋 URL
            url = f"https://www.google.com/search?q={encoded_query}&hl={lang}&num={num_results + 5}"

            # 設定請求標頭（模擬真實瀏覽器）
            headers = {
                'User-Agent': self._get_random_user_agent(),
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                'Accept-Language': f'{lang},zh;q=0.9,en;q=0.8',
                'Accept-Encoding': 'gzip, deflate, br',
                'Connection': 'keep-alive',
                'Upgrade-Insecure-Requests': '1',
            }

            logger.info(f"🔍 正在使用網頁抓取搜尋：{query}")

            # 發送請求
            response = requests.get(url, headers=headers, timeout=10)
            response.raise_for_status()

            # 解析 HTML
            soup = BeautifulSoup(response.text, 'lxml')

            # 提取搜尋結果
            results = []

            # Google 搜尋結果的主要容器（多種可能的選擇器）
            # 新版 Google 使用 <div class="g"> 或 <div data-sokoban-container>
            search_results = soup.find_all('div', class_='g')

            if not search_results:
                # 備用選擇器
                search_results = soup.find_all('div', {'data-sokoban-container': True})

            for result in search_results[:num_results]:
                try:
                    # 提取標題
                    title_elem = result.find('h3')
                    if not title_elem:
                        continue
                    title = title_elem.get_text(strip=True)

                    # 提取連結
                    link_elem = result.find('a')
                    if not link_elem or 'href' not in link_elem.attrs:
                        continue
                    link = link_elem['href']

                    # 提取摘要（snippet）
                    # 嘗試多種可能的摘要選擇器
                    snippet = ''
                    snippet_elem = result.find('div', class_='VwiC3b') or \
                                   result.find('span', class_='aCOpRe') or \
                                   result.find('div', class_='s')

                    if snippet_elem:
                        snippet = snippet_elem.get_text(strip=True)

                    # 過濾無效結果
                    if title and link and not link.startswith('/search'):
                        results.append({
                            'title': title,
                            'link': link,
                            'snippet': snippet or '（無摘要）',
                        })

                except Exception as e:
                    logger.warning(f"⚠️ 解析單個搜尋結果時出錯: {e}")
                    continue

            logger.info(f"✅ 網頁抓取完成，找到 {len(results)} 個結果")
            return results

        except requests.exceptions.Timeout:
            logger.error("❌ Google Search 請求超時")
            return []
        except requests.exceptions.RequestException as e:
            logger.error(f"❌ Google Search 請求失敗: {e}")
            return []
        except Exception as e:
            logger.log_error_with_trace(e, f"網頁抓取 Google Search (query: {query})")
            return []

    def search_and_summarize(self, query: str, context: str = "營養建議") -> str:
        """
        搜尋並返回摘要文本

        Args:
            query: 搜尋查詢
            context: 內容上下文

        Returns:
            格式化的搜尋結果摘要
        """
        # 添加隨機延遲，避免被 Google 封鎖
        time.sleep(random.uniform(1, 3))

        results = self.search(query)

        if not results:
            return f"無法找到關於「{query}」的相關資訊。"

        # 組合搜尋結果為文本
        summary_parts = [f"根據 Google 搜尋「{query}」的結果：\n"]

        for i, result in enumerate(results, 1):
            summary_parts.append(f"{i}. {result['title']}")
            if result['snippet']:
                summary_parts.append(f"   {result['snippet']}")
            summary_parts.append(f"   來源: {result['link']}\n")

        return "\n".join(summary_parts)


# 全域實例
web_scraper_search_service = WebScraperSearchService()
