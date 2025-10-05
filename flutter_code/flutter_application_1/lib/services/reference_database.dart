// ====================================================================
// 參考物體數據庫服務模組
// ====================================================================

import '../models/container_analysis.dart';

/// 參考物體數據庫
class ReferenceObjectDatabase {
  // 常見硬幣尺寸 (台灣)
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

  // 常見卡片尺寸
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

  // 常見餐具尺寸
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

  /// 取得所有參考物體
  static List<ReferenceObject> getAllObjects() {
    // 取得所有參考物體的靜態方法：將所有類別的參考物體合併為單一列表
    // 返回值：List<ReferenceObject> 包含硬幣、卡片、餐具等所有參考物體的完整列表
    return [
      ...coins.values,    // 展開硬幣映射表中的所有值，將硬幣物件加入列表
      ...cards.values,    // 展開卡片映射表中的所有值，將卡片物件加入列表
      ...utensils.values, // 展開餐具映射表中的所有值，將餐具物件加入列表
    ];
  }

  /// 根據類型取得參考物體
  static List<ReferenceObject> getObjectsByType(ReferenceObjectType type) {
    // 根據指定類型篩選參考物體的靜態方法：從資料庫中取得特定類別的物體
    // 參數type：ReferenceObjectType枚舉，指定要篩選的物體類型
    // 返回值：List<ReferenceObject> 符合指定類型的參考物體列表
    switch (type) { // 使用switch語句根據類型進行分流處理
      case ReferenceObjectType.coin:    // 當類型為硬幣時
        return coins.values.toList();   // 將硬幣映射表的所有值轉換為列表並返回
      case ReferenceObjectType.card:    // 當類型為卡片時
        return cards.values.toList();   // 將卡片映射表的所有值轉換為列表並返回
      case ReferenceObjectType.utensil: // 當類型為餐具時
        return utensils.values.toList(); // 將餐具映射表的所有值轉換為列表並返回
      case ReferenceObjectType.custom:  // 當類型為自定義時
        return [];                      // 返回空列表，表示目前無自定義參考物體
    }
  }
}
