/// ==========================================================================
/// @檔案: firebase_auth_datasource.dart
/// @描述: 負責處理所有與 Firebase Authentication 相關操作的資料來源類別。
///        這是資料層的最底層，直接與 Firebase 和 Google Sign-In SDK 互動。
/// ==========================================================================
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// --------------------------------------------------------------------
/// @類別: FirebaseAuthDatasource
/// @描述: 封裝了 Firebase 認證和 Google 登入的具體實作。
///        上層的 Repository 會呼叫此類別的方法來完成認證任務。
/// --------------------------------------------------------------------
class FirebaseAuthDatasource {
  // --- 區塊: 屬性 (Properties) ---
  /// [_firebaseAuth]: Firebase 認證 SDK 的主要實例。
  final FirebaseAuth _firebaseAuth;
  /// [_googleSignIn]: Google 登入 SDK 的主要實例。
  final GoogleSignIn _googleSignIn;

  // --- 區塊: 建構子 (Constructor) ---
  /// @描述: 允許在建立實例時傳入可選的 mock 物件，這對於單元測試非常重要。
  ///        如果沒有提供，則使用套件預設的單例 (singleton) 實例。
  FirebaseAuthDatasource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // --- 區塊: Getters ---
  /// @屬性: authStateChanges
  /// @描述: 提供一個即時串流(Stream)，當使用者的認證狀態發生變化時 (例如登入、登出)，
  ///        這個串流會發出一個新的 User? 物件。
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// @屬性: currentUser
  /// @描述: 同步地獲取當前已登入的 Firebase 使用者物件。如果未登入，則返回 null。
  User? get currentUser => _firebaseAuth.currentUser;

  // --- 區塊: 公開方法 (Public Methods) ---

  /// ------------------------------------------------------------------
  /// @方法: signInWithGoogle
  /// @描述: 執行完整的 Google 登入流程，並用獲取的憑證登入 Firebase。
  /// @參數: [googleUser] - (可選) 如果外部已經有 GoogleSignInAccount，可直接傳入。
  /// @返回: Future<User?> - 成功時返回 Firebase 使用者物件，若使用者取消則返回 null。
  /// @拋出: 如果登入過程中發生錯誤，則重新拋出異常。
  /// ------------------------------------------------------------------
  Future<User?> signInWithGoogle({GoogleSignInAccount? googleUser}) async {
    try {
      print('🔄 Datasource: 開始 Google 登入流程...');

      // 步驟 1: 如果未直接提供 googleUser，先嘗試靜默登入。
      // 這會檢查裝置上是否已有授權過的 Google 帳戶，避免每次都跳出選擇視窗。
      if (googleUser == null) {
        googleUser = await _googleSignIn.signInSilently();
        if (googleUser != null) {
          print('✅ Datasource: Silent sign-in successful');
        }
      }

      // 步驟 2: 如果靜默登入失敗或未執行，則啟動互動式登入流程。
      // 這會彈出 Google 的標準登入視窗，讓使用者選擇帳戶。
      if (googleUser == null) {
        print('🔄 Datasource: Silent sign-in failed, trying interactive sign-in...');
        googleUser = await _googleSignIn.signIn();
      }

      // 步驟 3: 如果此時 googleUser 仍為 null，表示使用者在選擇視窗中點擊了取消。
      if (googleUser == null) {
        print('❌ Datasource: 使用者取消 Google 登入');
        return null; // User cancelled the sign-in
      }

      print('✅ Datasource: Google 帳戶登入成功: ${googleUser.email}');

      // 步驟 4: 從登入成功的 Google 帳戶中獲取認證憑證 (idToken 和 accessToken)。
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('🔑 Datasource: 取得 Google 認證憑證');
      print('🔍 Access Token: ${googleAuth.accessToken != null ? "已取得" : "缺失"}');
      print('🔍 ID Token: ${googleAuth.idToken != null ? "已取得" : "缺失"}');

      // 步驟 5: 使用 Google 提供的憑證來建立一個 Firebase 能識別的 AuthCredential。
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔐 Datasource: 建立 Firebase 憑證');

      // 步驟 6: 使用此憑證登入 Firebase Authentication。
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      print('🎉 Datasource: Firebase 登入成功: ${userCredential.user?.email}');
      return userCredential.user;

    } catch (e) {
      // 捕獲所有可能的錯誤 (網路問題、憑證問題等)，打印日誌並重新拋出。
      print('💥 Datasource Google Sign-In Error: $e');
      print('錯誤類型: ${e.runtimeType}');
      rethrow;
    }
  }

  /// ------------------------------------------------------------------
  /// @方法: signInWithEmailAndPassword
  /// @描述: 使用電子郵件和密碼登入 Firebase。
  /// @返回: Future<User?> - 成功時返回 Firebase 使用者物件。
  /// @拋出: 如果信箱或密碼錯誤，拋出 FirebaseAuthException。
  /// ------------------------------------------------------------------
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      rethrow;
    }
  }

  /// ------------------------------------------------------------------
  /// @方法: createUserWithEmailAndPassword
  /// @描述: 使用電子郵件和密碼註冊一個新的 Firebase 帳戶。
  /// @返回: Future<User?> - 成功時返回新建立的 Firebase 使用者物件。
  /// @拋出: 如果信箱格式不符或已被使用，拋出 FirebaseAuthException。
  /// ------------------------------------------------------------------
  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      rethrow;
    }
  }

  /// ------------------------------------------------------------------
  /// @方法: signOut
  /// @描述: 將使用者從 Google 和 Firebase 同時登出。
  /// ------------------------------------------------------------------
  Future<void> signOut() async {
    // 必須先登出 Google，再登出 Firebase，以確保登出流程完整。
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}