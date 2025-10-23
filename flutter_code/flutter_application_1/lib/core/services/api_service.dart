import 'dart:convert';
import 'package:http/http.dart' as http;

// ===================================================================
// API 服務 (ApiService)
// ===================================================================
/// 封裝所有與後端 API (例如 Flask/YOLO) 溝通的服務
class ApiService {
  // -------------------------------------------------------------------
  // Properties
  // -------------------------------------------------------------------

  /// 您的後端伺服器基礎 URL
  /// TODO: 請將此 URL 替換為您真實的 Flask 伺服器網址
  final String _baseUrl = 'http://127.0.0.1:5000';

  // -------------------------------------------------------------------
  // Public Methods
  // -------------------------------------------------------------------

  /// 上傳圖片進行 YOLO 分析
  ///
  /// [imagePath] 是圖片在裝置上的本地路徑。
  /// 成功時返回一個 Map<String, dynamic> 類型的分析結果。
  /// 失敗時拋出異常。
  Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    // 1. 組合完整的預測 API 端點 URL
    final Uri predictUrl = Uri.parse('$_baseUrl/predict');

    print('準備上傳圖片至: $predictUrl');
    print('圖片路徑: $imagePath');

    // 2. 建立一個 multipart 請求，這種請求常用於檔案上傳
    final request = http.MultipartRequest('POST', predictUrl);

    try {
      // 3. 將圖片檔案附加到請求中
      // 'file' 是後端 Flask 預期接收的欄位名稱，您可能需要根據後端設定修改
      final multipartFile = await http.MultipartFile.fromPath('file', imagePath);
      request.files.add(multipartFile);

      // 4. 發送請求並等待回應
      final streamedResponse = await request.send();

      // 5. 將回應的串流轉換為字串
      final response = await http.Response.fromStream(streamedResponse);

      print('收到後端回應: ${response.statusCode}');
      // print('回應內容: ${response.body}');

      // 6. 檢查回應狀態碼
      if (response.statusCode == 200) {
        // 如果狀態碼是 200 (OK)，解析 JSON 回應
        final Map<String, dynamic> data = json.decode(response.body);
        print('圖片分析成功，結果: $data');
        return data;
      } else {
        // 如果伺服器返回錯誤，拋出異常
        print('圖片分析失敗，伺服器錯誤: ${response.body}');
        throw Exception('伺服器錯誤 ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // 處理網路或其他錯誤
      print('上傳或分析圖片時發生錯誤: $e');
      throw Exception('無法連接到分析伺服器: $e');
    }
  }
}
