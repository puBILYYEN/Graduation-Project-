import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart'; // Added
import 'package:provider/provider.dart';

import '../viewmodels/body_analysis_viewmodel.dart';
import '../../domain/usecases/get_body_metrics_usecase.dart';
import '../../domain/usecases/update_body_metrics_usecase.dart';
import '../../domain/entities/body_metrics.dart';

class BodyAnalysisPage extends StatelessWidget {
  const BodyAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = BodyAnalysisViewModel(
          context.read<GetBodyMetricsUseCase>(),
          context.read<UpdateBodyMetricsUseCase>(),
        );
        viewModel.fetchBodyMetrics(); // Call fetchBodyMetrics on the viewModel instance
        return viewModel;
      },
      child: const BodyAnalysisPageContent(),
    );
  }
}

class BodyAnalysisPageContent extends StatelessWidget {
  const BodyAnalysisPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Lock the screen to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox.shrink(),
        title: const Text(
          '身體素質分析',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<BodyAnalysisViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading || viewModel.bodyMetrics == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopTags(),
                _buildPeriodSelector(context, viewModel),
                _buildOverallAnalysis(),
                _buildMetricsCards(viewModel.bodyMetrics!),
                _buildAgeComparison(),
                _buildRecommendations(),
                _buildTestSection(context, viewModel),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopTags() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildTag('優秀'),
          _buildTag('良好'),
          _buildTag('正常'),
          _buildTag('注意'),
          _buildTag('改善'),
          _buildTag('睡眠'),
          _buildTag('體重'),
          _buildTag('心率'),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, BodyAnalysisViewModel viewModel) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPeriodButton(context, viewModel, '天'),
          _buildPeriodButton(context, viewModel, '週'),
          _buildPeriodButton(context, viewModel, '月'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(BuildContext context, BodyAnalysisViewModel viewModel, String period) {
    bool isSelected = viewModel.selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        viewModel.setSelectedPeriod(period);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[300] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          period,
          style: TextStyle(
            fontSize: 16,
            color: isSelected ? Colors.black : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOverallAnalysis() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '整體身體素質分析',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            '您的身體素質分析顯示您在睡眠品質、身高、體重、心率和血壓方面的重要參數。您的身體素質在您的年齡層級中處於平均水平，特別是在睡眠品質方面表現出色。',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCards(BodyMetrics bodyMetrics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  '睡眠品質',
                  '${bodyMetrics.sleepHours} 小時',
                  bodyMetrics.sleepChange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  '身高',
                  '${bodyMetrics.height} 公分',
                  bodyMetrics.heightChange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  '體重',
                  '${bodyMetrics.weight} 公斤',
                  bodyMetrics.weightChange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  '心率',
                  '${bodyMetrics.heartRate} 次/分鐘',
                  bodyMetrics.heartRateChange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBloodPressureCard(bodyMetrics),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, double change) {
    Color changeColor = change > 0
        ? Colors.green
        : change < 0
            ? Colors.red
            : Colors.grey;
    String changeText = change > 0
        ? '+${change.toStringAsFixed(change % 1 == 0 ? 0 : 1)}%'
        : change < 0
            ? '${change.toStringAsFixed(change % 1 == 0 ? 0 : 1)}%'
            : '${change.toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            changeText,
            style: TextStyle(
              fontSize: 14,
              color: changeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureCard(BodyMetrics bodyMetrics) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '血壓',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${bodyMetrics.bloodPressure} 毫米汞柱',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+${bodyMetrics.bloodPressureChange}%',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeComparison() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '與年齡層級的比較',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            '您的睡眠品質高於同年齡級的平均水平，而身高、體重、心率和血壓則處於平均水平。這表示睡眠方面的優勢，但也提示在體重和脂肪百分比方面可能需要調整。',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '建議',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            '為了維持睡眠品質並改善體重和脂肪百分比，可考慮增加肌力訓練、調整飲食以增加蛋白質攝取，並控制脂肪和糖分的攝取。',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection(BuildContext context, BodyAnalysisViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '測試功能 (Power BI 數據模擬)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '模擬數據更新：',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTestButton('更新睡眠數據', () => viewModel.updateSleepData()),
              _buildTestButton('更新體重數據', () => viewModel.updateWeightData()),
              _buildTestButton('更新心率數據', () => viewModel.updateHeartRateData()),
              _buildTestButton('模擬 Power BI 同步', () => viewModel.updateBodyMetricsFromPowerBI()),
              _buildTestButton('重置為默認值', () => viewModel.resetToDefault()),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '當前數據來源：${viewModel.selectedPeriod}統計',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.blue[700],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 11),
      ),
      child: Text(label),
    );
  }
}