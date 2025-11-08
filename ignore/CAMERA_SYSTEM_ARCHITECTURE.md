# 📷 相機頁面到後端系統架構圖

> **完整的營養分析系統流程**
> 從使用者拍照 → YOLO 辨識 → RAG 查詢 → 營養分析 → 資料儲存

---

## 🏗️ 系統架構總覽

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           使用者介面層 (UI Layer)                        │
│                        📱 Flutter Mobile App                             │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                        展示層 (Presentation Layer)                       │
│  lib/features/camera/presentation/                                       │
│  ├─ pages/                                                               │
│  │  └─ smart_camera_page.dart ................. 相機UI頁面              │
│  └─ viewmodels/                                                          │
│     └─ camera_view_model.dart ................ 狀態管理 (ChangeNotifier)│
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                         領域層 (Domain Layer)                            │
│  lib/features/camera/domain/                                             │
│  ├─ usecases/ ................................. Clean Architecture Use Cases│
│  │  ├─ analyze_image_usecase.dart ........... 圖像分析                  │
│  │  ├─ perform_volume_calculation_usecase.dart  體積計算                │
│  │  ├─ take_picture_usecase.dart ............ 拍照                      │
│  │  ├─ toggle_flash_usecase.dart ............ 閃光燈                    │
│  │  ├─ switch_camera_usecase.dart ........... 切換相機                  │
│  │  └─ pick_images_from_gallery_usecase.dart  選擇相簿                  │
│  └─ repositories/                                                        │
│     └─ camera_repository.dart ............... Repository Interface      │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                         資料層 (Data Layer)                              │
│  lib/features/camera/data/                                               │
│  ├─ repositories/                                                        │
│  │  └─ camera_repository_impl.dart .......... Repository 實作           │
│  └─ datasources/                                                         │
│     ├─ camera_datasource.dart ............... 相機硬體操作              │
│     │  • getAvailableCameras()                                          │
│     │  • createCameraController()                                       │
│     │  • takePicture()                                                  │
│     │  • setFlashMode()                                                 │
│     │  • pickImagesFromGallery()                                        │
│     └─ image_processing_datasource.dart ..... HTTP API 呼叫 + Firebase  │
│        • analyzeImage() ..................... 呼叫後端 YOLO API          │
│        • performVolumeCalculation() ......... 呼叫體積計算 API           │
│        • uploadImageToStorage() ............. 上傳圖片到 Firebase        │
│        • saveAnalysisResultToFirestore() .... 儲存結果到 Firestore       │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
                     ┌──────────────┴──────────────┐
                     ↓                             ↓
      ┌──────────────────────────┐   ┌──────────────────────────┐
      │   🔥 Firebase 雲端服務    │   │   🐍 Flask 後端 API      │
      └──────────────────────────┘   └──────────────────────────┘
                                                  ↓

═══════════════════════════════════════════════════════════════════════════
                         🌐 網路層 (Network Layer)
═══════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────┐
│                        通訊協定 (Communication)                          │
│  ① HTTP/REST API ............................ 圖像上傳、分析請求         │
│  ② Socket.IO ................................ 即時雙向通訊               │
│  ③ Firebase SDK ............................. 認證、資料庫、儲存         │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓

═══════════════════════════════════════════════════════════════════════════
                       🖥️ 後端系統 (Backend System)
═══════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────┐
│                    Flask 應用伺服器 (app_final.py)                       │
│  yolov8_flask_api/                                                       │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  🎯 核心端點 (Core Endpoints)                                    │    │
│  │  ├─ POST /predict ........................ 食物辨識與營養分析    │    │
│  │  ├─ POST /volume_calculation ............. 體積計算              │    │
│  │  ├─ GET  /nutrition/<food_name> .......... 查詢營養資訊          │    │
│  │  └─ WebSocket /chat ...................... RAG 聊天機器人        │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  🔧 服務層 (Services)                                            │    │
│  │  ├─ services/firebase_service.py ......... Firebase 整合         │    │
│  │  ├─ services/rag_service_chroma.py ....... RAG 向量檢索          │    │
│  │  ├─ services/nutrition_data_manager.py ... 營養資料管理          │    │
│  │  ├─ services/llm_provider.py ............. LLM 提供者管理        │    │
│  │  └─ utils/logger.py ...................... 日誌記錄              │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
      ┌────────────────┬────────────────────┬────────────────────┐
      ↓                ↓                    ↓                    ↓

┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  🤖 YOLO v8  │  │ 🧠 Gemini AI │  │ 🦙 LM Studio │  │ 🔥 Firebase  │
│  物體偵測     │  │  LLM 模型    │  │  本地 LLM    │  │  雲端服務    │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
      │                │                    │                    │
      │                └────────┬───────────┘                    │
      ↓                         ↓                                ↓
┌──────────────┐  ┌──────────────────────────┐  ┌────────────────────────┐
│ 初試v2.pt    │  │   📊 Chroma 向量資料庫    │  │  Firestore Database    │
│ 食物偵測模型  │  │   營養知識庫 (RAG)        │  │  ├─ users/            │
│ classes.txt  │  │   • 食材資訊              │  │  │  └─ food_analysis/ │
│ (食物類別)   │  │   • 營養成分              │  │  └─ nutrition_data/   │
└──────────────┘  │   • 料理知識              │  │                        │
                  │   • Embedding 向量        │  │  Firebase Storage      │
                  └──────────────────────────┘  │  └─ images/            │
                                                 │     └─ [user_id]/      │
                                                 └────────────────────────┘

═══════════════════════════════════════════════════════════════════════════

```

---

## 📊 詳細資料流程圖

### 流程 1️⃣：拍照 → 食物辨識 → 營養分析

```
┌─────────────────────────────────────────────────────────────────────────┐
│  使用者操作                                                               │
└─────────────────────────────────────────────────────────────────────────┘
         │
         │ 點擊「拍照」按鈕
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  smart_camera_page.dart                                                  │
│  └─ _CameraButton.onPressed() ................... UI 事件觸發           │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  camera_view_model.dart                                                  │
│  └─ takePictureAndNavigate()                                            │
│     ├─ Step 1: 拍照                                                     │
│     │  └─ _takePictureUseCase(controller)                               │
│     │     └─ camera_repository.takePicture()                            │
│     │        └─ camera_datasource.takePicture()                         │
│     │           └─ CameraController.takePicture() ........ 📸 取得圖片   │
│     │                                                                     │
│     ├─ Step 2: 圖像分析                                                 │
│     │  └─ _analyzeImageUseCase(imagePath)                               │
│     │     └─ camera_repository.analyzeImage()                           │
│     │        └─ image_processing_datasource.analyzeImage()              │
│     │           │                                                        │
│     │           └─ HTTP POST Request ━━━━━━━━━━━━━┓                     │
│     │              • URL: http://localhost:5000/predict                 │
│     │              • Method: POST                                       │
│     │              • Body: MultipartFile (image)                        │
│     │                                              ↓                     │
│     └─ Step 3: 導航到結果頁面                    ┌──────────────────┐  │
│        └─ context.go('/camera/nutrition-label')  │  Flask API       │  │
│           • 傳遞: imagePath, analysis            │  app_final.py    │  │
└──────────────────────────────────────────────────┴──────────────────┘  │
                                                                          │
         ┌────────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  Flask Backend: /predict 端點                                            │
│  yolov8_flask_api/app_final.py                                           │
│                                                                           │
│  @app.route('/predict', methods=['POST'])                               │
│  def predict():                                                          │
│      │                                                                   │
│      ├─ Step 1: 接收圖片                                                │
│      │  └─ request.files['image']                                       │
│      │                                                                   │
│      ├─ Step 2: YOLO 物體偵測                                           │
│      │  └─ model.predict(image_path)                                    │
│      │     ├─ 偵測食物位置 (Bounding Box)                              │
│      │     ├─ 辨識食物類別 (class_names)                                │
│      │     └─ 信心度分數 (Confidence)                                   │
│      │        Result: [                                                 │
│      │          {name: '雞腿', confidence: 0.95, bbox: [...]},          │
│      │          {name: '青菜', confidence: 0.88, bbox: [...]}           │
│      │        ]                                                          │
│      │                                                                   │
│      ├─ Step 3: 查詢營養資訊                                            │
│      │  └─ nutrition_manager.get_nutrition_by_name(food_name)           │
│      │     └─ 從營養資料庫查詢                                          │
│      │        Result: {                                                 │
│      │          calories: 150,                                          │
│      │          protein: 25g,                                           │
│      │          carbs: 0g,                                              │
│      │          fat: 8g                                                 │
│      │        }                                                          │
│      │                                                                   │
│      ├─ Step 4: 計算總營養                                              │
│      │  └─ 加總所有偵測到的食物營養                                     │
│      │                                                                   │
│      ├─ Step 5: 儲存到 Firebase                                         │
│      │  └─ firebase_service.save_analysis(user_id, result)              │
│      │     ├─ Firebase Storage: 儲存圖片                                │
│      │     └─ Firestore: 儲存分析結果                                   │
│      │                                                                   │
│      └─ Step 6: 返回結果 JSON                                           │
│         └─ Response:                                                    │
│            {                                                             │
│              "success": true,                                           │
│              "detected_items": [...],                                   │
│              "total_nutrition": {...},                                  │
│              "analysis_time": "450ms",                                  │
│              "image_url": "https://..."                                 │
│            }                                                             │
└─────────────────────────────────────────────────────────────────────────┘
         │
         │ HTTP Response (JSON)
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  Flutter: image_processing_datasource.dart                              │
│  └─ 解析 JSON 回應                                                      │
│     └─ 返回 Map<String, dynamic>                                        │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  Flutter: nutrition_label_screen.dart                                   │
│  └─ 顯示分析結果                                                        │
│     ├─ 圖片 (imagePath)                                                 │
│     ├─ 偵測到的食物列表                                                 │
│     ├─ 營養成分表                                                       │
│     └─ 總熱量計算                                                       │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### 流程 2️⃣：相簿選擇 → 批次分析

```
使用者點擊「相簿」按鈕
         │
         ↓
camera_view_model.pickFromGallery()
         │
         ├─ ImagePicker.pickMultiImage() ............... 📂 選擇多張圖片
         │  └─ 返回: List<XFile>
         │
         └─ 導航到多圖處理頁面
            └─ context.go('/camera/process-multiple')
               └─ MultipleImagesProcessingPage
                  │
                  ├─ 顯示所有選中的圖片
                  │
                  └─ 對每張圖片呼叫 analyzeImage()
                     └─ 重複「流程 1」的 Step 2-6
```

---

### 流程 3️⃣：RAG 聊天機器人

```
使用者在聊天介面輸入問題：「雞肉有哪些營養？」
         │
         ↓
Flutter App
  └─ Socket.IO Emit
     └─ Event: 'chat_message'
        └─ Data: { message: '雞肉有哪些營養？', user_id: '...' }
         │
         │ WebSocket 連線
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  Flask Backend: Socket.IO Handler                                       │
│  @socketio.on('chat_message')                                           │
│                                                                           │
│  ├─ Step 1: 向量檢索 (Retrieval)                                        │
│  │  └─ rag_service_chroma.query(question)                               │
│  │     ├─ 將問題轉換為 Embedding 向量                                   │
│  │     ├─ 在 Chroma DB 中檢索相似文檔                                   │
│  │     └─ 返回最相關的 5 筆營養資料                                     │
│  │        Result: [                                                     │
│  │          "雞肉含有豐富的蛋白質...",                                  │
│  │          "每100g雞胸肉含165卡路里...",                               │
│  │          ...                                                          │
│  │        ]                                                              │
│  │                                                                       │
│  ├─ Step 2: 生成回答 (Generation)                                       │
│  │  └─ llm_provider.generate_answer(question, context)                  │
│  │     └─ 呼叫 Gemini API 或 LM Studio                                  │
│  │        ├─ 組合 Prompt:                                               │
│  │        │  "根據以下營養資訊回答問題：                                │
│  │        │   [檢索到的文檔]                                            │
│  │        │   問題：雞肉有哪些營養？"                                   │
│  │        │                                                             │
│  │        └─ LLM 生成回答                                               │
│  │           Result: "雞肉是優質蛋白質來源，每100g含..."               │
│  │                                                                       │
│  └─ Step 3: 返回回答                                                    │
│     └─ emit('chat_response', {answer: ...})                             │
└─────────────────────────────────────────────────────────────────────────┘
         │
         │ WebSocket 回應
         ↓
Flutter App
  └─ Socket.IO On
     └─ Event: 'chat_response'
        └─ 顯示 AI 回答
```

---

## 🔧 技術堆疊詳情

### 前端 (Flutter)

| 層級 | 技術 | 用途 |
|------|------|------|
| UI框架 | Flutter 3.24.3 | 跨平台 Mobile UI |
| 狀態管理 | Provider (ChangeNotifier) | MVVM 架構 |
| 路由管理 | GoRouter | 聲明式路由 |
| 相機 | camera package | 硬體相機存取 |
| 圖片選擇 | image_picker | 相簿存取 |
| HTTP | http package | REST API 呼叫 |
| 即時通訊 | socket_io_client | WebSocket 連線 |
| 雲端服務 | Firebase SDK | 認證、資料庫、儲存 |

### 後端 (Python)

| 層級 | 技術 | 用途 |
|------|------|------|
| Web框架 | Flask | REST API 伺服器 |
| 物體偵測 | YOLO v8 (Ultralytics) | 食物辨識 |
| LLM | Google Gemini API | 自然語言生成 |
| 本地LLM | LM Studio | 離線 AI 模型 |
| 向量資料庫 | Chroma DB | RAG 知識檢索 |
| Embedding | HuggingFace sentence-transformers | 文本向量化 |
| 即時通訊 | Flask-SocketIO | WebSocket 伺服器 |
| 雲端服務 | Firebase Admin SDK | 後端 Firebase 整合 |
| CORS | Flask-CORS | 跨域請求處理 |

---

## 📡 API 端點清單

### 🔹 YOLO 辨識 API

**端點**: `POST /predict`

**請求**:
```json
{
  "image": "<multipart file>"
}
```

**回應**:
```json
{
  "success": true,
  "detected_items": [
    {
      "name": "雞腿",
      "confidence": 0.95,
      "bbox": [100, 150, 300, 400],
      "nutrition": {
        "calories": 150,
        "protein": 25,
        "carbs": 0,
        "fat": 8
      }
    }
  ],
  "total_nutrition": {
    "calories": 450,
    "protein": 60,
    "carbs": 20,
    "fat": 15
  },
  "image_url": "https://firebase.storage/...",
  "analysis_time": "450ms"
}
```

---

### 🔹 體積計算 API

**端點**: `POST /volume_calculation`

**請求**:
```json
{
  "image": "<multipart file>",
  "reference_object": "coin"  // 參考物體
}
```

**回應**:
```json
{
  "success": true,
  "volume": 500.0,
  "unit": "cm³",
  "shape": "長方體",
  "confidence": 0.90,
  "dimensions": {
    "length": 10,
    "width": 5,
    "height": 10
  }
}
```

---

### 🔹 營養查詢 API

**端點**: `GET /nutrition/<food_name>`

**回應**:
```json
{
  "name": "雞胸肉",
  "calories": 165,
  "protein": 31,
  "carbs": 0,
  "fat": 3.6,
  "fiber": 0,
  "vitamins": {
    "B6": "高",
    "B12": "中"
  }
}
```

---

### 🔹 Socket.IO 事件

**客戶端 → 伺服器**:
```javascript
// 發送問題
socket.emit('chat_message', {
  message: '雞肉的營養成分有哪些？',
  user_id: 'user_123',
  session_id: 'session_456'
})
```

**伺服器 → 客戶端**:
```javascript
// 接收回答
socket.on('chat_response', (data) => {
  // data = {
  //   answer: 'AI 生成的回答...',
  //   sources: ['營養資料庫', '食譜網站'],
  //   timestamp: '2025-11-08T10:30:00Z'
  // }
})
```

---

## 🔒 安全性機制

### 認證流程

```
Flutter App
    │
    ├─ Firebase Authentication
    │  ├─ Email/Password
    │  ├─ Google Sign-In
    │  └─ 取得 ID Token
    │
    ↓
HTTP Request Headers
    └─ Authorization: Bearer <firebase_id_token>
    │
    ↓
Flask Backend
    └─ firebase_admin.auth.verify_id_token(token)
       ├─ ✅ Token 有效 → 允許存取
       └─ ❌ Token 無效 → 返回 401 Unauthorized
```

### 權限控制

- **相機權限**: `Permission.camera.request()`
- **相簿權限**: `Permission.photos.request()`
- **Firebase 規則**:
  ```javascript
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /users/{userId}/food_analysis/{document} {
        allow read, write: if request.auth.uid == userId;
      }
    }
  }
  ```

---

## 📈 效能優化

### 前端優化

1. **延遲初始化**: Camera 在需要時才初始化
2. **圖片壓縮**: `imageQuality: 80` 降低上傳大小
3. **批次處理**: 多圖時使用 `Future.wait()` 並行處理
4. **狀態管理**: 使用 `ChangeNotifier` 避免不必要的重建

### 後端優化

1. **模型預載入**: YOLO 模型在啟動時載入一次
2. **向量資料庫**: Chroma DB 持久化，避免重複建立
3. **LLM 快取**: 相同問題快取回答
4. **非同步處理**: 使用 `eventlet` 處理並發請求

---

## 🎯 資料流向總結

```
📱 Flutter App (前端)
     ↕ HTTP/REST API + Socket.IO
🐍 Flask API (後端)
     ├─ 🤖 YOLO v8 (物體偵測)
     ├─ 🧠 Gemini/LM Studio (AI 對話)
     ├─ 📊 Chroma DB (知識檢索)
     └─ 🔥 Firebase (資料儲存)
         ├─ Firestore (結構化資料)
         └─ Storage (圖片檔案)
```

---

## 📝 未來擴展方向

1. **離線模式**: 使用 TensorFlow Lite 在裝置端運行 YOLO
2. **即時辨識**: 使用相機預覽流即時偵測
3. **AR 標註**: 使用 ARCore/ARKit 在相機畫面標註營養資訊
4. **社群功能**: 分享飲食記錄、食譜推薦
5. **個人化建議**: 根據使用者健康目標提供飲食建議

---

**文件版本**: 1.0
**建立時間**: 2025-11-08
**維護者**: Claude AI

