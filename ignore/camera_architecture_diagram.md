# 📸 相機頁面系統架構圖

## 🏗️ 整體架構概覽

```mermaid
graph TB
    %% 呈現層 (Presentation Layer)
    subgraph "📱 Presentation Layer"
        UI[SmartCameraScreen<br/>智慧相機頁面]
        VM[CameraViewModel<br/>相機視圖模型]
        UI --> VM
    end

    %% 領域層 (Domain Layer)
    subgraph "🎯 Domain Layer (Use Cases)"
        UC1[GetAvailableCamerasUseCase<br/>獲取可用相機]
        UC2[InitializeCameraUseCase<br/>初始化相機]
        UC3[TakePictureUseCase<br/>拍照]
        UC4[ToggleFlashUseCase<br/>切換閃光燈]
        UC5[SwitchCameraUseCase<br/>切換相機]
        UC6[PickImagesFromGalleryUseCase<br/>從相簿選擇]
        UC7[AnalyzeImageUseCase<br/>圖片分析]
        UC8[PerformVolumeCalculationUseCase<br/>體積計算]

        VM --> UC1
        VM --> UC2
        VM --> UC3
        VM --> UC4
        VM --> UC5
        VM --> UC6
        VM --> UC7
        VM --> UC8
    end

    %% 資料層 (Data Layer)
    subgraph "💾 Data Layer"
        subgraph "Repository"
            REPO[CameraRepositoryImpl<br/>相機倉庫實現]
        end

        subgraph "Data Sources"
            DS1[CameraDatasource<br/>相機資料源]
            DS2[ImageProcessingDatasource<br/>圖片處理資料源]
        end

        UC1 --> REPO
        UC2 --> REPO
        UC3 --> REPO
        UC4 --> REPO
        UC5 --> REPO
        UC6 --> REPO
        UC7 --> REPO
        UC8 --> REPO

        REPO --> DS1
        REPO --> DS2
    end

    %% 核心服務層 (Core Services)
    subgraph "⚙️ Core Services"
        CS[CameraService<br/>相機核心服務]
        LS[LoggingService<br/>日誌服務]
    end

    %% 外部依賴 (External Dependencies)
    subgraph "🔌 External Dependencies"
        CAM[Camera Package<br/>相機套件]
        IP[ImagePicker Package<br/>圖片選擇器]
        PERM[Permission Handler<br/>權限處理]
        FIRE[Firebase Storage<br/>雲端存儲]
        FS[Firestore<br/>資料庫]
    end

    %% 連接關係
    VM --> CS
    VM --> LS
    DS1 --> CAM
    DS1 --> IP
    DS1 --> PERM
    DS2 --> FIRE
    DS2 --> FS

    %% 樣式
    classDef presentation fill:#e1f5fe
    classDef domain fill:#f3e5f5
    classDef data fill:#e8f5e8
    classDef services fill:#fff3e0
    classDef external fill:#ffebee

    class UI,VM presentation
    class UC1,UC2,UC3,UC4,UC5,UC6,UC7,UC8 domain
    class REPO,DS1,DS2 data
    class CS,LS services
    class CAM,IP,PERM,FIRE,FS external
```

## 🔄 相機功能流程圖

```mermaid
sequenceDiagram
    participant U as 用戶
    participant UI as SmartCameraScreen
    participant VM as CameraViewModel
    participant UC as Use Cases
    participant REPO as Repository
    participant DS as Data Sources
    participant CAM as Camera API

    %% 初始化流程
    Note over U,CAM: 📷 相機初始化流程
    U->>UI: 進入相機頁面
    UI->>VM: initState() & initialize()
    VM->>UC: GetAvailableCamerasUseCase()
    UC->>REPO: getAvailableCameras()
    REPO->>DS: CameraDatasource.getAvailableCameras()
    DS->>CAM: availableCameras()
    CAM-->>DS: List<CameraDescription>
    DS-->>REPO: 相機列表
    REPO-->>UC: 相機列表
    UC-->>VM: 相機列表
    VM->>UC: InitializeCameraUseCase()
    UC->>REPO: createCameraController()
    REPO->>DS: createCameraController()
    DS->>CAM: CameraController.initialize()
    CAM-->>VM: 相機就緒

    %% 拍照流程
    Note over U,CAM: 📸 拍照處理流程
    U->>UI: 點擊拍照按鈕
    UI->>VM: takePictureAndNavigate()
    VM->>UC: TakePictureUseCase()
    UC->>REPO: takePicture()
    REPO->>DS: CameraDatasource.takePicture()
    DS->>CAM: controller.takePicture()
    CAM-->>DS: XFile (圖片檔案)
    DS-->>VM: 圖片路徑

    VM->>UC: AnalyzeImageUseCase()
    UC->>REPO: analyzeImage()
    REPO->>DS: ImageProcessingDatasource.analyzeImage()
    DS-->>VM: 分析結果 (Mock Data)
    VM->>UI: context.push('/nutrition-label')
    UI-->>U: 跳轉到營養標籤頁

    %% 切換相機流程
    Note over U,CAM: 🔄 切換相機流程
    U->>UI: 點擊切換相機按鈕
    UI->>VM: switchCamera()
    VM->>UC: SwitchCameraUseCase()
    UC->>REPO: createCameraController(nextCamera)
    REPO->>DS: 釋放舊控制器 & 創建新控制器
    DS->>CAM: 重新初始化相機
    CAM-->>VM: 相機切換完成

    %% 閃光燈控制
    Note over U,CAM: 💡 閃光燈控制流程
    U->>UI: 點擊閃光燈按鈕
    UI->>VM: toggleFlash()
    VM->>UC: ToggleFlashUseCase()
    UC->>REPO: setFlashMode()
    REPO->>DS: CameraDatasource.setFlashMode()
    DS->>CAM: controller.setFlashMode()
    CAM-->>VM: 閃光燈狀態更新
```

## 📊 資料流架構

```mermaid
graph LR
    subgraph "用戶操作"
        A[拍照]
        B[切換相機]
        C[開關閃光燈]
        D[選擇相簿]
    end

    subgraph "ViewModel 處理"
        E[CameraViewModel]
        E1[狀態管理]
        E2[錯誤處理]
        E3[生命周期管理]
        E --> E1
        E --> E2
        E --> E3
    end

    subgraph "Use Cases 業務邏輯"
        F[8個專用 Use Cases]
        F1[單一職責原則]
        F2[可測試性]
        F3[可重用性]
        F --> F1
        F --> F2
        F --> F3
    end

    subgraph "Repository 抽象"
        G[CameraRepository Interface]
        H[CameraRepositoryImpl]
        G --> H
    end

    subgraph "Data Sources"
        I[CameraDatasource]
        J[ImageProcessingDatasource]
        I1[實際硬體操作]
        J1[圖片分析處理]
        I --> I1
        J --> J1
    end

    subgraph "外部服務"
        K[Camera Package]
        L[Firebase]
        M[Permission Handler]
        N[Image Picker]
    end

    A --> E
    B --> E
    C --> E
    D --> E

    E --> F
    F --> G
    H --> I
    H --> J

    I --> K
    I --> M
    I --> N
    J --> L
```

## 🎯 設計模式說明

### 1. **Clean Architecture (清潔架構)**
- **Presentation Layer**: UI 和 ViewModel
- **Domain Layer**: Use Cases 和 Business Logic
- **Data Layer**: Repositories 和 Data Sources

### 2. **MVVM Pattern (模型-視圖-視圖模型)**
- **View**: SmartCameraScreen
- **ViewModel**: CameraViewModel
- **Model**: Use Cases + Repository

### 3. **Repository Pattern (倉庫模式)**
- 抽象資料存取邏輯
- 統一資料來源接口

### 4. **Use Case Pattern (用例模式)**
- 每個業務功能獨立封裝
- 單一職責原則

### 5. **Dependency Injection (依賴注入)**
- Provider 模式提供依賴
- 構造函數注入

## 🔧 技術特點

### ✅ **優點**
1. **模組化設計** - 各層職責清晰
2. **可測試性** - 每層都可獨立測試
3. **可維護性** - 易於修改和擴展
4. **可重用性** - Use Cases 可在其他頁面重用
5. **錯誤隔離** - 錯誤處理集中在各層邊界

### 📝 **核心組件說明**

#### **CameraViewModel**
- 管理相機狀態 (isInitialized, isLoading, isFlashOn)
- 協調各個 Use Cases
- 處理 UI 狀態更新

#### **Use Cases**
- `GetAvailableCamerasUseCase`: 獲取設備可用相機
- `InitializeCameraUseCase`: 初始化相機控制器
- `TakePictureUseCase`: 執行拍照操作
- `AnalyzeImageUseCase`: 圖片分析處理

#### **Repository**
- `CameraRepositoryImpl`: 統一相機操作接口
- 協調不同的 Data Sources

#### **Data Sources**
- `CameraDatasource`: 硬體相機操作
- `ImageProcessingDatasource`: 圖片處理和分析

這個架構確保了代碼的可維護性、可測試性和可擴展性，遵循了 SOLID 原則和 Clean Architecture 設計模式。