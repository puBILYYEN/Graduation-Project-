
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
      // 1. 觸發 Google 登入流程
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 使用者取消了登入流程
        print('Google 登入被使用者取消');
        return null;
      }

      // 2. 取得 Google 帳號的認證憑證
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. 將憑證轉換為 Firebase 可用的 OAuthCredential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. 使用該憑證登入 Firebase
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      print('Google 登入成功: ${userCredential.user?.displayName}');
      return userCredential.user;
    } catch (e) {
      print('Google 登入失敗: $e');
      return null;
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
