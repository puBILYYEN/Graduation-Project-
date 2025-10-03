import 'package:flutter/material.dart';

enum MeasurementMethod { automatic, manual, referenceObject }

enum MeasurementMode { calibration, length, area, volume }

class MeasurementPoint {
  final Offset position;
  final String? label;

  const MeasurementPoint({required this.position, this.label});
}

class MeasurementResult {
  final String description;
  final double value;
  final String unit;

  const MeasurementResult({
    required this.description,
    required this.value,
    required this.unit,
  });
}
