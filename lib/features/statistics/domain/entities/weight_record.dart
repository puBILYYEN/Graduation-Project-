/// 體重記錄
class WeightRecord {
  final DateTime date;
  final double weight;
  final double? bmi;

  const WeightRecord({
    required this.date,
    required this.weight,
    this.bmi,
  });

  factory WeightRecord.fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      date: DateTime.parse(map['date'] as String),
      weight: (map['weight'] as num).toDouble(),
      bmi: map['bmi'] != null ? (map['bmi'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'weight': weight,
      'bmi': bmi,
    };
  }
}
