import '../../domain/entities/nutrition_analysis.dart';

/// 營養分析 API 數據源介面
abstract class NutritionApiDatasource {
  /// 分析圖片中的食物營養成分
  Future<NutritionAnalysis> analyzeImage(String imagePath);

  /// 獲取食物的詳細營養信息
  Future<NutritionInfo?> getFoodNutritionInfo(String foodName);

  /// 檢查營養分析服務是否可用
  Future<bool> isServiceAvailable();
}