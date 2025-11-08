/// 運動記錄實體
class ExerciseRecord {
  final String id;
  final String type; // 運動類型（跑步、游泳等）
  final int duration; // 時長（分鐘）
  final DateTime date;
  final String? notes; // 備註
  final int? calories; // 消耗卡路里（可選）

  ExerciseRecord({
    required this.id,
    required this.type,
    required this.duration,
    required this.date,
    this.notes,
    this.calories,
  });

  /// 從 JSON 創建
  factory ExerciseRecord.fromJson(Map<String, dynamic> json) {
    return ExerciseRecord(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      duration: json['duration'] ?? 0,
      date: DateTime.parse(json['date']),
      notes: json['notes'],
      calories: json['calories'],
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'duration': duration,
      'date': date.toIso8601String(),
      'notes': notes,
      'calories': calories,
    };
  }
}
