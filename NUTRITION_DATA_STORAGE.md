# 營養數據儲存方案

## 問題背景

拍照後，經過 YOLO 辨識和 RAG 分析，會得到以下數據：
- YOLO 預測結果（食物名稱、信心度）
- 營養數據（蛋白質、碳水化合物、脂肪、卡路里等）
- Gemini AI 的食物說明
- 飲食建議

需要決定如何在 Firebase 中儲存這些數據。

---

## ✅ 推薦方案：擴展現有 `food_diary` 集合

### 為什麼選擇擴展而非新建？

#### 優點
1. **資料一致性**：飲食記錄和營養數據天然屬於同一個邏輯單元
2. **查詢效率**：統計每日/每週營養攝取時，只需查詢一個集合
3. **代碼復用**：可以使用現有的 FoodDiaryRepository 和 ViewModel
4. **避免資料同步問題**：不需要維護多個集合之間的關聯
5. **符合業界最佳實踐**：類似 MyFitnessPal、Lose It! 等應用的設計

#### 缺點（及解決方案）
- 文檔大小可能增加 → 使用可選欄位，舊數據不會受影響
- 查詢複雜度可能增加 → Firebase 的複合索引可以優化查詢

---

## 📊 新的資料結構

### Firebase Firestore 路徑
```
users/{userId}/food_diary/{entryId}
```

### 完整文檔結構（JSON 範例）

```json
{
  // === 基本資料（必填） ===
  "name": "烤鮭魚",
  "chineseName": "烤鮭魚",
  "mealType": "午餐",
  "calories": 350,
  "imageUrls": [
    "https://storage.googleapis.com/..."
  ],
  "servingInfo": "150g",
  "timestamp": 1699564800000,

  // === 完整營養數據（選填，從 RAG 獲取） ===
  "nutritionDetails": {
    "protein": 39.0,           // 蛋白質 (g)
    "carbohydrates": 0.0,      // 碳水化合物 (g)
    "fat": 20.5,               // 脂肪 (g)
    "fiber": 0.0,              // 膳食纖維 (g)
    "sugar": 0.0,              // 糖 (g)
    "sodium": 90.0,            // 鈉 (mg)
    "saturatedFat": 3.8,       // 飽和脂肪 (g)
    "cholesterol": 94.0,       // 膽固醇 (mg)
    "calcium": 20.0,           // 鈣 (mg)
    "iron": 0.8,               // 鐵 (mg)
    "vitaminA": 150.0,         // 維生素A (IU)
    "vitaminC": 0.0,           // 維生素C (mg)
    "potassium": 628.0         // 鉀 (mg)
  },

  // === AI 分析結果（選填，從 Gemini 獲取） ===
  "geminiReply": "這是一份營養豐富的烤鮭魚，富含優質蛋白質和 Omega-3 脂肪酸...",
  "dietAdvice": "建議搭配蔬菜沙拉和糙米飯，以達到營養均衡...",

  // === YOLO 預測結果（選填，用於追蹤辨識準確度） ===
  "predictions": [
    {
      "class_id": 5,
      "class_name": "salmon",
      "confidence": 0.95
    }
  ]
}
```

---

## 🔧 已完成的修改

### 1. 擴展 FoodEntry 實體

**檔案**: [lib/features/food_diary/domain/entities/food_entry.dart](lib/features/food_diary/domain/entities/food_entry.dart)

新增欄位：
- `nutritionDetails`: 完整營養數據（蛋白質、碳水、脂肪等 13 項）
- `geminiReply`: Gemini AI 的食物說明
- `dietAdvice`: 飲食建議
- `timestamp`: 時間戳記
- `predictions`: YOLO 預測結果

新增類別：
- `NutritionDetails`: 營養詳細資料
- `YoloPrediction`: YOLO 預測結果

新增方法：
- `FoodEntry.fromJson()`: 從 Firebase JSON 反序列化
- `FoodEntry.toJson()`: 序列化為 Firebase JSON
- `NutritionDetails.totalCalories`: 根據三大營養素計算總卡路里

---

## 💡 使用範例

### 範例 1：拍照後儲存完整營養數據

```dart
// 1. 使用 YOLO API 分析圖片
final analysisResult = await YoloApiService.analyzeImage(imageFile);

// 2. 從 API 回應建立 FoodEntry
final foodEntry = FoodEntry(
  name: analysisResult.predictions.first.className,
  chineseName: '烤鮭魚',  // 可從翻譯 API 獲取
  mealType: '午餐',
  calories: 350,
  imageUrls: [analysisResult.imagePath],
  servingInfo: '150g',
  timestamp: DateTime.now(),

  // 完整營養數據（從 Python 營養資料庫獲取）
  nutritionDetails: NutritionDetails(
    protein: 39.0,
    carbohydrates: 0.0,
    fat: 20.5,
    fiber: 0.0,
    sodium: 90.0,
    calcium: 20.0,
    iron: 0.8,
    vitaminA: 150.0,
    vitaminC: 0.0,
    potassium: 628.0,
  ),

  // AI 分析結果
  geminiReply: analysisResult.geminiReply,
  dietAdvice: analysisResult.dietAdvice,

  // YOLO 預測結果
  predictions: analysisResult.predictions
    .map((p) => YoloPrediction(
      classId: p.classId,
      className: p.className,
      confidence: p.confidence,
    ))
    .toList(),
);

// 3. 儲存到 Firebase
await firestoreService.addFoodDiaryEntry(foodEntry.toJson());
```

### 範例 2：統計每日營養攝取

```dart
// 獲取今日所有飲食記錄
final entries = await foodDiaryRepository.getFoodEntries(DateTime.now());

// 計算總營養攝取
double totalProtein = 0;
double totalCarbs = 0;
double totalFat = 0;
double totalCalories = 0;

for (final entry in entries) {
  if (entry.nutritionDetails != null) {
    totalProtein += entry.nutritionDetails!.protein;
    totalCarbs += entry.nutritionDetails!.carbohydrates;
    totalFat += entry.nutritionDetails!.fat;
    totalCalories += entry.nutritionDetails!.totalCalories;
  } else {
    // 舊數據只有總卡路里
    totalCalories += entry.calories;
  }
}

print('今日營養攝取：');
print('蛋白質: ${totalProtein}g');
print('碳水化合物: ${totalCarbs}g');
print('脂肪: ${totalFat}g');
print('總卡路里: ${totalCalories} kcal');
```

### 範例 3：向後兼容（舊數據沒有營養詳情）

```dart
// 讀取 Firebase 數據
final snapshot = await firestore
  .collection('users')
  .doc(userId)
  .collection('food_diary')
  .get();

for (final doc in snapshot.docs) {
  final entry = FoodEntry.fromJson(doc.data());

  // 檢查是否有完整營養數據
  if (entry.nutritionDetails != null) {
    print('完整營養數據：${entry.nutritionDetails!.protein}g 蛋白質');
  } else {
    print('僅有總卡路里：${entry.calories} kcal');
  }
}
```

---

## 🔄 資料流程

### 完整流程圖

```
[使用者拍照]
    ↓
Flutter: CameraPage.takePicture()
    ↓
上傳圖片到 Flask API
    ↓
YOLO 辨識食物
    ↓
查詢營養資料庫（nutrition_data_manager.py）
    ↓
Gemini/Claude 生成說明和建議（RAG）
    ↓
Flask API 返回完整分析結果：
  - predictions (YOLO 結果)
  - nutritionDetails (營養數據)
  - geminiReply (食物說明)
  - dietAdvice (飲食建議)
    ↓
Flutter: 建立 FoodEntry 物件
    ↓
FirestoreService.addFoodDiaryEntry()
    ↓
儲存到 Firebase: users/{userId}/food_diary/{entryId}
    ↓
FoodDiaryPage 自動更新顯示
```

---

## 📈 查詢索引建議

為了優化查詢效率，建議在 Firebase Console 創建以下複合索引：

### 索引 1：按日期查詢飲食記錄
```
Collection: users/{userId}/food_diary
Fields:
  - timestamp (Descending)
  - mealType (Ascending)
```

### 索引 2：按餐次統計
```
Collection: users/{userId}/food_diary
Fields:
  - mealType (Ascending)
  - timestamp (Descending)
```

---

## 🚀 未來擴展

### 1. 新增每日營養統計視圖

```dart
class DailyNutritionSummary {
  final DateTime date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int mealCount;

  // 計算營養素佔比
  double get proteinPercentage => (totalProtein * 4) / totalCalories * 100;
  double get carbsPercentage => (totalCarbs * 4) / totalCalories * 100;
  double get fatPercentage => (totalFat * 9) / totalCalories * 100;

  // 與目標比較
  bool isWithinCalorieGoal(double targetCalories) {
    return totalCalories >= targetCalories * 0.9 &&
           totalCalories <= targetCalories * 1.1;
  }
}
```

### 2. 營養建議優化

基於歷史數據，RAG 系統可以提供更個人化的建議：

```python
def generate_personalized_advice(user_id, current_meal):
    # 查詢使用者最近 7 天的飲食記錄
    meal_history = firebase_service.get_user_meal_history(user_id, limit=21)

    # 分析營養攝取趨勢
    avg_protein = calculate_avg_nutrient(meal_history, 'protein')
    avg_carbs = calculate_avg_nutrient(meal_history, 'carbs')
    avg_fat = calculate_avg_nutrient(meal_history, 'fat')

    # 生成個人化建議
    advice = rag_service.generate_advice(
        current_meal=current_meal,
        nutrition_trends={'protein': avg_protein, 'carbs': avg_carbs, 'fat': avg_fat},
        user_goals=get_user_goals(user_id)
    )

    return advice
```

### 3. 營養缺口分析

```dart
class NutritionGapAnalysis {
  final Map<String, double> currentIntake;   // 當前攝取
  final Map<String, double> recommendedIntake;  // 建議攝取

  Map<String, double> get gaps {
    final gaps = <String, double>{};
    for (final nutrient in recommendedIntake.keys) {
      final current = currentIntake[nutrient] ?? 0;
      final recommended = recommendedIntake[nutrient] ?? 0;
      gaps[nutrient] = recommended - current;
    }
    return gaps;
  }

  List<String> get deficientNutrients {
    return gaps.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();
  }
}
```

---

## ⚠️ 注意事項

### 1. 資料遷移
- 舊的飲食記錄沒有 `nutritionDetails` 欄位，但仍然可以正常讀取
- 新增欄位都是可選的（nullable），不會破壞現有數據

### 2. 營養數據來源
- Python 後端需要確保從營養資料庫正確提取數據
- 建議使用台灣食品營養成分資料庫（FDA）作為主要數據源

### 3. 效能考量
- 單個文檔大小不應超過 1 MB（Firebase 限制）
- 圖片 URL 應使用 Firebase Storage，不要將圖片 base64 編碼儲存

### 4. 隱私保護
- 營養數據屬於敏感個人健康資訊
- 確保 Firebase Security Rules 正確設定，只允許使用者存取自己的數據

```javascript
// Firebase Security Rules 範例
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/food_diary/{entryId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 📚 相關檔案

| 功能 | 檔案路徑 |
|------|--------|
| FoodEntry 實體 | `lib/features/food_diary/domain/entities/food_entry.dart` |
| Firestore 服務 | `lib/core/services/firestore_service.dart` |
| 飲食日記 Repository | `lib/features/food_diary/domain/repositories/food_diary_repository.dart` |
| YOLO API 服務 | `lib/core/services/api/yolo_api_service.dart` |
| 營養資料管理器 | `yolov8_flask_api/services/nutrition_data_manager.py` |
| Firebase 服務（Python） | `yolov8_flask_api/services/firebase_service.py` |

---

## 總結

✅ **建議採用擴展 `food_diary` 集合的方案**

這個方案：
- 保持資料結構的一致性和簡潔性
- 方便統計和查詢
- 向後兼容現有數據
- 為未來功能擴展預留空間

如有其他需求或問題，可以隨時調整方案！
