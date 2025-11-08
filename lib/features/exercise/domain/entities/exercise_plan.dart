/// 運動計劃實體
class ExercisePlan {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final int durationWeeks;
  final List<String> goals; // 訓練目標
  final String detailedPlan; // AI 生成的詳細計劃內容

  ExercisePlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.difficulty,
    required this.durationWeeks,
    required this.goals,
    required this.detailedPlan,
  });

  /// 從 JSON 創建
  factory ExercisePlan.fromJson(Map<String, dynamic> json) {
    return ExercisePlan(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 'beginner',
      durationWeeks: json['durationWeeks'] ?? 4,
      goals: (json['goals'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      detailedPlan: json['detailedPlan'] ?? '',
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'difficulty': difficulty,
      'durationWeeks': durationWeeks,
      'goals': goals,
      'detailedPlan': detailedPlan,
    };
  }

  /// 獲取難度顯示文字
  String get difficultyText {
    switch (difficulty) {
      case 'beginner':
        return '初階';
      case 'intermediate':
        return '中階';
      case 'advanced':
        return '進階';
      default:
        return '初階';
    }
  }

  /// 獲取難度顏色
  int get difficultyColor {
    switch (difficulty) {
      case 'beginner':
        return 0xFF4CAF50; // 綠色
      case 'intermediate':
        return 0xFFFF9800; // 橙色
      case 'advanced':
        return 0xFFF44336; // 紅色
      default:
        return 0xFF4CAF50;
    }
  }
}
