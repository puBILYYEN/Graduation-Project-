import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodels/login_view_model.dart';

/// 登入頁面 - 現在是一個 StatelessWidget，專注於 UI 顯示
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 ChangeNotifierProvider 來建立和提供 LoginViewModel
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: const _LoginView(), // 將 UI 實作部分拆分出去
    );
  }
}

/// 登入頁面的 UI 視圖
class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    // 表單驗證鍵
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    // 文字輸入控制器
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    // 使用 Consumer 來監聽 LoginViewModel 的變化
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ... (頭像和標題部分與之前相同，保持不變)
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: const Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 32),
                      const Text('歡迎回來', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 8),
                      const Text('請輸入您的帳號資訊', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('測試帳號: test\n測試密碼: 123456', style: TextStyle(fontSize: 14, color: Colors.blue), textAlign: TextAlign.center),
                      const SizedBox(height: 32),

                      // 帳號輸入欄位
                      TextFormField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: '帳號',
                          hintText: '請輸入您的帳號',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return '請輸入帳號';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 密碼輸入欄位 (需要一個 StatefulWidget 來管理 _isPasswordVisible)
                      // 為了簡化，我們先將其轉換為一個小的 StatefulWidget
                      const _PasswordFormField(),

                      const SizedBox(height: 24),

                      // 主要登入按鈕
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading ? null : () => viewModel.handleLogin(context, formKey),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: viewModel.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('登入', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ... (分隔線和 Google 登入按鈕)
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('或者', style: TextStyle(color: Colors.grey)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: viewModel.isGoogleLoading ? null : () => viewModel.handleGoogleSignIn(context),
                          icon: viewModel.isGoogleLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Image.asset('assets/google_logo.png', width: 20, height: 20, errorBuilder: (context, error, stackTrace) => const Icon(Icons.login, size: 20)),
                          label: Text(
                            viewModel.isGoogleLoading ? '登入中...' : '使用 Google 登入',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 註冊連結
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('還沒有帳號？ ', style: TextStyle(color: Colors.grey)),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: const Text('註冊', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 一個小的 StatefulWidget，專門用來管理密碼欄位的可見性狀態
class _PasswordFormField extends StatefulWidget {
  const _PasswordFormField();

  @override
  State<_PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<_PasswordFormField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // controller 應該從父級傳遞下來，但為簡化暫時省略
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: '密碼',
        hintText: '請輸入您的密碼',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '請輸入密碼';
        if (value.length < 6) return '密碼長度至少需要6個字元';
        return null;
      },
    );
  }
}
