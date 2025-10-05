// AK47 風格精簡版：註冊頁面
import 'package:flutter/material.dart';
import '../core/auth.dart';
import '../ui/widgets.dart';
import '../utils/constants.dart';
import 'home.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('註冊帳號'),
      backgroundColor: AppColors.background,
      elevation: 0,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.l),

              // 使用者名稱輸入
              InputField(
                label: '使用者名稱',
                controller: _nameController,
                validator: _validateName,
              ),
              const SizedBox(height: AppSpacing.m),

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
              const SizedBox(height: AppSpacing.m),

              // 確認密碼輸入
              InputField(
                label: '確認密碼',
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                validator: _validateConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 註冊按鈕
              PrimaryButton(
                text: '註冊',
                isLoading: _isLoading,
                onPressed: _handleRegister,
              ),
              const SizedBox(height: AppSpacing.m),

              // 返回登入
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('已有帳號？返回登入'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  String? _validateName(String? name) {
    if (name == null || name.isEmpty) return '請輸入使用者名稱';
    if (name.length < 2) return '使用者名稱至少需要2個字元';
    return null;
  }

  String? _validateConfirmPassword(String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) return '請確認密碼';
    if (confirmPassword != _passwordController.text) return '密碼不一致';
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 模擬註冊邏輯（AK47 簡化版）
      await Future.delayed(const Duration(seconds: 2));

      // 在 AK47 版本中，註冊成功後直接登入
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
        _showError('註冊失敗，請稍後再試');
      }
    } catch (e) {
      _showError('註冊錯誤：$e');
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}