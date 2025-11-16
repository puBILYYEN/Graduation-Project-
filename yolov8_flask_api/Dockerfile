# ====================================================================
# Dockerfile for Flask YOLOv8 API - GCP Cloud Run 優化版本
# ====================================================================

# 使用 Python 3.12 slim 版本（減少映像大小）
FROM python:3.12-slim

# 設定工作目錄
WORKDIR /app

# 設定環境變數
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

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

# 複製應用程式代碼和資源
COPY . .

# 創建必要的目錄
RUN mkdir -p static logs knowledge-base

# 暴露端口（Cloud Run 會動態分配，但我們預設 8080）
EXPOSE 8080

# 健康檢查（可選）
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8080/', timeout=5)"

# 啟動應用程式
# Cloud Run 會設定 PORT 環境變數，我們需要使用它
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 app_final:app
