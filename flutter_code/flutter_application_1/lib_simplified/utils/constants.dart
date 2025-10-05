// AK47 風格精簡版：常數定義
import 'package:flutter/material.dart';

// 顏色常數 - 極簡配色
class AppColors {
  static const primary = Colors.black87;
  static const secondary = Colors.grey;
  static const background = Colors.white;
  static const error = Colors.red;
  static const success = Colors.green;
  static const warning = Colors.orange;
}

// 文字樣式 - 簡化層級
class AppTextStyles {
  static const title = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static const subtitle = TextStyle(fontSize: 18, fontWeight: FontWeight.w500);
  static const body = TextStyle(fontSize: 16);
  static const caption = TextStyle(fontSize: 14, color: Colors.grey);
}

// 間距常數 - 統一間距
class AppSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
  static const xl = 32.0;
}

// 邊框常數
class AppBorders {
  static final radius = BorderRadius.circular(8);
  static const border = BorderSide(color: Colors.grey, width: 1);
}

// 陰影常數
class AppShadows {
  static final card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
}