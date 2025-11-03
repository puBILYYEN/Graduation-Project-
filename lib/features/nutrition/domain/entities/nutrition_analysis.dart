/// 營養分析實體 - 代表營養分析的核心業務物件
class NutritionAnalysis {
  final String id;
  final String imagePath;
  final List<FoodItem> detectedFoods;
  final NutritionSummary summary;
  final String dietAdvice;
  final DateTime analyzedAt;
  final double confidence;

  const NutritionAnalysis({
    required this.id,
    required this.imagePath,
    required this.detectedFoods,
    required this.summary,
    required this.dietAdvice,
    required this.analyzedAt,
    required this.confidence,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionAnalysis &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 食物項目實體
class FoodItem {
  final String id;
  final String name;
  final String chineseName;
  final double confidence;
  final NutritionInfo nutritionInfo;

  const FoodItem({
    required this.id,
    required this.name,
    required this.chineseName,
    required this.confidence,
    required this.nutritionInfo,
  });
}

/// 營養信息實體
class NutritionInfo {
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final String servingSize;

  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.servingSize,
  });
}

/// 營養摘要實體
class NutritionSummary {
  final double totalCalories;
  final double totalProtein;
  final double totalCarbohydrates;
  final double totalFat;
  final List<NutrientPercentage> nutritionBreakdown;

  const NutritionSummary({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbohydrates,
    required this.totalFat,
    required this.nutritionBreakdown,
  });
}

/// 營養素百分比實體
class NutrientPercentage {
  final String name;
  final double percentage;
  final String colorHex;

  const NutrientPercentage({
    required this.name,
    required this.percentage,
    required this.colorHex,
  });
}