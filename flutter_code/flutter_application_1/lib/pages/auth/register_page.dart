// ----- [pages/auth/register_page.dart] 開始 -----
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

// 註冊頁面狀態管理類別 - 處理使用者註冊流程和表單驗證
class _RegisterPageState extends State<RegisterPage> {
  // 文字輸入控制器：管理使用者名稱輸入框的文字內容
  final TextEditingController _usernameController = TextEditingController();

  // 文字輸入控制器：管理電子郵件輸入框的文字內容
  final TextEditingController _emailController = TextEditingController();

  // 文字輸入控制器：管理密碼輸入框的文字內容
  final TextEditingController _passwordController = TextEditingController();

  // 文字輸入控制器：管理確認密碼輸入框的文字內容
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // 表單驗證鍵：用於觸發整個註冊表單的驗證
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 密碼可見性控制：true 表示密碼以明文顯示
  bool _isPasswordVisible = false;

  // 確認密碼可見性控制：true 表示確認密碼以明文顯示
  bool _isConfirmPasswordVisible = false;

  // 註冊載入狀態：true 表示正在進行註冊處理
  bool _isLoading = false;

  /// 處理使用者註冊流程 - 驗證表單並執行註冊邏輯
  void _handleRegister() async {
    // 驗證所有表單輸入：檢查必填欄位和格式是否正確
    if (!_formKey.currentState!.validate()) return;

    // 設定載入狀態：顯示載入指示器
    setState(() {
      _isLoading = true;
    });

    // 模擬註冊過程：在實際應用中這裡會呼叫註冊 API
    await Future.delayed(const Duration(seconds: 2));

    // 關閉載入狀態：隱藏載入指示器
    setState(() {
      _isLoading = false;
    });

    // 檢查 Widget 是否仍在 Widget 樹中
    if (!context.mounted) return;

    // 顯示註冊成功訊息給使用者
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('註冊成功！請使用新帳號登入'), // 成功訊息內容
        backgroundColor: Colors.green, // 綠色背景表示成功
        duration: Duration(seconds: 3), // 訊息顯示時間
      ),
    );

    // 返回登入頁面：註冊成功後回到登入頁面
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 標題
                  const Text(
                    '建立新帳號',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '請填寫以下資訊來建立您的帳號',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // 帳號輸入框
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: '帳號',
                      hintText: '請輸入您的帳號',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入帳號';
                      }
                      if (value.length < 3) {
                        return '帳號至少需要3個字元';
                      }
                      if (value.length > 20) {
                        return '帳號不能超過20個字元';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

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
                      if (value.length > 20) {
                        return '密碼不能超過20個字元';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 確認密碼輸入框
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: '確認密碼',
                      hintText: '請再次輸入您的密碼',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
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
                        return '請確認密碼';
                      }
                      if (value != _passwordController.text) {
                        return '密碼不一致，請重新輸入';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // 註冊按鈕
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
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
                                Text('註冊中...'),
                              ],
                            )
                          : const Text(
                              '註冊',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 返回登入連結
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('已經有帳號了？'),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          '立即登入',
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
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

// ====================================================================
// ----- [pages/auth/register_page.dart] 結束 -----
