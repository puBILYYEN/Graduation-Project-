/// API 端�??�置
class ApiEndpoints {
  // Flask API ?��? URL（透�? ngrok ??��?�本??Flask ?��?�?
  // ?�地?�發�?http://127.0.0.1:5000'
  // ngrok�?https://nutrition-api-459965557703.asia-east1.run.app'
  static const String baseUrl = 'https://nutrition-api-459965557703.asia-east1.run.app';

  // 超�??��??�置
  static const Duration timeout = Duration(seconds: 120); // 延長以支援 YOLO 冷啟動 + 推論 + Gemini

  // AI ?��??��?端�?
  static const String predict = '/predict';
  static const String health = '/';

  // RAG 系統?��?端�?
  static const String ragData = '/rag-data';

  /// ?��?完整??API URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// ?��??��?檔�? URL
  static String getStaticFileUrl(String filePath) {
    if (filePath.startsWith('/static/')) {
      return '$baseUrl$filePath';
    }
    return filePath;
  }
}
