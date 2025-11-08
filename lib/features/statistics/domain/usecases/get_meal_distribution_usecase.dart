import '../entities/meal_distribution.dart';
import '../repositories/statistics_repository.dart';

class GetMealDistributionUseCase {
  final StatisticsRepository repository;

  GetMealDistributionUseCase(this.repository);

  Future<MealDistribution> call(DateTime date) {
    return repository.getMealDistribution(date);
  }
}
