// ====================================================================
// 應用程式日誌服務 (Logger Service)
// ====================================================================
import 'package:logger/logger.dart';

/// 應用程式日誌工具
/// 
/// 提供統一的日誌記錄介面，支援不同級別的日誌記錄和格式化輸出
class AppLogger {
  // 私有構造器
  AppLogger._();

  // 單例實例
  static final AppLogger _instance = AppLogger._();

  // 取得單例實例
  static AppLogger get instance => _instance;

  // Logger 實例
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    // 在發布版本中關閉除錯輸出
    level: bool.fromEnvironment('dart.vm.product') ? Level.warning : Level.debug,
  );

  // -------------------------------------------------------------------
  // 公開方法
  // -------------------------------------------------------------------

  /// 記錄除錯資訊
  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 記錄一般資訊
  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// 記錄警告資訊
  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// 記錄錯誤資訊
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// 記錄致命錯誤
  void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.wtf(message, error: error, stackTrace: stackTrace);
  }
}