import '../entities/daily_nutrition_summary.dart';
import '../repositories/statistics_repository.dart';

class GetDailyNutritionUseCase {
  final StatisticsRepository repository;

  GetDailyNutritionUseCase(this.repository);

  Future<DailyNutritionSummary> call(DateTime date) {
    return repository.getDailyNutritionSummary(date);
  }
}
