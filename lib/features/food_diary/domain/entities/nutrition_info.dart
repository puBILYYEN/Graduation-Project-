/// 營養資訊實體
class NutritionInfo {
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final String unit;

  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    this.unit = 'g',
  });

  /// 創建營養資訊副本
  NutritionInfo copyWith({
    double? calories,
    double? protein,
    double? carbohydrates,
    double? fat,
    double? fiber,
    double? sugar,
    double? sodium,
    String? unit,
  }) {
    return NutritionInfo(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbohydrates: carbohydrates ?? this.carbohydrates,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      unit: unit ?? this.unit,
    );
  }

  /// 轉換為 Map (用於序列化)
  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'unit': unit,
    };
  }

  /// 從 Map 創建 (用於反序列化)
  factory NutritionInfo.fromMap(Map<String, dynamic> map) {
    return NutritionInfo(
      calories: (map['calories'] ?? 0.0).toDouble(),
      protein: (map['protein'] ?? 0.0).toDouble(),
      carbohydrates: (map['carbohydrates'] ?? 0.0).toDouble(),
      fat: (map['fat'] ?? 0.0).toDouble(),
      fiber: (map['fiber'] ?? 0.0).toDouble(),
      sugar: (map['sugar'] ?? 0.0).toDouble(),
      sodium: (map['sodium'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'g',
    );
  }

  /// 空的營養資訊
  static const NutritionInfo empty = NutritionInfo(
    calories: 0.0,
    protein: 0.0,
    carbohydrates: 0.0,
    fat: 0.0,
    fiber: 0.0,
    sugar: 0.0,
    sodium: 0.0,
  );

  @override
  String toString() {
    return 'NutritionInfo(calories: $calories, protein: $protein, carbs: $carbohydrates, fat: $fat)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NutritionInfo &&
           other.calories == calories &&
           other.protein == protein &&
           other.carbohydrates == carbohydrates &&
           other.fat == fat &&
           other.fiber == fiber &&
           other.sugar == sugar &&
           other.sodium == sodium &&
           other.unit == unit;
  }

  @override
  int get hashCode {
    return Object.hash(
      calories,
      protein,
      carbohydrates,
      fat,
      fiber,
      sugar,
      sodium,
      unit,
    );
  }
}