import '../entities/food_entry.dart';
import '../repositories/food_diary_repository.dart';

/// 獲取每日營養摘要用例
class GetDailySummaryUseCase {
  final FoodDiaryRepository _repository;

  const GetDailySummaryUseCase(this._repository);

  /// 執行獲取每日營養摘要
  ///
  /// [date] 查詢的日期，如果為null則使用今天
  /// 返回該日期的營養統計摘要
  ///
  /// 業務規則：
  /// 1. 自動計算當日所有餐點的營養總和
  /// 2. 按餐點類型分組顯示
  /// 3. 提供詳細的營養成分分析
  Future<DailyNutritionSummary> call({DateTime? date}) async {
    try {
      final targetDate = date ?? DateTime.now();

      // 標準化日期（只保留年月日）
      final normalizedDate = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );

      // 獲取每日營養摘要
      final summary = await _repository.getDailyNutritionSummary(normalizedDate);

      return summary;
    } catch (e) {
      throw Exception('獲取每日營養摘要失敗: $e');
    }
  }

  /// 獲取多日營養摘要比較
  ///
  /// [startDate] 開始日期
  /// [endDate] 結束日期（如果為null則使用今天）
  /// 返回日期範圍內的每日營養摘要列表
  Future<List<DailyNutritionSummary>> getMultipleDaysSummary({
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      final targetEndDate = endDate ?? DateTime.now();

      if (startDate.isAfter(targetEndDate)) {
        throw Exception('開始日期不能晚於結束日期');
      }

      final summaries = <DailyNutritionSummary>[];
      var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
      final normalizedEndDate = DateTime(targetEndDate.year, targetEndDate.month, targetEndDate.day);

      while (!currentDate.isAfter(normalizedEndDate)) {
        final summary = await _repository.getDailyNutritionSummary(currentDate);
        summaries.add(summary);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      return summaries;
    } catch (e) {
      throw Exception('獲取多日營養摘要失敗: $e');
    }
  }
}