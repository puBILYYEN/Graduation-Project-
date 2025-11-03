import '../../domain/entities/nutrition_analysis.dart';
import '../../domain/repositories/nutrition_repository.dart';
import '../datasources/nutrition_api_datasource.dart';
import '../datasources/nutrition_local_datasource.dart';

/// 營養分析 Repository 實作
class NutritionRepositoryImpl implements NutritionRepository {
  final NutritionApiDatasource _apiDatasource;
  final NutritionLocalDatasource _localDatasource;

  const NutritionRepositoryImpl(
    this._apiDatasource,
    this._localDatasource,
  );

  @override
  Future<NutritionAnalysis> analyzeImage(String imagePath) async {
    try {
      // 使用 API 數據源進行圖片分析
      final analysis = await _apiDatasource.analyzeImage(imagePath);

      // 將結果保存到本地
      await _localDatasource.saveAnalysisResult(analysis);

      return analysis;
    } catch (e) {
      throw Exception('圖片分析失敗: $e');
    }
  }

  @override
  Future<NutritionInfo?> getFoodNutritionInfo(String foodName) async {
    try {
      // 優先從本地數據源查找
      var nutritionInfo = await _localDatasource.getFoodNutritionInfo(foodName);

      // 如果本地沒有，則從 API 獲取
      if (nutritionInfo == null) {
        nutritionInfo = await _apiDatasource.getFoodNutritionInfo(foodName);

        // 將 API 結果緩存到本地
        if (nutritionInfo != null) {
          await _localDatasource.cacheFoodNutritionInfo(foodName, nutritionInfo);
        }
      }

      return nutritionInfo;
    } catch (e) {
      throw Exception('獲取營養信息失敗: $e');
    }
  }

  @override
  Future<bool> saveAnalysisResult(NutritionAnalysis analysis) async {
    try {
      return await _localDatasource.saveAnalysisResult(analysis);
    } catch (e) {
      throw Exception('保存分析結果失敗: $e');
    }
  }

  @override
  Future<List<NutritionAnalysis>> getAnalysisHistory({int limit = 20}) async {
    try {
      return await _localDatasource.getAnalysisHistory(limit: limit);
    } catch (e) {
      throw Exception('獲取分析歷史失敗: $e');
    }
  }

  @override
  Future<bool> deleteAnalysisResult(String analysisId) async {
    try {
      return await _localDatasource.deleteAnalysisResult(analysisId);
    } catch (e) {
      throw Exception('刪除分析結果失敗: $e');
    }
  }

  @override
  Future<bool> isServiceAvailable() async {
    try {
      return await _apiDatasource.isServiceAvailable();
    } catch (e) {
      // 如果 API 不可用，仍可使用本地功能
      return true;
    }
  }
}