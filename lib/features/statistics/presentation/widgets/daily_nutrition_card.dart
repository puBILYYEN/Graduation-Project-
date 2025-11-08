import 'package:flutter/material.dart';
import '../../domain/entities/daily_nutrition_summary.dart';

/// 每日營養卡片 - 顯示營養攝取進度
class DailyNutritionCard extends StatelessWidget {
  final DailyNutritionSummary summary;

  const DailyNutritionCard({
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
              '今日營養攝取',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // 卡路里
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

            // 蛋白質
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

            // 碳水化合物
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

            // 脂肪
            _buildNutrientProgress(
              context,
              label: '脂肪',
              current: summary.totalFat,
              target: summary.targetFat,
              unit: 'g',
              color: Colors.amber,
              progress: summary.fatProgress,
            ),
          ],
        ),
      ),
    );
  }

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
