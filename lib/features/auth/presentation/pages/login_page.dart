import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../viewmodels/login_view_model.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/google_sign_in_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/widgets/nano_starry_background.dart';
import '../../../../core/widgets/meteor_shower_background.dart';
import '../../../../core/services/app_logger.dart';

/// 登入頁面 - 現在是一個 StatelessWidget，專注於 UI 顯示
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('📱 LoginPage: build 被調用');
    // 使用 ChangeNotifierProvider 來建立和提供 LoginViewModel
    return ChangeNotifierProvider(
      create: (context) {
        debugPrint('📱 LoginPage: 正在建立 LoginViewModel');
        try {
          final authRepository = context.read<AuthRepository>();
          debugPrint('📱 LoginPage: 成功獲取 AuthRepository');
          return LoginViewModel(
            SignInUseCase(authRepository),
            GoogleSignInUseCase(authRepository),
          );
        } catch (e, stackTrace) {
          debugPrint('❌ LoginPage: 獲取 AuthRepository 失敗: $e');
          debugPrint('❌ StackTrace: $stackTrace');
          rethrow;
        }
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

  @override
  void initState() {
    super.initState();
    // 設定螢幕方向為直向
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  /// 處理使用者登入流程 - 驗證表單並執行登入邏輯
  void _handleLogin(LoginViewModel viewModel) async {
    await AppLogger.logButtonClick('登入按鈕');
    // 驗證所有表單輸入：檢查必填欄位和格式是否正確
    if (!_formKey.currentState!.validate()) {
      await AppLogger.logEvent('登入表單驗證失敗');
      return;
    }

    await AppLogger.logEvent('開始 Email 登入: ${_emailController.text.trim()}');

    // 調用ViewModel的登入方法
    final success = await viewModel.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      await AppLogger.logEvent('[OK] Email 登入成功');
      await AppLogger.logNavigation('/login', '/home');
      // 登入成功，導航到主頁面
      context.go('/home');
    } else {
      await AppLogger.logEvent('[ERROR] Email 登入失敗');
    }
  }

  /// 處理 Google 登入
  void _handleGoogleLogin(LoginViewModel viewModel) async {
    await AppLogger.logButtonClick('Google 登入按鈕');
    await AppLogger.logEvent('開始 Google 登入');
    final success = await viewModel.signInWithGoogle();

    if (success && mounted) {
      await AppLogger.logEvent('[OK] Email 登入成功');
      await AppLogger.logNavigation('/login', '/home');
      // 登入成功，導航到主頁面
      context.go('/home');
    } else {
      await AppLogger.logEvent('[ERROR] Email 登入失敗');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // 星空動畫背景
              const NanoStarryBackground(),
              // 流星劃過效果
              const MeteorShowerBackground(),
              // 原有內容
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          // Logo區域
                          Container(
                            width: 150,
                            height: 150,
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              'assets/images/31165_0-removebg-preview.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 歡迎文字
                          const Text(
                            '歡迎回來',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '請登入您的帳號',
                            style: TextStyle(fontSize: 16, color: Colors.grey[300]),
                          ),
                          const SizedBox(height: 16),
                          // Display test credentials for debugging - compact version
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[900]!.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.cyan.withOpacity(0.8)),
                                const SizedBox(width: 8),
                                Text(
                                  '測試帳號: test@test.com / 123456',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[300],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

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
                                backgroundColor: Colors.cyan, // 改為實心青色背景
                                foregroundColor: Colors.white, // 文字改為白色
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5, // 增加陰影
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
                                        Text(
                                          '登入中...',
                                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), // 確保載入文字也是白色
                                        ),
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

                          // Google 登入按鈕 (仿 Google 官方樣式 - 無圖片版)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: viewModel.isGoogleLoading ? null : () => _handleGoogleLogin(viewModel),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white, // 白色背景
                                foregroundColor: Colors.black87, // 黑色文字
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey.shade300, width: 1), // 細灰色邊框
                              ),
                              icon: SvgPicture.string(
                                '''<svg width="18" height="18" viewBox="0 0 24 24">
                                  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                                  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                                  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                                  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                                </svg>''',
                                width: 18,
                                height: 18,
                              ),
                              label: const Text(
                                '使用 Google 登入',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 註冊連結
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('還沒有帳號？', style: TextStyle(color: Colors.white)),
                              TextButton(
                                onPressed: () {
                                  context.go('/register');
                                },
                                child: const Text(
                                  '立即註冊',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
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
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // 恢復螢幕方向設定
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
