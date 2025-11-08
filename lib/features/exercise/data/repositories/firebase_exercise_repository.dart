import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/exercise_record.dart';
import '../../domain/entities/exercise_goal.dart';
import '../../domain/repositories/exercise_repository.dart';

/// Firebase 運動資料 Repository 實作
class FirebaseExerciseRepository implements ExerciseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  @override
  Future<List<ExerciseRecord>> getExerciseRecords(DateTime startDate, DateTime endDate) async {
    if (_userId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('member')
          .doc(_userId)
          .collection('exercise_records')
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ExerciseRecord.fromJson(data);
      }).toList();
    } catch (e) {
      print('獲取運動記錄錯誤: $e');
      return [];
    }
  }

  @override
  Future<void> addExerciseRecord(ExerciseRecord record) async {
    if (_userId == null) throw Exception('用戶未登入');

    try {
      await _firestore
          .collection('member')
          .doc(_userId)
          .collection('exercise_records')
          .add(record.toJson());
    } catch (e) {
      print('新增運動記錄錯誤: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteExerciseRecord(String recordId) async {
    if (_userId == null) throw Exception('用戶未登入');

    try {
      await _firestore
          .collection('member')
          .doc(_userId)
          .collection('exercise_records')
          .doc(recordId)
          .delete();
    } catch (e) {
      print('刪除運動記錄錯誤: $e');
      rethrow;
    }
  }

  @override
  Future<List<ExerciseGoal>> getExerciseGoals() async {
    if (_userId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('member')
          .doc(_userId)
          .collection('exercise_goals')
          .get();

      if (querySnapshot.docs.isEmpty) {
        // 如果沒有目標，返回預設目標
        return _getDefaultGoals();
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ExerciseGoal.fromJson(data);
      }).toList();
    } catch (e) {
      print('獲取運動目標錯誤: $e');
      return _getDefaultGoals();
    }
  }

  @override
  Future<void> updateExerciseGoal(ExerciseGoal goal) async {
    if (_userId == null) throw Exception('用戶未登入');

    try {
      await _firestore
          .collection('member')
          .doc(_userId)
          .collection('exercise_goals')
          .doc(goal.id)
          .set(goal.toJson(), SetOptions(merge: true));
    } catch (e) {
      print('更新運動目標錯誤: $e');
      rethrow;
    }
  }

  @override
  Future<List<double>> getWeeklyStats(int weeks) async {
    if (_userId == null) return List.filled(weeks, 0);

    try {
      final List<double> weeklyData = [];
      final now = DateTime.now();

      for (int i = weeks - 1; i >= 0; i--) {
        final weekStart = now.subtract(Duration(days: 7 * (i + 1)));
        final weekEnd = now.subtract(Duration(days: 7 * i));

        final records = await getExerciseRecords(weekStart, weekEnd);
        final totalHours = records.fold<double>(
          0,
          (sum, record) => sum + (record.duration / 60),
        );

        weeklyData.add(totalHours);
      }

      return weeklyData;
    } catch (e) {
      print('獲取每週統計錯誤: $e');
      return List.filled(weeks, 0);
    }
  }

  /// 預設運動目標
  List<ExerciseGoal> _getDefaultGoals() {
    return [
      ExerciseGoal(
        id: 'aerobic',
        type: 'aerobic',
        current: 0,
        target: 200,
        unit: '分鐘',
      ),
      ExerciseGoal(
        id: 'strength',
        type: 'strength',
        current: 0,
        target: 2,
        unit: '天',
      ),
    ];
  }
}
