"""
翻譯服務模組
自動將英文輸出翻譯成繁體中文
用於 Gemma 3 視覺模型的中文化處理
"""
import re
from typing import Optional, Dict
from utils.logger import logger


class TranslationService:
    """
    翻譯服務
    負責偵測語言並自動翻譯成繁體中文
    """

    def __init__(self):
        self.translator_provider = None  # 將由 LLM Manager 設置

    def set_translator(self, translator):
        """
        設置翻譯提供者

        Args:
            translator: LLM Provider 實例（通常是 Breeze2）
        """
        self.translator_provider = translator
        logger.info(f"✅ 翻譯器已設置: {translator.provider_type.value if translator else 'None'}")

    def detect_language(self, text: str) -> str:
        """
        偵測文本語言

        Args:
            text: 要偵測的文本

        Returns:
            'zh' (中文) 或 'en' (英文) 或 'mixed' (混合)
        """
        if not text or len(text.strip()) == 0:
            return 'unknown'

        # 計算中文字符比例
        chinese_chars = len(re.findall(r'[\u4e00-\u9fff]', text))
        total_chars = len(re.sub(r'\s', '', text))  # 移除空白後的總字符數

        if total_chars == 0:
            return 'unknown'

        chinese_ratio = chinese_chars / total_chars

        # 判斷語言
        if chinese_ratio > 0.3:  # 中文字符超過 30%
            return 'zh'
        elif chinese_ratio < 0.1:  # 中文字符少於 10%
            return 'en'
        else:
            return 'mixed'

    def translate_to_chinese(
        self,
        text: str,
        context: Optional[str] = None,
        preserve_format: bool = True
    ) -> Optional[str]:
        """
        將英文翻譯成繁體中文

        Args:
            text: 要翻譯的英文文本
            context: 翻譯上下文（例如：營養建議、食物分析等）
            preserve_format: 是否保留原始格式（換行、編號等）

        Returns:
            繁體中文翻譯，失敗返回 None
        """
        if not self.translator_provider:
            logger.warning("⚠️ 翻譯器未設置，無法翻譯")
            return None

        if not self.translator_provider.is_available:
            logger.warning("⚠️ 翻譯器不可用")
            return None

        try:
            # 構建翻譯提示詞
            prompt = self._build_translation_prompt(text, context, preserve_format)

            # 調用翻譯器
            logger.info("🔄 正在翻譯成繁體中文...")
            translated = self.translator_provider.generate_content(
                prompt,
                temperature=0.3,  # 低溫度確保準確翻譯
                max_tokens=2048
            )

            if translated:
                logger.info(f"✅ 翻譯完成 (原文長度: {len(text)}, 譯文長度: {len(translated)})")
                return translated
            else:
                logger.error("❌ 翻譯失敗")
                return None

        except Exception as e:
            logger.error(f"❌ 翻譯過程發生錯誤: {e}")
            return None

    def _build_translation_prompt(
        self,
        text: str,
        context: Optional[str],
        preserve_format: bool
    ) -> str:
        """構建翻譯提示詞"""

        prompt_parts = [
            "你是一位專業的翻譯專家，專精於英文到繁體中文的翻譯。",
            "",
            "【翻譯要求】",
            "1. 將以下英文內容翻譯成流暢自然的繁體中文",
            "2. 保持專業術語的準確性",
            "3. 確保語意完整、語氣一致",
        ]

        if preserve_format:
            prompt_parts.append("4. 保留原文的格式結構（標題、編號、列表、換行等）")

        if context:
            prompt_parts.append(f"5. 翻譯領域：{context}")

        prompt_parts.extend([
            "",
            "【重要】",
            "- 只輸出翻譯後的繁體中文內容",
            "- 不要添加任何解釋或說明",
            "- 不要保留英文原文",
            "",
            "【待翻譯內容】",
            text,
            "",
            "【繁體中文翻譯】"
        ])

        return "\n".join(prompt_parts)

    def auto_translate_if_needed(
        self,
        text: str,
        context: Optional[str] = None,
        force_translate: bool = False
    ) -> Dict[str, any]:
        """
        自動偵測並翻譯（如果需要）

        Args:
            text: 原始文本
            context: 內容上下文
            force_translate: 強制翻譯（即使偵測到中文）

        Returns:
            包含以下鍵值的字典：
            - 'text': 最終文本（中文）
            - 'translated': 是否進行了翻譯（True/False）
            - 'original_language': 原始語言
            - 'original_text': 原始文本（如果有翻譯）
        """
        if not text:
            return {
                'text': text,
                'translated': False,
                'original_language': 'unknown',
                'original_text': None
            }

        # 偵測語言
        detected_lang = self.detect_language(text)
        logger.info(f"🔍 偵測語言: {detected_lang}")

        # 判斷是否需要翻譯
        needs_translation = force_translate or detected_lang == 'en'

        if not needs_translation:
            logger.info("✅ 文本已是中文，無需翻譯")
            return {
                'text': text,
                'translated': False,
                'original_language': detected_lang,
                'original_text': None
            }

        # 執行翻譯
        logger.info(f"🔄 偵測到英文內容，開始翻譯... (上下文: {context or '通用'})")
        translated_text = self.translate_to_chinese(text, context, preserve_format=True)

        if translated_text:
            return {
                'text': translated_text,
                'translated': True,
                'original_language': detected_lang,
                'original_text': text
            }
        else:
            logger.warning("⚠️ 翻譯失敗，返回原始文本")
            return {
                'text': text,
                'translated': False,
                'original_language': detected_lang,
                'original_text': None
            }


# 全域翻譯服務實例（單例模式）
_translation_service_instance = None

def get_translation_service() -> TranslationService:
    """獲取翻譯服務實例（單例）"""
    global _translation_service_instance
    if _translation_service_instance is None:
        _translation_service_instance = TranslationService()
    return _translation_service_instance
