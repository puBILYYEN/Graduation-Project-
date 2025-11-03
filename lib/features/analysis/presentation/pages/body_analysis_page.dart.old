import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/health_models.dart';

// ====================================================================
// 身體素質分析頁面 (Body Analysis Page)
// ====================================================================
class BodyAnalysisPageContent extends StatefulWidget {
  const BodyAnalysisPageContent({super.key});

  @override
  State<BodyAnalysisPageContent> createState() =>
      _BodyAnalysisPageContentState();
}

class _BodyAnalysisPageContentState extends State<BodyAnalysisPageContent> {
  String selectedPeriod = '週';

  // 身體素質數據
  BodyMetrics bodyMetrics = BodyMetrics(
    sleepHours: 8,
    sleepChange: 10,
    height: 175,
    heightChange: 0,
    weight: 65,
    weightChange: -1.2,
    heartRate: 70,
    heartRateChange: -2,
    bloodPressure: '120/80',
    bloodPressureChange: 1,
  );

  // ====================================================================
  // 身體分析頁面主要 UI
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    // 鎖定身體分析頁面為豎螢幕
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 頂部標籤區域
            _buildTopTags(),

            // 時間段選擇
            _buildPeriodSelector(),

            // 整體身體素質分析
            _buildOverallAnalysis(),

            // 身體指標卡片
            _buildMetricsCards(),

            // 年齡層級比較
            _buildAgeComparison(),

            // 建議
            _buildRecommendations(),

            // 測試功能區塊
            _buildTestSection(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // 身體分析頁面 UI 組件
  // ====================================================================

  // 頂部標籤
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

  // 時間段選擇器
  Widget _buildPeriodSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPeriodButton('天'),
          _buildPeriodButton('週'),
          _buildPeriodButton('月'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    bool isSelected = selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPeriod = period;
        });
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

  // 整體分析
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
        children: [
          const Text(
            '整體身體素質分析',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
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

  // 指標卡片組
  Widget _buildMetricsCards() {
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
          _buildBloodPressureCard(),
        ],
      ),
    );
  }

  // 單一指標卡片
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

  // 血壓卡片
  Widget _buildBloodPressureCard() {
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

  // 年齡比較區塊
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
        children: [
          const Text(
            '與年齡層級的比較',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
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

  // 建議區塊
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
        children: [
          const Text(
            '建議',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
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

  // 測試功能區塊
  Widget _buildTestSection() {
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
              _buildTestButton('更新睡眠數據', () => _updateSleepData()),
              _buildTestButton('更新體重數據', () => _updateWeightData()),
              _buildTestButton('更新心率數據', () => _updateHeartRateData()),
              _buildTestButton(
                  '模擬 Power BI 同步', () => _updateBodyMetricsFromPowerBI()),
              _buildTestButton('重置為默認值', () => _resetToDefault()),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '當前數據來源：$selectedPeriod統計',
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

  // ====================================================================
  // 身體分析功能方法
  // ====================================================================

  // 更新睡眠數據
  /// 更新睡眠數據 - 模擬從睡眠感測器獲取的睡眠時間數據
  void _updateSleepData() {
    setState(() {
      // 更新身體指標：設定新的睡眠時間為 9 小時，變化率為 +25%
      bodyMetrics = BodyMetrics(
        sleepHours: 9, // 設定睡眠時間為 9 小時
        sleepChange: 25.0, // 睡眠時間增加 25%
        height: bodyMetrics.height, // 保持原有身高數據
        heightChange: bodyMetrics.heightChange, // 保持原有身高變化數據
        weight: bodyMetrics.weight, // 保持原有體重數據
        weightChange: bodyMetrics.weightChange, // 保持原有體重變化數據
        heartRate: bodyMetrics.heartRate, // 保持原有心率數據
        heartRateChange: bodyMetrics.heartRateChange, // 保持原有心率變化數據
        bloodPressure: bodyMetrics.bloodPressure, // 保持原有血壓數據
        bloodPressureChange: bodyMetrics.bloodPressureChange, // 保持原有血壓變化數據
      );
    });
  }

  /// 更新體重數據 - 模擬從體重計感測器獲取的體重測量數據
  void _updateWeightData() {
    setState(() {
      // 更新身體指標：設定新的體重為 62 公斤，變化率為 -4.8%
      bodyMetrics = BodyMetrics(
        sleepHours: bodyMetrics.sleepHours, // 保持原有睡眠數據
        sleepChange: bodyMetrics.sleepChange, // 保持原有睡眠變化數據
        height: bodyMetrics.height, // 保持原有身高數據
        heightChange: bodyMetrics.heightChange, // 保持原有身高變化數據
        weight: 62, // 設定體重為 62 公斤
        weightChange: -4.8, // 體重減少 4.8%
        heartRate: bodyMetrics.heartRate, // 保持原有心率數據
        heartRateChange: bodyMetrics.heartRateChange, // 保持原有心率變化數據
        bloodPressure: bodyMetrics.bloodPressure, // 保持原有血壓數據
        bloodPressureChange: bodyMetrics.bloodPressureChange, // 保持原有血壓變化數據
      );
    });
  }

  /// 更新心率數據 - 模擬從心率感測器獲取的心跳監測數據
  void _updateHeartRateData() {
    setState(() {
      // 更新身體指標：準備設定新的心率數據
      bodyMetrics = BodyMetrics(
        sleepHours: bodyMetrics.sleepHours, // 保持原有睡眠數據
        sleepChange: bodyMetrics.sleepChange,
        height: bodyMetrics.height,
        heightChange: bodyMetrics.heightChange,
        weight: bodyMetrics.weight,
        weightChange: bodyMetrics.weightChange,
        heartRate: 75,
        heartRateChange: 7.1,
        bloodPressure: bodyMetrics.bloodPressure,
        bloodPressureChange: bodyMetrics.bloodPressureChange,
      );
    });
  }

  // 模擬 Power BI 同步
  void _updateBodyMetricsFromPowerBI() {
    setState(() {
      bodyMetrics = BodyMetrics(
        sleepHours: 8,
        sleepChange: 15.0,
        height: 175,
        heightChange: 0,
        weight: 63,
        weightChange: -3.1,
        heartRate: 68,
        heartRateChange: -2.9,
        bloodPressure: '118/78',
        bloodPressureChange: -1.5,
      );
    });
  }

  // 重置為默認值
  void _resetToDefault() {
    setState(() {
      bodyMetrics = BodyMetrics(
        sleepHours: 8,
        sleepChange: 10,
        height: 175,
        heightChange: 0,
        weight: 65,
        weightChange: -1.2,
        heartRate: 70,
        heartRateChange: -2,
        bloodPressure: '120/80',
        bloodPressureChange: 1,
      );
    });
  }
}