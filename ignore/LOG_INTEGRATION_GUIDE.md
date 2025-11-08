# 應用程式日誌集成指南

## 目標
在所有關鍵位置添加日誌記錄，完全掌握應用程式運行狀態。

## 需要修改的文件清單

### 1. lib/features/home/presentation/pages/main_frame.dart

**添加 import（第4行後）：**
```dart
import '../../../../core/services/app_logger.dart';
```

**修改 onTap 方法（約第82行）：**
```dart
onTap: (index) async {
  await AppLogger.logButtonClick('底部導航按鈕 index=$index');
  if (index == 2) {
    await AppLogger.logNavigation('MainFrame', '/camera');
    context.push('/camera');
  } else {
    setState(() {
      AppPage newPage = _getPageFromNavigationIndex(index);
      AppLogger.logNavigation(_currentPage.toString(), newPage.toString());
      _currentPage = newPage;
    });
  }
},
```

---

### 2. lib/features/auth/presentation/pages/login_page.dart

**添加 import（約第12行後）：**
```dart
import '../../../../core/services/app_logger.dart';
```

**修改 _handleLogin 方法（約第66行）：**
```dart
void _handleLogin(LoginViewModel viewModel) async {
  await AppLogger.logButtonClick('登入按鈕');
  if (!_formKey.currentState!.validate()) {
    await AppLogger.logEvent('登入表單驗證失敗');
    return;
  }

  await AppLogger.logEvent('開始 Email 登入: ${_emailController.text.trim()}');
  final success = await viewModel.signIn(
    _emailController.text.trim(),
    _passwordController.text,
  );

  if (success && mounted) {
    await AppLogger.logEvent('✅ Email 登入成功');
    await AppLogger.logNavigation('/login', '/home');
    context.go('/home');
  } else {
    await AppLogger.logEvent('❌ Email 登入失敗');
  }
}
```

**修改 _handleGoogleLogin 方法（約第83行）：**
```dart
void _handleGoogleLogin(LoginViewModel viewModel) async {
  await AppLogger.logButtonClick('Google 登入按鈕');
  await AppLogger.logEvent('開始 Google 登入');
  final success = await viewModel.signInWithGoogle();

  if (success && mounted) {
    await AppLogger.logEvent('✅ Google 登入成功');
    await AppLogger.logNavigation('/login', '/home');
    context.go('/home');
  } else {
    await AppLogger.logEvent('❌ Google 登入失敗');
  }
}
```

---

### 3. lib/features/home/presentation/pages/home_page.dart

**添加 import（約第11行後）：**
```dart
import '../../../../core/services/app_logger.dart';
```

**在 initState 中添加（約第55行後）：**
```dart
@override
void initState() {
  super.initState();
  AppLogger.logEvent('首頁初始化');
  _initializeSocket();
}
```

**在 Scaffold openDrawer 前添加（約第133行）：**
```dart
onPressed() async {
  await AppLogger.logButtonClick('側邊選單按鈕');
  Scaffold.of(context).openDrawer();
},
```

**在設置按鈕添加（約第151行）：**
```dart
onPressed: () async {
  await AppLogger.logButtonClick('設置按鈕');
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => const SettingsPage()),
  );
},
```

**在統計卡片點擊添加（約第978行）：**
```dart
onTap: () async {
  await AppLogger.logButtonClick('營養統計入口');
  context.push('/statistics');
},
```

---

### 4. lib/pages/camera/camera_screen_full.dart

**添加 import（約第27行後）：**
```dart
import '../../core/services/app_logger.dart';
```

**在 initState 中添加（約第120行後）：**
```dart
@override
void initState() {
  super.initState();
  AppLogger.logEvent('相機頁面初始化');

  WidgetsBinding.instance.addObserver(this);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  _initializeCamera();
  _initializeTestData();
  _startOrientationDetection();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeMeasurementFramePosition();
  });
}
```

**在拍照按鈕方法中添加（約第700行的 _takeSmartVolumePhoto）：**
在方法開頭添加：
```dart
Future<void> _takeSmartVolumePhoto() async {
  await AppLogger.logCameraAction('智慧拍照按鈕點擊');
  // ... 原有代碼
}
```

**在開啟相簿方法中添加（約第1600行的 _openGallery）：**
```dart
Future<void> _openGallery() async {
  await AppLogger.logCameraAction('開啟相簿');
  // ... 原有代碼
}
```

**在切換鏡頭方法中添加（約第1700行的 _switchCamera）：**
```dart
Future<void> _switchCamera() async {
  await AppLogger.logCameraAction('切換鏡頭');
  // ... 原有代碼
}
```

---

### 5. lib/core/services/auth_service.dart （如果存在）

**添加 Firebase 操作日誌：**
在每個 Firebase 操作前後添加日誌。

---

## 部署步驟

1. **停止當前運行的 flutter run**
2. **按照上述指南修改所有文件**
3. **保存所有修改**
4. **重新運行應用程式**
5. **測試並查看日誌輸出**

---

## 導出日誌文件

```bash
adb pull /data/user/0/com.foodtracker.nutritionapp/app_flutter/app_log.log ./app_log.log
```

---

## 日誌級別說明

- `📌 事件` - 一般事件
- `🔄 導航` - 頁面導航
- `👆 按鈕點擊` - 用戶交互
- `🌐 網路請求` - HTTP 請求
- `📡 網路響應` - HTTP 響應
- `📷 相機操作` - 相機相關
- `🔥 Firebase` - Firebase 操作
- `❌ 錯誤` - 錯誤信息
- `✅ 成功` - 成功操作
