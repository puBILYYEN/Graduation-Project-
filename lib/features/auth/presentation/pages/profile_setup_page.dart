import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../core/services/profile_photo_service.dart';
import '../../../camera/presentation/pages/simple_camera_screen.dart';

/// 個人資料完善頁面
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProfilePhotoService _profilePhotoService = ProfilePhotoService();
  final ImagePicker _imagePicker = ImagePicker();

  // 表單控制器
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  // 表單驗證
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 選擇項目
  bool? _selectedGender; // true=男性, false=女性
  int? _selectedGoal; // 0=維持, 1=減重, 2=增重
  String _selectedActivityLevel = 'moderately_active';

  // 大頭照相關
  Uint8List? _selectedImageData;
  String? _uploadedPhotoUrl;

  // 載入狀態
  bool _isLoading = false;
  bool _isUploadingPhoto = false;

  /// 計算 BMR (基礎代謝率)
  double _calculateBMR(int age, double height, double weight, bool isMale) {
    if (isMale) {
      // 男性 BMR = 88.362 + (13.397 × 體重) + (4.799 × 身高) - (5.677 × 年齡)
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      // 女性 BMR = 447.593 + (9.247 × 體重) + (3.098 × 身高) - (4.330 × 年齡)
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  /// 計算 TDEE (總日耗能)
  double _calculateTDEE(double bmr, String activityLevel) {
    Map<String, double> activityMultipliers = {
      'sedentary': 1.2,        // 久坐
      'lightly_active': 1.375, // 輕度活動
      'moderately_active': 1.55, // 中度活動
      'very_active': 1.725,    // 高度活動
      'extra_active': 1.9,     // 極高活動
    };

    return bmr * (activityMultipliers[activityLevel] ?? 1.55);
  }

  /// 計算建議卡路里
  double _calculateSuggestedCalories(double tdee, int goal) {
    double suggestedCalories;

    switch (goal) {
      case 1: // 減重
        suggestedCalories = tdee - 500; // 每天減少 500 卡
        break;
      case 2: // 增重
        suggestedCalories = tdee + 500; // 每天增加 500 卡
        break;
      default: // 維持
        suggestedCalories = tdee;
    }

    // 確保每日最低熱量攝取不低於 1200 大卡（健康安全標準）
    if (suggestedCalories < 1200) {
      print('⚠️ 計算出的熱量 ${suggestedCalories.toStringAsFixed(0)} 低於 1200 大卡，已調整為 1200');
      return 1200;
    }

    return suggestedCalories;
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

        // 立即上傳到 Firebase Storage
        await _uploadProfilePhoto(imageData);
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

        // 立即上傳到 Firebase Storage
        await _uploadProfilePhoto(imageData);
      }
    }
  }

  /// 上傳大頭照到 Firebase Storage
  Future<void> _uploadProfilePhoto(Uint8List imageData) async {
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('使用者未登入');
      }

      // 上傳到 Firebase Storage
      final photoUrl = await _profilePhotoService.uploadProfilePhoto(imageData);

      setState(() {
        _uploadedPhotoUrl = photoUrl;
      });

      _showSnackBar('大頭照上傳成功！', isError: false);

    } catch (e) {
      print('💥 大頭照上傳失敗: $e');
      _showSnackBar('大頭照上傳失敗：$e', isError: true);
    } finally {
      setState(() {
        _isUploadingPhoto = false;
      });
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

  /// 儲存個人資料
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      _showSnackBar('請選擇性別', isError: true);
      return;
    }
    if (_selectedGoal == null) {
      _showSnackBar('請選擇健康目標', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('使用者未登入');
      }

      // 解析輸入數據
      final age = int.parse(_ageController.text);
      final height = double.parse(_heightController.text);
      final weight = double.parse(_weightController.text);

      // 計算營養數據
      final bmr = _calculateBMR(age, height, weight, _selectedGender!);
      final tdee = _calculateTDEE(bmr, _selectedActivityLevel);
      final suggestedCalories = _calculateSuggestedCalories(tdee, _selectedGoal!);

      // 計算營養目標 (基於建議卡路里)
      final targetProtein = (suggestedCalories * 0.3) / 4; // 30% 來自蛋白質，每克4卡
      final targetCarbs = (suggestedCalories * 0.45) / 4;  // 45% 來自碳水，每克4卡
      final targetFat = (suggestedCalories * 0.25) / 9;    // 25% 來自脂肪，每克9卡

      // 更新 Firestore 資料 (使用 set 搭配 merge，如果文檔不存在會自動創建)
      await _firestore.collection('member').doc(user.uid).set({
        // 個人基本資料
        'age': age,
        'gender': _selectedGender,
        'height': height,
        'weight': weight,
        'goal': _selectedGoal,
        'activityLevel': _selectedActivityLevel, // 儲存活動量等級

        // 計算數值
        'BMR': bmr.round(),
        'TDEE_level': tdee.round(),
        'suggested_calories': suggestedCalories.round(),

        // 營養目標
        'targetCalories': suggestedCalories.round(),
        'targetProtein': targetProtein.round(),
        'targetCarbs': targetCarbs.round(),
        'targetFat': targetFat.round(),

        // 更新時間
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        _showSnackBar('個人資料設定完成！', isError: false);
        // 延遲一下再跳轉，讓使用者看到成功訊息
        await Future.delayed(const Duration(seconds: 1));
        context.go('/home');
      }

    } catch (e) {
      print('💥 個人資料儲存失敗: $e');
      if (mounted) {
        _showSnackBar('儲存失敗：$e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 跳過設定
  void _skipSetup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('跳過個人資料設定'),
        content: const Text('您可以稍後在設定頁面中完善個人資料。\n\n部分功能（如卡路里計算）將使用預設值。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('繼續設定'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: const Text('確定跳過'),
          ),
        ],
      ),
    );
  }

  /// 顯示訊息
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🔧 ProfileSetupPage build called');
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('完善個人資料'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _skipSetup,
            child: const Text('跳過'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 進度指示器
                LinearProgressIndicator(
                  value: 0.6,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 24),

                // 標題說明
                const Text(
                  '幫助我們為您量身定制',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '填寫以下資訊，我們將為您計算個人化的營養目標',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // 大頭照設定區域
                Center(
                  child: Column(
                    children: [
                      const Text(
                        '設定大頭照（選填）',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _isUploadingPhoto ? null : () {
                          print('🖱️ 大頭照框框被點擊');
                          _pickProfilePhoto();
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.grey[400]!, width: 2),
                            image: _selectedImageData != null
                                ? DecorationImage(
                                    image: MemoryImage(_selectedImageData!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _isUploadingPhoto
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : _selectedImageData == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo,
                                          size: 40,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '點擊選擇',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '拍照或相簿',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedImageData != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: _pickProfilePhoto,
                              icon: const Icon(Icons.edit),
                              label: const Text('更換'),
                            ),
                            const SizedBox(width: 16),
                            TextButton.icon(
                              onPressed: _removeProfilePhoto,
                              icon: const Icon(Icons.delete),
                              label: const Text('移除'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 年齡輸入
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '年齡',
                    hintText: '請輸入您的年齡',
                    suffixText: '歲',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return '請輸入年齡';
                    final age = int.tryParse(value);
                    if (age == null || age < 10 || age > 100) return '請輸入有效的年齡 (10-100)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 性別選擇
                const Text('性別', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('男性'),
                        value: true,
                        groupValue: _selectedGender,
                        onChanged: (value) => setState(() => _selectedGender = value),
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('女性'),
                        value: false,
                        groupValue: _selectedGender,
                        onChanged: (value) => setState(() => _selectedGender = value),
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 身高體重
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '身高',
                          hintText: '170',
                          suffixText: 'cm',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return '請輸入身高';
                          final height = double.tryParse(value);
                          if (height == null || height < 100 || height > 250) return '請輸入有效的身高';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '體重',
                          hintText: '70',
                          suffixText: 'kg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return '請輸入體重';
                          final weight = double.tryParse(value);
                          if (weight == null || weight < 30 || weight > 300) return '請輸入有效的體重';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 活動量選擇
                const Text('日常活動量', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('久坐'),
                      subtitle: const Text('辦公室工作，幾乎沒有運動'),
                      value: 'sedentary',
                      groupValue: _selectedActivityLevel,
                      onChanged: (value) => setState(() => _selectedActivityLevel = value!),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('輕度活動'),
                      subtitle: const Text('每週運動 1-3 天'),
                      value: 'lightly_active',
                      groupValue: _selectedActivityLevel,
                      onChanged: (value) => setState(() => _selectedActivityLevel = value!),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('中度活動'),
                      subtitle: const Text('每週運動 3-5 天'),
                      value: 'moderately_active',
                      groupValue: _selectedActivityLevel,
                      onChanged: (value) => setState(() => _selectedActivityLevel = value!),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('高度活動'),
                      subtitle: const Text('每週運動 6-7 天'),
                      value: 'very_active',
                      groupValue: _selectedActivityLevel,
                      onChanged: (value) => setState(() => _selectedActivityLevel = value!),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('極高活動'),
                      subtitle: const Text('每天運動 + 體力勞動工作'),
                      value: 'extra_active',
                      groupValue: _selectedActivityLevel,
                      onChanged: (value) => setState(() => _selectedActivityLevel = value!),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 健康目標
                const Text('健康目標', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Column(
                  children: [
                    RadioListTile<int>(
                      title: const Text('減重'),
                      subtitle: const Text('每天減少 500 卡路里'),
                      value: 1,
                      groupValue: _selectedGoal,
                      onChanged: (value) => setState(() => _selectedGoal = value),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<int>(
                      title: const Text('維持體重'),
                      subtitle: const Text('保持目前體重'),
                      value: 0,
                      groupValue: _selectedGoal,
                      onChanged: (value) => setState(() => _selectedGoal = value),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<int>(
                      title: const Text('增重'),
                      subtitle: const Text('每天增加 500 卡路里'),
                      value: 2,
                      groupValue: _selectedGoal,
                      onChanged: (value) => setState(() => _selectedGoal = value),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 完成按鈕
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            '完成設定',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}