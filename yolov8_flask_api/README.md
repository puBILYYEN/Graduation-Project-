# 營養知識 RAG 系統 - Flask 後端

完整的客製化營養知識系統，整合 YOLO、Firebase、Langchain、Chroma、Gemini 和 Socket.IO

## 系統架構

```
使用者手機 App (Flutter)
    ↓ 拍照
YOLO 食物辨識
    ↓ 辨識結果
Firebase (存儲用戶資料、用餐記錄、營養資料)
    ↓ 資料傳遞
Flask 後端
    ├─ Langchain + Chroma 向量資料庫
    ├─ Gemini RAG 分析
    └─ Socket.IO 即時通訊
    ↓ 回傳
Flutter App 顯示個性化建議
    ↓ 所有操作
.log 日誌檔案
```

## 核心功能

### 1. YOLO 食物辨識
- 使用自訓練的 YOLOv8 模型
- 支援 88+ 種台灣常見食物
- 即時辨識並標註

### 2. Chroma 向量資料庫
- ✅ **使用 cosine 作為度量方式** (`metadata={"hnsw:space": "cosine"}`)
- 儲存超過 3000+ 筆營養資料
- 支援相似度搜尋
- 基於 `Chatbot_Chroma.ipynb`

### 3. Gemini RAG 系統
- **不使用 OpenAI**，完全採用 Google Gemini API
- 個性化營養建議
- 根據用戶資料和用餐歷史生成建議

### 4. Firebase 整合
- 用戶資料管理
- 用餐記錄儲存
- 營養資料庫
- 圖片儲存

### 5. Socket.IO 即時通訊
- 雙向即時通訊
- RAG 問答
- 營養數據傳輸

### 6. 完整日誌系統
- 所有操作記錄到 `.log` 檔案
- 旋轉日誌（10MB per file，保留 5 個備份）
- 詳細的錯誤追蹤

## 安裝步驟

### 1. 環境需求

```bash
Python 3.8+
pip
```

### 2. 安裝依賴

```bash
cd C:\Users\pop90\flutter_code\flutter_application_1\yolov8_flask_api
pip install -r requirements.txt
```

### 3. 設置環境變數

複製 `.env.example` 為 `.env`：

```bash
copy .env.example .env
```

編輯 `.env` 檔案：

```env
# Gemini API 設定
GEMINI_API_KEY=你的_Gemini_API_金鑰

# Firebase 設定
FIREBASE_CREDENTIALS_PATH=firebase-credentials.json

# Flask 設定
FLASK_ENV=development
FLASK_DEBUG=True
FLASK_HOST=0.0.0.0
FLASK_PORT=5000

# 日誌設定
LOG_LEVEL=INFO
LOG_FILE=app.log

# YOLO 模型設定
YOLO_MODEL_PATH=初試v2.pt
YOLO_CLASSES_PATH=classes.txt
```

### 4. 設置 Firebase

1. 從 Firebase Console 下載服務帳戶金鑰
2. 將檔案重命名為 `firebase-credentials.json`
3. 放置在專案根目錄

### 5. 營養資料庫設置

系統會自動從以下來源載入營養資料：
- `D:\靜宜大學資料夾\畢業專題\UTF-8\食品營養成分資料庫2024UPDATE2.csv`
- `C:\Users\pop90\OneDrive\桌面\食物資料庫\食品營養成分資料庫2024_UPDATE1.csv`

## 啟動系統

### 方式 1: 直接運行

```bash
python app_final.py
```

### 方式 2: 使用開發模式

```bash
set FLASK_DEBUG=True
python app_final.py
```

### 方式 3: 使用生產模式

```bash
set FLASK_ENV=production
set FLASK_DEBUG=False
python app_final.py
```

## API 端點

### 1. 健康檢查
```http
GET /health
```

回應：
```json
{
  "status": "healthy",
  "timestamp": "2025-11-07T...",
  "services": {
    "yolo": true,
    "firebase": true,
    "rag": true,
    "vector_store": true,
    "nutrition_data": 3245
  }
}
```

### 2. YOLO 圖片辨識（原始端點）
```http
POST /predict
Content-Type: multipart/form-data

image: [圖片檔案]
```

回應：
```json
{
  "predictions": [
    {
      "class_id": 0,
      "class_name": "white_rice",
      "confidence": 0.95
    }
  ],
  "image_path": "/static/output_xxx.jpg",
  "gemini_reply": "辨識到白米...",
  "diet_advice": "建議搭配...",
  "timestamp": "2025-11-07T..."
}
```

### 3. 個性化營養分析（使用 Chroma RAG）
```http
POST /analyze_nutrition
Content-Type: multipart/form-data

image: [圖片檔案]
user_id: [使用者ID] (選填)
```

回應：
```json
{
  "predictions": [...],
  "detected_foods": ["white_rice", "fried_chicken"],
  "personalized_advice": "根據您的身高體重...",
  "user_profile": {...},
  "meal_history": [...],
  "timestamp": "2025-11-07T..."
}
```

### 4. RAG 查詢
```http
POST /rag_query
Content-Type: application/json

{
  "question": "白米的營養成分有哪些？"
}
```

回應：
```json
{
  "question": "白米的營養成分有哪些？",
  "answer": "白米主要含有...",
  "timestamp": "2025-11-07T..."
}
```

## Socket.IO 事件

### 連接

```javascript
socket.on('connect', () => {
  console.log('已連接');
});
```

### RAG 問答

發送問題：
```javascript
socket.emit('rag_question', {
  question: '請問雞蛋的營養價值？',
  user_id: 'user123' // 選填
});
```

接收回應：
```javascript
socket.on('rag_response', (data) => {
  console.log(data.question);
  console.log(data.answer);
});
```

### 營養數據傳輸

```javascript
socket.emit('nutrition_data', {
  user_id: 'user123',
  foods: ['white_rice', 'chicken'],
  timestamp: '2025-11-07T...'
});

socket.on('nutrition_data_received', (data) => {
  console.log(data.status); // 'success'
});
```

## 專案結構

```
yolov8_flask_api/
├── app.py                      # 原始程式
├── app_enhanced.py             # 增強版（FAISS）
├── app_final.py               # 最終版（Chroma）⭐
├── requirements.txt           # Python 依賴
├── .env                       # 環境變數配置
├── .env.example              # 環境變數範例
├── classes.txt               # YOLO 類別名稱
├── 初試v2.pt                 # YOLO 模型權重
│
├── utils/
│   └── logger.py             # 日誌管理器
│
├── services/
│   ├── firebase_service.py          # Firebase 服務
│   ├── rag_service.py               # RAG 服務（FAISS）
│   ├── rag_service_chroma.py        # RAG 服務（Chroma）⭐
│   └── nutrition_data_manager.py    # 營養資料管理
│
├── static/                   # 上傳圖片存放
├── logs/                     # 日誌檔案存放
├── knowledge-base/           # Chroma 向量資料庫
│
├── templates/
│   └── index.html           # 首頁模板（選用）
│
└── README.md                # 本文件
```

## Chroma 向量資料庫說明

### 配置

基於 `Chatbot_Chroma.ipynb`，系統使用以下配置：

```python
# 向量資料庫存放目錄
persist_directory = "knowledge-base"

# 集合名稱
collection_name = "nutrition-knowledge"

# 重要：使用 cosine 作為度量方式
metadata = {"hnsw:space": "cosine"}  # ✅ 不使用預設的 "l2"
```

### 嵌入模型

不使用 OpenAI，改用 HuggingFace：

```python
embeddings = HuggingFaceEmbeddings(
    model_name="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
    model_kwargs={'device': 'cpu'},
    encode_kwargs={'normalize_embeddings': True}
)
```

### 文檔分割

```python
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=0
)
```

## 日誌系統

所有操作都會記錄到 `.log` 檔案：

### 日誌位置
```
logs/app_YYYYMMDD.log
```

### 日誌格式
```
[2025-11-07 14:23:45] [INFO] [app_final] API 請求: POST /analyze_nutrition
[2025-11-07 14:23:46] [INFO] [rag_service_chroma] RAG 查詢: 白米的營養... | 回應長度: 245 字元
```

### 日誌類型
- API 請求記錄
- YOLO 預測記錄
- Firebase 操作記錄
- RAG 查詢記錄
- Socket 事件記錄
- 錯誤追蹤

## 開發提示

### 測試 API

使用 curl：
```bash
# 健康檢查
curl http://localhost:5000/health

# 圖片辨識
curl -X POST -F "image=@test.jpg" http://localhost:5000/predict

# RAG 查詢
curl -X POST -H "Content-Type: application/json" -d "{\"question\":\"白米的營養成分？\"}" http://localhost:5000/rag_query
```

### 查看日誌

```bash
# 即時查看日誌
tail -f logs/app_20251107.log

# Windows
type logs\app_20251107.log
```

### 重建向量資料庫

刪除舊的向量資料庫：
```bash
rm -rf knowledge-base
```

重新啟動應用即可自動重建。

## 疑難排解

### 問題 1: Chroma 初始化失敗

**錯誤**: `Cannot initialize Chroma`

**解決方案**:
```bash
pip install --upgrade chromadb langchain-chroma
```

### 問題 2: 營養資料載入失敗

**錯誤**: `找不到營養資料檔案`

**解決方案**:
確認以下路徑的檔案存在：
- `D:\靜宜大學資料夾\畢業專題\UTF-8\食品營養成分資料庫2024UPDATE2.csv`

### 問題 3: Gemini API 錯誤

**錯誤**: `Gemini API KEY not set`

**解決方案**:
在 `.env` 設定正確的 API 金鑰：
```env
GEMINI_API_KEY=你的_API_金鑰
```

### 問題 4: Firebase 連接失敗

**錯誤**: `Firebase credentials not found`

**解決方案**:
1. 確認 `firebase-credentials.json` 存在
2. 確認 `.env` 中的路徑正確

## 效能優化

### 1. 使用生產模式
```bash
set FLASK_ENV=production
set FLASK_DEBUG=False
```

### 2. 使用 Gunicorn（Linux/Mac）
```bash
pip install gunicorn
gunicorn -w 4 -k eventlet -b 0.0.0.0:5000 app_final:app
```

### 3. 快取向量資料庫
向量資料庫會自動持久化到 `knowledge-base/` 目錄，重啟不需要重建。

## 更新與維護

### 更新營養資料
1. 更新 CSV 檔案
2. 刪除 `knowledge-base/` 目錄
3. 重啟應用

### 更新 YOLO 模型
1. 替換 `初試v2.pt`
2. 更新 `classes.txt`（如果類別有變）
3. 重啟應用

## License

本專案為畢業專題作品。

## 聯絡資訊

如有問題請聯絡開發團隊。
