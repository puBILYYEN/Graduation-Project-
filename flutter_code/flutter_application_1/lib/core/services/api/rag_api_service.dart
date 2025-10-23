import 'api_client.dart';
import 'api_endpoints.dart';

/// RAG 系統 API 服務
class RagApiService {
  /// 發送 RAG 數據到 Flask 後端
  static Future<bool> sendRagData(Map<String, dynamic> ragData) async {
    try {
      print('正在向 RAG API 發送數據...');

      final response = await ApiClient.post(
        ApiEndpoints.ragData,
        ragData,
      );

      if (ApiClient.isSuccessResponse(response)) {
        print('RAG 數據發送成功');
        return true;
      } else {
        print('RAG API 回應錯誤: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('RAG API 連接失敗: $e');
      return false;
    }
  }

  /// 驗證 RAG 數據格式
  static bool validateRagData(Map<String, dynamic> ragData) {
    final requiredFields = [
      'image_path',
      'timestamp',
      'container',
      'measurements',
      'metadata'
    ];

    for (final field in requiredFields) {
      if (!ragData.containsKey(field)) {
        print('RAG 數據缺少必填欄位: $field');
        return false;
      }
    }

    return true;
  }

  /// 構建標準的 RAG 數據結構
  static Map<String, dynamic> buildRagData({
    required String imagePath,
    required String timestamp,
    required Map<String, dynamic> container,
    required Map<String, dynamic> measurements,
    required Map<String, dynamic> metadata,
  }) {
    return {
      'image_path': imagePath,
      'timestamp': timestamp,
      'container': container,
      'measurements': measurements,
      'metadata': metadata,
      'source': 'flutter_app',
      'version': '1.0',
    };
  }
}