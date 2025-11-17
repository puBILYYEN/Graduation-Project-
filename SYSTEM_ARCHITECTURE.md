# 系統架構圖 - 健康與營養 AI 應用程序

## 整體系統架構

```mermaid
graph TB
    subgraph "前端層 - Flutter Multi-Platform"
        A[Flutter 應用程式<br/>Android/iOS/Web/Desktop]
        A1[認證模組<br/>Auth]
        A2[相機模組<br/>Camera]
        A3[營養標籤掃描<br/>Nutrition]
        A4[食物測量<br/>Measurement]
        A5[飲食日記<br/>Food Diary]
        A6[運動追蹤<br/>Exercise]
        A7[身體分析<br/>Analysis]
        A8[統計圖表<br/>Statistics]

        A --> A1
        A --> A2
        A --> A3
        A --> A4
        A --> A5
        A --> A6
        A --> A7
        A --> A8
    end

    subgraph "通訊層"
        B1[REST API<br/>HTTP Client]
        B2[WebSocket<br/>Socket.IO]
    end

    subgraph "後端層 - Python Flask API"
        C[Flask 應用程式<br/>Gunicorn + Eventlet]
        C1[YOLO 服務<br/>食物檢測]
        C2[RAG 服務<br/>向量搜索]
        C3[LLM 服務<br/>Gemini AI]
        C4[營養數據管理<br/>Nutrition Manager]
        C5[Firebase 服務<br/>數據存儲]
        C6[翻譯服務<br/>多語言]

        C --> C1
        C --> C2
        C --> C3
        C --> C4
        C --> C5
        C --> C6
    end

    subgraph "機器學習層"
        D1[YOLOv8 模型<br/>88+ 食物類別]
        D2[Chroma 向量數據庫<br/>3000+ 營養文檔]
        D3[HuggingFace<br/>Sentence Transformers]
    end

    subgraph "外部服務"
        E1[Firebase Auth<br/>用戶認證]
        E2[Firebase Firestore<br/>NoSQL 數據庫]
        E3[Firebase Storage<br/>圖片存儲]
        E4[Google Gemini API<br/>生成式 AI]
    end

    subgraph "數據層"
        F1[(CSV 營養數據<br/>2237+ 食品項)]
        F2[(向量數據庫<br/>knowledge-base/)]
        F3[(日誌系統<br/>logs/)]
    end

    A1 --> B1
    A2 --> B1
    A3 --> B1
    A4 --> B1
    A5 --> B2
    A6 --> B1
    A7 --> B1
    A8 --> B1

    B1 --> C
    B2 --> C

    C1 --> D1
    C2 --> D2
    C2 --> D3
    C3 --> E4
    C5 --> E1
    C5 --> E2
    C5 --> E3

    C4 --> F1
    C2 --> F2
    C --> F3

    style A fill:#e1f5ff
    style C fill:#fff4e1
    style D1 fill:#ffe1f5
    style D2 fill:#ffe1f5
    style E4 fill:#e1ffe1
```

## 詳細架構層次

### 1. 前端架構 (Clean Architecture)

```mermaid
graph LR
    subgraph "Presentation Layer"
        P1[Pages/Screens]
        P2[ViewModels]
        P3[Widgets]
    end

    subgraph "Domain Layer"
        D1[Entities]
        D2[Use Cases]
        D3[Repository Interfaces]
    end

    subgraph "Data Layer"
        DA1[Repository Impl]
        DA2[Data Sources]
        DA3[Models]
    end

    P1 --> P2
    P2 --> D2
    D2 --> D3
    DA1 --> D3
    DA2 --> DA1
    DA3 --> DA1

    style P1 fill:#e1f5ff
    style D1 fill:#fff4e1
    style DA1 fill:#ffe1f5
```

### 2. API 通訊流程

```mermaid
sequenceDiagram
    participant U as 用戶
    participant F as Flutter App
    participant API as Flask API
    participant YOLO as YOLO 模型
    participant RAG as Chroma RAG
    participant LLM as Gemini AI
    participant FB as Firebase

    U->>F: 拍攝食物照片
    F->>API: POST /predict (圖片)
    API->>YOLO: 檢測食物
    YOLO-->>API: 食物類別 + 信心度
    API-->>F: 檢測結果

    F->>API: WebSocket: rag_question
    API->>RAG: 向量搜索
    RAG-->>API: 相關營養文檔
    API->>LLM: 生成個人化建議
    LLM-->>API: AI 回應
    API-->>F: WebSocket: rag_response

    F->>FB: 儲存飲食記錄
    FB-->>F: 確認儲存

    F->>API: POST /nutrition_analysis
    API->>RAG: 查詢營養數據
    API->>LLM: 分析營養成分
    LLM-->>API: 詳細分析
    API-->>F: 營養報告
```

### 3. 資料流架構

```mermaid
flowchart TD
    A[用戶輸入] --> B{輸入類型}

    B -->|照片| C[相機服務]
    B -->|營養標籤| D[OCR 掃描]
    B -->|手動輸入| E[食物日記]

    C --> F[YOLO API]
    D --> G[營養標籤 API]
    E --> H[Firestore]

    F --> I[食物識別結果]
    G --> J[營養成分提取]

    I --> K[RAG 查詢]
    J --> K

    K --> L[Chroma 向量搜索]
    L --> M[Gemini AI 分析]

    M --> N[個人化營養建議]
    N --> H

    H --> O[統計分析]
    O --> P[視覺化圖表]
    P --> Q[用戶界面顯示]

    style A fill:#e1f5ff
    style F fill:#ffe1f5
    style K fill:#fff4e1
    style M fill:#e1ffe1
    style Q fill:#e1f5ff
```

### 4. 服務層架構

```mermaid
graph TB
    subgraph "核心服務"
        S1[ApiClient 服務]
        S2[Socket 服務]
        S3[相機服務]
        S4[YOLO API 服務]
        S5[RAG API 服務]
    end

    subgraph "數據服務"
        D1[Firestore 服務]
        D2[Auth Repository]
        D3[圖片處理服務]
        D4[日誌服務]
    end

    subgraph "業務邏輯"
        B1[營養計算器]
        B2[測量計算器]
        B3[統計分析器]
        B4[參考資料庫]
    end

    S1 --> D1
    S2 --> S5
    S3 --> D3
    S4 --> S1
    S5 --> S2

    D1 --> B1
    D3 --> B2
    D1 --> B3
    B1 --> B4

    style S1 fill:#e1f5ff
    style D1 fill:#fff4e1
    style B1 fill:#ffe1f5
```

### 5. 後端服務架構

```mermaid
graph TB
    subgraph "Flask 路由層"
        R1[/health]
        R2[/predict]
        R3[/analyze_nutrition]
        R4[/rag_query]
        R5[/nutrition_analysis]
        R6[Socket.IO 事件]
    end

    subgraph "服務層"
        SV1[Firebase Service]
        SV2[RAG Service]
        SV3[LLM Provider]
        SV4[Nutrition Manager]
        SV5[Translation Service]
    end

    subgraph "模型層"
        M1[YOLO 模型載入器]
        M2[Chroma 向量引擎]
        M3[Embedding 模型]
    end

    R2 --> M1
    R3 --> SV3
    R4 --> SV2
    R5 --> SV2
    R6 --> SV2

    SV2 --> M2
    SV2 --> M3
    SV2 --> SV3
    SV3 --> E4[Gemini API]
    SV1 --> E1[Firebase]
    SV4 --> F1[(CSV Data)]

    style R1 fill:#e1f5ff
    style SV2 fill:#fff4e1
    style M1 fill:#ffe1f5
```

### 6. 部署架構

```mermaid
graph TB
    subgraph "用戶設備"
        U1[Android App]
        U2[iOS App]
        U3[Web App]
        U4[Desktop App]
    end

    subgraph "Google Cloud Platform"
        GCP1[Cloud Run<br/>容器化後端]
        GCP2[負載均衡器]
        GCP3[容器映像庫]
    end

    subgraph "Firebase"
        FB1[Authentication]
        FB2[Firestore]
        FB3[Storage]
    end

    subgraph "第三方 API"
        API1[Google Gemini API]
        API2[HuggingFace Models]
    end

    U1 --> GCP2
    U2 --> GCP2
    U3 --> GCP2
    U4 --> GCP2

    GCP2 --> GCP1
    GCP1 --> FB1
    GCP1 --> FB2
    GCP1 --> FB3
    GCP1 --> API1
    GCP1 --> API2

    GCP3 --> GCP1

    style GCP1 fill:#4285f4,color:#fff
    style FB1 fill:#ffca28
    style API1 fill:#34a853
```

## 技術堆疊總覽

### 前端 (Flutter)
- **框架**: Flutter 3.5.3+
- **狀態管理**: Provider 6.1.2
- **路由**: Go Router 15.1.2
- **即時通訊**: Socket.IO 3.1.2
- **Firebase**: Auth, Firestore, Storage
- **圖表**: fl_chart 0.69.0
- **UI**: Material Design

### 後端 (Python)
- **框架**: Flask 3.0.0
- **伺服器**: Gunicorn 21.2.0, Eventlet 0.35.1
- **機器學習**: YOLOv8, OpenCV, Pillow
- **RAG**: Langchain, Chroma, Sentence-transformers
- **AI**: Google Generativeai
- **數據庫**: Firebase Admin
- **WebSocket**: python-socketio

### 基礎設施
- **容器化**: Docker
- **部署**: GCP Cloud Run
- **CI/CD**: 自動化部署
- **監控**: 日誌輪替 + 健康檢查

## API 端點總覽

| 端點 | 方法 | 功能 | 輸入 | 輸出 |
|------|------|------|------|------|
| `/health` | GET | 健康檢查 | - | 服務狀態 |
| `/predict` | POST | 食物檢測 | 圖片 | 食物類別 + 信心度 |
| `/analyze_nutrition` | POST | 營養分析 | 食物數據 + 用戶資料 | 個人化建議 |
| `/rag_query` | POST | RAG 查詢 | 問題 + 用戶資料 | AI 回答 |
| `/nutrition_analysis` | POST | 詳細分析 | 食物列表 | 完整營養報告 |

## Socket.IO 事件

| 事件名稱 | 方向 | 功能 |
|----------|------|------|
| `rag_question` | 客戶端 → 伺服器 | 發送 RAG 查詢 |
| `rag_response` | 伺服器 → 客戶端 | 接收 AI 回應 |
| `nutrition_data` | 客戶端 → 伺服器 | 發送營養數據 |
| `nutrition_received` | 伺服器 → 客戶端 | 確認接收 |
| `connect` | 雙向 | 建立連接 |
| `disconnect` | 雙向 | 斷開連接 |

## 資料模型

### 前端模型
- **BodyMetrics**: 身高、體重、心率、血壓、睡眠
- **FoodEntry**: 名稱、餐次、卡路里、圖片、份量
- **NutrientData**: 蛋白質、碳水化合物、脂肪、維生素、礦物質
- **AIPrediction**: 食物類別、信心分數
- **AIAnalysisResult**: 預測、建議、營養資訊

### 後端模型
- **Nutrition Data**: 食品名稱、卡路里、營養素
- **User Profile**: 身高、體重、飲食偏好
- **Meal Record**: 食物、時間戳、圖片、分析
- **RAG Document**: 食物資訊、製作方法、益處

## 安全性考量

1. **認證**: Firebase Auth (Email/Password + Google OAuth)
2. **HTTPS**: 所有通訊加密
3. **環境變數**: 敏感資訊隔離 (.env)
4. **Firestore 規則**: 用戶資料隔離
5. **API 限流**: LLM 提供者故障轉移
6. **錯誤處理**: 優雅降級機制
7. **日誌**: 全面記錄，敏感資訊遮蔽

## 擴展性設計

1. **容器化**: Docker 容器易於水平擴展
2. **無狀態**: Flask API 無狀態設計
3. **雲端部署**: GCP Cloud Run 自動擴展
4. **快取**: HuggingFace 模型本地快取
5. **向量數據庫**: Chroma 持久化存儲
6. **異步處理**: Socket.IO 非阻塞通訊

## 監控與日誌

- **應用日誌**: 每日輪替，10MB/檔案，保留 5 份
- **健康檢查**: `/health` 端點監控服務狀態
- **錯誤追蹤**: Try-catch 全覆蓋
- **性能監控**: API 回應時間記錄
- **用戶行為**: Firebase Analytics 整合準備

---

## 系統特色

✅ **多平台支援**: 6 個平台 (Android, iOS, Web, macOS, Linux, Windows)
✅ **AI 驅動**: YOLO 食物識別 + RAG 個人化建議
✅ **即時通訊**: Socket.IO WebSocket 雙向通訊
✅ **Clean Architecture**: 分層架構，易於維護
✅ **雲端部署**: GCP Cloud Run 生產環境
✅ **完整功能**: 飲食追蹤、運動記錄、身體分析、統計圖表

**生產環境**: https://nutrition-api-459965557703.asia-east1.run.app
