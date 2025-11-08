import '../../../food_diary/domain/repositories/food_diary_repository.dart';
import '../../../analysis/domain/repositories/analysis_repository.dart';
import '../../domain/entities/daily_nutrition_summary.dart';
import '../../domain/entities/weight_record.dart';
import '../../domain/entities/meal_distribution.dart';
import '../../domain/repositories/statistics_repository.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final FoodDiaryRepository foodDiaryRepository;
  final AnalysisRepository analysisRepository;

  StatisticsRepositoryImpl({
    required this.foodDiaryRepository,
    required this.analysisRepository,
  });

  @override
  Future<DailyNutritionSummary> getDailyNutritionSummary(DateTime date) async {
    try {
      // 從飲食日記獲取當天的食物記錄
      final entries = await foodDiaryRepository.getFoodEntries(date);

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      double totalFiber = 0;
      double totalSugar = 0;
      double totalSodium = 0;

      // 計算總營養素
      for (var entry in entries) {
        // 簡化版本：只累加卡路里
        // 實際應該從 NutritionInfo 獲取完整營養資訊
        totalCalories += entry.calories;

        // 如果有營養資訊，獲取詳細數據
        try {
          final nutritionInfo = await foodDiaryRepository.getNutritionInfoForFood(entry.name);
          totalProtein += nutritionInfo.protein;
          totalCarbs += nutritionInfo.carbohydrates;
          totalFat += nutritionInfo.fat;
          totalFiber += nutritionInfo.fiber;
          totalSugar += nutritionInfo.sugar;
          totalSodium += nutritionInfo.sodium;
        } catch (e) {
          // 如果沒有營養資訊，使用估計值
          totalProtein += entry.calories * 0.15 / 4; // 15% 蛋白質
          totalCarbs += entry.calories * 0.50 / 4; // 50% 碳水
          totalFat += entry.calories * 0.35 / 9; // 35% 脂肪
        }
      }

      return DailyNutritionSummary(
        date: date,
        totalCalories: totalCalories,
        totalProtein: totalProtein,
        totalCarbs: totalCarbs,
        totalFat: totalFat,
        totalFiber: totalFiber,
        totalSugar: totalSugar,
        totalSodium: totalSodium,
      );
    } catch (e) {
      return DailyNutritionSummary.empty(date);
    }
  }

  @override
  Future<List<DailyNutritionSummary>> getWeeklyNutritionSummary(DateTime startDate) async {
    final List<DailyNutritionSummary> summaries = [];

    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final summary = await getDailyNutritionSummary(date);
      summaries.add(summary);
    }

    return summaries;
  }

  @override
  Future<List<WeightRecord>> getWeightHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // 模擬數據 - 實際應該從 Firebase/本地資料庫獲取
    // 未來可以整合 AnalysisRepository 的體重數據
    final List<WeightRecord> records = [];

    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      // 模擬數據：基準70kg，加上隨機波動
      final baseWeight = 70.0;
      final dayOffset = currentDate.difference(startDate).inDays;
      final weight = baseWeight + (dayOffset * 0.1) - (dayOffset % 3 == 0 ? 0.2 : 0);

      records.add(WeightRecord(
        date: currentDate,
        weight: double.parse(weight.toStringAsFixed(1)),
        bmi: double.parse((weight / (1.70 * 1.70)).toStringAsFixed(1)),
      ));

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return records;
  }

  @override
  Future<MealDistribution> getMealDistribution(DateTime date) async {
    try {
      final entries = await foodDiaryRepository.getFoodEntries(date);

      double breakfastCalories = 0;
      double lunchCalories = 0;
      double dinnerCalories = 0;
      double snackCalories = 0;

      for (var entry in entries) {
        switch (entry.mealType.toLowerCase()) {
          case '早餐':
          case 'breakfast':
            breakfastCalories += entry.calories;
            break;
          case '午餐':
          case 'lunch':
            lunchCalories += entry.calories;
            break;
          case '晚餐':
          case 'dinner':
            dinnerCalories += entry.calories;
            break;
          default:
            snackCalories += entry.calories;
        }
      }

      return MealDistribution(
        breakfastCalories: breakfastCalories,
        lunchCalories: lunchCalories,
        dinnerCalories: dinnerCalories,
        snackCalories: snackCalories,
      );
    } catch (e) {
      return MealDistribution.empty;
    }
  }

  @override
  Future<void> addWeightRecord(WeightRecord record) async {
    // 未來可以實作存儲到 Firebase
    // 目前暫時不實作
    throw UnimplementedError('addWeightRecord not yet implemented');
  }
}
