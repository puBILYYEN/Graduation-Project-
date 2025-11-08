import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/entities/food_entry.dart';
import '../../domain/usecases/get_food_entries_usecase.dart';
import '../../domain/usecases/add_food_entry_usecase.dart';

class FoodDiaryViewModel extends ChangeNotifier {
  final GetFoodEntriesUseCase _getFoodEntriesUseCase;
  final AddFoodEntryUseCase _addFoodEntryUseCase;

  FoodDiaryViewModel(this._getFoodEntriesUseCase, this._addFoodEntryUseCase) {
    _updateDaysInMonth();
    yearController = FixedExtentScrollController(
      initialItem: years.indexOf(selectedDate.year),
    );
    monthController = FixedExtentScrollController(
      initialItem: selectedDate.month - 1,
    );
    dayController = FixedExtentScrollController(
      initialItem: selectedDate.day - 1,
    );
  }

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  List<FoodEntry> _foodEntries = [];
  List<FoodEntry> get foodEntries => _foodEntries;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  Future<void> fetchFoodEntries() async {
    print('Fetching food entries for: $selectedDate');
    _setLoading(true);
    final entries = await _getFoodEntriesUseCase(selectedDate);
    print('Fetched entries: $entries');
    _foodEntries = entries;
    print('Food entries: $_foodEntries');
    _setLoading(false);
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    fetchFoodEntries();
  }

  @override
  void dispose() {
    yearController.dispose();
    monthController.dispose();
    dayController.dispose();
    super.dispose();
  }

  int get totalCalories {
    return _foodEntries.fold(0, (sum, entry) => sum + entry.calories);
  }

  // Date picker logic
  late FixedExtentScrollController yearController;
  late FixedExtentScrollController monthController;
  late FixedExtentScrollController dayController;

  List<int> years = List.generate(10, (index) => DateTime.now().year - 5 + index);
  List<int> months = List.generate(12, (index) => index + 1);
  late List<int> days;



  void _updateDaysInMonth() {
    int daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    days = List.generate(daysInMonth, (index) => index + 1);
  }

  void onYearChanged(int index) {
    final newDate = DateTime(
      years[index],
      selectedDate.month,
      math.min(selectedDate.day, DateTime(years[index], selectedDate.month + 1, 0).day),
    );
    _updateDaysInMonth();
    if (newDate.day > days.length) {
      dayController.jumpToItem(days.length - 1);
    }
    setSelectedDate(newDate);
  }

  void onMonthChanged(int index) {
    final newDate = DateTime(
      selectedDate.year,
      months[index],
      math.min(selectedDate.day, DateTime(selectedDate.year, months[index] + 1, 0).day),
    );
    _updateDaysInMonth();
    if (newDate.day > days.length) {
      dayController.jumpToItem(days.length - 1);
    }
    setSelectedDate(newDate);
  }

  void onDayChanged(int index) {
    final newDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      days[index],
    );
    setSelectedDate(newDate);
  }

  /// 添加測試資料到 Firebase
  Future<void> addTestData() async {
    try {
      _setLoading(true);

      // 測試資料1: 烤鮭魚
      final salmon = FoodEntry(
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
      );

      // 測試資料2: 希臘沙拉
      final salad = FoodEntry(
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
      );

      // 添加到 Firebase
      await _addFoodEntryUseCase(salmon);
      print('✓ 已添加測試資料：烤鮭魚');

      await _addFoodEntryUseCase(salad);
      print('✓ 已添加測試資料：希臘沙拉');

      // 重新載入資料
      await fetchFoodEntries();

      _setLoading(false);
      print('✓ 測試資料添加完成！');
    } catch (e) {
      _setLoading(false);
      print('✗ 添加測試資料失敗: $e');
      rethrow;
    }
  }
}
