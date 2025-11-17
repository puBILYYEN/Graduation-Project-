class FoodEntry {
  final String name;
  final String chineseName;
  final String mealType;
  final int calories;
  final List<String> imageUrls;
  final String servingInfo;

  // 擴展：完整營養數據（從 YOLO + RAG 獲取）
  final NutritionDetails? nutritionDetails;

  // 擴展：AI 分析結果
  final String? geminiReply;
  final String? dietAdvice;

  // 擴展：時間戳記
  final DateTime? timestamp;

  // 擴展：YOLO 預測結果
  final List<YoloPrediction>? predictions;

  FoodEntry({
    required this.name,
    required this.chineseName,
    required this.mealType,
    required this.calories,
    required this.imageUrls,
    required this.servingInfo,
    this.nutritionDetails,
    this.geminiReply,
    this.dietAdvice,
    this.timestamp,
    this.predictions,
  });

  /// 從 JSON 創建實例（用於 Firebase 反序列化）
  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      name: json['name'] ?? '',
      chineseName: json['chineseName'] ?? json['name'] ?? '',
      mealType: json['mealType'] ?? '其他',
      calories: json['calories'] ?? 0,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      servingInfo: json['servingInfo'] ?? '未知',
      nutritionDetails: json['nutritionDetails'] != null
          ? NutritionDetails.fromJson(json['nutritionDetails'])
          : null,
      geminiReply: json['geminiReply'],
      dietAdvice: json['dietAdvice'],
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : null,
      predictions: json['predictions'] != null
          ? (json['predictions'] as List)
              .map((p) => YoloPrediction.fromJson(p))
              .toList()
          : null,
    );
  }

  /// 轉換為 JSON（用於 Firebase 序列化）
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'chineseName': chineseName,
      'mealType': mealType,
      'calories': calories,
      'imageUrls': imageUrls,
      'servingInfo': servingInfo,
      'nutritionDetails': nutritionDetails?.toJson(),
      'geminiReply': geminiReply,
      'dietAdvice': dietAdvice,
      'timestamp': timestamp?.millisecondsSinceEpoch,
      'predictions': predictions?.map((p) => p.toJson()).toList(),
    };
  }
}

/// 營養詳細資料（蛋白質、碳水、脂肪等完整資訊）
class NutritionDetails {
  final double protein;         // 蛋白質 (g)
  final double carbohydrates;   // 碳水化合物 (g)
  final double fat;             // 脂肪 (g)
  final double fiber;           // 膳食纖維 (g)
  final double sugar;           // 糖 (g)
  final double sodium;          // 鈉 (mg)
  final double saturatedFat;    // 飽和脂肪 (g)
  final double cholesterol;     // 膽固醇 (mg)
  final double calcium;         // 鈣 (mg)
  final double iron;            // 鐵 (mg)
  final double vitaminA;        // 維生素A (IU)
  final double vitaminC;        // 維生素C (mg)
  final double potassium;       // 鉀 (mg)

  NutritionDetails({
    this.protein = 0,
    this.carbohydrates = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.saturatedFat = 0,
    this.cholesterol = 0,
    this.calcium = 0,
    this.iron = 0,
    this.vitaminA = 0,
    this.vitaminC = 0,
    this.potassium = 0,
  });

  factory NutritionDetails.fromJson(Map<String, dynamic> json) {
    return NutritionDetails(
      protein: (json['protein'] ?? 0).toDouble(),
      carbohydrates: (json['carbohydrates'] ?? json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      sugar: (json['sugar'] ?? 0).toDouble(),
      sodium: (json['sodium'] ?? 0).toDouble(),
      saturatedFat: (json['saturatedFat'] ?? json['saturated_fat'] ?? 0).toDouble(),
      cholesterol: (json['cholesterol'] ?? 0).toDouble(),
      calcium: (json['calcium'] ?? 0).toDouble(),
      iron: (json['iron'] ?? 0).toDouble(),
      vitaminA: (json['vitaminA'] ?? json['vitamin_a'] ?? 0).toDouble(),
      vitaminC: (json['vitaminC'] ?? json['vitamin_c'] ?? 0).toDouble(),
      potassium: (json['potassium'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'saturatedFat': saturatedFat,
      'cholesterol': cholesterol,
      'calcium': calcium,
      'iron': iron,
      'vitaminA': vitaminA,
      'vitaminC': vitaminC,
      'potassium': potassium,
    };
  }

  /// 計算總卡路里（根據三大營養素）
  double get totalCalories {
    return (protein * 4) + (carbohydrates * 4) + (fat * 9);
  }
}

/// YOLO 預測結果
class YoloPrediction {
  final int classId;
  final String className;
  final double confidence;

  YoloPrediction({
    required this.classId,
    required this.className,
    required this.confidence,
  });

  factory YoloPrediction.fromJson(Map<String, dynamic> json) {
    return YoloPrediction(
      classId: json['class_id'] ?? json['classId'] ?? 0,
      className: json['class_name'] ?? json['className'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'class_name': className,
      'confidence': confidence,
    };
  }
}
