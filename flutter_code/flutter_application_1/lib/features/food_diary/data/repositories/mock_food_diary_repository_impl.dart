import '../../domain/entities/food_entry.dart';
import '../../domain/entities/nutrition_info.dart';
import '../../domain/repositories/food_diary_repository.dart';

class MockFoodDiaryRepositoryImpl implements FoodDiaryRepository {
  final Map<String, List<FoodEntry>> _mockData = {
    _dateKey(DateTime.now()): [
      FoodEntry(
        name: 'Grilled Salmon',
        chineseName: '烤鮭魚',
        mealType: '午餐',
        calories: 350,
        imageUrls: [
          'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400',
          'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400',
          'https://images.unsplash.com/photo-1574781330855-d0db2293d3b3?w=400',
        ],
        servingInfo: '150g',
      ),
      FoodEntry(
        name: 'Greek Salad',
        chineseName: '希臘沙拉',
        mealType: '晚餐',
        calories: 180,
        imageUrls: [
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400',
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
          'https://images.unsplash.com/photo-1551248429-40975aa4de74?w=400',
        ],
        servingInfo: '200g',
      ),
    ],
  };

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<List<FoodEntry>> getFoodEntries(DateTime date) async {
    return _mockData[_dateKey(date)] ?? [];
  }

  @override
  Future<void> addFoodEntry(FoodEntry entry) async {
    final dateKey = _dateKey(DateTime.now());
    if (_mockData.containsKey(dateKey)) {
      _mockData[dateKey]!.add(entry);
    } else {
      _mockData[dateKey] = [entry];
    }
  }

  @override
  Future<NutritionInfo> getNutritionInfoForFood(String foodName) async {
    // Return mock nutrition info
    return NutritionInfo(
      calories: 350,
      protein: 25,
      carbohydrates: 30,
      fat: 15,
      fiber: 5,
      sugar: 8,
      sodium: 200,
      cholesterol: 50,
      vitaminA: 100,
      vitaminC: 20,
      calcium: 150,
      iron: 3,
    );
  }
}
