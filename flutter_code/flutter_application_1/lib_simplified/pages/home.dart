// AK47 風格精簡版：主頁面框架
import 'package:flutter/material.dart';
import '../core/models.dart';
import '../ui/widgets.dart';
import '../utils/constants.dart';
import 'camera.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppPage _currentPage = AppPage.home;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _buildCurrentPage(),
    bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentPage.index,
      onTap: _onTabTapped,
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.secondary,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
        BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: '飲食'),
        BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: '相機'),
        BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: '運動'),
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: '分析'),
      ],
    ),
  );

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case AppPage.home:
        return const HomeContent();
      case AppPage.food:
        return const FoodContent();
      case AppPage.exercise:
        return const ExerciseContent();
      case AppPage.analysis:
        return const AnalysisContent();
      case AppPage.camera:
        return const CameraPage();
    }
  }

  void _onTabTapped(int index) {
    if (index == 2) {  // 相機頁面使用 push navigation
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CameraPage()),
      );
    } else {
      setState(() => _currentPage = AppPage.values[index]);
    }
  }
}

// 簡化的首頁內容
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('健康追蹤', style: AppTextStyles.title),
      backgroundColor: AppColors.background,
      elevation: 0,
    ),
    body: const Padding(
      padding: EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          _QuickStatsCard(),
          SizedBox(height: AppSpacing.m),
          _NutritionSummary(),
        ],
      ),
    ),
  );
}

// 快速統計卡片
class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard();

  @override
  Widget build(BuildContext context) => CardContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('今日概況', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.m),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem('卡路里', '1,234', 'kcal', Colors.red),
            _StatItem('步數', '8,567', '步', Colors.blue),
            _StatItem('睡眠', '7.5', '小時', Colors.green),
          ],
        ),
      ],
    ),
  );
}

class _StatItem extends StatelessWidget {
  final String label, value, unit;
  final Color color;

  const _StatItem(this.label, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(Icons.circle, color: color, size: 12),
      const SizedBox(height: AppSpacing.xs),
      Text(value, style: AppTextStyles.subtitle),
      Text('$label ($unit)', style: AppTextStyles.caption),
    ],
  );
}

// 營養摘要
class _NutritionSummary extends StatelessWidget {
  const _NutritionSummary();

  @override
  Widget build(BuildContext context) => CardContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('營養攝取', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.m),
        _NutrientBar('蛋白質', 0.75, Colors.red),
        const SizedBox(height: AppSpacing.s),
        _NutrientBar('碳水化合物', 0.60, Colors.orange),
        const SizedBox(height: AppSpacing.s),
        _NutrientBar('脂肪', 0.45, Colors.yellow),
      ],
    ),
  );
}

class _NutrientBar extends StatelessWidget {
  final String name;
  final double progress;
  final Color color;

  const _NutrientBar(this.name, this.progress, this.color);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: AppTextStyles.body),
          Text('${(progress * 100).toInt()}%', style: AppTextStyles.caption),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation(color),
      ),
    ],
  );
}

// 飲食記錄頁面
class FoodContent extends StatelessWidget {
  const FoodContent({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('飲食記錄', style: AppTextStyles.title),
      backgroundColor: AppColors.background,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showAddFoodDialog(context),
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          _CaloriesSummaryCard(),
          const SizedBox(height: AppSpacing.m),
          _MealSectionCard('早餐', _getBreakfastItems()),
          const SizedBox(height: AppSpacing.m),
          _MealSectionCard('午餐', _getLunchItems()),
          const SizedBox(height: AppSpacing.m),
          _MealSectionCard('晚餐', _getDinnerItems()),
        ],
      ),
    ),
  );

  List<Map<String, dynamic>> _getBreakfastItems() => [
    {'name': '燕麥粥', 'calories': 150, 'portion': '1碗'},
    {'name': '香蕉', 'calories': 89, 'portion': '1根'},
  ];

  List<Map<String, dynamic>> _getLunchItems() => [
    {'name': '雞胸肉沙拉', 'calories': 320, 'portion': '1份'},
    {'name': '糙米飯', 'calories': 180, 'portion': '半碗'},
  ];

  List<Map<String, dynamic>> _getDinnerItems() => [
    {'name': '烤鮭魚', 'calories': 280, 'portion': '1片'},
    {'name': '蒸蔬菜', 'calories': 80, 'portion': '1份'},
  ];

  void _showAddFoodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增食物'),
        content: const Text('拍照辨識或手動輸入食物'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 這裡可以導航到相機頁面
            },
            child: const Text('拍照辨識'),
          ),
        ],
      ),
    );
  }
}

// 卡路里摘要卡片
class _CaloriesSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CardContainer(
    child: Column(
      children: [
        const Text('今日卡路里', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.m),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _CalorieItem('攝取', '1,179', Colors.red),
            _CalorieItem('消耗', '1,850', Colors.blue),
            _CalorieItem('剩餘', '671', Colors.green),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        LinearProgressIndicator(
          value: 0.64,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation(Colors.orange),
        ),
        const SizedBox(height: AppSpacing.s),
        const Text('目標達成 64%', style: AppTextStyles.caption),
      ],
    ),
  );
}

class _CalorieItem extends StatelessWidget {
  final String label, value;
  final Color color;

  const _CalorieItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: AppTextStyles.subtitle.copyWith(color: color)),
      Text(label, style: AppTextStyles.caption),
    ],
  );
}

// 餐點區段卡片
class _MealSectionCard extends StatelessWidget {
  final String mealName;
  final List<Map<String, dynamic>> items;

  const _MealSectionCard(this.mealName, this.items);

  @override
  Widget build(BuildContext context) => CardContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(mealName, style: AppTextStyles.subtitle),
            Text(
              '${items.fold<int>(0, (sum, item) => sum + (item['calories'] as int))} kcal',
              style: AppTextStyles.body.copyWith(color: Colors.orange),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(item['name'], style: AppTextStyles.body)),
              Text('${item['portion']}', style: AppTextStyles.caption),
              Text('${item['calories']} kcal', style: AppTextStyles.caption),
            ],
          ),
        )),
        const SizedBox(height: AppSpacing.s),
        TextButton.icon(
          onPressed: () => _showAddFoodDialog(context),
          icon: const Icon(Icons.add, size: 16),
          label: Text('新增${mealName}'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
      ],
    ),
  );

  void _showAddFoodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('新增$mealName'),
        content: const Text('選擇新增方式'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('拍照辨識'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('手動輸入'),
          ),
        ],
      ),
    );
  }
}

class ExerciseContent extends StatelessWidget {
  const ExerciseContent({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('運動記錄', style: AppTextStyles.title),
      backgroundColor: AppColors.background,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showAddExerciseDialog(context),
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          _ExerciseSummaryCard(),
          const SizedBox(height: AppSpacing.m),
          _TodayExerciseCard(),
          const SizedBox(height: AppSpacing.m),
          _ExerciseHistoryCard(),
        ],
      ),
    ),
  );

  void _showAddExerciseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增運動'),
        content: const Text('選擇運動類型'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('跑步'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('健身'),
          ),
        ],
      ),
    );
  }
}

// 運動摘要卡片
class _ExerciseSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CardContainer(
    child: Column(
      children: [
        const Text('今日運動概況', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.m),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ExerciseStatItem('運動時間', '45', '分鐘', Colors.blue),
            _ExerciseStatItem('卡路里', '320', 'kcal', Colors.red),
            _ExerciseStatItem('步數', '8,234', '步', Colors.green),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        LinearProgressIndicator(
          value: 0.75,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation(Colors.blue),
        ),
        const SizedBox(height: AppSpacing.s),
        const Text('運動目標達成 75%', style: AppTextStyles.caption),
      ],
    ),
  );
}

class _ExerciseStatItem extends StatelessWidget {
  final String label, value, unit;
  final Color color;

  const _ExerciseStatItem(this.label, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: AppTextStyles.subtitle.copyWith(color: color)),
      Text(unit, style: AppTextStyles.caption),
      Text(label, style: AppTextStyles.caption),
    ],
  );
}

// 今日運動卡片
class _TodayExerciseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CardContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('今日運動', style: AppTextStyles.subtitle),
            TextButton.icon(
              onPressed: () => _showAddExerciseDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('新增'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        _ExerciseItem('跑步', '30分鐘', '3.2公里', '180 kcal', Icons.directions_run, Colors.orange),
        const SizedBox(height: AppSpacing.s),
        _ExerciseItem('重訓', '15分鐘', '8組', '140 kcal', Icons.fitness_center, Colors.blue),
      ],
    ),
  );

  void _showAddExerciseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增運動'),
        content: const Text('選擇運動類型'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('跑步'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('健身'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseItem extends StatelessWidget {
  final String name, duration, detail, calories;
  final IconData icon;
  final Color color;

  const _ExerciseItem(this.name, this.duration, this.detail, this.calories, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(width: AppSpacing.m),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
            Text('$duration • $detail', style: AppTextStyles.caption),
          ],
        ),
      ),
      Text(calories, style: AppTextStyles.body.copyWith(color: Colors.orange)),
    ],
  );
}

// 運動歷史卡片
class _ExerciseHistoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CardContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('本週運動歷史', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.m),
        ...List.generate(5, (index) {
          final days = ['週一', '週二', '週三', '週四', '週五'];
          final exercises = ['跑步 25分', '重訓 40分', '瑜珈 30分', '游泳 35分', '騎車 50分'];
          final calories = ['150', '200', '120', '180', '250'];

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(days[index], style: AppTextStyles.body),
                Text(exercises[index], style: AppTextStyles.caption),
                Text('${calories[index]} kcal', style: AppTextStyles.caption.copyWith(color: Colors.orange)),
              ],
            ),
          );
        }),
      ],
    ),
  );
}

class AnalysisContent extends StatelessWidget {
  const AnalysisContent({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('健康分析', style: AppTextStyles.title),
      backgroundColor: AppColors.background,
      elevation: 0,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          _BodyMetricsCard(),
          const SizedBox(height: AppSpacing.m),
          _HealthTrendsCard(),
          const SizedBox(height: AppSpacing.m),
          _RecommendationsCard(),
        ],
      ),
    ),
  );
}

// 身體指標卡片
class _BodyMetricsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CardContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('身體指標', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.m),
        _MetricRow('體重', '65.2', 'kg', '+0.5', Colors.orange),
        const SizedBox(height: AppSpacing.s),
        _MetricRow('身高', '170', 'cm', '0', Colors.grey),
        const SizedBox(height: AppSpacing.s),
        _MetricRow('心率', '72', 'bpm', '-3', Colors.green),
        const SizedBox(height: AppSpacing.s),
        _MetricRow('血壓', '120/80', 'mmHg', '+2', Colors.blue),
      ],
    ),
  );
}

class _MetricRow extends StatelessWidget {
  final String label, value, unit, change;
  final Color color;

  const _MetricRow(this.label, this.value, this.unit, this.change, this.color);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(child: Text(label, style: AppTextStyles.body)),
      Text('$value $unit', style: AppTextStyles.subtitle),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          change,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}

// 健康趨勢卡片
class _HealthTrendsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CardContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('本週趨勢', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.m),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: AppBorders.radius,
          ),
          child: const Center(
            child: Text('趨勢圖表', style: AppTextStyles.caption),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _TrendItem('平均睡眠', '7.5小時', Colors.blue),
            _TrendItem('平均步數', '8,234', Colors.green),
            _TrendItem('卡路里', '1,845', Colors.orange),
          ],
        ),
      ],
    ),
  );
}

class _TrendItem extends StatelessWidget {
  final String label, value;
  final Color color;

  const _TrendItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(Icons.circle, color: color, size: 12),
      const SizedBox(height: AppSpacing.xs),
      Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
      Text(label, style: AppTextStyles.caption),
    ],
  );
}

// 建議卡片
class _RecommendationsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CardContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('健康建議', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.m),
        _RecommendationItem(
          Icons.fitness_center,
          '運動建議',
          '建議每天增加30分鐘有氧運動',
          Colors.red,
        ),
        const SizedBox(height: AppSpacing.m),
        _RecommendationItem(
          Icons.restaurant,
          '飲食建議',
          '多攝取蛋白質，減少精製糖分',
          Colors.green,
        ),
        const SizedBox(height: AppSpacing.m),
        _RecommendationItem(
          Icons.bedtime,
          '睡眠建議',
          '保持規律作息，維持充足睡眠',
          Colors.blue,
        ),
      ],
    ),
  );
}

class _RecommendationItem extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;

  const _RecommendationItem(this.icon, this.title, this.subtitle, this.color);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: AppSpacing.m),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
            Text(subtitle, style: AppTextStyles.caption),
          ],
        ),
      ),
    ],
  );
}