// ====================================================================
// 營養和健康相關資料模型 (Nutrition & Health Data Models)
// ====================================================================
// 這個檔案包含身體指標、飲食記錄等健康相關的資料結構

import 'package:flutter/material.dart';

// 身體指標資料模型 - 存放使用者的各種健康數據和變化情形
class BodyMetrics {
  final int sleepHours; // 睡眠時間(小時)
  final double sleepChange; // 睡眠時間變化百分比(正數表示增加，負數表示減少)
  final int height; // 身高(公分)
  final double heightChange; // 身高變化百分比(通常是0，因為成人身高不會變)
  final int weight; // 體重(公斤)
  final double weightChange; // 體重變化百分比(正數表示增加，負數表示減少)
  final int heartRate; // 心跳(次/分鐘)
  final double heartRateChange; // 心跳變化百分比(正數表示增加，負數表示減少)
  final String bloodPressure; // 血壓(格式:收縮壓/舒張壓，例如"120/80")
  final double bloodPressureChange; // 血壓變化百分比(正數表示增加，負數表示減少)

  // 建構函數 - 設定所有身體指標數據(所有參數都必須填寫)
  BodyMetrics({
    required this.sleepHours, // 必填:睡眠時間
    required this.sleepChange, // 必填:睡眠變化率
    required this.height, // 必填:身高
    required this.heightChange, // 必填:身高變化率
    required this.weight, // 必填:體重
    required this.weightChange, // 必填:體重變化率
    required this.heartRate, // 必填:心跳
    required this.heartRateChange, // 必填:心跳變化率
    required this.bloodPressure, // 必填:血壓
    required this.bloodPressureChange, // 必填:血壓變化率
  });
}

// 飲食記錄資料模型 - 存放單一食物項目的詳細資訊
class FoodEntry {
  final String name; // 食物英文名稱
  final String chineseName; // 食物中文名稱
  final String mealType; // 餐點類型(例如:早餐、午餐、晚餐、點心)
  final int calories; // 熱量(單位:大卡)
  final List<String> imageUrls; // 食物圖片網址列表(可以放多張圖片)
  final String servingInfo; // 份量資訊(例如:"150g"、"1杯"、"1份")

  // 建構函數 - 設定飲食記錄的所有屬性(所有參數都必須填寫)
  FoodEntry({
    required this.name, // 必填:食物英文名稱
    required this.chineseName, // 必填:食物中文名稱
    required this.mealType, // 必填:餐點類型
    required this.calories, // 必填:熱量值
    required this.imageUrls, // 必填:圖片網址列表(可以是空的列表)
    required this.servingInfo, // 必填:份量資訊
  });
}

// 營養素資料模型 - 存放單一營養素的名稱、百分比和顯示顏色
class NutrientData {
  final String name; // 營養素名稱(例如:蛋白質、碳水化合物、脂肪等)
  final double percentage; // 營養素所佔的百分比(0.0到100.0)
  final Color color; // 在圖表中顯示的顏色

  // 建構函數 - 用簡潔的方式設定營養素資料
  NutrientData(this.name, this.percentage, this.color);
}