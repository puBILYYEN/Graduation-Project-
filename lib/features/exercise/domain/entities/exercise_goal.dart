/// 運動目標實體
class ExerciseGoal {
  final String id;
  final String type; // 目標類型（aerobic: 有氧, strength: 肌力）
  final double current; // 當前進度
  final double target; // 目標值
  final String unit; // 單位（分鐘、天等）

  ExerciseGoal({
    required this.id,
    required this.type,
    required this.current,
    required this.target,
    required this.unit,
  });

  /// 進度百分比
  double get progress => current / target;

  /// 是否達標
  bool get isAchieved => current >= target;

  /// 從 JSON 創建
  factory ExerciseGoal.fromJson(Map<String, dynamic> json) {
    return ExerciseGoal(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      current: (json['current'] ?? 0).toDouble(),
      target: (json['target'] ?? 1).toDouble(),
      unit: json['unit'] ?? '分鐘',
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'current': current,
      'target': target,
      'unit': unit,
    };
  }

  /// 更新進度
  ExerciseGoal copyWith({
    String? id,
    String? type,
    double? current,
    double? target,
    String? unit,
  }) {
    return ExerciseGoal(
      id: id ?? this.id,
      type: type ?? this.type,
      current: current ?? this.current,
      target: target ?? this.target,
      unit: unit ?? this.unit,
    );
  }
}
