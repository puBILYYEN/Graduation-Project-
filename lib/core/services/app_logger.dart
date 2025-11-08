// ====================================================================
// 應用程式日誌初始化服務
// ====================================================================
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../data/services/log_manager.dart';

class AppLogger {
  /// 初始化應用程式日誌系統
  static Future<void> initialize() async {
    // 初始化日誌管理器
    await LogManager.instance.initialize();
    await log('========================================');
    await log('應用程式啟動');
    await log('時間: ${DateTime.now()}');
    await log('日誌文件位置: ${LogManager.instance.logFilePath}');
    await log('========================================');

    // 設置 Flutter 錯誤捕獲
    FlutterError.onError = (FlutterErrorDetails details) async {
      await log('❌ Flutter 框架錯誤:');
      await log('   異常: ${details.exception}');
      await log('   堆疊: ${details.stack}');
      await log('   上下文: ${details.context}');
      await log('   庫: ${details.library}');

      // 仍然顯示錯誤到控制台
      FlutterError.presentError(details);
    };

    // 設置 Dart 異步錯誤捕獲
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      log('❌ Dart 異步錯誤:');
      log('   異常: $error');
      log('   堆疊: $stack');
      return true; // 表示錯誤已處理
    };

    await log('✅ 日誌系統初始化完成');
  }

  /// 記錄應用程式關鍵事件
  static Future<void> logEvent(String event) async {
    await log('📌 事件: $event');
  }

  /// 記錄頁面導航
  static Future<void> logNavigation(String from, String to) async {
    await log('🔄 導航: $from → $to');
  }

  /// 記錄按鈕點擊
  static Future<void> logButtonClick(String buttonName) async {
    await log('👆 按鈕點擊: $buttonName');
  }

  /// 記錄網路請求
  static Future<void> logNetworkRequest(String method, String url) async {
    await log('🌐 網路請求: $method $url');
  }

  /// 記錄網路響應
  static Future<void> logNetworkResponse(int statusCode, String url) async {
    await log('📡 網路響應: $statusCode $url');
  }

  /// 記錄相機操作
  static Future<void> logCameraAction(String action) async {
    await log('📷 相機操作: $action');
  }

  /// 記錄 Firebase 操作
  static Future<void> logFirebaseAction(String action) async {
    await log('🔥 Firebase: $action');
  }
}
