/// API 端點配置
class ApiEndpoints {
  // Flask API 基礎 URL
  static const String baseUrl = 'http://127.0.0.1:5000';

  // 超時時間配置
  static const Duration timeout = Duration(seconds: 30);

  // AI 分析相關端點
  static const String predict = '/predict';
  static const String health = '/';

  // RAG 系統相關端點
  static const String ragData = '/rag-data';

  /// 獲取完整的 API URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// 獲取靜態檔案 URL
  static String getStaticFileUrl(String filePath) {
    if (filePath.startsWith('/static/')) {
      return '$baseUrl$filePath';
    }
    return filePath;
  }
}