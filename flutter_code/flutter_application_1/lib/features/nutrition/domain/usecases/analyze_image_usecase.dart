import '../entities/nutrition_analysis.dart';
import '../repositories/nutrition_repository.dart';

/// 分析圖片營養成分用例
class AnalyzeImageUseCase {
  final NutritionRepository _repository;

  const AnalyzeImageUseCase(this._repository);

  /// 執行圖片營養分析
  ///
  /// [imagePath] 要分析的圖片路徑
  /// 返回營養分析結果
  ///
  /// 業務規則：
  /// 1. 圖片路徑不能為空
  /// 2. 服務必須可用
  /// 3. 分析結果會自動保存
  Future<NutritionAnalysis> call(String imagePath) async {
    if (imagePath.isEmpty) {
      throw Exception('圖片路徑不能為空');
    }

    // 檢查服務是否可用
    final isAvailable = await _repository.isServiceAvailable();
    if (!isAvailable) {
      throw Exception('營養分析服務暫時不可用，請稍後再試');
    }

    try {
      // 執行圖片分析
      final analysis = await _repository.analyzeImage(imagePath);

      // 自動保存分析結果
      await _repository.saveAnalysisResult(analysis);

      return analysis;
    } catch (e) {
      throw Exception('圖片分析失敗: $e');
    }
  }
}