import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../domain/entities/daily_nutrition_summary.dart';

/// 每週營養攝取長條圖
class WeeklyNutritionChart extends StatefulWidget {
  final List<DailyNutritionSummary> weeklySummaries;

  const WeeklyNutritionChart({
    super.key,
    required this.weeklySummaries,
  });

  @override
  State<WeeklyNutritionChart> createState() => _WeeklyNutritionChartState();
}

class _WeeklyNutritionChartState extends State<WeeklyNutritionChart> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('zh_TW', null);
    } catch (e) {
      // Fallback to default locale - continue anyway
      debugPrint('Failed to initialize zh_TW locale: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // Show loading indicator while initializing
        if (snapshot.connectionState != ConnectionState.done) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.all(16),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        // Once initialized, show the chart
        return _buildChart(context);
      },
    );
  }

  Widget _buildChart(BuildContext context) {

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '每週營養攝取',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: widget.weeklySummaries.isEmpty
                  ? Center(
                      child: Text(
                        '尚無數據',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxY(),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => Colors.black87,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toInt()} kcal',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= widget.weeklySummaries.length) {
                                  return const SizedBox.shrink();
                                }
                                final date = widget.weeklySummaries[index].date;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('E', 'zh_TW').format(date),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 500,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300]!,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: _getBarGroups(),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            _buildWeeklyAverage(),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    return widget.weeklySummaries.asMap().entries.map((entry) {
      final index = entry.key;
      final summary = entry.value;
      final isOnTarget = summary.isCaloriesOnTarget;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: summary.totalCalories,
            color: isOnTarget ? Colors.green : Colors.orange,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxY() {
    if (widget.weeklySummaries.isEmpty) return 3000;
    final maxCalories = widget.weeklySummaries
        .map((s) => s.totalCalories)
        .reduce((a, b) => a > b ? a : b);
    return ((maxCalories / 500).ceil() * 500).toDouble();
  }

  Widget _buildWeeklyAverage() {
    if (widget.weeklySummaries.isEmpty) return const SizedBox.shrink();

    final totalCalories = widget.weeklySummaries
        .map((s) => s.totalCalories)
        .reduce((a, b) => a + b);
    final averageCalories = totalCalories / widget.weeklySummaries.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '平均每日攝取',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${averageCalories.toStringAsFixed(0)} kcal',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
