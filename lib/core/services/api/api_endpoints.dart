/// API ç«¯é??ç½®
class ApiEndpoints {
  // Flask API ?ºç? URLï¼ˆé€é? ngrok ??¥?°æœ¬??Flask ?å?ï¼?
  // ?¬åœ°?‹ç™¼ï¼?http://127.0.0.1:5000'
  // ngrokï¼?https://nutrition-api-459965557703.asia-east1.run.app'
  static const String baseUrl = 'https://nutrition-api-459965557703.asia-east1.run.app';

  // è¶…æ??‚é??ç½®
  static const Duration timeout = Duration(seconds: 30);

  // AI ?†æ??¸é?ç«¯é?
  static const String predict = '/predict';
  static const String health = '/';

  // RAG ç³»çµ±?¸é?ç«¯é?
  static const String ragData = '/rag-data';

  /// ?²å?å®Œæ•´??API URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// ?²å??œæ?æª”æ? URL
  static String getStaticFileUrl(String filePath) {
    if (filePath.startsWith('/static/')) {
      return '$baseUrl$filePath';
    }
    return filePath;
  }
}
