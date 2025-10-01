// AK47 風格精簡版：營養詳細資訊頁面
import 'dart:io';
import 'package:flutter/material.dart';
import '../ui/widgets.dart';
import '../utils/constants.dart';

class NutritionDetailPage extends StatelessWidget {
  final String imagePath;

  const NutritionDetailPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('營養資訊', style: AppTextStyles.title),
      backgroundColor: AppColors.background,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: () => _saveFoodEntry(context),
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ImageCard(),
          const SizedBox(height: AppSpacing.m),
          _FoodInfoCard(),
          const SizedBox(height: AppSpacing.m),
          _NutritionCard(),
          const SizedBox(height: AppSpacing.m),
          _IngredientsCard(),
          const SizedBox(height: AppSpacing.m),
          _AllergenCard(),
        ],
      ),
    ),
    bottomNavigationBar: Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('重新拍照'),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _saveFoodEntry(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('保存記錄'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _ImageCard() => CardContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('拍攝圖片', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.m),
        ClipRRect(
          borderRadius: AppBorders.radius,
          child: Image.file(
            File(imagePath),
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[300],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 48, color: Colors.grey),
                  Text('無法載入圖片', style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _FoodInfoCard() => CardContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('食物資訊', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.m),
        _InfoRow('食物名稱', '雞胸肉沙拉'),
        _InfoRow('份量', '1 份 (約 250g)'),
        _InfoRow('熱量', '320 大卡'),
        _InfoRow('用餐時間', '午餐'),
      ],
    ),
  );

  Widget _NutritionCard() => CardContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('營養成分', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.m),

        // 宏量營養素圓餅圖區域
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: AppBorders.radius,
          ),
          child: const Center(
            child: Text('營養素比例圖', style: AppTextStyles.caption),
          ),
        ),
        const SizedBox(height: AppSpacing.m),

        // 詳細營養數據
        _NutritionRow('蛋白質', '35g', '44%', Colors.red),
        _NutritionRow('碳水化合物', '12g', '15%', Colors.orange),
        _NutritionRow('脂肪', '15g', '47%', Colors.yellow),
        _NutritionRow('纖維', '8g', '-', Colors.green),
        _NutritionRow('糖分', '3g', '-', Colors.blue),
        _NutritionRow('鈉', '450mg', '-', Colors.purple),
      ],
    ),
  );

  Widget _IngredientsCard() => CardContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('成分清單', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.m),
        ...[
          '雞胸肉 (60%)',
          '混合蔬菜 (25%)',
          '橄欖油 (8%)',
          '檸檬汁 (4%)',
          '香料調味 (3%)',
        ].map((ingredient) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 6, color: Colors.grey),
              const SizedBox(width: AppSpacing.s),
              Text(ingredient, style: AppTextStyles.body),
            ],
          ),
        )),
      ],
    ),
  );

  Widget _AllergenCard() => CardContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 20),
            const SizedBox(width: AppSpacing.s),
            const Text('過敏原資訊', style: AppTextStyles.subtitle),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: AppBorders.radius,
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('此產品可能含有：',
                style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: AppSpacing.s),
              Text('• 本產品在處理蛋類、堅果類的工廠生產'),
              Text('• 可能含有微量花生、芝麻'),
              Text('• 過敏體質者請注意'),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _InfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.s),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body),
        Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _NutritionRow(String name, String amount, String percentage, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.s),
    child: Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(child: Text(name, style: AppTextStyles.body)),
        Text(amount, style: AppTextStyles.body),
        const SizedBox(width: AppSpacing.s),
        SizedBox(
          width: 40,
          child: Text(percentage,
            style: AppTextStyles.caption.copyWith(color: color),
            textAlign: TextAlign.end),
        ),
      ],
    ),
  );

  void _saveFoodEntry(BuildContext context) {
    // AK47 簡化版：模擬保存
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('食物記錄已保存！'),
        backgroundColor: AppColors.success,
      ),
    );

    // 返回主頁面
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}