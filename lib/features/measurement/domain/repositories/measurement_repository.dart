import '../entities/measurement_result.dart';

/// 測量 Repository 介面 - 定義測量相關的資料操作契約
abstract class MeasurementRepository {
  /// 保存測量結果
  ///
  /// [result] 要保存的測量結果
  /// 返回保存是否成功
  Future<bool> saveMeasurementResult(MeasurementResult result);

  /// 獲取測量結果歷史記錄
  ///
  /// [limit] 限制返回的記錄數量
  /// 返回測量結果歷史記錄列表
  Future<List<MeasurementResult>> getMeasurementHistory({int limit = 20});

  /// 獲取特定類型的測量記錄
  ///
  /// [type] 測量類型
  /// [limit] 限制返回的記錄數量
  /// 返回指定類型的測量記錄
  Future<List<MeasurementResult>> getMeasurementsByType(
    MeasurementType type, {
    int limit = 20,
  });

  /// 刪除測量結果
  ///
  /// [resultId] 要刪除的測量結果ID
  /// 返回刪除是否成功
  Future<bool> deleteMeasurementResult(String resultId);

  /// 獲取可用的參考物體列表
  ///
  /// 返回預定義的參考物體列表
  Future<List<ReferenceObject>> getAvailableReferenceObjects();

  /// 添加自定義參考物體
  ///
  /// [referenceObject] 要添加的參考物體
  /// 返回添加是否成功
  Future<bool> addCustomReferenceObject(ReferenceObject referenceObject);

  /// 搜尋測量記錄
  ///
  /// [keyword] 搜尋關鍵字
  /// [limit] 限制返回數量
  /// 返回符合條件的測量記錄
  Future<List<MeasurementResult>> searchMeasurements(
    String keyword, {
    int limit = 20,
  });

  /// 匯出測量數據
  ///
  /// [startDate] 開始日期
  /// [endDate] 結束日期
  /// 返回匯出檔案路徑
  Future<String?> exportMeasurementData({
    required DateTime startDate,
    required DateTime endDate,
  });
}