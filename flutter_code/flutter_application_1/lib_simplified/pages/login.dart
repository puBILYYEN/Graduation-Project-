// AK47 風格精簡版：登入頁面
import 'package:flutter/material.dart';
import '../core/auth.dart';
import '../ui/widgets.dart';
import '../utils/constants.dart';
import 'home.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              // 簡潔標題
              const Text('登入', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.xl),

              // 電子郵件輸入
              InputField(
                label: '電子郵件',
                controller: _emailController,
                validator: Auth.validateEmail,
              ),
              const SizedBox(height: AppSpacing.m),

              // 密碼輸入
              InputField(
                label: '密碼',
                controller: _passwordController,
                obscureText: !_showPassword,
                validator: Auth.validatePassword,
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 登入按鈕
              PrimaryButton(
                text: '登入',
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: AppSpacing.m),

              // Google 登入按鈕
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleLogin,
                icon: const Icon(Icons.login),
                label: const Text('Google 登入'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // 註冊連結
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                ),
                child: const Text('沒有帳號？立即註冊'),
              ),
              const SizedBox(height: AppSpacing.l),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await Auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        _showError('登入失敗，請檢查您的憑證');
      }
    } catch (e) {
      _showError('登入錯誤：$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final success = await Auth.googleSignIn();
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      _showError('Google 登入失敗');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}