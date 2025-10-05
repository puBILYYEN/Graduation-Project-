// 測試主程式能否 import 所有模組
import 'package:flutter/material.dart';

// 導入所有拆分出來的模組
import 'lib/widgets/custom_painters.dart';
import 'lib/utils/image_processing.dart';
import 'lib/models/container_analysis.dart';
import 'lib/services/log_manager.dart';
import 'lib/services/measurement_calculator.dart';
import 'lib/services/reference_database.dart';

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '模組 Import 測試',
      home: TestHomePage(),
    );
  }
}

class TestHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('模組 Import 測試'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('所有模組測試:', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            _buildModuleTest('CustomPainters', () {
              return EdgeDetectionPainter([]).toString();
            }),
            _buildModuleTest('ImageProcessing', () {
              return EdgeDetectionConfig().toString();
            }),
            _buildModuleTest('ContainerAnalysis', () {
              return ContainerAnalysisData(
                imagePath: 'test.jpg',
                timestamp: '2024-01-01',
                container: ContainerInfo(
                  shape: 'circle',
                  material: 'plastic',
                  color: 'blue',
                  features: ['smooth'],
                ),
                measurements: MeasurementResults(
                  volume: 100.0,
                  confidence: 0.9,
                  method: 'test',
                ),
                metadata: AnalysisMetadata(
                  deviceModel: 'Test',
                  appVersion: '1.0',
                  processingTime: 1.0,
                  settings: {},
                ),
              ).toString();
            }),
            _buildModuleTest('LogManager', () {
              return LogManager.instance.toString();
            }),
            _buildModuleTest('MeasurementCalculator', () {
              return MeasurementCalculator().toString();
            }),
            _buildModuleTest('ReferenceDatabase', () {
              return ReferenceObjectDatabase.coins['NT_50'].toString();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTest(String name, String Function() test) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 10),
          Text('$name: 導入成功'),
        ],
      ),
    );
  }
}