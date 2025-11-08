import 'package:flutter/material.dart';

extension ColorWithValues on Color {
  Color withValues({double? red, double? green, double? blue, double? alpha}) {
    return Color.fromARGB(
      (alpha ?? opacity) * 255 ~/ 1,
      (red ?? this.red),
      (green ?? this.green),
      (blue ?? this.blue),
    );
  }
}