import '../entities/food_entry.dart';
import '../repositories/food_diary_repository.dart';

class GetFoodEntriesUseCase {
  final FoodDiaryRepository repository;

  GetFoodEntriesUseCase(this.repository);

  Future<List<FoodEntry>> call(DateTime date) {
    return repository.getFoodEntries(date);
  }
}
