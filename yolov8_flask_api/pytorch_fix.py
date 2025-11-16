"""
PyTorch 2.6+ 權重載入修復腳本
在主應用程式啟動前執行此腳本以設定安全全域變數
"""
import torch
import torch.serialization

def setup_pytorch_safe_globals():
    """設定 PyTorch 安全全域變數以允許 ultralytics 模型載入"""
    try:
        from ultralytics.nn.tasks import DetectionModel, SegmentationModel, ClassificationModel
        torch.serialization.add_safe_globals([
            DetectionModel,
            SegmentationModel,
            ClassificationModel
        ])
        print("[PyTorch Fix] 已添加 ultralytics 安全全域變數")
        return True
    except ImportError as e:
        print(f"[PyTorch Fix] 無法導入 ultralytics 類別: {e}")
        print("[PyTorch Fix] 將依賴 ultralytics 內部的 weights_only 處理")
        return False
    except Exception as e:
        print(f"[PyTorch Fix] 設定安全全域變數時發生錯誤: {e}")
        return False

# 自動執行修復
if __name__ == "__main__":
    setup_pytorch_safe_globals()
else:
    # 當被導入時自動執行
    setup_pytorch_safe_globals()
