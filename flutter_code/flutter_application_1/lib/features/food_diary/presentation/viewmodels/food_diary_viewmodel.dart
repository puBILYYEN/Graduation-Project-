import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/entities/food_entry.dart';
import '../../domain/usecases/get_food_entries_usecase.dart';
import '../../domain/usecases/add_food_entry_usecase.dart';

class FoodDiaryViewModel extends ChangeNotifier {
  final GetFoodEntriesUseCase _getFoodEntriesUseCase;
  final AddFoodEntryUseCase _addFoodEntryUseCase;

  FoodDiaryViewModel(this._getFoodEntriesUseCase, this._addFoodEntryUseCase);

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
    _setLoading(true);
    _foodEntries = await _getFoodEntriesUseCase(selectedDate);
    _setLoading(false);
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    fetchFoodEntries();
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

  void initDatePickers() {
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

  void disposeDatePickers() {
    yearController.dispose();
    monthController.dispose();
    dayController.dispose();
  }

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
}
