# Firebase 索引設定指南

## 🎯 問題解決方案

當您遇到 `permission-denied` 錯誤且 Firebase 提示「this index is not necessary, configure using single field index controls」時，代表您需要設定**單一欄位索引**而非複合索引。

---

## ✅ 解決方案：設定單一欄位索引

### 步驟 1：前往 Firebase Console

1. 開啟 [Firebase Console](https://console.firebase.google.com/)
2. 選擇您的專案
3. 左側選單：**Firestore Database**
4. 點擊頂部的 **「索引 (Indexes)」** 標籤
5. 選擇 **「單一欄位 (Single field)」** 子標籤

### 步驟 2：新增 timestamp 欄位索引

1. 點擊 **「新增豁免 (Add exemption)」** 按鈕

2. 填寫以下資訊：

   **集合群組 ID (Collection group ID)**:
   ```
   food_diary
   ```

   **欄位路徑 (Field path)**:
   ```
   timestamp
   ```

   **查詢範圍 (Query scope)**:
   - 選擇 **「集合群組 (Collection group)」**

3. **索引設定**：

   在「索引」區塊中，確保以下選項已啟用：
   - ✅ **Collection** - Enabled
   - ✅ **Collection group** - Enabled
   - ✅ **Array** - (保持預設)
   - ✅ **Ascending** - Enabled（遞增排序）
   - ✅ **Descending** - Enabled（遞減排序）

4. 點擊 **「建立 (Create)」**

### 步驟 3：等待索引生效

- 單一欄位索引通常會**立即生效**
- 如果資料庫有大量數據，可能需要等待 1-2 分鐘

---

## 🔍 為什麼需要單一欄位索引？

### 原因

程式碼使用了以下查詢：

```dart
_db
  .collection('users')
  .doc(user.uid)
  .collection('food_diary')
  .orderBy('timestamp', descending: true)
  .limit(100)
  .snapshots();
```

這個查詢需要 `timestamp` 欄位支援：
- **Descending (遞減排序)** - 用於 `orderBy('timestamp', descending: true)`

### 預設行為

Firebase 預設只為欄位啟用 **Ascending (遞增)** 索引，如果您使用 `descending: true`，就需要手動啟用 **Descending** 索引。

---

## 🛠️ 程式碼修改（已完成）

為了避免複合索引問題，我已經修改了查詢邏輯：

### 修改前（需要複合索引）

```dart
Stream<QuerySnapshot> getDailyFoodEntriesStream(DateTime date) {
  return _db
      .collection('users')
      .doc(user.uid)
      .collection('food_diary')
      .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
      .where('timestamp', isLessThanOrEqualTo: endOfDay)  // ← 兩個 where 需要複合索引
      .snapshots();
}
```

### 修改後（只需單一欄位索引）

```dart
Stream<QuerySnapshot> getDailyFoodEntriesStream(DateTime date) {
  return _db
      .collection('users')
      .doc(user.uid)
      .collection('food_diary')
      .orderBy('timestamp', descending: true)  // ← 只用 orderBy
      .limit(100)
      .snapshots();
}
```

**日期過濾改為在客戶端進行**：

```dart
Map<String, dynamic> calculateDailyNutritionFromEntries(
  QuerySnapshot entries, {
  DateTime? targetDate,
}) {
  final date = targetDate ?? DateTime.now();
  final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
  final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;

  for (var doc in entries.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as int?;

    // 客戶端過濾：只處理今日的記錄
    if (timestamp == null || timestamp < startOfDay || timestamp > endOfDay) {
      continue;
    }

    // 累加營養數據...
  }
}
```

---

## 📊 效能考量

### 優點

✅ 不需要複合索引，設定更簡單
✅ 查詢只需單一欄位索引，Firebase 免費方案足夠
✅ 使用 `limit(100)` 限制查詢數量，避免過度讀取

### 缺點

❌ 客戶端過濾會讀取最近 100 筆記錄（而非只讀取今天的記錄）
❌ 如果使用者在一天內記錄超過 100 筆，會遺漏較早的記錄

### 適用場景

✅ 適合一般使用者（每天記錄 5-20 筆飲食）
✅ 適合開發測試階段
⚠️ 如果每天記錄數量極大，建議改用伺服器端查詢（Cloud Functions）

---

## 🔐 額外檢查：Security Rules

如果設定索引後仍有權限問題，請確認 Security Rules：

### 前往 Security Rules

1. Firebase Console → Firestore Database
2. 點擊 **「規則 (Rules)」** 標籤
3. 確認包含以下規則：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // member 集合：使用者只能讀寫自己的資料
    match /member/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // users 集合及其子集合
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // food_diary 子集合（重要！）
      match /food_diary/{entryId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

4. 點擊 **「發布 (Publish)」**

---

## ✅ 驗證步驟

1. ✅ 在 Firebase Console 設定單一欄位索引（`timestamp` - Descending）
2. ✅ 確認 Security Rules 允許使用者存取 `food_diary`
3. ✅ 重新啟動 Flutter 應用
4. ✅ 測試首頁是否正常載入營養數據

---

## 📝 相關文件

- [Firebase 索引說明文件](https://firebase.google.com/docs/firestore/query-data/indexing)
- [HOME_NUTRITION_INTEGRATION.md](HOME_NUTRITION_INTEGRATION.md)
- [NUTRITION_DATA_STORAGE.md](NUTRITION_DATA_STORAGE.md)

---

## 🆘 仍然有問題？

如果完成上述步驟後仍有錯誤，請檢查：

1. 使用者是否已登入？
2. Firebase 專案 ID 是否正確？
3. `food_diary` 集合是否為空（空集合可能導致查詢失敗）
4. 查看完整錯誤訊息（包含錯誤代碼）

如有問題，請提供完整的錯誤訊息以便進一步診斷。
