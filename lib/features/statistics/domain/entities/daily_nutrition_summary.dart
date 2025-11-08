/// 每日營養總結
class DailyNutritionSummary {
  final DateTime date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final double totalSugar;
  final double totalSodium;

  // 目標值
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;

  const DailyNutritionSummary({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.totalSugar,
    required this.totalSodium,
    this.targetCalories = 2000,
    this.targetProtein = 80,
    this.targetCarbs = 250,
    this.targetFat = 70,
  });

  /// 卡路里達成率 (0.0 - 1.0)
  double get caloriesProgress => totalCalories / targetCalories;

  /// 蛋白質達成率
  double get proteinProgress => totalProtein / targetProtein;

  /// 碳水達成率
  double get carbsProgress => totalCarbs / targetCarbs;

  /// 脂肪達成率
  double get fatProgress => totalFat / targetFat;

  /// 是否達標
  bool get isCaloriesOnTarget => caloriesProgress >= 0.9 && caloriesProgress <= 1.1;

  static DailyNutritionSummary empty(DateTime date) {
    return DailyNutritionSummary(
      date: date,
      totalCalories: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      totalFiber: 0,
      totalSugar: 0,
      totalSodium: 0,
    );
  }
}
