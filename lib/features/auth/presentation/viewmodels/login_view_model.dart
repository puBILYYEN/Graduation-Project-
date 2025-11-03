import 'package:flutter/material.dart';
import '../../domain/usecases/google_sign_in_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';

class LoginViewModel extends ChangeNotifier {
  final SignInUseCase _signInUseCase;
  final GoogleSignInUseCase _googleSignInUseCase;

  LoginViewModel(this._signInUseCase, this._googleSignInUseCase);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isGoogleLoading = false;
  bool get isGoogleLoading => _isGoogleLoading;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _setIsLoading(bool value) {
    _isLoading = value;
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _setIsGoogleLoading(bool value) {
    _isGoogleLoading = value;
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> handleLogin(
    BuildContext context,
    GlobalKey<FormState> formKey,
    String email,
    String password,
  ) async {
    if (!formKey.currentState!.validate()) return;

    _setIsLoading(true);
    try {
      await _signInUseCase(email, password);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _setIsLoading(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    // --- 開發/測試用後門 ---
    if (email == 'test@test.com' && password == '123456') {
      print('--- 開發者登入後門：成功 ---');
      return true; // 模擬登入成功
    }
    // --- 後門結束 ---

    _setIsLoading(true);
    try {
      final user = await _signInUseCase(email, password);
      return user != null;
    } catch (error) {
      return false;
    } finally {
      _setIsLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setIsGoogleLoading(true);
    try {
      print('📱 ViewModel: 開始 Google 登入...');
      final user = await _googleSignInUseCase();
      if (user != null) {
        print('🎉 ViewModel: Google 登入成功');
        return true;
      } else {
        print('❌ ViewModel: Google 登入返回 null');
        return false;
      }
    } catch (error) {
      print('💥 ViewModel: Google 登入錯誤: $error');
      return false;
    } finally {
      _setIsGoogleLoading(false);
    }
  }

  Future<void> handleGoogleSignIn(BuildContext context) async {
    _setIsGoogleLoading(true);
    try {
      await _googleSignInUseCase();
    } catch (error) {
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
