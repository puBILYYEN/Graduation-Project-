// ====================================================================
// 容器分析資料模型 - Container Analysis
// ====================================================================

/// 容器分析結果
class ContainerAnalysis {
  final String id;
  final String imagePath;
  final String containerType;
  final double confidence;
  final ContainerDimensions dimensions;
  final DateTime analyzedAt;
  final List<DetectedObject> detectedObjects;

  const ContainerAnalysis({
    required this.id,
    required this.imagePath,
    required this.containerType,
    required this.confidence,
    required this.dimensions,
    required this.analyzedAt,
    required this.detectedObjects,
  });

  /// 創建分析結果副本
  ContainerAnalysis copyWith({
    String? id,
    String? imagePath,
    String? containerType,
    double? confidence,
    ContainerDimensions? dimensions,
    DateTime? analyzedAt,
    List<DetectedObject>? detectedObjects,
  }) {
    return ContainerAnalysis(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      containerType: containerType ?? this.containerType,
      confidence: confidence ?? this.confidence,
      dimensions: dimensions ?? this.dimensions,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      detectedObjects: detectedObjects ?? this.detectedObjects,
    );
  }

  /// 轉換為 Map (用於序列化)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'containerType': containerType,
      'confidence': confidence,
      'dimensions': dimensions.toMap(),
      'analyzedAt': analyzedAt.millisecondsSinceEpoch,
      'detectedObjects': detectedObjects.map((obj) => obj.toMap()).toList(),
    };
  }

  /// 從 Map 創建 (用於反序列化)
  factory ContainerAnalysis.fromMap(Map<String, dynamic> map) {
    return ContainerAnalysis(
      id: map['id'] ?? '',
      imagePath: map['imagePath'] ?? '',
      containerType: map['containerType'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      dimensions: ContainerDimensions.fromMap(map['dimensions'] ?? {}),
      analyzedAt: DateTime.fromMillisecondsSinceEpoch(map['analyzedAt'] ?? 0),
      detectedObjects: (map['detectedObjects'] as List?)?.map((obj) =>
        DetectedObject.fromMap(obj as Map<String, dynamic>)
      ).toList() ?? [],
    );
  }

  @override
  String toString() {
    return 'ContainerAnalysis(id: $id, containerType: $containerType, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContainerAnalysis && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 容器尺寸
class ContainerDimensions {
  final double width;
  final double height;
  final double depth;
  final double volume;
  final String unit;

  const ContainerDimensions({
    required this.width,
    required this.height,
    required this.depth,
    required this.volume,
    required this.unit,
  });

  /// 轉換為 Map
  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
      'depth': depth,
      'volume': volume,
      'unit': unit,
    };
  }

  /// 從 Map 創建
  factory ContainerDimensions.fromMap(Map<String, dynamic> map) {
    return ContainerDimensions(
      width: (map['width'] ?? 0.0).toDouble(),
      height: (map['height'] ?? 0.0).toDouble(),
      depth: (map['depth'] ?? 0.0).toDouble(),
      volume: (map['volume'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'cm',
    );
  }

  @override
  String toString() {
    return 'ContainerDimensions(width: $width, height: $height, depth: $depth, volume: $volume $unit)';
  }
}

/// 檢測到的物件
class DetectedObject {
  final String label;
  final double confidence;
  final BoundingBox boundingBox;

  const DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  /// 轉換為 Map
  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'confidence': confidence,
      'boundingBox': boundingBox.toMap(),
    };
  }

  /// 從 Map 創建
  factory DetectedObject.fromMap(Map<String, dynamic> map) {
    return DetectedObject(
      label: map['label'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      boundingBox: BoundingBox.fromMap(map['boundingBox'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'DetectedObject(label: $label, confidence: $confidence)';
  }
}

/// 邊界框
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// 轉換為 Map
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  /// 從 Map 創建
  factory BoundingBox.fromMap(Map<String, dynamic> map) {
    return BoundingBox(
      x: (map['x'] ?? 0.0).toDouble(),
      y: (map['y'] ?? 0.0).toDouble(),
      width: (map['width'] ?? 0.0).toDouble(),
      height: (map['height'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() {
    return 'BoundingBox(x: $x, y: $y, width: $width, height: $height)';
  }
}