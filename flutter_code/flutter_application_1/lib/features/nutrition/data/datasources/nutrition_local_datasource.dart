import '../../domain/entities/nutrition_analysis.dart';

/// 營養分析本地數據源介面
abstract class NutritionLocalDatasource {
  /// 保存營養分析結果到本地
  Future<bool> saveAnalysisResult(NutritionAnalysis analysis);

  /// 獲取本地保存的營養分析歷史記錄
  Future<List<NutritionAnalysis>> getAnalysisHistory({int limit = 20});

  /// 刪除本地的營養分析記錄
  Future<bool> deleteAnalysisResult(String analysisId);

  /// 從本地緩存獲取食物營養信息
  Future<NutritionInfo?> getFoodNutritionInfo(String foodName);

  /// 緩存食物營養信息到本地
  Future<bool> cacheFoodNutritionInfo(String foodName, NutritionInfo nutritionInfo);
}