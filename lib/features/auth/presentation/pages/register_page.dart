
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/profile_photo_service.dart';
import '../../../camera/presentation/pages/simple_camera_screen.dart';

import '../viewmodels/register_view_model.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/repositories/auth_repository.dart';

/// 註冊頁面 - 現在是一個 StatelessWidget，專注於 UI 顯示
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 ChangeNotifierProvider 來建立和提供 RegisterViewModel
    return ChangeNotifierProvider(
      create: (context) {
        final authRepository = context.read<AuthRepository>();
        return RegisterViewModel(
          SignUpUseCase(authRepository),
        );
      },
      child: const _RegisterView(), // 將 UI 實作部分拆分出去
    );
  }
}

/// 註冊頁面的 UI 實作部分 - 內部 Widget，專注於 UI 顯示和使用者互動
class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

// 註冊頁面狀態管理類別 - 處理使用者註冊流程和表單驗證
class _RegisterViewState extends State<_RegisterView> {
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

  // 大頭照相關
  final ProfilePhotoService _profilePhotoService = ProfilePhotoService();
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedImageData;
  String? _uploadedPhotoUrl;
  bool _isUploadingPhoto = false;

  /// 處理使用者註冊流程 - 驗證表單並執行註冊邏輯
  void _handleRegister(RegisterViewModel viewModel) async {
    // 驗證所有表單輸入：檢查必填欄位和格式是否正確
    if (!_formKey.currentState!.validate()) return;

    // 調用ViewModel的註冊方法
    final success = await viewModel.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      imageData: _selectedImageData,
    );

    if (success && mounted) {
      // 顯示註冊成功訊息並準備跳轉
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('註冊成功！正在跳轉到個人資料設定...'), // 更新訊息內容
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2), // 縮短顯示時間
        ),
      );

      // 等待 SnackBar 顯示完成後再跳轉
      await Future.delayed(const Duration(seconds: 2));

      // 使用 go_router 導航到個人資料設定頁面
      context.go('/profile-setup');
    } else if (mounted) {
      // 顯示註冊失敗訊息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('註冊失敗，請稍後再試'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  /// 顯示照片來源選擇對話框
  Future<void> _pickProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '選擇大頭照',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 相機拍照選項
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _selectImageFromSource(ImageSource.camera);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '拍照',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 相簿選擇選項
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _selectImageFromSource(ImageSource.gallery);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 40,
                          color: Colors.green[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '相簿',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }


  /// 從指定來源選擇圖片
  Future<void> _selectImageFromSource(ImageSource source) async {
    if (source == ImageSource.camera) {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final image = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleCameraScreen(camera: frontCamera),
        ),
      );

      if (image != null) {
        final Uint8List imageData = await (image as XFile).readAsBytes();
        setState(() {
          _selectedImageData = imageData;
        });
      }
    } else {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final Uint8List imageData = await image.readAsBytes();
        setState(() {
          _selectedImageData = imageData;
        });
      }
    }
  }

  /// 移除大頭照
  Future<void> _removeProfilePhoto() async {
    try {
      if (_uploadedPhotoUrl != null) {
        await _profilePhotoService.deleteProfilePhoto();
      }

      setState(() {
        _selectedImageData = null;
        _uploadedPhotoUrl = null;
      });

      _showSnackBar('大頭照已移除', isError: false);

    } catch (e) {
      print('💥 移除大頭照失敗: $e');
      _showSnackBar('移除大頭照失敗：$e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RegisterViewModel>(
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
                      GestureDetector(
                        onTap: _pickProfilePhoto,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            image: _selectedImageData != null
                                ? DecorationImage(
                                    image: MemoryImage(_selectedImageData!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _selectedImageData == null
                              ? const Icon(
                                  Icons.person_add,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
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
                          onPressed: viewModel.isLoading ? null : () => _handleRegister(viewModel),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
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
                              context.go('/');
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
      },
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