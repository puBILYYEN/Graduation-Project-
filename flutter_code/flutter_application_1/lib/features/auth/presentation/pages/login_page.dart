import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodels/login_view_model.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/google_sign_in_usecase.dart';
import '../../domain/repositories/auth_repository.dart';

/// 登入頁面 - 現在是一個 StatelessWidget，專注於 UI 顯示
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 ChangeNotifierProvider 來建立和提供 LoginViewModel
    return ChangeNotifierProvider(
      create: (context) {
        final authRepository = context.read<AuthRepository>();
        return LoginViewModel(
          SignInUseCase(authRepository),
          GoogleSignInUseCase(authRepository),
        );
      },
      child: const _LoginView(), // 將 UI 實作部分拆分出去
    );
  }
}

/// 登入頁面的 UI 實作部分 - 內部 Widget，專注於 UI 顯示和使用者互動
class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

/// 登入頁面狀態管理類別 - 處理使用者登入流程和表單驗證
class _LoginViewState extends State<_LoginView> {
  // 文字輸入控制器：管理 Email 輸入框的文字內容
  final TextEditingController _emailController = TextEditingController();

  // 文字輸入控制器：管理密碼輸入框的文字內容
  final TextEditingController _passwordController = TextEditingController();

  // 表單驗證鍵：用於觸發整個登入表單的驗證
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 密碼可見性控制：true 表示密碼以明文顯示
  bool _isPasswordVisible = false;

  /// 處理使用者登入流程 - 驗證表單並執行登入邏輯
  void _handleLogin(LoginViewModel viewModel) async {
    // 驗證所有表單輸入：檢查必填欄位和格式是否正確
    if (!_formKey.currentState!.validate()) return;

    // 調用ViewModel的登入方法
    final success = await viewModel.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      // 登入成功，導航到主頁面
      context.go('/home');
    }
  }

  /// 處理 Google 登入
  void _handleGoogleLogin(LoginViewModel viewModel) async {
    final success = await viewModel.signInWithGoogle();

    if (success && mounted) {
      // 登入成功，導航到主頁面
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo區域
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 歡迎文字
                      const Text(
                        '歡迎回來',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '請登入您的帳號',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      // Display test credentials for debugging
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '開發測試用帳號',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('Email: test@test.com', style: TextStyle(fontSize: 13, color: Colors.black54)),
                            SizedBox(height: 4),
                            Text('密碼: 123456', style: TextStyle(fontSize: 13, color: Colors.black54)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email輸入框
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: '請輸入您的Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '請輸入Email';
                          }
                          // 簡單的Email格式檢查
                          if (!value.contains('@') || !value.contains('.')) {
                            return '請輸入有效的Email格式';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 密碼輸入框
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: '密碼',
                          hintText: '請輸入您的密碼',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '請輸入密碼';
                          }
                          if (value.length < 6) {
                            return '密碼至少需要6個字元';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // 登入按鈕
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading ? null : () => _handleLogin(viewModel),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: viewModel.isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('登入中...'),
                                  ],
                                )
                              : const Text(
                                  '登入',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Google 登入按鈕
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: viewModel.isLoading ? null : () => _handleGoogleLogin(viewModel),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: viewModel.isLoading ? Colors.grey : Colors.red),
                          ),
                          icon: Icon(
                            Icons.login,
                            color: viewModel.isLoading ? Colors.grey : Colors.red,
                          ),
                          label: Text(
                            '使用 Google 登入',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: viewModel.isLoading ? Colors.grey : Colors.red,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 註冊連結
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('還沒有帳號？'),
                          TextButton(
                            onPressed: () {
                              context.go('/register');
                            },
                            child: const Text(
                              '立即註冊',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}