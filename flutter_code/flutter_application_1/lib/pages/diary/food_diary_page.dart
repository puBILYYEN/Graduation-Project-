// ----- [pages/diary/food_diary_page.dart] 開始 -----
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../models/container_analysis.dart';

// 飲食記錄頁面 (Food Diary Page)
// ====================================================================
class FoodDiaryPageContent extends StatefulWidget {
  const FoodDiaryPageContent({super.key});

  @override
  State<FoodDiaryPageContent> createState() => _FoodDiaryPageContentState();
}

class _FoodDiaryPageContentState extends State<FoodDiaryPageContent> {
  DateTime selectedDate = DateTime.now();

  // 滾輪控制器
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  // 年月日選項
  List<int> years =
      List.generate(10, (index) => DateTime.now().year - 5 + index);
  List<int> months = List.generate(12, (index) => index + 1);
  late List<int> days;

  @override
  void initState() {
    super.initState();
    _updateDaysInMonth();

    // 初始化控制器，設定為當前日期
    _yearController = FixedExtentScrollController(
      initialItem: years.indexOf(selectedDate.year),
    );
    _monthController = FixedExtentScrollController(
      initialItem: selectedDate.month - 1,
    );
    _dayController = FixedExtentScrollController(
      initialItem: selectedDate.day - 1,
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  // 更新該月份的天數
  void _updateDaysInMonth() {
    int daysInMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    days = List.generate(daysInMonth, (index) => index + 1);
  }

  // 模擬飲食記錄數據
  Map<String, List<FoodEntry>> get foodEntries {
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return {
      // 今天的數據
      todayKey: [
        FoodEntry(
          name: 'Grilled Salmon',
          chineseName: '烤鮭魚',
          mealType: '午餐',
          calories: 350,
          imageUrls: [
            'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400',
            'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400',
            'https://images.unsplash.com/photo-1574781330855-d0db2293d3b3?w=400',
          ],
          servingInfo: '150g',
        ),
        FoodEntry(
          name: 'Greek Salad',
          chineseName: '希臘沙拉',
          mealType: '晚餐',
          calories: 180,
          imageUrls: [
            'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400',
            'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
            'https://images.unsplash.com/photo-1551248429-40975aa4de74?w=400',
          ],
          servingInfo: '200g',
        ),
      ],
      // 示例日期數據
      '2024-07-15': [
        FoodEntry(
          name: 'Oatmeal with Berries',
          chineseName: '燕麥莓果',
          mealType: '早餐',
          calories: 250,
          imageUrls: [
            'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400',
            'https://images.unsplash.com/photo-1559847844-5315695dadae?w=400',
            'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400',
          ],
          servingInfo: '1杯',
        ),
        FoodEntry(
          name: 'Chicken Salad Sandwich',
          chineseName: '雞肉沙拉三明治',
          mealType: '午餐',
          calories: 450,
          imageUrls: [
            'https://images.unsplash.com/photo-1553909489-cd47e0ef937f?w=400',
            'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
            'https://images.unsplash.com/photo-1571091655789-405eb7a3a3a8?w=400',
          ],
          servingInfo: '1份',
        ),
        FoodEntry(
          name: 'Salmon with Roasted Vegetables',
          chineseName: '烤蔬菜鮭魚',
          mealType: '晚餐',
          calories: 600,
          imageUrls: [
            'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400',
            'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400',
            'https://images.unsplash.com/photo-1574781330855-d0db2293d3b3?w=400',
          ],
          servingInfo: '1份',
        ),
      ],
      // 昨天的數據示例
      '${DateTime.now().subtract(Duration(days: 1)).year}-${DateTime.now().subtract(Duration(days: 1)).month.toString().padLeft(2, '0')}-${DateTime.now().subtract(Duration(days: 1)).day.toString().padLeft(2, '0')}':
          [
        FoodEntry(
          name: 'Avocado Toast',
          chineseName: '酪梨吐司',
          mealType: '早餐',
          calories: 280,
          imageUrls: [
            'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=400',
            'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=400',
            'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400',
          ],
          servingInfo: '2片',
        ),
      ],
    };
  }

  // ====================================================================
  // 飲食記錄頁面主要 UI
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    // 鎖定飲食記錄頁面為豎螢幕
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
          '飲食記錄',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 日期選擇器
          _buildDateSelector(),

          // 選中日期顯示
          _buildSelectedDate(),

          // 飲食記錄列表
          Expanded(
            child: _buildFoodList(),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 飲食記錄頁面 UI 組件
  // ====================================================================

  // 日期選擇器 - 三個垂直滾輪
  Widget _buildDateSelector() {
    return Container(
      color: Colors.white,
      height: 200,
      child: Row(
        children: [
          // 年份滾輪
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '年',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _yearController,
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedDate = DateTime(
                          years[index],
                          selectedDate.month,
                          math.min(
                              selectedDate.day,
                              DateTime(years[index], selectedDate.month + 1, 0)
                                  .day),
                        );
                        _updateDaysInMonth();
                        // 如果當前選中的日期超出新月份的天數，則調整日期滾輪
                        if (selectedDate.day > days.length) {
                          _dayController.jumpToItem(days.length - 1);
                        }
                      });
                    },
                    children: years
                        .map((year) => Center(
                              child: Text(
                                year.toString(),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // 月份滾輪
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '月',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _monthController,
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedDate = DateTime(
                          selectedDate.year,
                          months[index],
                          math.min(
                              selectedDate.day,
                              DateTime(selectedDate.year, months[index] + 1, 0)
                                  .day),
                        );
                        _updateDaysInMonth();
                        // 如果當前選中的日期超出新月份的天數，則調整日期滾輪
                        if (selectedDate.day > days.length) {
                          _dayController.jumpToItem(days.length - 1);
                        }
                      });
                    },
                    children: months
                        .map((month) => Center(
                              child: Text(
                                month.toString(),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // 日期滾輪
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '日',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _dayController,
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          days[index],
                        );
                      });
                    },
                    children: days
                        .map((day) => Center(
                              child: Text(
                                day.toString(),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 獲取星期幾的中文名稱
  String _getWeekday(DateTime date) {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return '週${weekdays[date.weekday % 7]}';
  }

  // 選中日期顯示
  Widget _buildSelectedDate() {
    String formattedDate =
        '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_getWeekday(selectedDate)} • ${_getTotalCalories()} kcal',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // 獲取該日期的總熱量（示例）
  int _getTotalCalories() {
    final dateKey =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    final entries = foodEntries[dateKey] ?? [];
    return entries.fold(0, (sum, entry) => sum + entry.calories);
  }

  // 飲食記錄列表
  Widget _buildFoodList() {
    final dateKey =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    final entries = foodEntries[dateKey] ?? [];

    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('尚無飲食記錄', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return _buildFoodCard(entries[index]);
      },
    );
  }

  // 飲食卡片
  Widget _buildFoodCard(FoodEntry entry) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NutritionDetailPage(
              foodName: entry.name,
              servingSize: 250, // 預設份量
              nutritionInfo: NutritionInfo(
                calories: entry.calories,
                protein: 25,
                carbohydrates: 30,
                fat: 15,
                fiber: 5,
                sugar: 8,
                sodium: 200,
                cholesterol: 50,
                vitaminA: 100,
                vitaminC: 20,
                calcium: 150,
                iron: 3,
              ),
              ingredients: ["有機蔬菜", "全穀物", "植物蛋白"],
              allergens: ["麩質 / Gluten", "大豆 / Soy"],
              imageUrl:
                  entry.imageUrls.isNotEmpty ? entry.imageUrls.first : null,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // 多張食物圖片輪播
            _buildImageCarousel(entry.imageUrls),

            // 食物資訊
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.mealType,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${entry.calories} kcal',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          entry.servingInfo,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 建構圖片輪播組件
  Widget _buildImageCarousel(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return _buildPlaceholderImage();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          // 圖片輪播
          SizedBox(
            height: 200,
            width: double.infinity,
            child: PageView.builder(
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                );
              },
            ),
          ),

          // 頁面指示器
          if (imageUrls.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 建構佔位圖片
  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Icon(
        Icons.restaurant,
        size: 64,
        color: Colors.grey,
      ),
    );
  }
}

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
            // 食物圖片
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

            // 食物名稱
            _buildInfoSection(
              '食物名稱 / Food Name',
              foodName,
            ),

            // 份量
            _buildInfoSection(
              '份量 / Serving Size (g)',
              '${servingSize}g',
            ),

            // 營養素資訊
            _buildNutritionSection(),

            // 食材來源/烹調方式
            _buildInfoSection(
              '食材來源/烹調方式 / Ingredients & Preparation',
              ingredients.join(', '),
            ),

            // 過敏原
            _buildAllergensSection(),

            // 營養師評估/建議
            _buildInfoSection(
              '營養師評估/建議 / Dietitian\'s Assessment/Recommendations',
              '', // 空白區域，可以根據需要填入內容
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
          // 營養素網格
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 16,
            children: [
              _buildNutritionItem(
                  '卡路里 / Calories', '${nutritionInfo.calories}卡路里'),
              _buildNutritionItem('蛋白質 / Protein', '${nutritionInfo.protein}克'),
              _buildNutritionItem(
                  '碳水化合物 / Carbohydrates', '${nutritionInfo.carbohydrates}克'),
              _buildNutritionItem('脂肪 / Fat', '${nutritionInfo.fat}克'),
              _buildNutritionItem(
                  '膳食纖維 / Dietary Fiber', '${nutritionInfo.fiber}克'),
              _buildNutritionItem('糖 / Sugar', '${nutritionInfo.sugar}克'),
              _buildNutritionItem('鈉 / Sodium', '${nutritionInfo.sodium}毫克'),
              _buildNutritionItem(
                  '膽固醇 / Cholesterol', '${nutritionInfo.cholesterol}毫克'),
              _buildNutritionItem(
                  '維生素A / Vitamin A', '${nutritionInfo.vitaminA}微克'),
              _buildNutritionItem(
                  '維生素C / Vitamin C', '${nutritionInfo.vitaminC}毫克'),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
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

// 營養資訊數據類
class NutritionInfo {
  final int calories;
  final int protein;
  final int carbohydrates;
  final int fat;
  final int fiber;
  final int sugar;
  final int sodium;
  final int cholesterol;
  final int vitaminA;
  final int vitaminC;
  final int calcium;
  final int iron;

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.cholesterol,
    required this.vitaminA,
    required this.vitaminC,
    required this.calcium,
    required this.iron,
  });
}

// 使用範例
class ExampleUsage extends StatelessWidget {
  const ExampleUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return NutritionDetailPage(
      foodName: "健康蔬食碗",
      servingSize: 250,
      nutritionInfo: NutritionInfo(
        calories: 350,
        protein: 25,
        carbohydrates: 15,
        fat: 20,
        fiber: 5,
        sugar: 5,
        sodium: 200,
        cholesterol: 50,
        vitaminA: 100,
        vitaminC: 15,
        calcium: 100,
        iron: 2,
      ),
      ingredients: ["有機蔬菜", "全穀物", "植物蛋白", "橄欖油"],
      allergens: [
        "花生 / Peanuts",
        "牛奶 / Milk",
        "蛋 / Eggs",
        "麩質 / Gluten",
        "大豆 / Soy",
        "堅果 / Tree Nuts",
        "魚 / Fish",
        "甲殼類 / Shellfish"
      ],
      imageUrl: "https://example.com/food-image.jpg",
    );
  }
}
// ----- [pages/diary/food_diary_page.dart] 結束 -----