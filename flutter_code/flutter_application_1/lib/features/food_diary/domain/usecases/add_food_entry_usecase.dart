import '../entities/food_entry.dart';
import '../repositories/food_diary_repository.dart';

class AddFoodEntryUseCase {
  final FoodDiaryRepository repository;

  AddFoodEntryUseCase(this.repository);

  Future<void> call(FoodEntry entry) {
    return repository.addFoodEntry(entry);
  }
}
