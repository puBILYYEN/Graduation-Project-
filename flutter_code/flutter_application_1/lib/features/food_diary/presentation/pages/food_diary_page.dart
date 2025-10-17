import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../../data/models/health_models.dart';

// ====================================================================
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

// ====================================================================
// 營養詳情頁面 (Nutrition Detail Page)
// ====================================================================
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

            // 食物名稱和份量
            Text(
              foodName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '份量: ${servingSize}g',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // 營養成分標題
            const Text(
              '營養成分',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 營養成分資訊卡片
            _buildNutritionCard(),
            const SizedBox(height: 24),

            // 成分標題
            const Text(
              '主要成分',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 成分列表
            _buildIngredientsList(),
            const SizedBox(height: 24),

            // 過敏原標題
            const Text(
              '過敏原資訊',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 過敏原列表
            _buildAllergensList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard() {
    return Container(
      width: double.infinity,
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
        children: [
          _buildNutritionRow('熱量', '${nutritionInfo.calories}', 'kcal'),
          const Divider(height: 16),
          _buildNutritionRow('蛋白質', '${nutritionInfo.protein}', 'g'),
          const Divider(height: 16),
          _buildNutritionRow('碳水化合物', '${nutritionInfo.carbohydrates}', 'g'),
          const Divider(height: 16),
          _buildNutritionRow('脂肪', '${nutritionInfo.fat}', 'g'),
          const Divider(height: 16),
          _buildNutritionRow('纖維', '${nutritionInfo.fiber}', 'g'),
          const Divider(height: 16),
          _buildNutritionRow('糖分', '${nutritionInfo.sugar}', 'g'),
          const Divider(height: 16),
          _buildNutritionRow('鈉', '${nutritionInfo.sodium}', 'mg'),
          const Divider(height: 16),
          _buildNutritionRow('膽固醇', '${nutritionInfo.cholesterol}', 'mg'),
          const Divider(height: 16),
          _buildNutritionRow('維生素A', '${nutritionInfo.vitaminA}', 'IU'),
          const Divider(height: 16),
          _buildNutritionRow('維生素C', '${nutritionInfo.vitaminC}', 'mg'),
          const Divider(height: 16),
          _buildNutritionRow('鈣', '${nutritionInfo.calcium}', 'mg'),
          const Divider(height: 16),
          _buildNutritionRow('鐵', '${nutritionInfo.iron}', 'mg'),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Text(
          '$value $unit',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsList() {
    return Container(
      width: double.infinity,
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
        children: ingredients.map((ingredient) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B9A7A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  ingredient,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAllergensList() {
    return Container(
      width: double.infinity,
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
        children: allergens.map((allergen) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    allergen,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}