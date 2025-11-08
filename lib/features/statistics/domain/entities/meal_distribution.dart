/// 餐別熱量分布
class MealDistribution {
  final double breakfastCalories;
  final double lunchCalories;
  final double dinnerCalories;
  final double snackCalories;

  const MealDistribution({
    required this.breakfastCalories,
    required this.lunchCalories,
    required this.dinnerCalories,
    this.snackCalories = 0,
  });

  /// 總卡路里
  double get totalCalories =>
      breakfastCalories + lunchCalories + dinnerCalories + snackCalories;

  /// 早餐比例
  double get breakfastPercentage =>
      totalCalories > 0 ? breakfastCalories / totalCalories : 0;

  /// 午餐比例
  double get lunchPercentage =>
      totalCalories > 0 ? lunchCalories / totalCalories : 0;

  /// 晚餐比例
  double get dinnerPercentage =>
      totalCalories > 0 ? dinnerCalories / totalCalories : 0;

  /// 點心比例
  double get snackPercentage =>
      totalCalories > 0 ? snackCalories / totalCalories : 0;

  static const MealDistribution empty = MealDistribution(
    breakfastCalories: 0,
    lunchCalories: 0,
    dinnerCalories: 0,
    snackCalories: 0,
  );
}
