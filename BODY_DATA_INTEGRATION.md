# 身體數據整合功能說明

## 概述

本功能實現了首頁視覺化與 Firebase 資料庫身體數據的連接，並且當使用者在 AI 個人化諮詢中提及身體相關數據時，系統能自動提取並更新到 Firebase。

## 功能特點

### 1. 首頁數據即時同步
- ✅ 首頁熱量目標從 Firebase `member` 集合讀取使用者的 `targetCalories` 或 `suggested_calories`
- ✅ 營養素比例（蛋白質、碳水化合物、脂肪）根據 Firebase 中的 `targetProtein`、`targetCarbs`、`targetFat` 自動計算
- ✅ 使用 Stream 監聽，當 Firebase 數據更新時，首頁自動刷新

### 2. AI 對話中的身體數據提取
當使用者在 AI 諮詢中提及以下身體數據時，系統會自動識別並儲存：

#### 支援的數據類型
- **體重** (weight)
  - 識別模式：`體重70kg`、`我的體重是65公斤`、`目前體重75`
  - 儲存格式：浮點數 (kg)

- **身高** (height)
  - 識別模式：`身高170cm`、`我的身高是165公分`、`現在身高180`
  - 儲存格式：整數 (cm)

- **年齡** (age)
  - 識別模式：`年齡25歲`、`我今年30歲`、`現在28歲`
  - 儲存格式：整數 (歲)

- **睡眠時間** (sleepHours)
  - 識別模式：`睡眠時間7小時`、`睡了8小時`、`睡眠8.5小時`
  - 儲存格式：浮點數 (小時)

- **心率** (heartRate)
  - 識別模式：`心率75bpm`、`心跳80次`、`脈搏72`
  - 儲存格式：整數 (bpm)

- **血壓** (bloodPressure)
  - 識別模式：`血壓120/80`
  - 儲存格式：字串 (格式: "收縮壓/舒張壓")

### 3. 數據流程

```
使用者輸入 AI 問題
    ↓
AI 回應（包含身體數據）
    ↓
FirestoreService.parseBodyDataFromText() 提取數據
    ↓
FirestoreService.updateUserBodyData() 更新到 Firebase
    ↓
SocketService.sendBodyDataUpdate() 通知 RAG 系統
    ↓
首頁 Stream 自動刷新顯示
```

## 修改的檔案

### 1. [FirestoreService](lib/core/services/firestore_service.dart)
新增方法：
- `getUserBodyData()`: 讀取使用者身體數據
- `getUserBodyDataStream()`: 即時監聽身體數據變化
- `updateUserBodyData()`: 更新身體數據
- `parseBodyDataFromText()`: 從文字中提取身體數據

### 2. [HomePage](lib/features/home/presentation/pages/home_page.dart)
修改內容：
- 新增 `_loadUserBodyData()`: 載入並監聽使用者身體數據
- 修改 `_handleRagResponse()`: 處理 AI 回應並提取身體數據
- 新增 `_extractAndSaveBodyData()`: 提取並儲存身體數據
- 整合 Firebase Stream 以即時更新首頁顯示

### 3. [SocketService](lib/core/services/api/socket_service.dart)
新增方法：
- `sendBodyDataUpdate()`: 發送身體數據更新給 RAG 系統

## 使用範例

### 範例 1：使用者詢問體重相關問題

**使用者輸入：**
```
我現在體重 75kg，應該如何調整飲食？
```

**系統行為：**
1. 將問題發送給 Gemini AI
2. AI 回應營養建議
3. 系統自動識別 `體重 75kg`
4. 更新 Firebase 中的 `weight` 欄位為 75
5. 通知 RAG 系統身體數據已更新
6. 顯示提示：「已更新您的身體數據：weight」
7. 首頁的相關視覺化自動更新

### 範例 2：使用者分享多項身體數據

**使用者輸入：**
```
我今年 28 歲，身高 170cm，體重 65kg，每天睡眠 7 小時，心率大約 72bpm
```

**系統行為：**
1. AI 提供個人化建議
2. 系統識別並提取：
   - age: 28
   - height: 170
   - weight: 65
   - sleepHours: 7
   - heartRate: 72
3. 批量更新到 Firebase
4. 顯示提示：「已更新您的身體數據：age、height、weight、sleepHours、heartRate」

### 範例 3：使用者更新血壓

**使用者輸入：**
```
今天量血壓是 120/80
```

**系統行為：**
1. AI 回應血壓狀況分析
2. 系統識別血壓值
3. 更新 Firebase 中的 `bloodPressure` 為 "120/80"
4. 通知使用者數據已更新

## Firebase 資料結構

### member 集合
```javascript
{
  // 基本資料
  "age": 28,                    // 年齡
  "gender": true,               // 性別（true=男，false=女）
  "height": 170,                // 身高 (cm)
  "weight": 65,                 // 體重 (kg)

  // 健康數據
  "sleepHours": 7,              // 睡眠時間 (小時)
  "heartRate": 72,              // 心率 (bpm)
  "bloodPressure": "120/80",    // 血壓

  // 目標設定
  "goal": 1,                    // 健康目標（0=維持，1=減重，2=增重）
  "activityLevel": "moderately_active",  // 活動量等級

  // 計算數值
  "BMR": 1650,                  // 基礎代謝率
  "TDEE_level": 2557,           // 總日耗能
  "suggested_calories": 2057,   // 建議卡路里

  // 營養目標
  "targetCalories": 2057,       // 目標卡路里
  "targetProtein": 154,         // 目標蛋白質 (g)
  "targetCarbs": 231,           // 目標碳水化合物 (g)
  "targetFat": 57,              // 目標脂肪 (g)

  // 時間戳
  "updatedAt": Timestamp        // 最後更新時間
}
```

## 技術實現細節

### 1. 正則表達式提取
使用多個正則表達式模式來匹配不同的輸入格式，確保高準確率。

範例（體重提取）：
```dart
final patterns = {
  'weight': [
    RegExp(r'體重[：:是為]?\s*(\d+\.?\d*)\s*(?:kg|公斤|KG)', caseSensitive: false),
    RegExp(r'(?:目前|現在|我的)體重\s*(\d+\.?\d*)', caseSensitive: false),
    RegExp(r'(\d+\.?\d*)\s*(?:kg|公斤|KG)', caseSensitive: false),
  ],
};
```

### 2. 數據類型轉換
根據不同的欄位自動進行數據類型轉換：
- 整數欄位：age, height, heartRate
- 浮點數欄位：weight, sleepHours
- 字串欄位：bloodPressure

### 3. Firebase 更新策略
使用 `SetOptions(merge: true)` 確保只更新提取到的欄位，不會覆蓋其他現有數據。

### 4. 即時同步
使用 Firebase Firestore 的 `snapshots()` Stream 實現即時數據同步，無需手動刷新。

## 注意事項

1. **隱私保護**：身體數據僅儲存在使用者自己的 Firebase 文檔中，受 Firebase Security Rules 保護

2. **數據驗證**：提取的數據會經過基本驗證（如年齡範圍 10-100 歲），防止異常數據

3. **非侵入式**：數據提取在背景執行，不影響正常的 AI 對話體驗

4. **容錯機制**：如果提取或儲存失敗，不會顯示錯誤訊息給使用者，避免打斷對話

5. **RAG 整合**：更新的身體數據會通知 RAG 系統，使後續的 AI 建議更加個人化

## 未來擴展

1. **健康趨勢分析**：記錄身體數據的歷史變化，生成趨勢圖表
2. **智能提醒**：根據數據變化提供主動建議
3. **更多數據類型**：支援體脂率、肌肉量等更多健康指標
4. **數據匯出**：允許使用者匯出個人健康數據報告

## 測試建議

### 測試案例 1：基本數據提取
輸入：`我體重70kg，身高175cm`
預期：成功提取並更新 weight 和 height

### 測試案例 2：中文數字格式
輸入：`我的體重是七十公斤`
預期：目前不支援中文數字，未來可擴展

### 測試案例 3：多輪對話
1. 第一輪：`我想減重`
2. 第二輪：`我現在75kg`
預期：第二輪成功提取體重

### 測試案例 4：數據更新通知
輸入包含身體數據的問題
預期：
- Firebase 數據更新成功
- 顯示更新通知
- 首頁視覺化自動刷新

## 支援與維護

如有問題或建議，請查看相關程式碼註解或聯繫開發團隊。
