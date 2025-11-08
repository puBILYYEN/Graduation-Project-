/// API 端點配置
class ApiEndpoints {
  // Flask API 基礎 URL（透過 DevTunnel 連接到本地 Flask 服務）
  // 本地開發：'http://127.0.0.1:5000'
  // DevTunnel：'https://6j274tdx-5000.asse.devtunnels.ms'
  static const String baseUrl = 'https://6j274tdx-5000.asse.devtunnels.ms';

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