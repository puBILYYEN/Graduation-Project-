import '../entities/nutrition_analysis.dart';

/// 營養分析 Repository 介面 - 定義營養分析的資料操作契約
abstract class NutritionRepository {
  /// 分析圖片中的食物營養成分
  ///
  /// [imagePath] 要分析的圖片路徑
  /// 返回營養分析結果，失敗時拋出異常
  Future<NutritionAnalysis> analyzeImage(String imagePath);

  /// 獲取食物的詳細營養信息
  ///
  /// [foodName] 食物名稱
  /// 返回食物的營養信息，找不到時返回 null
  Future<NutritionInfo?> getFoodNutritionInfo(String foodName);

  /// 保存營養分析結果
  ///
  /// [analysis] 要保存的營養分析結果
  /// 返回保存是否成功
  Future<bool> saveAnalysisResult(NutritionAnalysis analysis);

  /// 獲取歷史營養分析記錄
  ///
  /// [limit] 限制返回的記錄數量
  /// 返回營養分析歷史記錄列表
  Future<List<NutritionAnalysis>> getAnalysisHistory({int limit = 20});

  /// 刪除營養分析記錄
  ///
  /// [analysisId] 要刪除的分析記錄ID
  /// 返回刪除是否成功
  Future<bool> deleteAnalysisResult(String analysisId);

  /// 檢查營養分析服務是否可用
  ///
  /// 返回服務是否正常運行
  Future<bool> isServiceAvailable();
}