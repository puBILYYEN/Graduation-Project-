// 測試所有模組的 import
import 'lib/widgets/custom_painters.dart';
import 'package:flutter_application_1/core/services/image_processing/image_processing.dart';
import 'lib/models/container_analysis.dart';
import 'package:flutter_application_1/core/services/logging/log_manager.dart';
import 'package:flutter_application_1/features/measurement/services/measurement_calculator.dart';
import 'package:flutter_application_1/features/measurement/data/reference_database.dart';

void main() {
  // 測試 custom_painters
  final painter = EdgeDetectionPainter([]);

  // 測試 image_processing
  final config = EdgeDetectionConfig();

  // 測試 container_analysis - 需要提供必要參數
  final analysis = ContainerAnalysisData(
    imagePath: 'test.jpg',
    timestamp: '2024-01-01',
    container: ContainerInfo(
      shape: 'circle',
      material: 'plastic',
      color: 'blue',
      features: ['smooth', 'round'],
    ),
    measurements: MeasurementResults(
      volume: 100.0,
      confidence: 0.9,
      method: 'canny',
      dimensions: {'radius': 5.0},
    ),
    metadata: AnalysisMetadata(
      deviceModel: 'Test Device',
      appVersion: '1.0.0',
      processingTime: 1.0,
      settings: {'resolution': '1080p'},
    ),
  );

  // 測試服務 - LogManager 是單例
  final logManager = LogManager.instance;
  final calculator = MeasurementCalculator();

  // ReferenceDatabase 實際上是 ReferenceObjectDatabase
  final database = ReferenceObjectDatabase.coins['NT_50'];

  // 簡單使用變量避免 unused 警告
  if (painter.runtimeType != Null &&
      config.runtimeType != Null &&
      analysis.runtimeType != Null &&
      logManager.runtimeType != Null &&
      calculator.runtimeType != Null &&
      database.runtimeType != Null) {
    // 所有模組都能正常 import！
  }
}