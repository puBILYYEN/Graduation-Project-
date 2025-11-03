/// 測量結果實體 - 代表測量操作的核心業務物件
class MeasurementResult {
  final String id;
  final MeasurementType type;
  final double value;
  final String unit;
  final List<MeasurementPoint> points;
  final double scale;
  final DateTime measuredAt;
  final MeasurementMetadata metadata;

  const MeasurementResult({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.points,
    required this.scale,
    required this.measuredAt,
    required this.metadata,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementResult &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// 獲取測量結果的描述
  String get description {
    switch (type) {
      case MeasurementType.length:
        return '長度: ${value.toStringAsFixed(2)} $unit';
      case MeasurementType.area:
        return '面積: ${value.toStringAsFixed(2)} $unit²';
      case MeasurementType.volume:
        return '體積: ${value.toStringAsFixed(2)} $unit³';
      case MeasurementType.calibration:
        return '校準比例: ${scale.toStringAsFixed(4)} px/$unit';
    }
  }
}

/// 測量類型枚舉
enum MeasurementType {
  calibration('校準'),
  length('長度'),
  area('面積'),
  volume('體積');

  const MeasurementType(this.displayName);
  final String displayName;
}

/// 測量點實體
class MeasurementPoint {
  final double x;
  final double y;
  final int index;
  final DateTime timestamp;

  const MeasurementPoint({
    required this.x,
    required this.y,
    required this.index,
    required this.timestamp,
  });

  /// 創建測量點
  factory MeasurementPoint.create({
    required double x,
    required double y,
    required int index,
  }) {
    return MeasurementPoint(
      x: x,
      y: y,
      index: index,
      timestamp: DateTime.now(),
    );
  }
}

/// 測量元數據實體
class MeasurementMetadata {
  final String deviceModel;
  final String appVersion;
  final double processingTime;
  final Map<String, dynamic> settings;
  final ReferenceObject? referenceObject;

  const MeasurementMetadata({
    required this.deviceModel,
    required this.appVersion,
    required this.processingTime,
    required this.settings,
    this.referenceObject,
  });
}

/// 參考物體實體
class ReferenceObject {
  final ReferenceObjectType type;
  final String name;
  final double width;
  final double height;
  final String unit;

  const ReferenceObject({
    required this.type,
    required this.name,
    required this.width,
    required this.height,
    this.unit = 'cm',
  });
}

/// 參考物體類型枚舉
enum ReferenceObjectType {
  coin('硬幣'),
  card('卡片'),
  utensil('餐具'),
  custom('自定義');

  const ReferenceObjectType(this.displayName);
  final String displayName;
}