#!/bin/bash

# ==============================================================================
# Cloud Run 部署腳本 - 啟用 WebSocket 支援
# ==============================================================================

set -e  # 遇到錯誤立即退出

# 設定變數
PROJECT_ID="fooddata-92fa8"
REGION="asia-east1"
SERVICE_NAME="nutrition-api"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

echo "=========================================="
echo "🚀 開始部署 ${SERVICE_NAME} 到 Cloud Run"
echo "=========================================="

# 1. 設定專案
echo "📋 設定 GCP 專案: ${PROJECT_ID}"
gcloud config set project ${PROJECT_ID}

# 2. 建立 Docker 映像
echo ""
echo "🐳 建立 Docker 映像..."
gcloud builds submit --tag ${IMAGE_NAME} .

# 3. 部署到 Cloud Run (重要：啟用 HTTP/2 端到端)
echo ""
echo "☁️ 部署到 Cloud Run (啟用 WebSocket)..."
gcloud run deploy ${SERVICE_NAME} \
  --image ${IMAGE_NAME} \
  --platform managed \
  --region ${REGION} \
  --allow-unauthenticated \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --max-instances 20 \
  --min-instances 0 \
  --set-env-vars "FLASK_ENV=production" \
  --use-http2

# 4. 獲取服務 URL
echo ""
echo "✅ 部署完成！"
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format='value(status.url)')
echo "🌐 服務 URL: ${SERVICE_URL}"

# 5. 測試健康檢查
echo ""
echo "🔍 測試健康檢查..."
curl -s ${SERVICE_URL}/health | jq .

echo ""
echo "=========================================="
echo "✅ 部署成功完成！"
echo "=========================================="
echo ""
echo "📝 重要提示："
echo "1. WebSocket 連接現已啟用 (HTTP/2)"
echo "2. Socket.IO 端點: ${SERVICE_URL}"
echo "3. 測試連接: ${SERVICE_URL}/health"
echo ""
