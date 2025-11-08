import 'package:flutter/foundation.dart';
import '../../domain/entities/daily_nutrition_summary.dart';
import '../../domain/entities/weight_record.dart';
import '../../domain/entities/meal_distribution.dart';
import '../../domain/usecases/get_daily_nutrition_usecase.dart';
import '../../domain/usecases/get_weekly_nutrition_usecase.dart';
import '../../domain/usecases/get_weight_history_usecase.dart';
import '../../domain/usecases/get_meal_distribution_usecase.dart';

class StatisticsViewModel extends ChangeNotifier {
  final GetDailyNutritionUseCase getDailyNutritionUseCase;
  final GetWeeklyNutritionUseCase getWeeklyNutritionUseCase;
  final GetWeightHistoryUseCase getWeightHistoryUseCase;
  final GetMealDistributionUseCase getMealDistributionUseCase;

  StatisticsViewModel({
    required this.getDailyNutritionUseCase,
    required this.getWeeklyNutritionUseCase,
    required this.getWeightHistoryUseCase,
    required this.getMealDistributionUseCase,
  });

  // State
  bool _isLoading = false;
  String? _errorMessage;

  DailyNutritionSummary? _dailySummary;
  List<DailyNutritionSummary> _weeklySummaries = [];
  List<WeightRecord> _weightRecords = [];
  MealDistribution? _mealDistribution;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DailyNutritionSummary? get dailySummary => _dailySummary;
  List<DailyNutritionSummary> get weeklySummaries => _weeklySummaries;
  List<WeightRecord> get weightRecords => _weightRecords;
  MealDistribution? get mealDistribution => _mealDistribution;

  /// 載入今日統計數據
  Future<void> loadTodayStatistics() async {
    final today = DateTime.now();
    await loadStatistics(today);
  }

  /// 載入指定日期的統計數據
  Future<void> loadStatistics(DateTime date) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // 並行載入所有數據
      final results = await Future.wait([
        getDailyNutritionUseCase(date),
        getWeeklyNutritionUseCase(_getWeekStart(date)),
        getWeightHistoryUseCase(
          startDate: date.subtract(const Duration(days: 30)),
          endDate: date,
        ),
        getMealDistributionUseCase(date),
      ]);

      _dailySummary = results[0] as DailyNutritionSummary;
      _weeklySummaries = results[1] as List<DailyNutritionSummary>;
      _weightRecords = results[2] as List<WeightRecord>;
      _mealDistribution = results[3] as MealDistribution;

      _setLoading(false);
    } catch (e) {
      _errorMessage = '載入數據失敗: $e';
      _setLoading(false);
    }
  }

  /// 刷新數據
  Future<void> refresh() async {
    await loadTodayStatistics();
  }

  DateTime _getWeekStart(DateTime date) {
    // 取得本週一
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
