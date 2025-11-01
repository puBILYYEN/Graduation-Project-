import '../../domain/entities/body_metrics.dart';
import '../../domain/repositories/analysis_repository.dart';
import '../datasources/analysis_local_datasource.dart';
import '../datasources/analysis_remote_datasource.dart';

/// 身體分析 Repository 實作
class AnalysisRepositoryImpl implements AnalysisRepository {
  final AnalysisLocalDatasource _localDatasource;
  final AnalysisRemoteDatasource _remoteDatasource;

  const AnalysisRepositoryImpl(
    this._localDatasource,
    this._remoteDatasource,
  );

  @override
  Future<BodyMetrics> getBodyMetrics(String userId) async {
    try {
      // 優先從本地獲取最新數據
      var metrics = await _localDatasource.getLatestBodyMetrics();

      // 如果本地沒有數據，則使用預設值
      if (metrics == null) {
        metrics = BodyMetrics.defaultMetrics();
        await _localDatasource.saveBodyMetrics(metrics);
      }

      return metrics;
    } catch (e) {
      throw Exception('獲取身體指標失敗: $e');
    }
  }

  @override
  Future<bool> updateBodyMetrics(BodyMetrics metrics) async {
    try {
      // 保存到本地
      await _localDatasource.saveBodyMetrics(metrics);

      // 嘗試同步到遠端（非阻塞）
      _syncToRemote(metrics);

      return true;
    } catch (e) {
      throw Exception('更新身體指標失敗: $e');
    }
  }

  @override
  Future<List<BodyMetrics>> getBodyMetricsHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await _localDatasource.getBodyMetricsHistory(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('獲取身體指標歷史失敗: $e');
    }
  }

  @override
  Future<BodyMetrics> getBodyMetricsByDate(DateTime date) async {
    try {
      final metrics = await _localDatasource.getBodyMetricsByDate(date);
      if (metrics == null) {
        throw Exception('找不到該日期的身體指標數據');
      }
      return metrics;
    } catch (e) {
      throw Exception('獲取指定日期身體指標失敗: $e');
    }
  }

  @override
  Future<bool> syncWithPowerBI() async {
    try {
      final powerBIData = await _remoteDatasource.fetchFromPowerBI();
      if (powerBIData != null) {
        await _localDatasource.saveBodyMetrics(powerBIData);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Power BI 同步失敗: $e');
    }
  }

  /// 非阻塞同步到遠端
  void _syncToRemote(BodyMetrics metrics) async {
    try {
      await _remoteDatasource.uploadBodyMetrics(metrics);
    } catch (e) {
      // 遠端同步失敗不影響本地操作，僅記錄錯誤
      print('遠端同步失敗: $e');
    }
  }
}