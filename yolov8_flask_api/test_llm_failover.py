"""
測試 LLM 備援切換功能
驗證 Gemini 和 LM Studio 的自動切換機制
"""
import os
import sys

# 設置 stdout 編碼為 UTF-8（解決 Windows cmd emoji 顯示問題）
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

from dotenv import load_dotenv

# 載入環境變數
load_dotenv()

# 導入 LLM Provider
from services.llm_provider import (
    get_llm_manager,
    LLMProviderType,
    GeminiProvider,
    LMStudioProvider
)
from utils.logger import logger


def print_separator(title: str = ""):
    """列印分隔線"""
    if title:
        print(f"\n{'='*60}")
        print(f"  {title}")
        print(f"{'='*60}\n")
    else:
        print(f"{'='*60}\n")


def test_individual_providers():
    """測試個別提供者"""
    print_separator("測試 1: 個別提供者測試")

    # 測試 Gemini
    print("📝 測試 Gemini Provider...")
    gemini = GeminiProvider()
    if gemini.is_available:
        print("✅ Gemini Provider 可用")
        response = gemini.generate_content(
            "請用繁體中文簡短說明香蕉的營養價值（50字內）",
            temperature=0.7,
            max_tokens=150
        )
        if response:
            print(f"✅ Gemini 回應:\n{response}\n")
        else:
            print("❌ Gemini 生成內容失敗\n")
    else:
        print(f"❌ Gemini Provider 不可用: {gemini.get_last_error()}\n")

    # 測試 LM Studio
    print("📝 測試 LM Studio Provider...")
    lm_studio = LMStudioProvider()
    if lm_studio.is_available:
        print("✅ LM Studio Provider 可用")
        response = lm_studio.generate_content(
            "Please briefly explain the nutritional value of bananas (within 50 words)",
            temperature=0.7,
            max_tokens=150
        )
        if response:
            print(f"✅ LM Studio 回應:\n{response}\n")
        else:
            print("❌ LM Studio 生成內容失敗\n")
    else:
        print(f"❌ LM Studio Provider 不可用: {lm_studio.get_last_error()}\n")


def test_llm_manager_status():
    """測試 LLM Manager 狀態"""
    print_separator("測試 2: LLM Manager 狀態檢查")

    llm_manager = get_llm_manager()

    print(f"🎯 當前提供者: {llm_manager.get_current_provider_name()}")
    print("\n📊 所有提供者狀態:")

    status = llm_manager.get_status()
    for provider_name, info in status.items():
        status_icon = "✅" if info['available'] else "❌"
        current_icon = "👉" if info['is_current'] else "  "
        print(f"  {current_icon} {status_icon} {provider_name.upper()}")
        if info['last_error']:
            print(f"     錯誤: {info['last_error']}")
    print()


def test_normal_generation():
    """測試正常情況下的生成"""
    print_separator("測試 3: 正常生成（使用當前提供者）")

    llm_manager = get_llm_manager()

    prompt = """你是一位專業的營養師，請根據以下資訊提供個性化的營養建議：

=== 本餐辨識到的食物 ===
白飯, 雞腿, 花椰菜

=== 使用者資料 ===
身高：170 cm
體重：70 kg
目標：增肌

=== 請提供 ===
1. 本餐的營養評估（熱量、營養均衡性）
2. 針對使用者目標的具體建議
3. 飲食搭配改善建議

請用繁體中文回答，簡潔專業，約150字。"""

    print("📝 測試提示詞:")
    print(prompt[:100] + "...\n")

    print("⏳ 正在生成...")
    response = llm_manager.generate_content(prompt, temperature=0.7, max_tokens=500)

    if response:
        print(f"✅ 生成成功 (使用: {llm_manager.get_current_provider_name()})")
        print(f"\n回應內容:\n{response}\n")
    else:
        print("❌ 生成失敗\n")


def test_failover_mechanism():
    """測試備援切換機制"""
    print_separator("測試 4: 備援切換機制")

    llm_manager = get_llm_manager()

    print("🔧 模擬 Gemini 失敗情況...")
    print("📝 說明: 將使用無效的 API Key 來模擬 Gemini 失敗\n")

    # 記錄原始提供者
    original_provider = llm_manager.current_provider
    print(f"原始提供者: {llm_manager.get_current_provider_name()}")

    # 如果當前是 Gemini，手動使其失敗
    gemini_provider = llm_manager.providers.get(LLMProviderType.GEMINI)
    if gemini_provider:
        # 標記為不可用
        gemini_provider.is_available = False
        print("✅ 已模擬 Gemini 失敗\n")

    # 嘗試生成內容（應該會自動切換到 LM Studio）
    print("⏳ 嘗試生成內容...")
    test_prompt = "Please briefly explain what proteins are good for muscle building."
    response = llm_manager.generate_content(test_prompt, temperature=0.7, max_tokens=200)

    if response:
        print(f"\n✅ 備援切換成功!")
        print(f"🔄 切換到: {llm_manager.get_current_provider_name()}")
        print(f"\n回應內容:\n{response}\n")
    else:
        print("\n❌ 備援切換失敗（所有提供者都不可用）\n")

    # 恢復 Gemini 狀態
    if gemini_provider:
        print("🔧 恢復 Gemini 狀態...")
        gemini_provider.initialize()


def test_force_switch():
    """測試手動切換提供者"""
    print_separator("測試 5: 手動切換提供者")

    llm_manager = get_llm_manager()

    print(f"當前提供者: {llm_manager.get_current_provider_name()}\n")

    # 嘗試切換到 LM Studio
    print("🔄 嘗試手動切換到 LM Studio...")
    success = llm_manager.force_switch_provider(LLMProviderType.LM_STUDIO)

    if success:
        print(f"✅ 切換成功: {llm_manager.get_current_provider_name()}")

        # 測試生成
        test_prompt = "What are the benefits of eating vegetables?"
        response = llm_manager.generate_content(test_prompt, temperature=0.7, max_tokens=150)

        if response:
            print(f"\n回應內容:\n{response}\n")
    else:
        print("❌ 切換失敗\n")

    # 嘗試切換回 Gemini
    print("🔄 嘗試切換回 Gemini...")
    success = llm_manager.force_switch_provider(LLMProviderType.GEMINI)

    if success:
        print(f"✅ 切換成功: {llm_manager.get_current_provider_name()}\n")
    else:
        print("❌ 切換失敗\n")


def run_all_tests():
    """執行所有測試"""
    print("\n" + "="*60)
    print("  [TEST] LLM 備援切換功能測試")
    print("="*60 + "\n")

    try:
        # 測試 1: 個別提供者
        test_individual_providers()

        # 測試 2: LLM Manager 狀態
        test_llm_manager_status()

        # 測試 3: 正常生成
        test_normal_generation()

        # 測試 4: 備援切換機制
        test_failover_mechanism()

        # 測試 5: 手動切換
        test_force_switch()

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
