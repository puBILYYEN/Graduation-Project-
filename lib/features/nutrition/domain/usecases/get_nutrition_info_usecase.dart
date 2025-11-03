import '../entities/nutrition_analysis.dart';
import '../repositories/nutrition_repository.dart';

/// 獲取食物營養信息用例
class GetNutritionInfoUseCase {
  final NutritionRepository _repository;

  const GetNutritionInfoUseCase(this._repository);

  /// 執行獲取食物營養信息
  ///
  /// [foodName] 食物名稱
  /// 返回營養信息，找不到時返回 null
  ///
  /// 業務規則：
  /// 1. 食物名稱不能為空
  /// 2. 自動處理中英文名稱
  Future<NutritionInfo?> call(String foodName) async {
    if (foodName.trim().isEmpty) {
      throw Exception('食物名稱不能為空');
    }

    try {
      return await _repository.getFoodNutritionInfo(foodName.trim());
    } catch (e) {
      throw Exception('獲取營養信息失敗: $e');
    }
  }
}