import '../entities/food_entry.dart';
import '../entities/nutrition_info.dart';

abstract class FoodDiaryRepository {
  Future<List<FoodEntry>> getFoodEntries(DateTime date);
  Future<void> addFoodEntry(FoodEntry entry);
  Future<NutritionInfo> getNutritionInfoForFood(String foodName);
}