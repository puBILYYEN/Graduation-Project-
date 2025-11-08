import 'package:flutter/material.dart';
import '../../domain/entities/exercise_record.dart';
import '../../domain/entities/exercise_goal.dart';
import '../../domain/repositories/exercise_repository.dart';

class ExerciseViewModel extends ChangeNotifier {
  final ExerciseRepository _repository;

  ExerciseViewModel(this._repository);

  // 運動記錄
  List<ExerciseRecord> _exerciseRecords = [];
  List<ExerciseRecord> get exerciseRecords => _exerciseRecords;

  // 運動目標
  List<ExerciseGoal> _exerciseGoals = [];
  List<ExerciseGoal> get exerciseGoals => _exerciseGoals;

  // 每週統計數據
  List<double> _weeklyData = [];
  List<double> get weeklyData => _weeklyData;

  // 載入狀態
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 錯誤訊息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 初始化（載入所有數據）
  Future<void> initialize() async {
    await Future.wait([
      loadExerciseRecords(),
      loadExerciseGoals(),
      loadWeeklyStats(),
    ]);
  }

  /// 載入運動記錄（最近7天）
  Future<void> loadExerciseRecords() async {
    try {
      _setLoading(true);
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 7));

      _exerciseRecords = await _repository.getExerciseRecords(startDate, now);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = '載入運動記錄失敗: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// 載入運動目標
  Future<void> loadExerciseGoals() async {
    try {
      _exerciseGoals = await _repository.getExerciseGoals();

      // 計算當前進度（基於最近的記錄）
      await _updateGoalsProgress();

      notifyListeners();
    } catch (e) {
      print('載入運動目標錯誤: $e');
    }
  }

  /// 載入每週統計（最近4週）
  Future<void> loadWeeklyStats() async {
    try {
      _weeklyData = await _repository.getWeeklyStats(4);
      notifyListeners();
    } catch (e) {
      print('載入每週統計錯誤: $e');
    }
  }

  /// 新增運動記錄
  Future<void> addExerciseRecord({
    required String type,
    required int duration,
    String? notes,
    int? calories,
  }) async {
    try {
      _setLoading(true);

      final record = ExerciseRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        duration: duration,
        date: DateTime.now(),
        notes: notes,
        calories: calories,
      );

      await _repository.addExerciseRecord(record);

      // 重新載入數據
      await Future.wait([
        loadExerciseRecords(),
        loadExerciseGoals(),
        loadWeeklyStats(),
      ]);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = '新增運動記錄失敗: $e';
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 刪除運動記錄
  Future<void> deleteExerciseRecord(String recordId) async {
    try {
      _setLoading(true);
      await _repository.deleteExerciseRecord(recordId);

      // 重新載入數據
      await Future.wait([
        loadExerciseRecords(),
        loadExerciseGoals(),
        loadWeeklyStats(),
      ]);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = '刪除運動記錄失敗: $e';
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新目標進度
  Future<void> _updateGoalsProgress() async {
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));

    final weekRecords = await _repository.getExerciseRecords(weekStart, now);

    for (var goal in _exerciseGoals) {
      double current = 0;

      if (goal.type == 'aerobic') {
        // 有氧運動：計算總分鐘數
        current = weekRecords
            .where((r) => ['跑步', '游泳', '騎車'].contains(r.type))
            .fold<double>(0, (sum, r) => sum + r.duration);
      } else if (goal.type == 'strength') {
        // 肌力訓練：計算天數
        final strengthDays = weekRecords
            .where((r) => ['重訓', '瑜珈'].contains(r.type))
            .map((r) => '${r.date.year}-${r.date.month}-${r.date.day}')
            .toSet()
            .length;
        current = strengthDays.toDouble();
      }

      // 更新目標的當前進度
      final updatedGoal = goal.copyWith(current: current);
      final index = _exerciseGoals.indexOf(goal);
      if (index != -1) {
        _exerciseGoals[index] = updatedGoal;
      }

      // 同步到 Firebase
      await _repository.updateExerciseGoal(updatedGoal);
    }
  }

  /// 獲取本週總運動時間（小時）
  double get weeklyTotalHours {
    if (_weeklyData.isEmpty) return 0;
    return _weeklyData.last;
  }

  /// 獲取有氧運動目標
  ExerciseGoal? get aerobicGoal {
    return _exerciseGoals.firstWhere(
      (g) => g.type == 'aerobic',
      orElse: () => ExerciseGoal(
        id: 'aerobic',
        type: 'aerobic',
        current: 0,
        target: 200,
        unit: '分鐘',
      ),
    );
  }

  /// 獲取肌力訓練目標
  ExerciseGoal? get strengthGoal {
    return _exerciseGoals.firstWhere(
      (g) => g.type == 'strength',
      orElse: () => ExerciseGoal(
        id: 'strength',
        type: 'strength',
        current: 0,
        target: 2,
        unit: '天',
      ),
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// 刷新所有數據
  Future<void> refresh() async {
    await initialize();
  }
}
