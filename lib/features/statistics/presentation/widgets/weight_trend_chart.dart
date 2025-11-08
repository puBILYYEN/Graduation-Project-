import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/weight_record.dart';

/// 體重趨勢折線圖
class WeightTrendChart extends StatelessWidget {
  final List<WeightRecord> records;

  const WeightTrendChart({
    super.key,
    required this.records,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '體重趨勢',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (records.isNotEmpty)
                  Text(
                    '${records.last.weight}kg',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: records.isEmpty
                  ? Center(
                      child: Text(
                        '尚無體重記錄',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300]!,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}kg',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= records.length) {
                                  return const SizedBox.shrink();
                                }
                                final date = records[index].date;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('M/d').format(date),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _getSpots(),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withOpacity(0.1),
                            ),
                          ),
                        ],
                        minY: _getMinY(),
                        maxY: _getMaxY(),
                      ),
                    ),
            ),
            if (records.length >= 2) ...[
              const SizedBox(height: 16),
              _buildWeightChange(),
            ],
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getSpots() {
    return records
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble(),
              entry.value.weight,
            ))
        .toList();
  }

  double _getMinY() {
    if (records.isEmpty) return 0;
    final minWeight = records.map((r) => r.weight).reduce((a, b) => a < b ? a : b);
    return (minWeight - 2).floorToDouble();
  }

  double _getMaxY() {
    if (records.isEmpty) return 100;
    final maxWeight = records.map((r) => r.weight).reduce((a, b) => a > b ? a : b);
    return (maxWeight + 2).ceilToDouble();
  }

  Widget _buildWeightChange() {
    final firstWeight = records.first.weight;
    final lastWeight = records.last.weight;
    final change = lastWeight - firstWeight;
    final isIncrease = change > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isIncrease ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isIncrease ? Icons.trending_up : Icons.trending_down,
            color: isIncrease ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            '${isIncrease ? '+' : ''}${change.toStringAsFixed(1)}kg',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isIncrease ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '過去 ${records.length} 天',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
