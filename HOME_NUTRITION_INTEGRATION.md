# 首頁營養數據整合說明

## 概述

首頁現在已經與 `food_diary` 集合完全整合，能夠即時顯示使用者每日的營養攝取數據。

## ✅ 已實現的功能

### 1. 即時營養統計

首頁會即時監聽今日的飲食日記，並自動計算和顯示：
- **當日已攝取卡路里** - 從所有飲食記錄累加
- **營養素比例** - 蛋白質、碳水化合物、脂肪的實際攝取比例
- **進度追蹤** - 當前攝取 vs 目標攝取的對比

### 2. 數據來源整合

```
Firebase Firestore
    ↓
users/{userId}/food_diary (拍照後的營養數據)
    ↓
首頁即時監聽並統計
    ↓
顯示在視覺化圖表中
```

---

## 📊 首頁顯示的數據

### 熱量進度條
- **目標卡路里**: 從 `member` 集合的 `targetCalories` 讀取
- **當前卡路里**: 從 `food_diary` 集合即時計算（累加所有今日條目的 `calories`）
- **進度百分比**: `currentCalories / targetCalories * 100%`

範例顯示：
```
每日熱量目標
1250/2000 kcal
[進度條 ████████░░░░░░░░] 62.5%
```

### 營養素比例圖表

如果飲食記錄包含 `nutritionDetails`，首頁會顯示實際攝取比例：
- **蛋白質**: 藍色柱狀圖
- **碳水化合物**: 橙色柱狀圖
- **脂肪**: 綠色柱狀圖
- **膳食纖維**: 灰色柱狀圖（目前固定為 15%）

計算方式：
```dart
蛋白質卡路里 = 蛋白質克數 × 4
碳水化合物卡路里 = 碳水化合物克數 × 4
脂肪卡路里 = 脂肪克數 × 9

總卡路里 = 蛋白質卡路里 + 碳水化合物卡路里 + 脂肪卡路里

蛋白質百分比 = 蛋白質卡路里 / 總卡路里 × 100%
```

---

## 🔄 數據流程

### 完整流程圖

```
使用者拍照 → YOLO 辨識 → RAG 分析營養數據
    ↓
儲存到 Firebase: users/{userId}/food_diary
    {
      calories: 350,
      nutritionDetails: {
        protein: 39.0,
        carbohydrates: 0.0,
        fat: 20.5,
        ...
      }
    }
    ↓
首頁 _loadTodayFoodEntries() 監聽變化
    ↓
FirestoreService.calculateDailyNutritionFromEntries()
計算今日總營養攝取
    ↓
首頁視覺化圖表自動更新
    - 熱量進度條更新
    - 營養素比例圖更新
```

### 即時更新機制

使用 Firestore 的 `snapshots()` Stream：
```dart
_firestoreService.getTodayFoodEntriesStream().listen((snapshot) {
  // 每當飲食日記有變化時自動觸發
  final nutrition = _firestoreService.calculateDailyNutritionFromEntries(snapshot);

  setState(() {
    currentCalories = nutrition['totalCalories'];
    // 更新營養素比例圖表
  });
});
```

---

## 📁 修改的檔案

### 1. [FirestoreService](lib/core/services/firestore_service.dart:233-351)

新增方法：
- `getDailyFoodEntriesStream(DateTime date)` - 獲取特定日期的飲食日記
- `getTodayFoodEntriesStream()` - 獲取今日飲食日記
- `calculateDailyNutritionFromEntries(QuerySnapshot entries)` - 計算每日營養統計
- `calculateNutrientPercentages(Map<String, dynamic> nutrition)` - 計算營養素百分比

### 2. [HomePage](lib/features/home/presentation/pages/home_page.dart)

修改內容：
- 新增 `_foodEntriesSubscription` - 監聽飲食日記變化
- 新增 `_todayNutrition` - 儲存今日營養統計
- 新增 `_loadTodayFoodEntries()` - 載入並監聽今日飲食日記
- 修改 `currentCalories` - 從飲食日記即時計算，不再使用假資料
- 修改 `nutrients` - 根據實際攝取計算比例，不再使用假資料

---

## 💡 使用範例

### 範例 1：使用者拍照後自動更新首頁

**步驟：**
1. 使用者在相機頁面拍攝一份烤鮭魚
2. YOLO 辨識出 "salmon"，RAG 分析營養數據
3. 儲存到 `food_diary`：
   ```json
   {
     "name": "烤鮭魚",
     "calories": 350,
     "nutritionDetails": {
       "protein": 39.0,
       "carbohydrates": 0.0,
       "fat": 20.5
     },
     "timestamp": 1699564800000
   }
   ```
4. 首頁的 Stream 自動觸發
5. 計算今日總營養：
   ```
   總卡路里: 350 kcal
   蛋白質: 39g
   碳水化合物: 0g
   脂肪: 20.5g
   ```
6. 首頁圖表自動更新顯示新數據

### 範例 2：一天內多次進食

**早餐（08:00）:**
```json
{
  "mealType": "早餐",
  "calories": 400,
  "nutritionDetails": {
    "protein": 15,
    "carbohydrates": 50,
    "fat": 10
  }
}
```

**午餐（12:30）:**
```json
{
  "mealType": "午餐",
  "calories": 600,
  "nutritionDetails": {
    "protein": 35,
    "carbohydrates": 60,
    "fat": 15
  }
}
```

**首頁顯示（即時累計）:**
```
每日熱量目標
1000/2000 kcal [進度條 50%]

營養素比例：
蛋白質: 26.5% (50g)
碳水化合物: 58.2% (110g)
脂肪: 15.3% (25g)
```

---

## 🎨 視覺化改進

### 1. 熱量進度條顏色

```dart
// 根據完成度改變顏色
Color getProgressColor(double progress) {
  if (progress < 0.5) return Colors.red;        // 未達標
  if (progress < 0.9) return Colors.orange;     // 接近目標
  if (progress <= 1.1) return Colors.green;     // 達標
  return Colors.amber;                          // 超標
}
```

### 2. 營養素圖表顏色編碼

- 🔵 **蛋白質**: 藍色 (`Colors.blue[300]`)
- 🟠 **碳水化合物**: 橙色 (`Colors.orange[300]`)
- 🟢 **脂肪**: 綠色 (`Colors.green[300]`)
- ⚪ **膳食纖維**: 灰色 (`Colors.grey[400]`)

---

## 🔍 數據準確性

### 1. 舊數據兼容性

如果飲食記錄沒有 `nutritionDetails`（舊格式），系統會：
- 仍然累加 `calories` 到總卡路里
- 營養素圖表顯示為預設值或隱藏
- 不會導致錯誤或崩潰

```dart
if (data['nutritionDetails'] != null) {
  // 使用詳細營養數據
  totalProtein += nutrition['protein'];
} else {
  // 只累加卡路里
  totalCalories += data['calories'];
}
```

### 2. 計算精確度

所有營養數據使用 `double` 類型，確保小數點精確度：
```dart
double totalProtein = 0;
double totalCarbs = 0;
double totalFat = 0;
```

### 3. 即時性

使用 Firestore 的 `snapshots()` 實現毫秒級更新：
- 新增飲食記錄 → 立即更新首頁
- 刪除飲食記錄 → 立即更新首頁
- 修改飲食記錄 → 立即更新首頁

---

## 📈 未來擴展

### 1. 每週營養趨勢

```dart
Future<List<Map<String, dynamic>>> getWeeklyNutritionTrend() async {
  final weekData = <Map<String, dynamic>>[];

  for (int i = 6; i >= 0; i--) {
    final date = DateTime.now().subtract(Duration(days: i));
    final entries = await _firestoreService.getDailyFoodEntries(date);
    final nutrition = _firestoreService.calculateDailyNutritionFromEntries(entries);

    weekData.add({
      'date': date,
      'calories': nutrition['totalCalories'],
      'protein': nutrition['totalProtein'],
      'carbs': nutrition['totalCarbs'],
      'fat': nutrition['totalFat'],
    });
  }

  return weekData;
}
```

### 2. 營養建議卡片

```dart
Widget _buildNutritionAdviceCard() {
  final protein = _todayNutrition['totalProtein'];
  final targetProtein = _userBodyData['targetProtein'];

  if (protein < targetProtein * 0.8) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.info_outline, color: Colors.orange),
        title: Text('蛋白質攝取不足'),
        subtitle: Text('建議增加優質蛋白質來源，如雞胸肉、豆腐、雞蛋等'),
      ),
    );
  }

  return SizedBox.shrink();
}
```

### 3. 每日營養報告分享

```dart
Future<void> shareNutritionReport() async {
  final report = '''
📊 我的每日營養報告

🔥 總卡路里: ${_todayNutrition['totalCalories']} kcal
💪 蛋白質: ${_todayNutrition['totalProtein']}g
🍞 碳水化合物: ${_todayNutrition['totalCarbs']}g
🥑 脂肪: ${_todayNutrition['totalFat']}g

目標達成率: ${(currentCalories / targetCalories * 100).toStringAsFixed(1)}%

#營養追蹤 #健康生活
  ''';

  await Share.share(report);
}
```

---

## ⚠️ 注意事項

### 1. Firebase 查詢限制

當前實現使用時間戳範圍查詢：
```dart
.where('timestamp', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
.where('timestamp', isLessThanOrEqualTo: endOfDay.millisecondsSinceEpoch)
```

**需要創建複合索引**，在 Firebase Console 中：
```
Collection: users/{userId}/food_diary
Fields:
  - timestamp (Ascending)
```

### 2. 效能優化

- 使用 Stream 而非輪詢，減少資料庫讀取次數
- 計算在客戶端進行，不消耗 Cloud Functions 配額
- 僅查詢今日數據，不載入歷史記錄

### 3. 離線支援

Firestore 自動支援離線快取：
```dart
// 無需額外配置，Firestore 會自動：
// 1. 在離線時使用快取數據
// 2. 在重新連線時同步更新
```

### 4. 測試建議

測試場景：
1. 新用戶（無飲食記錄）→ 應顯示 0 kcal
2. 添加第一筆記錄 → 首頁應立即更新
3. 添加多筆記錄 → 應正確累加
4. 跨日測試 → 應只顯示今日數據
5. 刪除記錄 → 應立即減少總量

---

## 📚 相關文檔

- [身體數據整合功能說明](BODY_DATA_INTEGRATION.md)
- [營養數據儲存方案](NUTRITION_DATA_STORAGE.md)
- [FoodEntry 實體定義](lib/features/food_diary/domain/entities/food_entry.dart)
- [FirestoreService API](lib/core/services/firestore_service.dart)

---

## 總結

✅ **首頁現在已經完全整合飲食日記的營養數據**

這個整合實現了：
1. ⚡ **即時更新** - 使用 Stream 監聽，毫秒級響應
2. 📊 **準確統計** - 自動累加所有今日飲食記錄
3. 🎨 **視覺化呈現** - 熱量進度條 + 營養素比例圖
4. 🔄 **完整閉環** - 拍照 → 辨識 → 儲存 → 顯示

使用者體驗：
- 拍照後首頁**自動更新**，無需手動刷新
- 數據來自**真實飲食記錄**，不再是假資料
- 營養比例反映**實際攝取**，而非目標值

這樣就形成了一個完整的營養追蹤系統！🎉
