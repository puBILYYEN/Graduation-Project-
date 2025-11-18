/// ==========================================================================
/// @檔案: firestore_service.dart
/// @描述: 封裝所有與 Firebase Cloud Firestore 互動的邏輯，作為資料庫存取層。
/// ==========================================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// --------------------------------------------------------------------
/// @類別: FirestoreService
/// @描述: 處理所有 Cloud Firestore 資料庫操作的服務類別。
///        提供業務導向的 API，隱藏底層資料庫的實作細節。
/// --------------------------------------------------------------------
class FirestoreService {
  // -------------------------------------------------------------------
  // @區塊: 屬性 (Properties)
  // @描述: 定義這個服務需要的資料庫和認證實例。
  // -------------------------------------------------------------------

  /// [_db]: Cloud Firestore 資料庫的主要實例，用於執行所有資料庫操作。
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// [_auth]: Firebase 認證的實例，主要用來獲取當前登入使用者的 UID。
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // -------------------------------------------------------------------
  // @區塊: 公開方法 (Public Methods)
  // -------------------------------------------------------------------

  /// ------------------------------------------------------------------
  /// @方法: addFoodDiaryEntry
  /// @描述: 新增一筆飲食日記條目到當前登入使用者的資料庫中。
  /// @參數: [foodData] - 一個 Map<String, dynamic>，包含要新增的食物資料。
  /// @返回: Future<void> - 操作完成後返回。
  /// @拋出: 如果使用者未登入或寫入失敗，則拋出 Exception。
  /// ------------------------------------------------------------------
  Future<void> addFoodDiaryEntry(Map<String, dynamic> foodData) async {
    // 步驟 1: 獲取當前登入的使用者。如果為 null，表示未登入，應立即拋出錯誤。
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('錯誤：使用者未登入，無法新增資料。');
    }

    // 步驟 2: 建立一個指向特定使用者 'food_diary' 子集合的參照 (reference)。
    // 這種路徑結構 (`users/{userID}/food_diary`) 可以確保每個使用者的資料都是隔離的。
    final CollectionReference foodDiaryCollection = 
        _db.collection('users').doc(user.uid).collection('food_diary');

    // 步驟 3: 使用 try-catch 區塊來執行資料庫寫入操作，以處理可能的錯誤。
    try {
      // 呼叫 .add() 方法將 foodData 作為一個新文件新增到集合中。
      await foodDiaryCollection.add(foodData);
      print('成功新增一筆飲食日記到 Firestore');
    } catch (e) {
      // 如果寫入失敗，在控制台打印錯誤，並重新拋出異常，讓上層呼叫者可以進行處理 (例如：在 UI 上顯示錯誤訊息)。
      print('新增飲食日記失敗: $e');
      throw Exception('新增資料到資料庫時發生錯誤: $e');
    }
  }

  /// ------------------------------------------------------------------
  /// @方法: getFoodDiaryStream
  /// @描述: 獲取當前使用者所有飲食日記的即時串流 (Stream)。
  /// @返回: Stream<QuerySnapshot> - 一個 Firestore 查詢快照的串流。
  ///         UI 層可以透過監聽此串流來實現資料的即時更新。
  /// ------------------------------------------------------------------
  Stream<QuerySnapshot> getFoodDiaryStream() {
    // 步驟 1: 檢查使用者登入狀態。
    final User? user = _auth.currentUser;
    if (user == null) {
      // 如果使用者未登入，不應拋出錯誤，而是返回一個空的串流。
      // 這樣 UI 層就不會因為等待一個永遠不會來的資料而掛起。
      return const Stream.empty();
    }

    // 步驟 2: 建立查詢並返回串流。
    // - .collection('users').doc(user.uid).collection('food_diary'): 定位到使用者的日記集合。
    // - .orderBy('timestamp', descending: true): 根據 'timestamp' 欄位進行降序排序，確保最新的日記在最前面。
    // - .snapshots(): 返回一個即時串流，每當集合中的資料發生變化時，它都會發出一個新的快照。
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('food_diary')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // -------------------------------------------------------------------
  // @區塊: 使用者身體數據相關方法
  // -------------------------------------------------------------------

  /// ------------------------------------------------------------------
  /// @方法: getUserBodyData
  /// @描述: 讀取當前使用者的身體數據（身高、體重、BMI等）
  /// @返回: Future<Map<String, dynamic>?> - 使用者的身體數據，若無則返回 null
  /// ------------------------------------------------------------------
  Future<Map<String, dynamic>?> getUserBodyData() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('錯誤：使用者未登入，無法讀取資料。');
    }

    try {
      final DocumentSnapshot doc = await _db.collection('member').doc(user.uid).get();

      if (doc.exists) {
        print('成功讀取使用者身體數據');
        return doc.data() as Map<String, dynamic>?;
      } else {
        print('使用者身體數據不存在');
        return null;
      }
    } catch (e) {
      print('讀取使用者身體數據失敗: $e');
      throw Exception('讀取資料庫時發生錯誤: $e');
    }
  }

  /// ------------------------------------------------------------------
  /// @方法: getUserBodyDataStream
  /// @描述: 獲取當前使用者身體數據的即時串流
  /// @返回: Stream<DocumentSnapshot> - 使用者身體數據的即時串流
  /// ------------------------------------------------------------------
  Stream<DocumentSnapshot> getUserBodyDataStream() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _db.collection('member').doc(user.uid).snapshots();
  }

  /// ------------------------------------------------------------------
  /// @方法: updateUserBodyData
  /// @描述: 更新當前使用者的身體數據
  /// @參數: [bodyData] - 要更新的身體數據
  /// @返回: Future<void> - 操作完成後返回
  /// ------------------------------------------------------------------
  Future<void> updateUserBodyData(Map<String, dynamic> bodyData) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('錯誤：使用者未登入，無法更新資料。');
    }

    try {
      // 添加更新時間戳
      bodyData['updatedAt'] = FieldValue.serverTimestamp();

      await _db.collection('member').doc(user.uid).set(
        bodyData,
        SetOptions(merge: true), // 使用 merge 以避免覆蓋其他欄位
      );
      print('成功更新使用者身體數據');
    } catch (e) {
      print('更新使用者身體數據失敗: $e');
      throw Exception('更新資料庫時發生錯誤: $e');
    }
  }

  /// ------------------------------------------------------------------
  /// @方法: parseBodyDataFromText
  /// @描述: 從 AI 回應文字中提取身體數據的數字
  /// @參數: [text] - AI 回應的文字內容
  /// @返回: Map<String, dynamic> - 提取出的身體數據
  /// ------------------------------------------------------------------
  Map<String, dynamic> parseBodyDataFromText(String text) {
    final Map<String, dynamic> extractedData = {};

    // 定義數據模式和對應的 Firebase 欄位名稱
    final patterns = {
      'weight': [
        RegExp(r'體重[：:是為]?\s*(\d+\.?\d*)\s*(?:kg|公斤|KG)', caseSensitive: false),
        RegExp(r'(?:目前|現在|我的)體重\s*(\d+\.?\d*)', caseSensitive: false),
        RegExp(r'(\d+\.?\d*)\s*(?:kg|公斤|KG)', caseSensitive: false),
      ],
      'height': [
        RegExp(r'身高[：:是為]?\s*(\d+\.?\d*)\s*(?:cm|公分|CM)', caseSensitive: false),
        RegExp(r'(?:目前|現在|我的)身高\s*(\d+\.?\d*)', caseSensitive: false),
        RegExp(r'(\d+\.?\d*)\s*(?:cm|公分|CM)', caseSensitive: false),
      ],
      'age': [
        RegExp(r'年齡[：:是為]?\s*(\d+)\s*(?:歲|岁)?', caseSensitive: false),
        RegExp(r'(?:目前|現在|我)(?:今年)?\s*(\d+)\s*歲', caseSensitive: false),
      ],
      'sleepHours': [
        RegExp(r'睡眠?[時时][間间][：:是為]?\s*(\d+\.?\d*)\s*(?:小時|小时|hours?)', caseSensitive: false),
        RegExp(r'睡[了]?\s*(\d+\.?\d*)\s*(?:小時|小时|hours?)', caseSensitive: false),
      ],
      'heartRate': [
        RegExp(r'心[率跳][：:是為]?\s*(\d+)\s*(?:bpm|次|下)?', caseSensitive: false),
        RegExp(r'(?:心跳|脈搏)\s*(\d+)', caseSensitive: false),
      ],
    };

    // 血壓的特殊處理（格式：120/80）
    final bloodPressurePattern = RegExp(
      r'血壓[：:是為]?\s*(\d+)\s*/\s*(\d+)',
      caseSensitive: false,
    );
    final bpMatch = bloodPressurePattern.firstMatch(text);
    if (bpMatch != null) {
      extractedData['bloodPressure'] = '${bpMatch.group(1)}/${bpMatch.group(2)}';
    }

    // 提取其他數據
    patterns.forEach((key, regexList) {
      for (final regex in regexList) {
        final match = regex.firstMatch(text);
        if (match != null && match.group(1) != null) {
          final value = match.group(1)!;

          // 根據欄位類型進行轉換
          if (key == 'age' || key == 'heartRate') {
            extractedData[key] = int.tryParse(value);
          } else if (key == 'weight' || key == 'sleepHours') {
            extractedData[key] = double.tryParse(value);
          } else if (key == 'height') {
            // 身高轉換為整數
            final heightValue = double.tryParse(value);
            if (heightValue != null) {
              extractedData[key] = heightValue.round();
            }
          }

          // 找到匹配後就跳出內層循環
          if (extractedData[key] != null) break;
        }
      }
    });

    return extractedData;
  }

  // -------------------------------------------------------------------
  // @區塊: 飲食日記營養統計相關方法
  // -------------------------------------------------------------------

  /// ------------------------------------------------------------------
  /// @方法: getDailyFoodEntriesStream
  /// @描述: 獲取特定日期的飲食日記即時串流
  /// @參數: [date] - 查詢的日期
  /// @返回: Stream<QuerySnapshot> - 飲食日記的即時串流
  /// ------------------------------------------------------------------
  Stream<QuerySnapshot> getDailyFoodEntriesStream(DateTime date) {
    final User? user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    // 簡化查詢：只使用 orderBy，避免複合索引需求
    // 日期過濾將在 calculateDailyNutritionFromEntries 中進行客戶端過濾
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('food_diary')
        .orderBy('timestamp', descending: true)
        .limit(100) // 限制最近 100 筆記錄以優化效能
        .snapshots();
  }

  /// ------------------------------------------------------------------
  /// @方法: getTodayFoodEntriesStream
  /// @描述: 獲取今日飲食日記的即時串流（方便首頁使用）
  /// @返回: Stream<QuerySnapshot> - 今日飲食日記的即時串流
  /// ------------------------------------------------------------------
  Stream<QuerySnapshot> getTodayFoodEntriesStream() {
    return getDailyFoodEntriesStream(DateTime.now());
  }

  /// ------------------------------------------------------------------
  /// @方法: calculateDailyNutritionFromEntries
  /// @描述: 從飲食日記條目計算每日營養攝取（包含客戶端日期過濾）
  /// @參數: [entries] - 飲食日記條目列表（QuerySnapshot）
  /// @參數: [targetDate] - 目標日期（可選，預設為今天）
  /// @返回: Map<String, dynamic> - 包含總營養數據
  /// ------------------------------------------------------------------
  Map<String, dynamic> calculateDailyNutritionFromEntries(
    QuerySnapshot entries, {
    DateTime? targetDate,
  }) {
    // 計算目標日期的開始和結束時間戳
    final date = targetDate ?? DateTime.now();
    final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSodium = 0;

    int entryCount = 0;

    for (var doc in entries.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // 客戶端日期過濾：只處理今日的記錄
      final timestampField = data['timestamp'];
      int? timestamp;

      if (timestampField is Timestamp) {
        timestamp = timestampField.millisecondsSinceEpoch;
      } else if (timestampField is int) {
        timestamp = timestampField;
      }

      if (timestamp == null || timestamp < startOfDay || timestamp > endOfDay) {
        continue; // 跳過不是今天的記錄
      }

      // 累加基本卡路里（所有條目都應該有）
      totalCalories += (data['calories'] ?? 0).toDouble();

      // 如果有詳細營養數據，則累加
      if (data['nutritionDetails'] != null) {
        final nutrition = data['nutritionDetails'] as Map<String, dynamic>;
        totalProtein += (nutrition['protein'] ?? 0).toDouble();
        totalCarbs += (nutrition['carbohydrates'] ?? nutrition['carbs'] ?? 0).toDouble();
        totalFat += (nutrition['fat'] ?? 0).toDouble();
        totalFiber += (nutrition['fiber'] ?? 0).toDouble();
        totalSodium += (nutrition['sodium'] ?? 0).toDouble();
      }

      entryCount++;
    }

    return {
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'totalFiber': totalFiber,
      'totalSodium': totalSodium,
      'entryCount': entryCount,
      'hasDetailedNutrition': totalProtein > 0 || totalCarbs > 0 || totalFat > 0,
    };
  }

  /// ------------------------------------------------------------------
  /// @方法: calculateNutrientPercentages
  /// @描述: 計算營養素佔比（用於圓餅圖等視覺化）
  /// @參數: [nutrition] - 營養數據
  /// @返回: Map<String, double> - 各營養素的百分比
  /// ------------------------------------------------------------------
  Map<String, double> calculateNutrientPercentages(Map<String, dynamic> nutrition) {
    final protein = nutrition['totalProtein'] as double;
    final carbs = nutrition['totalCarbs'] as double;
    final fat = nutrition['totalFat'] as double;

    // 根據卡路里計算百分比
    final proteinCal = protein * 4;
    final carbsCal = carbs * 4;
    final fatCal = fat * 9;
    final total = proteinCal + carbsCal + fatCal;

    if (total == 0) {
      return {
        'protein': 0,
        'carbs': 0,
        'fat': 0,
      };
    }

    return {
      'protein': (proteinCal / total * 100),
      'carbs': (carbsCal / total * 100),
      'fat': (fatCal / total * 100),
    };
  }

  // ... 之後可以陸續加入更新、刪除、讀取測量數據等方法 ...
}
