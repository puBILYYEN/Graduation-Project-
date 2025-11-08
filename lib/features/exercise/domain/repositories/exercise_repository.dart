import '../entities/exercise_record.dart';
import '../entities/exercise_goal.dart';

/// 運動資料 Repository 介面
abstract class ExerciseRepository {
  /// 獲取運動記錄（指定日期範圍）
  Future<List<ExerciseRecord>> getExerciseRecords(DateTime startDate, DateTime endDate);

  /// 新增運動記錄
  Future<void> addExerciseRecord(ExerciseRecord record);

  /// 刪除運動記錄
  Future<void> deleteExerciseRecord(String recordId);

  /// 獲取運動目標
  Future<List<ExerciseGoal>> getExerciseGoals();

  /// 更新運動目標
  Future<void> updateExerciseGoal(ExerciseGoal goal);

  /// 獲取每週統計數據（最近 N 週）
  Future<List<double>> getWeeklyStats(int weeks);
}
