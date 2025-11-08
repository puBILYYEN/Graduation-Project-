import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/models/container_analysis.dart';

class NutritionLabelScreen extends StatelessWidget {
  final ContainerAnalysisData analysisData;
  final String imagePath;

  const NutritionLabelScreen({
    Key? key,
    required this.analysisData,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('營養標籤分析'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              imagePath,
              height: 200,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection('容器資訊', [
                        '形狀: ${analysisData.container.shape}',
                        '材質: ${analysisData.container.material}',
                        '顏色: ${analysisData.container.color}',
                      ]),
                      const Divider(),
                      _buildInfoSection('測量結果', [
                        '容量: ${analysisData.measurements.volume} ml',
                        '準確度: ${(analysisData.measurements.confidence * 100).toStringAsFixed(1)}%',
                        '測量方法: ${analysisData.measurements.method}',
                      ]),
                      if (analysisData.measurements.dimensions != null) ...[
                        const Divider(),
                        _buildInfoSection('尺寸', [
                          '長: ${analysisData.measurements.dimensions!["length"]} cm',
                          '寬: ${analysisData.measurements.dimensions!["width"]} cm',
                          '高: ${analysisData.measurements.dimensions!["height"]} cm',
                        ]),
                      ],
                      const Divider(),
                      _buildInfoSection('其他資訊', [
                        '處理時間: ${analysisData.metadata.processingTime.toStringAsFixed(2)} 秒',
                        '裝置型號: ${analysisData.metadata.deviceModel}',
                        'App 版本: ${analysisData.metadata.appVersion}',
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.check),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(item),
            )),
      ],
    );
  }
}