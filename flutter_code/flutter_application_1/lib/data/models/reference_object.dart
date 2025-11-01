// ====================================================================
// 參考物件資料模型 - Reference Object
// ====================================================================

/// 參考物件類別
class ReferenceObject {
  final String name;
  final double width;
  final double height;
  final String type;
  final String? description;
  final String? imagePath;

  const ReferenceObject({
    required this.name,
    required this.width,
    required this.height,
    required this.type,
    this.description,
    this.imagePath,
  });

  /// 創建參考物件副本
  ReferenceObject copyWith({
    String? name,
    double? width,
    double? height,
    String? type,
    String? description,
    String? imagePath,
  }) {
    return ReferenceObject(
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      type: type ?? this.type,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  /// 轉換為 Map (用於序列化)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'width': width,
      'height': height,
      'type': type,
      'description': description,
      'imagePath': imagePath,
    };
  }

  /// 從 Map 創建 (用於反序列化)
  factory ReferenceObject.fromMap(Map<String, dynamic> map) {
    return ReferenceObject(
      name: map['name'] ?? '',
      width: (map['width'] ?? 0.0).toDouble(),
      height: (map['height'] ?? 0.0).toDouble(),
      type: map['type'] ?? '',
      description: map['description'],
      imagePath: map['imagePath'],
    );
  }

  @override
  String toString() {
    return 'ReferenceObject(name: $name, width: $width, height: $height, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReferenceObject &&
           other.name == name &&
           other.width == width &&
           other.height == height &&
           other.type == type;
  }

  @override
  int get hashCode => Object.hash(name, width, height, type);
}

/// 參考物件資料庫
class ReferenceObjectDatabase {
  /// 硬幣類參考物件
  static final Map<String, ReferenceObject> coins = {
    'NT_50': ReferenceObject(
      name: '50元硬幣',
      width: 2.8,
      height: 2.8,
      type: 'coin',
      description: '新台幣50元硬幣，直徑28mm',
    ),
    'NT_10': ReferenceObject(
      name: '10元硬幣',
      width: 2.6,
      height: 2.6,
      type: 'coin',
      description: '新台幣10元硬幣，直徑26mm',
    ),
    'NT_5': ReferenceObject(
      name: '5元硬幣',
      width: 2.2,
      height: 2.2,
      type: 'coin',
      description: '新台幣5元硬幣，直徑22mm',
    ),
    'NT_1': ReferenceObject(
      name: '1元硬幣',
      width: 2.0,
      height: 2.0,
      type: 'coin',
      description: '新台幣1元硬幣，直徑20mm',
    ),
  };

  /// 日常物品類參考物件
  static final Map<String, ReferenceObject> commonObjects = {
    'credit_card': ReferenceObject(
      name: '信用卡',
      width: 8.56,
      height: 5.398,
      type: 'card',
      description: '標準信用卡尺寸',
    ),
    'a4_paper': ReferenceObject(
      name: 'A4紙',
      width: 21.0,
      height: 29.7,
      type: 'paper',
      description: 'A4規格紙張',
    ),
    'business_card': ReferenceObject(
      name: '名片',
      width: 9.0,
      height: 5.4,
      type: 'card',
      description: '標準名片尺寸',
    ),
  };

  /// 獲取所有參考物件
  static List<ReferenceObject> getAllReferenceObjects() {
    final List<ReferenceObject> allObjects = [];
    allObjects.addAll(coins.values);
    allObjects.addAll(commonObjects.values);
    return allObjects;
  }

  /// 根據類型獲取參考物件
  static List<ReferenceObject> getReferenceObjectsByType(String type) {
    return getAllReferenceObjects()
        .where((obj) => obj.type == type)
        .toList();
  }

  /// 根據名稱搜尋參考物件
  static ReferenceObject? findByName(String name) {
    try {
      return getAllReferenceObjects()
          .firstWhere((obj) => obj.name == name);
    } catch (e) {
      return null;
    }
  }

  /// 獲取所有可用的類型
  static List<String> getAvailableTypes() {
    return getAllReferenceObjects()
        .map((obj) => obj.type)
        .toSet()
        .toList();
  }
}