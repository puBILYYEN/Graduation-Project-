import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/logging/log_manager.dart';

/// 管理登入頁面的狀態和業務邏輯
class LoginViewModel extends ChangeNotifier {
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

  /// 處理一般登入流程 (此處為範例，尚未與 Firebase 整合)
  Future<void> handleLogin(BuildContext context, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    _setIsLoading(true);
    await Future.delayed(const Duration(seconds: 1)); // 模擬網路請求
    _setIsLoading(false);

    // 注意：此處的直接導航在整合 Firebase 帳密登入後也應移除，
    // 改為依賴 GoRouter 的 redirect。
    if (context.mounted) {
      // context.go('/home');
    }
  }

  /// 處理 Google 登入流程，委託給 AuthService
  Future<void> handleGoogleSignIn(BuildContext context) async {
    _setIsGoogleLoading(true);
    try {
      // 從 Provider 獲取 AuthService 實例
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // 呼叫服務中的登入方法
      final user = await authService.signInWithGoogle();

      if (user != null) {
        await log('AuthService 登入成功: ${user.displayName}');
        // 登入成功後，不需要手動導航。
        // GoRouter 的 redirect 會自動偵測到登入狀態的改變並導航到 /home。
      } else {
        await log('AuthService 登入被使用者取消');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google 登入已取消'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (error) {
      await log('AuthService 登入錯誤: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登入失敗: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _setIsGoogleLoading(false);
    }
  }
}
