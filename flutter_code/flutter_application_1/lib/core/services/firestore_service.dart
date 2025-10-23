import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ===================================================================
// Firestore 服務 (FirestoreService)
// ===================================================================
/// 封裝所有 Cloud Firestore 相關邏輯的服務類別
class FirestoreService {
  // -------------------------------------------------------------------
  // Properties
  // -------------------------------------------------------------------

  /// Firestore 資料庫實例
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Firebase 認證實例，用來獲取當前使用者
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // -------------------------------------------------------------------
  // Public Methods
  // -------------------------------------------------------------------

  /// 新增一筆飲食日記條目
  ///
  /// [foodData] 是一個包含食物資訊的 Map，例如：
  /// {
  ///   'name': '蘋果',
  ///   'calories': 95,
  ///   'timestamp': Timestamp.now(),
  /// }
  /// 這個方法會將資料儲存到 `users/{userID}/food_diary` 集合中。
  Future<void> addFoodDiaryEntry(Map<String, dynamic> foodData) async {
    // 1. 獲取當前登入的使用者
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('錯誤：使用者未登入，無法新增資料。');
    }

    // 2. 建立指向該使用者專屬的 'food_diary' 集合的引用
    final CollectionReference foodDiaryCollection = 
        _db.collection('users').doc(user.uid).collection('food_diary');

    // 3. 在該集合中新增一筆文件
    try {
      await foodDiaryCollection.add(foodData);
      print('成功新增一筆飲食日記到 Firestore');
    } catch (e) {
      print('新增飲食日記失敗: $e');
      // 重新拋出異常，讓調用者可以處理
      throw Exception('新增資料到資料庫時發生錯誤: $e');
    }
  }

  /// 獲取目前使用者的飲食日記串流
  ///
  /// 返回一個即時的查詢快照 (QuerySnapshot) 串流。
  /// UI 層可以監聽此串流來即時顯示最新的飲食日記。
  Stream<QuerySnapshot> getFoodDiaryStream() {
    // 1. 獲取當前登入的使用者
    final User? user = _auth.currentUser;
    if (user == null) {
      // 如果使用者未登入，返回一個空的串流
      return const Stream.empty();
    }

    // 2. 返回指向該使用者飲食日記集合的快照串流，並按時間戳降序排列
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('food_diary')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ... 之後可以陸續加入更新、刪除、讀取測量數據等方法 ...
}
