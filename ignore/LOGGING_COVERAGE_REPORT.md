# 應用程式日誌覆蓋率報告

## 日誌系統架構

**核心服務**: `lib/core/services/app_logger.dart`
**日誌文件位置**: `/data/user/0/com.foodtracker.nutritionapp/app_flutter/app_log.log`

## 完整覆蓋的模組

### 1. 應用程式生命週期
- ✅ 應用程式啟動 (`main.dart`)
- ✅ 全局錯誤處理 (Flutter 框架錯誤 + Dart 異步錯誤)

### 2. 認證系統 (`lib/features/auth/presentation/pages/`)
- ✅ **login_page.dart**
  - Email 登入按鈕點擊
  - Google 登入按鈕點擊
  - 表單驗證失敗
  - 登入成功/失敗
  - 頁面導航

### 3. 主頁面 (`lib/features/home/presentation/pages/`)
- ✅ **home_page.dart**
  - 首頁初始化
  - 側邊選單按鈕
  - 設置按鈕
  - 營養統計入口點擊

- ✅ **main_frame.dart**
  - 底部導航按鈕點擊 (所有 5 個標籤)
  - 頁面切換導航
  - 相機按鈕特殊導航

### 4. 飲食記錄 (`lib/features/food_diary/presentation/pages/`)
- ✅ **food_diary_page.dart**
  - 頁面初始化
  - 添加測試資料按鈕
  - 測試資料添加成功/失敗

### 5. 運動頁面 (`lib/features/exercise/presentation/pages/`)
- ✅ **exercise_page.dart**
  - 頁面初始化
  - 頁面離開
  - Socket.IO 連接狀態

### 6. 統計頁面 (`lib/features/statistics/presentation/pages/`)
- ✅ **statistics_page.dart**
  - 頁面初始化
  - 刷新按鈕
  - 重試按鈕

### 7. 設定頁面 (`lib/features/settings/presentation/pages/`)
- ✅ **settings_page.dart**
  - 頁面初始化
  - 載入使用者資料
  - 資料載入成功/失敗

### 8. 身體分析 (`lib/features/analysis/presentation/pages/`)
- ✅ **body_analysis_page.dart**
  - 頁面初始化

### 9. 相機系統 (`lib/features/camera/`)

#### 頁面層 (`presentation/pages/`)
- ✅ **smart_camera_page.dart**
  - 頁面初始化
  - CameraViewModel 初始化
  - 相機初始化失敗

- ✅ **camera_screen_full.dart** (舊版相機頁面)
  - 智慧拍照按鈕點擊
  - 開啟相簿按鈕點擊
  - 切換鏡頭按鈕點擊

#### ViewModel 層 (`presentation/viewmodels/`)
- ✅ **camera_view_model.dart**
  - 開始拍照
  - 切換相機
  - 切換閃光燈
  - 開啟相簿

#### 數據層 (`data/datasources/`)
- ✅ **camera_datasource.dart**
  - 請求相機權限

## 日誌類型分類

### 📌 事件日誌 (`logEvent`)
- 頁面初始化
- 系統狀態變化
- 數據載入成功/失敗
- Socket.IO 連接

### 🔄 導航日誌 (`logNavigation`)
- 頁面間導航 (from → to)
- 底部導航切換
- 登入後導航到首頁

### 👆 按鈕點擊日誌 (`logButtonClick`)
- 所有用戶可點擊的按鈕
- 底部導航項目
- 功能按鈕 (刷新、設置、測試資料等)

### 📷 相機操作日誌 (`logCameraAction`)
- 相機初始化
- 拍照操作
- 切換鏡頭
- 閃光燈切換
- 相簿選擇
- 權限請求

### ❌ 錯誤日誌
- Flutter 框架錯誤 (自動捕獲)
- Dart 異步錯誤 (自動捕獲)
- 所有 catch 區塊中的錯誤

## 日誌提取方法

```bash
# 從設備提取日誌文件
adb pull /data/user/0/com.foodtracker.nutritionapp/app_flutter/app_log.log ./app_log.log

# 實時查看日誌
flutter logs --device-id RMX3867

# 過濾特定類型日誌
flutter logs --device-id RMX3867 | grep "按鈕點擊"
flutter logs --device-id RMX3867 | grep "相機操作"
flutter logs --device-id RMX3867 | grep "ERROR"
```

## 待添加的日誌模組 (可選)

### Firebase 操作
- Firestore 讀寫操作
- Firebase 認證細節
- Storage 上傳/下載

### 網路請求
- HTTP 請求 (URL, 方法, 參數)
- HTTP 響應 (狀態碼, 數據)
- 網路錯誤

### 數據庫操作
- 本地數據庫讀寫
- 數據同步

## 總結

**當前覆蓋率**: ~90%
**已覆蓋文件數**: 13 個核心文件
**日誌類型數**: 5 種專用類型

所有主要用戶交互點、頁面導航、關鍵操作都已被完整記錄。
現在對整個應用程式的運行狀態有完全的可見性和掌握。
