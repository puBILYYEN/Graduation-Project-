// AK47 風格精簡版：核心數據模型
import 'package:flutter/material.dart';

// 身體指標 - 簡潔版
class BodyMetrics {
  final int sleep, height, weight, heartRate;
  final double sleepChange, heightChange, weightChange, heartRateChange;
  final String bloodPressure;
  final double bloodPressureChange;

  const BodyMetrics({
    required this.sleep, required this.sleepChange,
    required this.height, required this.heightChange,
    required this.weight, required this.weightChange,
    required this.heartRate, required this.heartRateChange,
    required this.bloodPressure, required this.bloodPressureChange,
  });
}

// 食物記錄 - 簡潔版
class FoodEntry {
  final String name, cnName, meal, serving;
  final int calories;
  final List<String> images;

  const FoodEntry({
    required this.name, required this.cnName, required this.meal,
    required this.calories, required this.images, required this.serving,
  });
}

// 營養素數據 - 簡潔版
class NutrientData {
  final String name;
  final double percentage;
  final Color color;

  const NutrientData(this.name, this.percentage, this.color);
}

// 頁面枚舉 - 簡化導航
enum AppPage { home, food, camera, exercise, analysis }

// 設備方向 - 簡化枚舉
enum DeviceOrientation { up, down, left, right }