/// ==========================================================================
/// @檔案: add_food_entry_usecase.dart
/// @描述: 負責「新增一筆飲食日記」這個特定業務邏輯的用例 (Use Case)。
/// ==========================================================================
import '../entities/food_entry.dart';
import '../repositories/food_diary_repository.dart';

/// --------------------------------------------------------------------
/// @類別: AddFoodEntryUseCase
/// @描述: 封裝了新增飲食日記條目的單一功能。
///        在 Clean Architecture 中，Use Case 是連接 Presentation 層 (如 ViewModel)
///        和 Domain/Data 層 (Repository) 的橋樑，它代表了一個獨立的業務操作。
/// --------------------------------------------------------------------
class AddFoodEntryUseCase {
  // --- 區塊: 屬性 (Properties) ---
  /// [repository]: FoodDiaryRepository 的抽象介面。
  /// Use Case 不依賴於具體的 Repository 實作 (例如是從網路還是本地資料庫獲取)，
  /// 而是依賴於抽象介面，這符合依賴反轉原則。
  final FoodDiaryRepository repository;

  // --- 區塊: 建構子 (Constructor) ---
  /// @描述: 透過建構子注入 Repository，讓測試時可以輕易地傳入 mock 的 Repository，
  ///        從而實現對此 Use Case 的獨立單元測試。
  AddFoodEntryUseCase(this.repository);

  // --- 區塊: 執行方法 (Execute Method) ---
  /// ------------------------------------------------------------------
  /// @方法: call
  /// @描述: 執行此用例的核心邏輯。
  ///        在 Dart 中，將核心方法命名為 `call` 是一個常見慣例，
  ///        它讓類別的實例可以像函式一樣被直接呼叫。
  ///        例如: `addFoodEntryUseCase(myEntry)` 而不是 `addFoodEntryUseCase.execute(myEntry)`。
  /// @參數: [entry] - 要新增的 FoodEntry 實體，由上層 (ViewModel) 傳入。
  /// @返回: Future<void> - 一個表示操作完成的 Future。
  /// ------------------------------------------------------------------
  Future<void> call(FoodEntry entry) {
    // 將操作直接委派給 repository 的 addFoodEntry 方法。
    // 在更複雜的 Use Case 中，這裡可能會包含更多的業務邏輯，
    // 例如資料驗證、組合多個 repository 的呼叫、錯誤處理等。
    return repository.addFoodEntry(entry);
  }
}
