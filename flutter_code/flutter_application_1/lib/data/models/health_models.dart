import 'package:flutter/material.dart';

// 應用程式頁面枚舉 - 定義應用程式中所有可導航的頁面
enum AppPage {
  home, // 首頁
  foodDiary, // 飲食記錄頁面
  exercise, // 運動頁面
  analysis, // 身體分析頁面
}

// 身體指標數據模型 - 存儲用戶的各種健康指標數據和變化率
class BodyMetrics {
  final int sleepHours; // 睡眠時長（小時）
  final double sleepChange; // 睡眠時長變化百分比（正值表示增加，負值表示減少）
  final int height; // 身高（公分）
  final double heightChange; // 身高變化百分比（通常為 0，成人身高不會變化）
  final int weight; // 體重（公斤）
  final double weightChange; // 體重變化百分比（正值表示增加，負值表示減少）
  final int heartRate; // 心率（次/分鐘）
  final double heartRateChange; // 心率變化百分比（正值表示增加，負值表示減少）
  final String bloodPressure; // 血壓（格式：縮張壓/舟張壓，如 "120/80"）
  final double bloodPressureChange; // 血壓變化百分比（正值表示增加，負值表示減少）

  // 構造函數 - 初始化所有身體指標數據，所有參數都是必需的
  BodyMetrics({
    required this.sleepHours, // 必填：睡眠時長
    required this.sleepChange, // 必填：睡眠變化率
    required this.height, // 必填：身高
    required this.heightChange, // 必填：身高變化率
    required this.weight, // 必填：體重
    required this.weightChange, // 必填：體重變化率
    required this.heartRate, // 必填：心率
    required this.heartRateChange, // 必填：心率變化率
    required this.bloodPressure, // 必填：血壓
    required this.bloodPressureChange, // 必填：血壓變化率
  });
}

// 飲食記錄數據模型 - 存儲單一飲食項目的詳細資訊
class FoodEntry {
  final String name; // 食物英文名稱
  final String chineseName; // 食物中文名稱
  final String mealType; // 餐點類型（如：早餐、午餐、晚餐、點心）
  final int calories; // 熱量（大卡/kcal）
  final List<String> imageUrls; // 食物圖片 URL 列表，支援多張圖片展示
  final String servingInfo; // 份量資訊（如："150g"、"1杯"、"1份"）

  // 構造函數 - 初始化飲食記錄的所有屬性，所有參數都是必需的
  FoodEntry({
    required this.name, // 必填：食物英文名稱
    required this.chineseName, // 必填：食物中文名稱
    required this.mealType, // 必填：餐點類型
    required this.calories, // 必填：熱量值
    required this.imageUrls, // 必填：圖片 URL 列表（可為空列表）
    required this.servingInfo, // 必填：份量資訊
  });
}

// 營養素數據模型 - 存儲單一營養素的名稱、百分比和顯示顏色
class NutrientData {
  final String name; // 營養素名稱（如：蛋白質、碳水化合物、脂肪等）
  final double percentage; // 營養素所佔的百分比（0.0-100.0）
  final Color color; // 在圖表中顯示的顏色

  // 構造函數 - 使用位置參數的簡潔形式初始化營養素數據
  NutrientData(this.name, this.percentage, this.color);
}

// 營養資訊數據模型 - 存儲食物的詳細營養成分資訊
class NutritionInfo {
  final int calories; // 熱量（大卡）
  final int protein; // 蛋白質（克）
  final int carbohydrates; // 碳水化合物（克）
  final int fat; // 脂肪（克）
  final int fiber; // 纖維（克）
  final int sugar; // 糖分（克）
  final int sodium; // 鈉（毫克）
  final int cholesterol; // 膽固醇（毫克）
  final int vitaminA; // 維生素A（國際單位IU）
  final int vitaminC; // 維生素C（毫克）
  final int calcium; // 鈣（毫克）
  final int iron; // 鐵（毫克）

  // 構造函數 - 初始化所有營養成分數據，所有參數都是必需的
  NutritionInfo({
    required this.calories, // 必填：熱量
    required this.protein, // 必填：蛋白質
    required this.carbohydrates, // 必填：碳水化合物
    required this.fat, // 必填：脂肪
    required this.fiber, // 必填：纖維
    required this.sugar, // 必填：糖分
    required this.sodium, // 必填：鈉
    required this.cholesterol, // 必填：膽固醇
    required this.vitaminA, // 必填：維生素A
    required this.vitaminC, // 必填：維生素C
    required this.calcium, // 必填：鈣
    required this.iron, // 必填：鐵
  });
}