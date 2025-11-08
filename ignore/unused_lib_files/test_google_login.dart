import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class TestGoogleLoginPage extends StatefulWidget {
  const TestGoogleLoginPage({super.key});

  @override
  State<TestGoogleLoginPage> createState() => _TestGoogleLoginPageState();
}

class _TestGoogleLoginPageState extends State<TestGoogleLoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String _status = '等待測試...';
  bool _isLoading = false;

  Future<void> _testGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _status = '🚀 開始測試 Google 登入...';
    });

    try {
      // Step 1: Google Sign In
      setState(() => _status = '📱 Step 1: 啟動 Google 登入視窗...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _status = '❌ 使用者取消登入');
        return;
      }

      setState(() => _status = '✅ Step 1: Google 帳戶登入成功\nEmail: ${googleUser.email}');

      // Step 2: Get Google Auth
      setState(() => _status = '🔑 Step 2: 取得 Google 認證憑證...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      setState(() => _status = '''
✅ Step 2: 憑證取得成功
Access Token: ${googleAuth.accessToken != null ? "✅ 已取得" : "❌ 缺失"}
ID Token: ${googleAuth.idToken != null ? "✅ 已取得" : "❌ 缺失"}
''');

      // Step 3: Create Firebase Credential
      setState(() => _status = '''
✅ Step 2: 憑證取得成功
Access Token: ${googleAuth.accessToken != null ? "✅ 已取得" : "❌ 缺失"}
ID Token: ${googleAuth.idToken != null ? "✅ 已取得" : "❌ 缺失"}

🔐 Step 3: 建立 Firebase 憑證...
''');

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4: Firebase Sign In
      setState(() => _status = '''
✅ Step 2: 憑證取得成功
Access Token: ${googleAuth.accessToken != null ? "✅ 已取得" : "❌ 缺失"}
ID Token: ${googleAuth.idToken != null ? "✅ 已取得" : "❌ 缺失"}

✅ Step 3: Firebase 憑證建立成功

🔄 Step 4: 使用憑證登入 Firebase...
''');

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      setState(() => _status = '''
🎉 全部測試成功！

Step 1: ✅ Google 帳戶登入
Step 2: ✅ 取得認證憑證
Step 3: ✅ 建立 Firebase 憑證
Step 4: ✅ Firebase 登入成功

使用者資訊:
- Email: ${userCredential.user?.email}
- Name: ${userCredential.user?.displayName}
- UID: ${userCredential.user?.uid}
''');

    } catch (e) {
      setState(() => _status = '''
💥 測試失敗

錯誤訊息: $e
錯誤類型: ${e.runtimeType}

請檢查:
1. 網路連線
2. Google Services 配置
3. Firebase 專案設定
4. SHA-1 憑證
''');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    setState(() => _status = '已登出');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google 登入測試'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '測試狀態',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testGoogleSignIn,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isLoading ? '測試中...' : '開始測試 Google 登入'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('登出'),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '檢查清單',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('✅ pubspec.yaml 已添加 google_sign_in'),
                    Text('✅ android/app/google-services.json 已配置'),
                    Text('✅ android/app/build.gradle 已添加 google-services plugin'),
                    Text('⚠️ 需要檢查 Firebase Console OAuth 設定'),
                    Text('⚠️ 需要檢查 SHA-1 憑證'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}