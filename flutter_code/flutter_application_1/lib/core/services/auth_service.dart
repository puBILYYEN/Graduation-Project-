
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('密碼強度不足。');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('此電子郵件已被註冊。');
      } else if (e.code == 'invalid-email') {
        throw Exception('電子郵件格式不正確。');
      }
      throw Exception('註冊失敗，請稍後再試。');
    } catch (e) {
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
