import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/statistics_viewmodel.dart';
import '../../../../core/services/app_logger.dart';
// import '../widgets/daily_nutrition_card.dart'; // 已註解：功能已整合到 NutritionPieChart
import '../widgets/nutrition_pie_chart.dart';
import '../widgets/weight_trend_chart.dart';
import '../widgets/weekly_nutrition_chart.dart';

/// 統計頁面
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  @override
  void initState() {
    super.initState();
    // 載入今日統計數據
    AppLogger.logEvent('營養統計頁面初始化');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsViewModel>().loadTodayStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('營養統計'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await AppLogger.logButtonClick('統計頁面刷新按鈕');
              context.read<StatisticsViewModel>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<StatisticsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await AppLogger.logButtonClick('統計頁面重試按鈕');
                      await viewModel.refresh();
                    },
                    child: const Text('重試'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // 今日營養攝取與宏量比例（整合了進度條和圓餅圖）
                  if (viewModel.dailySummary != null)
                    NutritionPieChart(summary: viewModel.dailySummary!),

                  // 每週營養攝取長條圖
                  if (viewModel.weeklySummaries.isNotEmpty)
                    WeeklyNutritionChart(
                        weeklySummaries: viewModel.weeklySummaries),

                  // 體重趨勢折線圖
                  if (viewModel.weightRecords.isNotEmpty)
                    WeightTrendChart(records: viewModel.weightRecords),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
