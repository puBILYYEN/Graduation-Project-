import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';

/// HTTP API 客戶端基礎類
class ApiClient {
  /// 發送 GET 請求
  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse(ApiEndpoints.getFullUrl(endpoint));

    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    ).timeout(ApiEndpoints.timeout);
  }

  /// 發送 POST 請求（JSON 數據）
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse(ApiEndpoints.getFullUrl(endpoint));

    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    ).timeout(ApiEndpoints.timeout);
  }

  /// 發送多部分表單請求（用於檔案上傳）
  static Future<http.StreamedResponse> multipartRequest(
    String endpoint,
    String method, {
    Map<String, String>? fields,
    Map<String, String>? files,
  }) async {
    final url = Uri.parse(ApiEndpoints.getFullUrl(endpoint));
    final request = http.MultipartRequest(method, url);

    // 添加表單欄位
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // 添加檔案
    if (files != null) {
      for (final entry in files.entries) {
        final multipartFile = await http.MultipartFile.fromPath(
          entry.key,
          entry.value,
        );
        request.files.add(multipartFile);
      }
    }

    request.headers.addAll({
      'Content-Type': 'multipart/form-data',
    });

    return await request.send().timeout(ApiEndpoints.timeout);
  }

  /// 將 StreamedResponse 轉換為 Response
  static Future<http.Response> responseFromStream(
    http.StreamedResponse streamedResponse,
  ) async {
    return await http.Response.fromStream(streamedResponse);
  }

  /// 檢查回應是否成功
  static bool isSuccessResponse(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// 解析 JSON 回應
  static Map<String, dynamic> parseJsonResponse(http.Response response) {
    if (!isSuccessResponse(response)) {
      throw ApiException(
        'API 請求失敗: ${response.statusCode}',
        response.body,
      );
    }

    try {
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('JSON 解析失敗', e.toString());
    }
  }
}

/// API 異常類
class ApiException implements Exception {
  final String message;
  final String? details;

  ApiException(this.message, [this.details]);

  @override
  String toString() {
    return details != null ? '$message: $details' : message;
  }
}