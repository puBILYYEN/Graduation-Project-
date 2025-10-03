import 'package:flutter/material.dart';
import '../../../models/measurement_data.dart';

class ReferenceMeasurementPage extends StatelessWidget {
  final String imagePath;
  final Function(List<MeasurementResult>) onMeasurementComplete;

  const ReferenceMeasurementPage({
    Key? key,
    required this.imagePath,
    required this.onMeasurementComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('參考物體測量')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('測量圖片路徑: $imagePath'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 模擬測量結果
                onMeasurementComplete([
                  MeasurementResult(
                    description: '容器體積',
                    value: 1000.0,
                    unit: 'ml',
                  ),
                ]);
                Navigator.pop(context);
              },
              child: const Text('完成測量'),
            ),
          ],
        ),
      ),
    );
  }
}
