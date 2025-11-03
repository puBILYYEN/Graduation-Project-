import '../../domain/entities/body_metrics.dart';

/// 身體分析遠端數據源介面
abstract class AnalysisRemoteDatasource {
  /// 從 Power BI 獲取身體指標數據
  Future<BodyMetrics?> fetchFromPowerBI();

  /// 上傳身體指標到雲端
  Future<bool> uploadBodyMetrics(BodyMetrics metrics);

  /// 從健康穿戴設備同步數據
  Future<BodyMetrics?> syncFromWearableDevice();

  /// 檢查遠端服務是否可用
  Future<bool> isServiceAvailable();
}