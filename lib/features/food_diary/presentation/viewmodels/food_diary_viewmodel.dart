/// ==========================================================================
/// @檔案: food_diary_viewmodel.dart
/// @描述: 飲食日記功能的視圖模型 (ViewModel)。
///        使用 ChangeNotifier 來管理 UI 狀態並通知更新。
/// ==========================================================================
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/entities/food_entry.dart';
import '../../domain/usecases/get_food_entries_usecase.dart';
import '../../domain/usecases/add_food_entry_usecase.dart';

/// --------------------------------------------------------------------
/// @類別: FoodDiaryViewModel
/// @描述: 繼承自 ChangeNotifier，用於管理飲食日記頁面的狀態。
///        它封裝了 UI 狀態、處理用戶輸入，並透過呼叫 UseCase 來執行業務邏輯。
/// --------------------------------------------------------------------
class FoodDiaryViewModel extends ChangeNotifier {
  // --- 區塊: 依賴 (Dependencies) ---
  /// [_getFoodEntriesUseCase]: 獲取飲食日記列表的用例。
  final GetFoodEntriesUseCase _getFoodEntriesUseCase;
  /// [_addFoodEntryUseCase]: 新增一筆飲食日記的用例。
  final AddFoodEntryUseCase _addFoodEntryUseCase;

  // --- 區塊: 建構子 (Constructor) ---
  /// @描述: 透過建構子注入所需的 UseCase。
  ///        同時，初始化日期選擇器所需的控制器 (Controller)。
  FoodDiaryViewModel(this._getFoodEntriesUseCase, this._addFoodEntryUseCase) {
    // 初始化日期選擇器的天數列表
    _updateDaysInMonth();
    // 設定滾輪選擇器的初始位置為當前日期
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

  // --- 區塊: 狀態屬性 (State Properties) ---
  // 這些是 UI 需要監聽並據此更新畫面的狀態。
  // 通常將它們設為私有(`_`)，並提供公開的 getter。

  /// [_selectedDate]: 當前選擇的日期。
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  /// [_foodEntries]: 當前選擇日期的飲食日記列表。
  List<FoodEntry> _foodEntries = [];
  List<FoodEntry> get foodEntries => _foodEntries;

  /// [_isLoading]: 表示當前是否正在從伺服器獲取資料。
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- 區塊: 內部狀態管理方法 ---

  /// @方法: _setLoading
  /// @描述: 一個私有的輔助方法，用於更新載入狀態並通知 UI 重建。
  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners(); // 通知所有監聽者狀態已改變，觸發 UI 重建。
  }

  // --- 區塊: 公開方法 (給 UI 呼叫) ---

  /// ------------------------------------------------------------------
  /// @方法: fetchFoodEntries
  /// @描述: 根據當前選擇的日期，異步獲取飲食日記列表。
  /// ------------------------------------------------------------------
  /// ------------------------------------------------------------------
  /// @方法: fetchFoodEntries
  /// @描述: 根據當前選擇的日期，異步獲取飲食日記列表。
  /// ------------------------------------------------------------------
  Future<void> fetchFoodEntries() async {
    // 步驟 1: 打印日誌，標示開始獲取資料。
    print('Fetching food entries for: $selectedDate');
    // 步驟 2: 設定為載入中狀態，並通知 UI 更新 (例如顯示讀取圈)。
    _setLoading(true);
    // 步驟 3: 呼叫 UseCase 來執行獲取資料的業務邏輯。
    final entries = await _getFoodEntriesUseCase(selectedDate);
    print('Fetched entries: $entries');
    // 步驟 4: 將獲取到的資料更新到 ViewModel 的狀態中。
    _foodEntries = entries;
    print('Food entries: $_foodEntries');
    // 步驟 5: 設定為非載入中狀態，並通知 UI 更新 (例如隱藏讀取圈)。
    _setLoading(false);
  }

  /// ------------------------------------------------------------------
  /// @方法: setSelectedDate
  /// @描述: 設定新的日期，並觸發日記列表的重新獲取。
  /// ------------------------------------------------------------------
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners(); // 立即更新 UI 以顯示新日期
    fetchFoodEntries(); // 獲取新日期的資料
  }

  // --- 區塊: 生命週期管理 ---

  /// @覆寫: dispose
  /// @描述: 當 ViewModel 不再被使用時 (例如頁面被銷毀)，釋放所持有的資源。
  ///        這對於防止記憶體洩漏至關重要。
  @override
  void dispose() {
    yearController.dispose();
    monthController.dispose();
    dayController.dispose();
    super.dispose(); // 最後必須呼叫父類別的 dispose
  }

  // --- 區塊: 計算屬性 (Computed Properties) ---

  /// @屬性: totalCalories
  /// @描述: 動態計算當前日記列表的總卡路里。
  int get totalCalories {
    // 使用 fold 方法來累加所有條目的卡路里
    return _foodEntries.fold(0, (sum, entry) => sum + entry.calories);
  }

  // --- 區塊: 日期選擇器邏輯 (Date Picker Logic) ---
  // 這部分處理自訂日期滾輪選擇器的狀態和邏輯。

  late FixedExtentScrollController yearController;
  late FixedExtentScrollController monthController;
  late FixedExtentScrollController dayController;

  List<int> years = List.generate(10, (index) => DateTime.now().year - 5 + index);
  List<int> months = List.generate(12, (index) => index + 1);
  late List<int> days;

  /// @方法: _updateDaysInMonth
  /// @描述: 根據當前選擇的年份和月份，更新 `days` 列表的內容。
  void _updateDaysInMonth() {
    int daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    days = List.generate(daysInMonth, (index) => index + 1);
  }

  /// @方法: onYearChanged
  /// @描述: 當年份滾輪變化時呼叫，更新日期。
  void onYearChanged(int index) {
    final newYear = years[index];
    // 處理閏年或大小月切換時，日期可能超出範圍的問題
    final newDay = math.min(selectedDate.day, DateTime(newYear, selectedDate.month + 1, 0).day);
    final newDate = DateTime(newYear, selectedDate.month, newDay);
    
    _updateDaysInMonth();
    // 如果滾動後的天數超出範圍，自動跳到最後一天
    if (newDate.day > days.length) {
      dayController.jumpToItem(days.length - 1);
    }
    setSelectedDate(newDate);
  }

  /// @方法: onMonthChanged
  /// @描述: 當月份滾輪變化時呼叫，更新日期。
  void onMonthChanged(int index) {
    final newMonth = months[index];
    final newDay = math.min(selectedDate.day, DateTime(selectedDate.year, newMonth + 1, 0).day);
    final newDate = DateTime(selectedDate.year, newMonth, newDay);

    _updateDaysInMonth();
    if (newDate.day > days.length) {
      dayController.jumpToItem(days.length - 1);
    }
    setSelectedDate(newDate);
  }

  /// @方法: onDayChanged
  /// @描述: 當天數滾輪變化時呼叫，更新日期。
  void onDayChanged(int index) {
    final newDate = DateTime(selectedDate.year, selectedDate.month, days[index]);
    setSelectedDate(newDate);
  }

  // --- 區塊: 測試專用方法 ---

  /// ------------------------------------------------------------------
  /// @方法: addTestData
  /// @描述: (僅供開發測試用) 添加一些預設的食物資料到 Firebase。
  /// ------------------------------------------------------------------
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
