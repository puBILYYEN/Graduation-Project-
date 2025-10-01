// AK47 風格精簡版：認證系統
import 'package:google_sign_in/google_sign_in.dart';
import 'logger.dart';

class Auth {
  static final GoogleSignIn _google = GoogleSignIn(scopes: ['email']);

  // 簡潔的 Google 登入
  static Future<bool> googleSignIn() async {
    try {
      final account = await _google.signIn();
      if (account != null) {
        await log('Google login success: ${account.email}');
        return true;
      }
    } catch (e) {
      await log('Google login failed: $e');
    }
    return false;
  }

  // 簡潔的登出
  static Future<void> signOut() async {
    try {
      await _google.signOut();
      await log('User signed out');
    } catch (e) {
      await log('Sign out failed: $e');
    }
  }

  // 簡潔的表單驗證
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return '請輸入電子郵件';
    if (!email.contains('@')) return '電子郵件格式不正確';
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) return '請輸入密碼';
    if (password.length < 6) return '密碼至少需要6個字元';
    return null;
  }

  // 簡潔的模擬登入（原本的複雜邏輯簡化）
  static Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // 模擬網路延遲
    final isValid = validateEmail(email) == null && validatePassword(password) == null;
    await log(isValid ? 'Login success: $email' : 'Login failed: invalid credentials');
    return isValid;
  }
}