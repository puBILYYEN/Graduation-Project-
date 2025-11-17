/// ==========================================================================
/// @檔案: auth_repository_impl.dart
/// @描述: 認證倉儲的具體實作，作為 Domain 層與 Data 層之間的橋樑。
/// ==========================================================================
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

/// --------------------------------------------------------------------
/// @類別: AuthRepositoryImpl
/// @描述: 實作了 `AuthRepository` 介面所定義的契約。
///        它本身不包含認證邏輯，而是將呼叫委派 (delegate) 給 `FirebaseAuthDatasource`。
///        這種結構是「倉儲模式 (Repository Pattern)」的典型應用。
/// --------------------------------------------------------------------
class AuthRepositoryImpl implements AuthRepository {
  // --- 區塊: 屬性 (Properties) ---
  /// [datasource]: 資料來源的實例，所有操作都將透過它來執行。
  /// 透過建構子注入，實現了依賴注入 (Dependency Injection)。
  final FirebaseAuthDatasource datasource;

  // --- 區塊: 建構子 (Constructor) ---
  AuthRepositoryImpl(this.datasource);

  // --- 區塊: 介面實作 (Interface Implementation) ---

  /// @覆寫: authStateChanges
  /// @描述: 直接從 datasource 傳遞認證狀態變化的串流。
  @override
  Stream<User?> get authStateChanges => datasource.authStateChanges;

  /// @覆寫: currentUser
  /// @描述: 直接從 datasource 獲取當前的登入使用者。
  @override
  User? get currentUser => datasource.currentUser;

  /// @覆寫: signInWithGoogle
  /// @描述: 呼叫 datasource 來執行 Google 登入流程。
  @override
  Future<User?> signInWithGoogle({GoogleSignInAccount? googleUser}) {
    return datasource.signInWithGoogle(googleUser: googleUser);
  }

  /// @覆寫: signInWithEmailAndPassword
  /// @描述: 呼叫 datasource 來執行信箱密碼登入。
  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) {
    return datasource.signInWithEmailAndPassword(email, password);
  }

  /// @覆寫: createUserWithEmailAndPassword
  /// @描述: 呼叫 datasource 來執行信箱密碼註冊。
  @override
  Future<User?> createUserWithEmailAndPassword(String email, String password) {
    return datasource.createUserWithEmailAndPassword(email, password);
  }

  /// @覆寫: signOut
  /// @描述: 呼叫 datasource 來執行登出。
  @override
  Future<void> signOut() {
    return datasource.signOut();
  }
}