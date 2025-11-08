import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../analysis/presentation/viewmodels/body_analysis_viewmodel.dart';
import '../../../../core/services/app_logger.dart';

/// 設定頁面
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 表單控制器
  final _displayNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _sleepHoursController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _systolicController = TextEditingController(); // 收縮壓
  final _diastolicController = TextEditingController(); // 舒張壓

  // 選擇項目
  bool? _selectedGender; // true=男性, false=女性
  int? _selectedGoal; // 0=維持, 1=減重, 2=增重
  String _selectedActivityLevel = 'moderately_active';

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    AppLogger.logEvent('設定頁面初始化');
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _sleepHoursController.dispose();
    _heartRateController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    super.dispose();
  }

  /// 載入使用者資料
  Future<void> _loadUserData() async {
    await AppLogger.logEvent('開始載入使用者資料');
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 載入基本資料
      _displayNameController.text = user.displayName ?? '';

      // 載入所有數據
      final doc = await _firestore.collection('member').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;

        // 基本資料
        _ageController.text = (data['age'] ?? 25).toString();
        _heightController.text = (data['height'] ?? 170).toString();
        _weightController.text = (data['weight'] ?? 70).toString();

        // 健康數據
        _sleepHoursController.text = (data['sleepHours'] ?? 8).toString();
        _heartRateController.text = (data['heartRate'] ?? 75).toString();

        // 性別、目標、活動量
        _selectedGender = data['gender'] as bool?;
        _selectedGoal = data['goal'] as int?;
        _selectedActivityLevel = data['activityLevel'] ?? 'moderately_active';

        // 解析血壓
        final bloodPressure = data['bloodPressure'] ?? '120/80';
        final parts = bloodPressure.split('/');
        if (parts.length == 2) {
          _systolicController.text = parts[0];
          _diastolicController.text = parts[1];
        }
      }

      await AppLogger.logEvent('[OK] 使用者資料載入成功');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      await AppLogger.logEvent('[ERROR] 載入資料錯誤: $e');
      print('載入資料錯誤: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 計算 BMR (基礎代謝率)
  double _calculateBMR(int age, double height, double weight, bool isMale) {
    if (isMale) {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  /// 計算 TDEE (總日耗能)
  double _calculateTDEE(double bmr, String activityLevel) {
    Map<String, double> activityMultipliers = {
      'sedentary': 1.2,
      'lightly_active': 1.375,
      'moderately_active': 1.55,
      'very_active': 1.725,
      'extra_active': 1.9,
    };
    return bmr * (activityMultipliers[activityLevel] ?? 1.55);
  }

  /// 計算建議卡路里
  double _calculateSuggestedCalories(double tdee, int goal) {
    double suggestedCalories;
    switch (goal) {
      case 1: // 減重
        suggestedCalories = tdee - 500;
        break;
      case 2: // 增重
        suggestedCalories = tdee + 500;
        break;
      default: // 維持
        suggestedCalories = tdee;
    }
    return suggestedCalories < 1200 ? 1200 : suggestedCalories;
  }

  /// 保存資料
  Future<void> _saveUserData() async {
    try {
      setState(() {
        _isSaving = true;
      });

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('使用者未登入');
      }

      // 驗證輸入
      final age = int.tryParse(_ageController.text);
      final height = int.tryParse(_heightController.text);
      final weight = int.tryParse(_weightController.text);
      final sleepHours = int.tryParse(_sleepHoursController.text);
      final heartRate = int.tryParse(_heartRateController.text);
      final systolic = int.tryParse(_systolicController.text);
      final diastolic = int.tryParse(_diastolicController.text);

      // 基本驗證
      if (age == null || age < 10 || age > 100) {
        throw Exception('年齡數值不正確 (10-100 歲)');
      }
      if (height == null || height < 100 || height > 250) {
        throw Exception('身高數值不正確 (100-250 cm)');
      }
      if (weight == null || weight < 30 || weight > 300) {
        throw Exception('體重數值不正確 (30-300 kg)');
      }
      if (sleepHours == null || sleepHours < 0 || sleepHours > 24) {
        throw Exception('睡眠時數不正確 (0-24 小時)');
      }
      if (heartRate == null || heartRate < 40 || heartRate > 200) {
        throw Exception('心率數值不正確 (40-200 bpm)');
      }
      if (systolic == null || diastolic == null) {
        throw Exception('血壓數值不正確');
      }
      if (_selectedGender == null) {
        throw Exception('請選擇性別');
      }
      if (_selectedGoal == null) {
        throw Exception('請選擇健康目標');
      }

      // 計算營養數據
      final bmr = _calculateBMR(age, height.toDouble(), weight.toDouble(), _selectedGender!);
      final tdee = _calculateTDEE(bmr, _selectedActivityLevel);
      final suggestedCalories = _calculateSuggestedCalories(tdee, _selectedGoal!);

      // 計算營養目標
      final targetProtein = (suggestedCalories * 0.3) / 4;
      final targetCarbs = (suggestedCalories * 0.45) / 4;
      final targetFat = (suggestedCalories * 0.25) / 9;

      // 更新 Firebase Auth 顯示名稱
      if (_displayNameController.text.isNotEmpty) {
        await user.updateDisplayName(_displayNameController.text);
        await user.reload();
      }

      // 更新 Firestore 所有數據（與 ProfileSetupPage 保持一致）
      final bloodPressure = '$systolic/$diastolic';

      await _firestore.collection('member').doc(user.uid).set({
        // 個人基本資料
        'age': age,
        'gender': _selectedGender,
        'height': height,
        'weight': weight,
        'goal': _selectedGoal,
        'activityLevel': _selectedActivityLevel,

        // 健康數據
        'sleepHours': sleepHours,
        'heartRate': heartRate,
        'bloodPressure': bloodPressure,

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

      // 刷新 ViewModel
      if (mounted) {
        final viewModel = context.read<BodyAnalysisViewModel>();
        await viewModel.fetchBodyMetrics();
      }

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ 資料已儲存並重新計算營養目標'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('💥 設定頁面儲存失敗: $e');
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('儲存失敗: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 刪除帳號
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除帳號'),
        content: const Text(
          '確定要刪除帳號嗎？\n\n此操作將：\n• 刪除所有個人資料\n• 刪除所有運動記錄\n• 刪除所有飲食記錄\n\n此操作無法復原！',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('確定刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 刪除 Firestore 資料
      await _firestore.collection('member').doc(user.uid).delete();

      // 刪除 Firebase Auth 帳號
      await user.delete();

      // 返回登入頁面
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刪除失敗: $e')),
        );
      }
    }
  }

  /// 登出
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('登出'),
        content: const Text('確定要登出嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('登出'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _auth.signOut();

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '設定',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 使用者資訊卡片
                  _buildUserInfoCard(user),
                  const SizedBox(height: 16),

                  // 基本資料
                  _buildSectionTitle('基本資料'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _displayNameController,
                    label: '顯示名稱',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _ageController,
                    label: '年齡',
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  // 性別選擇
                  const Text('性別', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('男性', style: TextStyle(fontSize: 14)),
                          value: true,
                          groupValue: _selectedGender,
                          onChanged: (value) => setState(() => _selectedGender = value),
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('女性', style: TextStyle(fontSize: 14)),
                          value: false,
                          groupValue: _selectedGender,
                          onChanged: (value) => setState(() => _selectedGender = value),
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 身體數據
                  _buildSectionTitle('身體數據'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _heightController,
                          label: '身高 (cm)',
                          icon: Icons.height,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _weightController,
                          label: '體重 (kg)',
                          icon: Icons.monitor_weight,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _sleepHoursController,
                          label: '睡眠時數',
                          icon: Icons.bedtime,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _heartRateController,
                          label: '心率 (bpm)',
                          icon: Icons.favorite,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSectionTitle('血壓 (mmHg)'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _systolicController,
                          label: '收縮壓',
                          icon: Icons.arrow_upward,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _diastolicController,
                          label: '舒張壓',
                          icon: Icons.arrow_downward,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 日常活動量
                  _buildSectionTitle('日常活動量'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('久坐', style: TextStyle(fontSize: 14)),
                          subtitle: const Text('辦公室工作,幾乎沒有運動', style: TextStyle(fontSize: 12)),
                          value: 'sedentary',
                          groupValue: _selectedActivityLevel,
                          onChanged: (value) => setState(() => _selectedActivityLevel = value!),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        RadioListTile<String>(
                          title: const Text('輕度活動', style: TextStyle(fontSize: 14)),
                          subtitle: const Text('每週運動 1-3 天', style: TextStyle(fontSize: 12)),
                          value: 'lightly_active',
                          groupValue: _selectedActivityLevel,
                          onChanged: (value) => setState(() => _selectedActivityLevel = value!),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        RadioListTile<String>(
                          title: const Text('中度活動', style: TextStyle(fontSize: 14)),
                          subtitle: const Text('每週運動 3-5 天', style: TextStyle(fontSize: 12)),
                          value: 'moderately_active',
                          groupValue: _selectedActivityLevel,
                          onChanged: (value) => setState(() => _selectedActivityLevel = value!),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        RadioListTile<String>(
                          title: const Text('高度活動', style: TextStyle(fontSize: 14)),
                          subtitle: const Text('每週運動 6-7 天', style: TextStyle(fontSize: 12)),
                          value: 'very_active',
                          groupValue: _selectedActivityLevel,
                          onChanged: (value) => setState(() => _selectedActivityLevel = value!),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        RadioListTile<String>(
                          title: const Text('極高活動', style: TextStyle(fontSize: 14)),
                          subtitle: const Text('每天運動 + 體力勞動工作', style: TextStyle(fontSize: 12)),
                          value: 'extra_active',
                          groupValue: _selectedActivityLevel,
                          onChanged: (value) => setState(() => _selectedActivityLevel = value!),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 健康目標
                  _buildSectionTitle('健康目標'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<int>(
                          title: const Text('減重', style: TextStyle(fontSize: 14)),
                          subtitle: const Text('每天減少 500 卡路里', style: TextStyle(fontSize: 12)),
                          value: 1,
                          groupValue: _selectedGoal,
                          onChanged: (value) => setState(() => _selectedGoal = value),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        RadioListTile<int>(
                          title: const Text('維持體重', style: TextStyle(fontSize: 14)),
                          subtitle: const Text('保持目前體重', style: TextStyle(fontSize: 12)),
                          value: 0,
                          groupValue: _selectedGoal,
                          onChanged: (value) => setState(() => _selectedGoal = value),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        RadioListTile<int>(
                          title: const Text('增重', style: TextStyle(fontSize: 14)),
                          subtitle: const Text('每天增加 500 卡路里', style: TextStyle(fontSize: 12)),
                          value: 2,
                          groupValue: _selectedGoal,
                          onChanged: (value) => setState(() => _selectedGoal = value),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 儲存按鈕
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              '儲存變更',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 登出按鈕
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _signOut,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '登出',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 刪除帳號按鈕
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _deleteAccount,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '刪除帳號',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  /// 使用者資訊卡片
  Widget _buildUserInfoCard(User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? '未設定',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 區塊標題
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  /// 文字輸入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2196F3)),
        ),
      ),
    );
  }
}
