import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Added
import 'package:flutter/services.dart'; // Added
import 'package:provider/provider.dart';

import '../viewmodels/food_diary_viewmodel.dart';
import '../../domain/usecases/get_food_entries_usecase.dart';
import '../../domain/usecases/add_food_entry_usecase.dart';
import '../../domain/entities/food_entry.dart';
import '../../../nutrition/presentation/pages/nutrition_detail_page.dart';
import '../../../nutrition/domain/entities/nutrition_info.dart';

class FoodDiaryPage extends StatelessWidget {
  const FoodDiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = FoodDiaryViewModel(
          context.read<GetFoodEntriesUseCase>(),
          context.read<AddFoodEntryUseCase>(),
        );
        viewModel.fetchFoodEntries(); // Call fetchFoodEntries on the viewModel instance
        return viewModel;
      },
      child: const FoodDiaryPageContent(),
    );
  }
}

class FoodDiaryPageContent extends StatefulWidget {
  const FoodDiaryPageContent({super.key});

  @override
  State<FoodDiaryPageContent> createState() => _FoodDiaryPageContentState();
}

class _FoodDiaryPageContentState extends State<FoodDiaryPageContent> {


  @override
  Widget build(BuildContext context) {
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
          '飲食記錄',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<FoodDiaryViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              _buildDateSelector(viewModel),
              _buildSelectedDate(viewModel),
              Expanded(
                child: viewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildFoodList(viewModel),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateSelector(FoodDiaryViewModel viewModel) {
    return Container(
      color: Colors.white,
      height: 200,
      child: Row(
        children: [
          _buildDatePicker(viewModel.yearController, viewModel.years, viewModel.onYearChanged, '年'),
          _buildDatePicker(viewModel.monthController, viewModel.months, viewModel.onMonthChanged, '月'),
          _buildDatePicker(viewModel.dayController, viewModel.days, viewModel.onDayChanged, '日'),
        ],
      ),
    );
  }

  Widget _buildDatePicker(FixedExtentScrollController controller, List<int> items, ValueChanged<int> onSelectedItemChanged, String label) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: controller,
              itemExtent: 40,
              onSelectedItemChanged: onSelectedItemChanged,
              children: items.map((item) => Center(child: Text(item.toString(), style: const TextStyle(fontSize: 18)))).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekday(DateTime date) {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return '週${weekdays[date.weekday % 7]}';
  }

  Widget _buildSelectedDate(FoodDiaryViewModel viewModel) {
    String formattedDate = '${viewModel.selectedDate.year}年${viewModel.selectedDate.month}月${viewModel.selectedDate.day}日';

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
            '${_getWeekday(viewModel.selectedDate)} • ${viewModel.totalCalories} kcal',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(FoodDiaryViewModel viewModel) {
    if (viewModel.foodEntries.isEmpty) {
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
      itemCount: viewModel.foodEntries.length,
      itemBuilder: (context, index) {
        return _buildFoodCard(context, viewModel.foodEntries[index]);
      },
    );
  }

  Widget _buildFoodCard(BuildContext context, FoodEntry entry) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NutritionDetailPage(
              foodName: entry.name,
              servingSize: 250, // This should come from the entry itself in a real app
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
              imageUrl: entry.imageUrls.isNotEmpty ? entry.imageUrls.first : null,
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
            _buildImageCarousel(entry.imageUrls),
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

  Widget _buildImageCarousel(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return _buildPlaceholderImage();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
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