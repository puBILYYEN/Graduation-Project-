"""
PyTorch 2.6+ 權重載入修復腳本
在主應用程式啟動前執行此腳本以設定安全全域變數
"""
import torch
import torch.serialization

def setup_pytorch_safe_globals():
    """設定 PyTorch 安全全域變數以允許 ultralytics 模型載入"""
    try:
        # 導入 ultralytics 模型類別
        from ultralytics.nn.tasks import DetectionModel, SegmentationModel, ClassificationModel

        # 導入 ultralytics 模組 - 這是錯誤訊息中缺少的關鍵部分
        from ultralytics.nn.modules.conv import Conv
        from ultralytics.nn.modules.block import C2f, SPPF, Bottleneck

        # 導入常用的 PyTorch 模組類別
        from torch.nn.modules.container import Sequential
        from torch.nn.modules.linear import Linear
        from torch.nn.modules.conv import Conv2d
        from torch.nn.modules.batchnorm import BatchNorm2d
        from torch.nn.modules.activation import ReLU, SiLU
        from torch.nn.modules.pooling import MaxPool2d
        from torch.nn.modules.upsampling import Upsample

        # 添加所有必要的安全全域變數
        torch.serialization.add_safe_globals([
            # Ultralytics 模型
            DetectionModel,
            SegmentationModel,
            ClassificationModel,
            # Ultralytics 模組（關鍵修復 - 包含 Conv）
            Conv,
            C2f,
            SPPF,
            Bottleneck,
            # PyTorch 容器
            Sequential,
            # PyTorch 層
            Linear,
            Conv2d,
            BatchNorm2d,
            MaxPool2d,
            Upsample,
            # PyTorch 激活函數
            ReLU,
            SiLU
        ])
        print('[PyTorch Fix] 已添加 ultralytics 模組（包含 Conv）和 PyTorch 核心類別到安全全域變數')
        return True
    except ImportError as e:
        print(f'[PyTorch Fix] 無法導入必要類別: {e}')
        print('[PyTorch Fix] 將依賴 ultralytics 內部的 weights_only 處理')
        return False
    except Exception as e:
        print(f'[PyTorch Fix] 設定安全全域變數時發生錯誤: {e}')
        return False

# 自動執行修復
if __name__ == "__main__":
    setup_pytorch_safe_globals()
else:
    # 當被導入時自動執行
    setup_pytorch_safe_globals()
