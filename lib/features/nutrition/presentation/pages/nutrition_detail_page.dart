import 'package:flutter/material.dart';
import '../../domain/entities/nutrition_info.dart';

class NutritionDetailPage extends StatelessWidget {
  final String foodName;
  final int servingSize;
  final NutritionInfo nutritionInfo;
  final List<String> ingredients;
  final List<String> allergens;
  final String? imageUrl;

  const NutritionDetailPage({
    super.key,
    required this.foodName,
    required this.servingSize,
    required this.nutritionInfo,
    required this.ingredients,
    required this.allergens,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '餐點詳細資訊',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B9A7A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF8B9A7A),
                      child: const Icon(
                        Icons.fastfood,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            _buildInfoSection(
              '食物名稱 / Food Name',
              foodName,
            ),
            _buildInfoSection(
              '份量 / Serving Size (g)',
              '${servingSize}g',
            ),
            _buildNutritionSection(),
            _buildInfoSection(
              '食材來源/烹調方式 / Ingredients & Preparation',
              ingredients.join(', '),
            ),
            _buildAllergensSection(),
            _buildInfoSection(
              '營養師評估/建議 / Dietitian\'s Assessment/Recommendations',
              '', // Empty for now
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '營養素資訊 / Nutrition Info',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 16,
            children: [
              _buildNutritionItem('卡路里 / Calories', '${nutritionInfo.calories}卡路里'),
              _buildNutritionItem('蛋白質 / Protein', '${nutritionInfo.protein}克'),
              _buildNutritionItem('碳水化合物 / Carbohydrates', '${nutritionInfo.carbohydrates}克'),
              _buildNutritionItem('脂肪 / Fat', '${nutritionInfo.fat}克'),
              _buildNutritionItem('膳食纖維 / Dietary Fiber', '${nutritionInfo.fiber}克'),
              _buildNutritionItem('糖 / Sugar', '${nutritionInfo.sugar}克'),
              _buildNutritionItem('鈉 / Sodium', '${nutritionInfo.sodium}毫克'),
              _buildNutritionItem('膽固醇 / Cholesterol', '${nutritionInfo.cholesterol}毫克'),
              _buildNutritionItem('維生素A / Vitamin A', '${nutritionInfo.vitaminA}微克'),
              _buildNutritionItem('維生素C / Vitamin C', '${nutritionInfo.vitaminC}毫克'),
              _buildNutritionItem('鈣 / Calcium', '${nutritionInfo.calcium}毫克'),
              _buildNutritionItem('鐵 / Iron', '${nutritionInfo.iron}毫克'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildAllergensSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '過敏原 / Allergens',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergens
                .map((allergen) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Text(
                        allergen,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
