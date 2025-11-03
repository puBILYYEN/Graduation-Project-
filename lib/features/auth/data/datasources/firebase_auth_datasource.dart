import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthDatasource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthDatasource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<User?> signInWithGoogle({GoogleSignInAccount? googleUser}) async {
    try {
      print('🔄 Datasource: 開始 Google 登入流程...');

      // Try silent sign-in first if no user provided
      if (googleUser == null) {
        googleUser = await _googleSignIn.signInSilently();
        if (googleUser != null) {
          print('✅ Datasource: Silent sign-in successful');
        }
      }

      // If silent sign-in failed, try interactive sign-in
      if (googleUser == null) {
        print('🔄 Datasource: Silent sign-in failed, trying interactive sign-in...');
        googleUser = await _googleSignIn.signIn();
      }

      if (googleUser == null) {
        print('❌ Datasource: 使用者取消 Google 登入');
        return null; // User cancelled the sign-in
      }

      print('✅ Datasource: Google 帳戶登入成功: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('🔑 Datasource: 取得 Google 認證憑證');
      print('🔍 Access Token: ${googleAuth.accessToken != null ? "已取得" : "缺失"}');
      print('🔍 ID Token: ${googleAuth.idToken != null ? "已取得" : "缺失"}');

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔐 Datasource: 建立 Firebase 憑證');

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      print('🎉 Datasource: Firebase 登入成功: ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e) {
      print('💥 Datasource Google Sign-In Error: $e');
      print('錯誤類型: ${e.runtimeType}');
      rethrow; // 重新拋出錯誤以便上層處理
    }
  }

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

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}