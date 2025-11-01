import '../entities/nutrition_analysis.dart';
import '../repositories/nutrition_repository.dart';

/// 獲取營養分析歷史記錄用例
class GetAnalysisHistoryUseCase {
  final NutritionRepository _repository;

  const GetAnalysisHistoryUseCase(this._repository);

  /// 執行獲取分析歷史
  ///
  /// [limit] 限制返回的記錄數量，預設20筆
  /// 返回營養分析歷史記錄列表
  ///
  /// 業務規則：
  /// 1. 限制數量必須大於0且不超過100
  /// 2. 結果按時間倒序排列（最新的在前）
  Future<List<NutritionAnalysis>> call({int limit = 20}) async {
    if (limit <= 0 || limit > 100) {
      throw Exception('記錄數量限制必須在1-100之間');
    }

    try {
      final history = await _repository.getAnalysisHistory(limit: limit);

      // 確保按時間倒序排列
      history.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));

      return history;
    } catch (e) {
      throw Exception('獲取分析歷史失敗: $e');
    }
  }
}