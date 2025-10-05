// ====================================================================
// 應用程式根節點 (Application Root)
// ====================================================================
// 這個檔案包含應用程式的最上層 Widget

import 'package:flutter/material.dart';

import '../features/auth/presentation/login_page.dart';

// 主應用程式類別(Main Application Class)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '登入系統', // 應用程式標題
      debugShowCheckedModeBanner: false, // 隱藏除錯橫幅
      theme: ThemeData(
        primarySwatch: Colors.blue, // 主色系設定為藍色
        useMaterial3: true, // 啟用Material 3設計系統(新版的介面設計風格)
      ),
      home: const LoginPage(), // 登入頁面為應用程式起始頁面
    );
  }
}
