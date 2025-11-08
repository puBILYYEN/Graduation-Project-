import '../entities/daily_nutrition_summary.dart';
import '../repositories/statistics_repository.dart';

class GetWeeklyNutritionUseCase {
  final StatisticsRepository repository;

  GetWeeklyNutritionUseCase(this.repository);

  Future<List<DailyNutritionSummary>> call(DateTime startDate) {
    return repository.getWeeklyNutritionSummary(startDate);
  }
}
