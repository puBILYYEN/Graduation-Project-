"""
測試翻譯管道功能
驗證 Gemma 3 (英文) → Breeze2 (繁體中文) 自動翻譯流程
"""
import os
import sys

# 設置 stdout 編碼為 UTF-8
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

from dotenv import load_dotenv

# 載入環境變數
load_dotenv()

from services.llm_provider import get_llm_manager
from services.translation_service import get_translation_service
from utils.logger import logger


def print_separator(title: str = ""):
    """列印分隔線"""
    if title:
        print(f"\n{'='*60}")
        print(f"  {title}")
        print(f"{'='*60}\n")
    else:
        print(f"{'='*60}\n")


def test_language_detection():
    """測試語言偵測功能"""
    print_separator("測試 1: 語言偵測功能")

    translation_service = get_translation_service()

    test_cases = [
        ("This is an English sentence.", "en"),
        ("這是一個繁體中文句子。", "zh"),
        ("This sentence has 一些中文 mixed in.", "mixed"),
        ("Bananas are rich in potassium.", "en"),
        ("香蕉富含鉀，有助於維持血壓平衡。", "zh"),
    ]

    for text, expected in test_cases:
        detected = translation_service.detect_language(text)
        status = "✅" if detected == expected else "❌"
        print(f"{status} 文本: {text[:50]}...")
        print(f"   偵測: {detected}, 預期: {expected}\n")


def test_translation():
    """測試翻譯功能"""
    print_separator("測試 2: 英文 → 繁體中文翻譯")

    llm_manager = get_llm_manager()

    # 檢查翻譯器是否可用
    if not llm_manager.translator or not llm_manager.translator.is_available:
        print("❌ 翻譯器不可用，跳過測試")
        return

    translation_service = get_translation_service()

    # 測試文本
    english_text = """
Bananas are a good source of potassium, essential for heart health and muscle function.
They also provide carbohydrates for energy, along with fiber for digestion and vitamins like B6 and C.
A medium banana offers around 105 calories and key nutrients!
"""

    print("📝 原始英文文本:")
    print(english_text)
    print()

    print("⏳ 正在翻譯...")
    translated = translation_service.translate_to_chinese(
        english_text,
        context="營養資訊",
        preserve_format=True
    )

    if translated:
        print("✅ 翻譯成功！")
        print("\n📝 繁體中文翻譯:")
        print(translated)
        print()
    else:
        print("❌ 翻譯失敗")


def test_auto_translation():
    """測試自動翻譯（偵測後翻譯）"""
    print_separator("測試 3: 自動翻譯（語言偵測 + 翻譯）")

    llm_manager = get_llm_manager()

    if not llm_manager.auto_translation_enabled:
        print("⚠️ 自動翻譯功能已停用（ENABLE_AUTO_TRANSLATION=false）")
        return

    if not llm_manager.translation_service:
        print("❌ 翻譯服務不可用，跳過測試")
        return

    translation_service = llm_manager.translation_service

    # 測試案例 1: 英文文本（需要翻譯）
    print("📋 測試案例 1: 英文文本")
    english_text = "Chicken is an excellent source of lean protein, providing essential amino acids for muscle building and repair."

    result = translation_service.auto_translate_if_needed(english_text, context="營養建議")

    print(f"原始文本: {english_text}")
    print(f"偵測語言: {result['original_language']}")
    print(f"是否翻譯: {result['translated']}")
    print(f"最終文本: {result['text']}")
    print()

    # 測試案例 2: 中文文本（不需翻譯）
    print("📋 測試案例 2: 中文文本")
    chinese_text = "雞肉是優質的蛋白質來源，提供肌肉生長所需的必需胺基酸。"

    result = translation_service.auto_translate_if_needed(chinese_text, context="營養建議")

    print(f"原始文本: {chinese_text}")
    print(f"偵測語言: {result['original_language']}")
    print(f"是否翻譯: {result['translated']}")
    print(f"最終文本: {result['text']}")
    print()


def test_full_pipeline():
    """測試完整翻譯管道（LLM Manager）"""
    print_separator("測試 4: 完整翻譯管道（Gemini → Breeze2）")

    llm_manager = get_llm_manager()

    if not llm_manager.auto_translation_enabled:
        print("⚠️ 自動翻譯功能已停用")
        return

    # 模擬營養師問題（英文提示詞）
    prompt = """
You are a professional nutritionist. Based on the following information, provide personalized nutrition advice:

=== Detected Foods ===
White rice, Chicken leg, Broccoli

=== User Profile ===
Height: 170 cm
Weight: 70 kg
Goal: Muscle building

=== Please Provide ===
1. Nutritional assessment (calories, nutritional balance)
2. Specific recommendations for the user's goal
3. Dietary pairing improvement suggestions

Please answer in English, concise and professional, about 150 words.
"""

    print("📝 提示詞（英文）:")
    print(prompt[:200] + "...\n")

    print("⏳ 正在生成內容並自動翻譯...")

    # 使用帶翻譯的生成方法
    result = llm_manager.generate_with_translation(
        prompt,
        context="營養建議",
        temperature=0.7,
        max_tokens=500
    )

    if result['text']:
        print(f"✅ 生成成功！")
        print(f"📊 提供者: {result['provider']}")
        print(f"🔄 是否翻譯: {result['translated']}")
        if result['translated']:
            print(f"🌐 翻譯器: {result['translator']}")
            print(f"\n📝 原始英文:")
            print(result['original_text'][:200] + "..." if len(result['original_text']) > 200 else result['original_text'])
        print(f"\n📝 最終繁體中文:")
        print(result['text'])
        print()
    else:
        print("❌ 生成失敗")
        if 'error' in result:
            print(f"錯誤: {result['error']}")


def test_gemini_english_output():
    """測試 Gemini 英文輸出 + 自動翻譯"""
    print_separator("測試 5: Gemini 英文輸出 + Breeze2 翻譯")

    llm_manager = get_llm_manager()

    if not llm_manager.auto_translation_enabled:
        print("⚠️ 自動翻譯功能已停用")
        return

    # 使用英文提示詞確保 Gemini 輸出英文
    prompt = "Explain the nutritional benefits of eating vegetables in 50 words (in English)."

    print(f"📝 提示詞: {prompt}\n")
    print("⏳ 正在生成並翻譯...\n")

    result = llm_manager.generate_with_translation(
        prompt,
        context="營養資訊",
        temperature=0.7,
        max_tokens=150
    )

    if result['text']:
        print(f"✅ 完成！")
        print(f"📊 LLM: {result['provider']}")
        print(f"🔄 翻譯: {result['translated']}")

        if result['translated']:
            print(f"\n📝 原始英文 ({result['provider']}):")
            print(result['original_text'])
            print(f"\n📝 翻譯後繁體中文 ({result['translator']}):")
            print(result['text'])
        else:
            print(f"\n📝 輸出 (無需翻譯):")
            print(result['text'])
        print()
    else:
        print("❌ 失敗")


def run_all_tests():
    """執行所有測試"""
    print("\n" + "="*60)
    print("  [TEST] 翻譯管道功能測試")
    print("  Gemma 3 (英文) → Breeze2 (繁體中文)")
    print("="*60 + "\n")

    try:
        # 測試 1: 語言偵測
        test_language_detection()

        # 測試 2: 翻譯功能
        test_translation()

        # 測試 3: 自動翻譯
        test_auto_translation()

        # 測試 4: 完整管道
        test_full_pipeline()

        # 測試 5: Gemini 英文 + 翻譯
        test_gemini_english_output()

        print_separator("測試完成")
        print("✅ 所有測試執行完畢\n")

    except KeyboardInterrupt:
        print("\n\n⚠️ 測試被使用者中斷\n")
    except Exception as e:
        print(f"\n\n❌ 測試過程中發生錯誤: {e}\n")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    run_all_tests()
