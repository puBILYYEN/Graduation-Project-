import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/daily_nutrition_summary.dart';

/// 營養比例圓餅圖
class NutritionPieChart extends StatelessWidget {
  final DailyNutritionSummary summary;

  const NutritionPieChart({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今日營養攝取與宏量比例',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // 圓餅圖區域
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _getSections(),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildLegend(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // 進度條區域
            _buildNutrientProgress(
              context,
              label: '熱量',
              current: summary.totalCalories,
              target: summary.targetCalories,
              unit: 'kcal',
              color: Colors.orange,
              progress: summary.caloriesProgress,
            ),
            const SizedBox(height: 16),

            _buildNutrientProgress(
              context,
              label: '蛋白質',
              current: summary.totalProtein,
              target: summary.targetProtein,
              unit: 'g',
              color: Colors.red,
              progress: summary.proteinProgress,
            ),
            const SizedBox(height: 16),

            _buildNutrientProgress(
              context,
              label: '碳水化合物',
              current: summary.totalCarbs,
              target: summary.targetCarbs,
              unit: 'g',
              color: Colors.blue,
              progress: summary.carbsProgress,
            ),
            const SizedBox(height: 16),

            _buildNutrientProgress(
              context,
              label: '脂肪',
              current: summary.totalFat,
              target: summary.targetFat,
              unit: 'g',
              color: Colors.amber,
              progress: summary.fatProgress,
            ),
            const SizedBox(height: 16),

            _buildNutrientProgress(
              context,
              label: '膳食纖維',
              current: summary.totalFiber,
              target: 25.0, // 建議每日攝取 25-30g
              unit: 'g',
              color: Colors.green,
              progress: summary.totalFiber / 25.0,
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getSections() {
    final total = summary.totalProtein * 4 +
                  summary.totalCarbs * 4 +
                  summary.totalFat * 9;

    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey[300],
          value: 1,
          title: '',
          radius: 50,
        ),
      ];
    }

    final proteinCalories = summary.totalProtein * 4;
    final carbsCalories = summary.totalCarbs * 4;
    final fatCalories = summary.totalFat * 9;

    return [
      // 蛋白質
      PieChartSectionData(
        color: Colors.red,
        value: proteinCalories,
        title: '${(proteinCalories / total * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      // 碳水化合物
      PieChartSectionData(
        color: Colors.blue,
        value: carbsCalories,
        title: '${(carbsCalories / total * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      // 脂肪
      PieChartSectionData(
        color: Colors.amber,
        value: fatCalories,
        title: '${(fatCalories / total * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildLegend(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendItem(
          color: Colors.red,
          label: '蛋白質',
          value: '${summary.totalProtein.toStringAsFixed(0)}g',
        ),
        const SizedBox(height: 12),
        _buildLegendItem(
          color: Colors.blue,
          label: '碳水',
          value: '${summary.totalCarbs.toStringAsFixed(0)}g',
        ),
        const SizedBox(height: 12),
        _buildLegendItem(
          color: Colors.amber,
          label: '脂肪',
          value: '${summary.totalFat.toStringAsFixed(0)}g',
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 建立營養素進度條
  Widget _buildNutrientProgress(
    BuildContext context, {
    required String label,
    required double current,
    required double target,
    required String unit,
    required Color color,
    required double progress,
  }) {
    // 限制進度在 0-1 之間用於顯示
    final displayProgress = progress.clamp(0.0, 1.0);

    // 判斷是否超標
    final isOver = progress > 1.0;
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  '${current.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOver ? Colors.red : color,
                  ),
                ),
                Text(
                  ' / ${target.toStringAsFixed(0)} $unit',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // 背景進度條
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // 實際進度
            FractionallySizedBox(
              widthFactor: displayProgress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isOver ? Colors.red : color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 12,
            color: isOver ? Colors.red : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
