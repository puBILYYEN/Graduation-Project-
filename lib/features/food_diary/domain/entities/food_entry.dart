class FoodEntry {
  final String name;
  final String chineseName;
  final String mealType;
  final int calories;
  final List<String> imageUrls;
  final String servingInfo;

  FoodEntry({
    required this.name,
    required this.chineseName,
    required this.mealType,
    required this.calories,
    required this.imageUrls,
    required this.servingInfo,
  });
}
