import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/services/log_manager.dart';

/// 管理登入頁面的狀態和業務邏輯
class LoginViewModel extends ChangeNotifier {
  // Google 登入配置
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // 一般登入載入狀態
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Google 登入載入狀態
  bool _isGoogleLoading = false;
  bool get isGoogleLoading => _isGoogleLoading;

  // 更新一般登入載入狀態
  void _setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // 通知監聽者狀態已改變
  }

  // 更新 Google 登入載入狀態
  void _setIsGoogleLoading(bool value) {
    _isGoogleLoading = value;
    notifyListeners(); // 通知監聽者狀態已改變
  }

  /// 處理一般登入流程
  Future<void> handleLogin(BuildContext context, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    _setIsLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    _setIsLoading(false);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('登入成功'),
        backgroundColor: Colors.green,
      ),
    );

    context.go('/home');
  }

  /// 處理 Google 登入流程
  Future<void> handleGoogleSignIn(BuildContext context) async {
    _setIsGoogleLoading(true);

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account != null) {
        await log('Google 登入成功: ${account.displayName} (${account.email})');

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('歡迎 ${account.displayName}！'),
            backgroundColor: Colors.green,
          ),
        );

        context.go('/home');
      } else {
        await log('Google 登入被取消');
      }
    } catch (error) {
      await log('Google 登入錯誤: $error');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google 登入失敗: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _setIsGoogleLoading(false);
    }
  }
}
