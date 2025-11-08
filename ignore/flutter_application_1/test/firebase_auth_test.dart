import 'package:firebase_core/firebase_core.dart';
import '../lib/core/services/auth_service.dart';
import '../lib/firebase_options.dart';

Future<void> main() async {
  // 確保Flutter綁定初始化完成
  // WidgetsFlutterBinding.ensureInitialized(); // For pure Dart test, not strictly necessary unless Flutter services are implicitly used.

  // 初始化 Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase 初始化成功');
  } catch (e) {
    print('Firebase 初始化失敗: $e');
    return; // 如果初始化失敗，則停止測試
  }

  final authService = AuthService();

  // 測試註冊功能
  print('開始測試 Firebase 註冊...');
  try {
    // 請替換為未註冊過的電子郵件和密碼
    // 每次測試請使用不同的電子郵件，或在 Firebase Console 中刪除測試用戶
    final String testEmail = 'testuser_${DateTime.now().millisecondsSinceEpoch}@example.com';
    final String testPassword = 'password123';

    print('嘗試使用電子郵件: $testEmail 進行註冊...');
    final user = await authService.signUpWithEmailAndPassword(testEmail, testPassword);

    if (user != null) {
      print('Firebase 註冊成功！用戶 ID: ${user.uid}, 電子郵件: ${user.email}');
      // 可以在這裡添加登出操作，以便下次測試使用相同的電子郵件
      // await authService.signOut();
      // print('測試用戶已登出。');
    } else {
      print('Firebase 註冊失敗：未返回用戶資訊。');
    }
  } catch (e) {
    print('Firebase 註冊失敗，錯誤訊息: $e');
  }
}
