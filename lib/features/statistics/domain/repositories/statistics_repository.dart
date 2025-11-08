import '../entities/daily_nutrition_summary.dart';
import '../entities/weight_record.dart';
import '../entities/meal_distribution.dart';

abstract class StatisticsRepository {
  /// 獲取每日營養總結
  Future<DailyNutritionSummary> getDailyNutritionSummary(DateTime date);

  /// 獲取一週的營養總結
  Future<List<DailyNutritionSummary>> getWeeklyNutritionSummary(DateTime startDate);

  /// 獲取體重歷史記錄
  Future<List<WeightRecord>> getWeightHistory({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 獲取餐別熱量分布
  Future<MealDistribution> getMealDistribution(DateTime date);

  /// 新增體重記錄
  Future<void> addWeightRecord(WeightRecord record);
}
