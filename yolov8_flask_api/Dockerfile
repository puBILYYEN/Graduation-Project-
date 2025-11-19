# ====================================================================
# Dockerfile for Flask YOLOv8 API - GCP Cloud Run 優化版本
# ====================================================================

# 使用 Python 3.12 slim 版本（減少映像大小）
FROM python:3.12-slim

# 設定工作目錄
WORKDIR /app

# 設定環境變數（不包含 offline 模式，下載時需要網路）
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    HF_HOME=/app/models_cache \
    TRANSFORMERS_CACHE=/app/models_cache \
    SENTENCE_TRANSFORMERS_HOME=/app/models_cache \
    TORCH_FORCE_WEIGHTS_ONLY_LOAD=0

# 安裝系統依賴（OpenCV 和其他需要的套件）
RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgthread-2.0-0 \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# 複製 requirements.txt 並安裝 Python 依賴
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 預先下載機器學習模型（在複製完整應用程式前執行以利用 Docker 快取）
COPY download_models.py .
RUN python download_models.py

# 模型下載完成後，啟用離線模式（防止 runtime 時嘗試連線 huggingface.co）
ENV TRANSFORMERS_OFFLINE=1 \
    HF_HUB_OFFLINE=1

# 複製向量資料庫 (重要！加速啟動)
COPY knowledge-base /app/knowledge-base/

# 複製應用程式代碼和資源
COPY . .

# 創建必要的目錄
RUN mkdir -p static logs

# 暴露端口（Cloud Run 會動態分配，但我們預設 8080）
EXPOSE 8080

# 健康檢查（可選）
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8080/', timeout=5)"

# 啟動應用程式
# Cloud Run 會設定 PORT 環境變數，我們需要使用它
# 使用 gevent worker（用於 Socket.IO polling 模式）
CMD exec gunicorn --worker-class gevent -w 1 --bind 0.0.0.0:$PORT --timeout 0 --preload app_final:app
