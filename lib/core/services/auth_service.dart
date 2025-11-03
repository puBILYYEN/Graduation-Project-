
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ===================================================================
// 認證服務 (AuthService)
// ===================================================================
/// 封裝所有 Firebase Authentication 相關邏輯的服務類別
class AuthService {
  // -------------------------------------------------------------------
  // Properties
  // -------------------------------------------------------------------

  /// Firebase 認證實例
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Google 登入實例
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Firestore 資料庫實例
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -------------------------------------------------------------------
  // Streams
  // -------------------------------------------------------------------

  /// 提供使用者認證狀態的串流
  ///
  /// 當使用者登入或登出時，這個串流會發出新的狀態。
  /// UI 層可以監聽此串流來決定要顯示登入頁面還是主頁。
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // -------------------------------------------------------------------
  // Public Methods
  // -------------------------------------------------------------------

  /// 將使用者資料寫入 Firestore member 集合
  ///
  /// 在使用者成功註冊後，將使用者的基本資訊儲存到 Firestore 中
  /// [user] Firebase 認證使用者物件
  /// [username] 使用者名稱
  Future<void> _createUserDocument(User user, String username) async {
    try {
      print('📝 正在建立使用者文檔到 Firestore...');

      // 標準會員資料結構（按邏輯順序排列）
      final userData = {
        // === 1. 基本識別資料 ===
        'id': user.uid,
        'uid': user.uid,
        'email': user.email,
        'username': username,
        'displayName': username,
        'password': '', // Firebase Auth 已處理，不儲存

        // === 2. 個人基本資料 ===
        'age': null, // 待填寫
        'gender': null, // 待填寫：true=男性, false=女性
        'height': null, // 待填寫 (cm)
        'weight': null, // 待填寫 (kg)
        'dateOfBirth': null, // 待填寫

        // === 3. 聯絡資訊 ===
        'phoneNumber': '',
        'isEmailVerified': user.emailVerified,

        // === 4. 大頭照資料 ===
        'profilePhotoUrl': '',
        'profilePhotoThumbUrl': '',
        'hasProfilePhoto': false,
        'photoURL': user.photoURL ?? '',

        // === 5. 健康目標設定 ===
        'goal': null, // 待選擇：0=維持, 1=減重, 2=增重

        // === 6. 計算數值（基於個人資料計算）===
        'BMR': null, // 基礎代謝率（待計算）
        'TDEE_level': null, // 總日耗能（待計算）
        'suggested_calories': null, // 建議卡路里（待計算）

        // === 7. 營養目標設定 ===
        'targetCalories': null, // 目標卡路里
        'targetProtein': null, // 目標蛋白質 (g)
        'targetCarbs': null, // 目標碳水化合物 (g)
        'targetFat': null, // 目標脂肪 (g)

        // === 8. 應用偏好設定 ===
        'preferredUnits': 'metric', // 單位制：metric 或 imperial
        'language': 'zh-TW', // 語言設定
        'timezone': 'Asia/Taipei', // 時區設定
        'notificationsEnabled': true, // 通知設定
        'darkMode': false, // 深色模式

        // === 9. 會員狀態 ===
        'membershipType': 'free', // 會員類型：free, premium
        'isActive': true, // 帳號是否啟用

        // === 10. 統計資料 ===
        'totalFoodEntries': 0, // 總食物紀錄數
        'streakDays': 0, // 連續記錄天數

        // === 11. 時間戳記（最後，因為是系統自動）===
        'created_at': FieldValue.serverTimestamp(), // 建立時間
        'updatedAt': FieldValue.serverTimestamp(), // 最後更新時間
        'lastLoginAt': FieldValue.serverTimestamp(), // 最後登入時間
        'lastActiveDate': FieldValue.serverTimestamp(), // 最後活躍時間
      };

      // 將資料寫入 member 集合
      await _firestore.collection('member').doc(user.uid).set(userData);

      print('✅ 使用者文檔建立成功: ${user.uid}');
    } catch (e) {
      print('💥 建立使用者文檔失敗: $e');
      // 不要拋出錯誤，因為 Authentication 已經成功
      // 這只是額外的資料儲存步驟
    }
  }

  /// 透過 Google 帳號登入
  ///
  /// 彈出 Google 登入視窗，並在成功後將憑證交給 Firebase。
  /// 成功時返回 Firebase 的 User 物件，失敗或取消時返回 null。
  Future<User?> signInWithGoogle() async {
    try {
      print('🚀 開始 Google 登入流程...');

      // 1. 觸發 Google 登入流程
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 使用者取消了登入流程
        print('❌ Google 登入被使用者取消');
        return null;
      }

      print('✅ Google 帳戶登入成功: ${googleUser.email}');

      // 2. 取得 Google 帳號的認證憑證
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('🔑 取得 Google 認證憑證');

      // 檢查憑證是否有效
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('❌ Google 認證憑證無效');
        throw Exception('Google 認證憑證無效');
      }

      // 3. 將憑證轉換為 Firebase 可用的 OAuthCredential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('🔐 建立 Firebase 憑證');

      // 4. 使用該憑證登入 Firebase
      print('🔄 正在向 Firebase 認證...');
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      print('🎉 Google 登入成功: ${userCredential.user?.displayName} (${userCredential.user?.email})');
      return userCredential.user;
    } catch (e) {
      print('💥 Google 登入失敗: $e');
      print('錯誤類型: ${e.runtimeType}');

      // 詳細錯誤處理
      if (e.toString().contains('network_error')) {
        throw Exception('網路連線錯誤，請檢查網路連線');
      } else if (e.toString().contains('sign_in_canceled')) {
        print('使用者取消登入');
        return null;
      } else if (e.toString().contains('sign_in_failed')) {
        throw Exception('Google 登入服務暫時無法使用');
      }

      // 將錯誤向上拋出，讓 ViewModel 處理
      throw Exception('Google 登入失敗: $e');
    }
  }

  /// 使用電子郵件和密碼登入
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // 根據錯誤代碼拋出可讀的錯誤訊息
      if (e.code == 'user-not-found') {
        throw Exception('找不到該用戶。');
      } else if (e.code == 'wrong-password') {
        throw Exception('密碼錯誤。');
      } else if (e.code == 'invalid-email') {
        throw Exception('電子郵件格式不正確。');
      }
      throw Exception('登入失敗，請稍後再試。');
    } catch (e) {
      throw Exception('發生未知錯誤。');
    }
  }

  /// 使用電子郵件和密碼註冊新用戶
  /// [email] 使用者電子郵件
  /// [password] 使用者密碼
  /// [username] 使用者名稱（可選，會寫入 Firestore）
  Future<User?> signUpWithEmailAndPassword(String email, String password, {String? username}) async {
    try {
      print('🔄 開始註冊新使用者: $email');

      // 1. 在 Firebase Authentication 中建立使用者
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        print('✅ Firebase Authentication 註冊成功: ${user.uid}');

        // 2. 如果提供了使用者名稱，將資料寫入 Firestore
        if (username != null && username.isNotEmpty) {
          await _createUserDocument(user, username);
        }

        // 3. 更新 displayName（如果提供了使用者名稱）
        if (username != null && username.isNotEmpty) {
          await user.updateDisplayName(username);
          await user.reload();
          print('✅ 使用者 displayName 更新完成: $username');
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('💥 Firebase Authentication 錯誤: ${e.code} - ${e.message}');
      if (e.code == 'weak-password') {
        throw Exception('密碼強度不足。');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('此電子郵件已被註冊。');
      } else if (e.code == 'invalid-email') {
        throw Exception('電子郵件格式不正確。');
      }
      throw Exception('註冊失敗，請稍後再試。');
    } catch (e) {
      print('💥 註冊過程發生錯誤: $e');
      throw Exception('發生未知錯誤。');
    }
  }

  /// 登出目前的使用者
  ///
  /// 同時會從 Firebase 和 Google 登出。
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // 從 Google 登出
      await _firebaseAuth.signOut(); // 從 Firebase 登出
      print('使用者已成功登出');
    } catch (e) {
      print('登出時發生錯誤: $e');
    }
  }
}
