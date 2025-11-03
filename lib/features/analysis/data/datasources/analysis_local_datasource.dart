import '../../domain/entities/body_metrics.dart';

/// 身體分析本地數據源介面
abstract class AnalysisLocalDatasource {
  /// 獲取最新的身體指標
  Future<BodyMetrics?> getLatestBodyMetrics();

  /// 保存身體指標到本地
  Future<bool> saveBodyMetrics(BodyMetrics metrics);

  /// 獲取指定日期的身體指標
  Future<BodyMetrics?> getBodyMetricsByDate(DateTime date);

  /// 獲取身體指標歷史記錄
  Future<List<BodyMetrics>> getBodyMetricsHistory({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 刪除指定日期的身體指標
  Future<bool> deleteBodyMetrics(DateTime date);

  /// 清空所有本地身體指標數據
  Future<bool> clearAllBodyMetrics();
}