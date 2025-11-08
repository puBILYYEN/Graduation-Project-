"""
LLM Provider 抽象層
支援多個 LLM 提供者並實作自動切換機制
包含自動翻譯功能（Gemma 3 英文輸出 → Breeze2 繁體中文）
"""
import os
import time
import requests
from abc import ABC, abstractmethod
from typing import Optional, Dict, List
from enum import Enum

# Gemini API
import google.generativeai as genai

from utils.logger import logger


class LLMProviderType(Enum):
    """LLM 提供者類型"""
    GEMINI = "gemini"
    LM_STUDIO = "lm_studio"


class BaseLLMProvider(ABC):
    """LLM 提供者抽象基類"""

    def __init__(self, provider_type: LLMProviderType):
        self.provider_type = provider_type
        self.is_available = False
        self._last_error = None

    @abstractmethod
    def initialize(self) -> bool:
        """初始化 LLM 提供者"""
        pass

    @abstractmethod
    def generate_content(self, prompt: str, **kwargs) -> Optional[str]:
        """生成內容"""
        pass

    def get_last_error(self) -> Optional[str]:
        """獲取最後一次錯誤"""
        return self._last_error

    def check_availability(self) -> bool:
        """檢查提供者是否可用"""
        return self.is_available


class GeminiProvider(BaseLLMProvider):
    """Gemini API 提供者"""

    def __init__(self, api_key: Optional[str] = None, model: str = "gemini-2.0-flash-exp"):
        super().__init__(LLMProviderType.GEMINI)
        self.api_key = api_key or os.getenv('GEMINI_API_KEY')
        self.model_name = model
        self.model = None
        self.initialize()

    def initialize(self) -> bool:
        """初始化 Gemini API"""
        try:
            if not self.api_key:
                logger.warning("GEMINI_API_KEY 未設置")
                self.is_available = False
                return False

            genai.configure(api_key=self.api_key)
            self.model = genai.GenerativeModel(self.model_name)

            # 測試連接
            test_response = self.model.generate_content("test")
            if test_response:
                self.is_available = True
                logger.info(f"✅ Gemini API ({self.model_name}) 初始化成功")
                return True

        except Exception as e:
            self._last_error = str(e)
            logger.warning(f"⚠️ Gemini API 初始化失敗: {e}")
            self.is_available = False
            return False

        return False

    def generate_content(self, prompt: str, **kwargs) -> Optional[str]:
        """使用 Gemini 生成內容"""
        if not self.is_available:
            logger.warning("Gemini API 不可用")
            return None

        try:
            temperature = kwargs.get('temperature', 0.7)
            max_tokens = kwargs.get('max_tokens', 2048)

            # Gemini API 使用 generation_config
            generation_config = {
                'temperature': temperature,
                'max_output_tokens': max_tokens,
            }

            start_time = time.time()
            response = self.model.generate_content(
                prompt,
                generation_config=generation_config
            )
            elapsed_time = time.time() - start_time

            logger.info(f"✅ Gemini 回應成功 (耗時: {elapsed_time:.2f}s)")
            return response.text

        except Exception as e:
            self._last_error = str(e)
            logger.error(f"❌ Gemini API 調用失敗: {e}")
            self.is_available = False  # 標記為不可用
            return None


class LMStudioProvider(BaseLLMProvider):
    """LM Studio 本地 API 提供者"""

    def __init__(
        self,
        base_url: Optional[str] = None,
        model: Optional[str] = None
    ):
        super().__init__(LLMProviderType.LM_STUDIO)
        self.base_url = base_url or os.getenv('LM_STUDIO_BASE_URL', 'http://127.0.0.1:1234')
        self.model_name = model or os.getenv('LM_STUDIO_MODEL', 'gemma-3-4b-it')
        self.api_url = f"{self.base_url}/v1/chat/completions"
        self.initialize()

    def initialize(self) -> bool:
        """初始化 LM Studio 連接"""
        try:
            # 測試連接
            test_url = f"{self.base_url}/v1/models"
            response = requests.get(test_url, timeout=5)

            if response.status_code == 200:
                models_data = response.json()
                available_models = [m['id'] for m in models_data.get('data', [])]

                if self.model_name in available_models:
                    self.is_available = True
                    logger.info(f"✅ LM Studio API 初始化成功 (模型: {self.model_name})")
                    return True
                else:
                    logger.warning(f"⚠️ 模型 {self.model_name} 不在可用列表中")
                    logger.info(f"可用模型: {', '.join(available_models)}")
                    # 仍標記為可用，但記錄警告
                    self.is_available = True
                    return True
            else:
                logger.warning(f"⚠️ LM Studio API 回應異常: {response.status_code}")
                self.is_available = False
                return False

        except requests.exceptions.ConnectionError:
            logger.warning("⚠️ 無法連接到 LM Studio (請確認 LM Studio 已啟動)")
            self.is_available = False
            return False
        except Exception as e:
            self._last_error = str(e)
            logger.warning(f"⚠️ LM Studio 初始化失敗: {e}")
            self.is_available = False
            return False

    def generate_content(self, prompt: str, **kwargs) -> Optional[str]:
        """使用 LM Studio 生成內容"""
        if not self.is_available:
            # 嘗試重新初始化
            if not self.initialize():
                logger.warning("LM Studio API 不可用")
                return None

        try:
            temperature = kwargs.get('temperature', 0.7)
            max_tokens = kwargs.get('max_tokens', 2048)

            # OpenAI 兼容格式
            payload = {
                "model": self.model_name,
                "messages": [
                    {"role": "user", "content": prompt}
                ],
                "temperature": temperature,
                "max_tokens": max_tokens
            }

            start_time = time.time()
            response = requests.post(
                self.api_url,
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=60  # LM Studio 本地運行可能較慢
            )
            elapsed_time = time.time() - start_time

            if response.status_code == 200:
                data = response.json()
                content = data['choices'][0]['message']['content']
                logger.info(f"✅ LM Studio 回應成功 (耗時: {elapsed_time:.2f}s)")
                return content
            else:
                self._last_error = f"HTTP {response.status_code}: {response.text}"
                logger.error(f"❌ LM Studio API 錯誤: {self._last_error}")
                return None

        except requests.exceptions.Timeout:
            self._last_error = "請求超時"
            logger.error(f"❌ LM Studio 請求超時 (>60s)")
            return None
        except Exception as e:
            self._last_error = str(e)
            logger.error(f"❌ LM Studio API 調用失敗: {e}")
            return None


class LLMManager:
    """
    LLM 管理器 - 自動切換機制
    優先使用 Gemini，失敗時自動切換到 LM Studio
    支援自動翻譯（Gemma 3 英文 → Breeze2 繁體中文）
    """

    def __init__(self):
        self.providers: Dict[LLMProviderType, BaseLLMProvider] = {}
        self.current_provider: Optional[BaseLLMProvider] = None
        self.provider_order = [LLMProviderType.GEMINI, LLMProviderType.LM_STUDIO]

        # 翻譯相關
        self.translator: Optional[BaseLLMProvider] = None
        self.translation_service = None
        self.auto_translation_enabled = os.getenv('ENABLE_AUTO_TRANSLATION', 'false').lower() == 'true'

        # 初始化所有提供者
        self._initialize_providers()

        # 選擇當前提供者
        self._select_current_provider()

        # 初始化翻譯器
        self._initialize_translator()

    def _initialize_providers(self):
        """初始化所有 LLM 提供者"""
        logger.info("=== 初始化 LLM 提供者 ===")

        # 初始化 Gemini
        gemini = GeminiProvider()
        self.providers[LLMProviderType.GEMINI] = gemini

        # 初始化 LM Studio
        lm_studio = LMStudioProvider()
        self.providers[LLMProviderType.LM_STUDIO] = lm_studio

        logger.info("=== LLM 提供者初始化完成 ===")

    def _select_current_provider(self):
        """選擇當前可用的提供者"""
        for provider_type in self.provider_order:
            provider = self.providers.get(provider_type)
            if provider and provider.check_availability():
                self.current_provider = provider
                logger.info(f"🎯 當前使用: {provider_type.value.upper()}")
                return

        logger.warning("⚠️ 沒有可用的 LLM 提供者")
        self.current_provider = None

    def _initialize_translator(self):
        """初始化翻譯器（Breeze2 模型）"""
        if not self.auto_translation_enabled:
            logger.info("⏭️ 自動翻譯功能已停用")
            return

        try:
            # 導入翻譯服務（延遲導入避免循環依賴）
            from services.translation_service import get_translation_service

            translator_model = os.getenv('TRANSLATOR_MODEL', 'llama-breeze2-8b-instruct-text')
            base_url = os.getenv('LM_STUDIO_BASE_URL', 'http://127.0.0.1:1234')

            logger.info(f"🔧 正在初始化翻譯器: {translator_model}")

            # 建立翻譯器提供者（使用 LM Studio）
            self.translator = LMStudioProvider(
                base_url=base_url,
                model=translator_model
            )

            if self.translator.is_available:
                # 設置翻譯服務
                self.translation_service = get_translation_service()
                self.translation_service.set_translator(self.translator)
                logger.info(f"✅ 翻譯器初始化成功: {translator_model}")
            else:
                logger.warning(f"⚠️ 翻譯器 {translator_model} 不可用")
                self.translator = None
                self.translation_service = None

        except Exception as e:
            logger.error(f"❌ 翻譯器初始化失敗: {e}")
            self.translator = None
            self.translation_service = None

    def generate_content(self, prompt: str, **kwargs) -> Optional[str]:
        """
        生成內容 - 自動切換機制

        Args:
            prompt: 提示詞
            **kwargs: 其他參數 (temperature, max_tokens 等)

        Returns:
            生成的內容，失敗返回 None
        """
        if not self.current_provider:
            logger.error("❌ 沒有可用的 LLM 提供者")
            return None

        # 嘗試當前提供者
        result = self.current_provider.generate_content(prompt, **kwargs)

        # 如果成功，直接返回
        if result:
            return result

        # 如果失敗，嘗試切換到備援提供者
        logger.warning(f"⚠️ {self.current_provider.provider_type.value.upper()} 失敗，嘗試切換備援...")

        for provider_type in self.provider_order:
            provider = self.providers.get(provider_type)

            # 跳過當前已失敗的提供者
            if provider == self.current_provider:
                continue

            # 檢查提供者是否可用
            if provider and provider.check_availability():
                logger.info(f"🔄 切換到備援: {provider_type.value.upper()}")

                # 嘗試使用備援提供者
                result = provider.generate_content(prompt, **kwargs)

                if result:
                    # 切換成功，更新當前提供者
                    self.current_provider = provider
                    logger.info(f"✅ 備援切換成功: {provider_type.value.upper()}")
                    return result

        # 所有提供者都失敗
        logger.error("❌ 所有 LLM 提供者都不可用")
        return None

    def get_current_provider_name(self) -> str:
        """獲取當前提供者名稱"""
        if self.current_provider:
            return self.current_provider.provider_type.value.upper()
        return "NONE"

    def get_status(self) -> Dict:
        """獲取所有提供者狀態"""
        status = {}
        for provider_type, provider in self.providers.items():
            status[provider_type.value] = {
                'available': provider.check_availability(),
                'is_current': provider == self.current_provider,
                'last_error': provider.get_last_error()
            }
        return status

    def force_switch_provider(self, provider_type: LLMProviderType) -> bool:
        """
        強制切換到指定提供者

        Args:
            provider_type: 要切換到的提供者類型

        Returns:
            切換是否成功
        """
        provider = self.providers.get(provider_type)
        if provider and provider.check_availability():
            self.current_provider = provider
            logger.info(f"🔄 手動切換到: {provider_type.value.upper()}")
            return True
        else:
            logger.warning(f"⚠️ 無法切換到 {provider_type.value.upper()} (不可用)")
            return False

    def generate_with_translation(
        self,
        prompt: str,
        context: Optional[str] = None,
        **kwargs
    ) -> Dict[str, any]:
        """
        生成內容並自動翻譯（如果需要）

        Args:
            prompt: 提示詞
            context: 內容上下文（用於翻譯）
            **kwargs: 其他參數

        Returns:
            包含以下鍵值的字典：
            - 'text': 最終文本（繁體中文）
            - 'translated': 是否進行了翻譯
            - 'original_text': 原始文本（如果有翻譯）
            - 'provider': 使用的 LLM 提供者
            - 'translator': 使用的翻譯器（如果有翻譯）
        """
        # 生成內容
        result = self.generate_content(prompt, **kwargs)

        if not result:
            return {
                'text': None,
                'translated': False,
                'original_text': None,
                'provider': self.get_current_provider_name(),
                'translator': None,
                'error': '生成失敗'
            }

        # 如果翻譯功能未啟用或翻譯服務不可用，直接返回原始結果
        if not self.auto_translation_enabled or not self.translation_service:
            return {
                'text': result,
                'translated': False,
                'original_text': None,
                'provider': self.get_current_provider_name(),
                'translator': None
            }

        # 自動翻譯
        translation_result = self.translation_service.auto_translate_if_needed(
            result,
            context=context
        )

        return {
            'text': translation_result['text'],
            'translated': translation_result['translated'],
            'original_text': translation_result.get('original_text'),
            'provider': self.get_current_provider_name(),
            'translator': self.translator.model_name if self.translator else None
        }


# 全域 LLM 管理器實例（單例模式）
_llm_manager_instance = None

def get_llm_manager() -> LLMManager:
    """獲取 LLM 管理器實例（單例）"""
    global _llm_manager_instance
    if _llm_manager_instance is None:
        _llm_manager_instance = LLMManager()
    return _llm_manager_instance
