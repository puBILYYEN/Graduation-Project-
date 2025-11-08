// ====================================================================
// 參考物體資料庫服務 (Reference Object Database Service)
// ====================================================================
// 這個檔案提供各種標準物品的尺寸資料，用於測量時的參考

import '../models/measurement.dart';

/// 參考物體資料庫(存放各種物品的標準尺寸，像是硬幣、卡片的大小)
class ReferenceObjectDatabase {
  // 常見硬幣尺寸(台灣的硬幣)
  static const Map<String, ReferenceObject> coins = {
    'NT_50': ReferenceObject(
      type: ReferenceObjectType.coin,
      name: '50元硬幣',
      width: 2.5,
      height: 2.5,
    ),
    'NT_10': ReferenceObject(
      type: ReferenceObjectType.coin,
      name: '10元硬幣',
      width: 2.6,
      height: 2.6,
    ),
    'NT_5': ReferenceObject(
      type: ReferenceObjectType.coin,
      name: '5元硬幣',
      width: 2.2,
      height: 2.2,
    ),
    'NT_1': ReferenceObject(
      type: ReferenceObjectType.coin,
      name: '1元硬幣',
      width: 2.0,
      height: 2.0,
    ),
  };

  // 常見卡片尺寸(信用卡、名片等)
  static const Map<String, ReferenceObject> cards = {
    'CREDIT_CARD': ReferenceObject(
      type: ReferenceObjectType.card,
      name: '信用卡',
      width: 8.56,
      height: 5.398,
    ),
    'BUSINESS_CARD': ReferenceObject(
      type: ReferenceObjectType.card,
      name: '名片',
      width: 9.0,
      height: 5.4,
    ),
  };

  // 常見餐具尺寸(湯匙、筷子等)
  static const Map<String, ReferenceObject> utensils = {
    'SPOON': ReferenceObject(
      type: ReferenceObjectType.utensil,
      name: '湯匙',
      width: 2.0,
      height: 18.0,
    ),
    'FORK': ReferenceObject(
      type: ReferenceObjectType.utensil,
      name: '叉子',
      width: 2.5,
      height: 18.0,
    ),
    'CHOPSTICKS': ReferenceObject(
      type: ReferenceObjectType.utensil,
      name: '筷子',
      width: 0.8,
      height: 23.0,
    ),
  };

  /// 取得所有參考物體(把所有可以用來測量的物品全部列出來)
  static List<ReferenceObject> getAllObjects() {
    return [
      ...coins.values,
      ...cards.values,
      ...utensils.values,
    ];
  }

  /// 根據類型取得參考物體(依照物品種類來篩選，例如只要硬幣或只要卡片)
  static List<ReferenceObject> getObjectsByType(ReferenceObjectType type) {
    switch (type) {
      case ReferenceObjectType.coin:
        return coins.values.toList();
      case ReferenceObjectType.card:
        return cards.values.toList();
      case ReferenceObjectType.utensil:
        return utensils.values.toList();
      case ReferenceObjectType.custom:
        return [];
    }
  }
}
