# flutter_application_2

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
 Flutter 模組化重構 - 完整決策邏輯版本

  決策樹總覽

  開始重構
      ↓
  檢查專案狀態 → [已模組化?] → Yes → 跳至修復流程
      ↓ No
  確定拆分策略 → [依賴分析] → 建立拆分順序
      ↓
  執行拆分 → [遇到錯誤?] → Yes → 錯誤決策樹
      ↓ No
  驗證功能 → [測試通過?] → No → 回滾
      ↓ Yes
  完成dering… (esc to interrupt · 11s · ↓ 75 tokens)
  ⎿  Tip: Start with small features or bug fixes, tell Claude to propose a plan, and verify its suggested edits
  ---
  一、前置決策：專案狀態判定───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
> 
  決策點 1.1：是否需要重構？───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  ⏵⏵ accept edits on (shift+tab to cycle)
  檢查條件：
  ├─ lib/main.dart 行數 > 3000？
  │  ├─ Yes → 需要重構
  │  └─ No → 檢查下一條件
  ├─ lib/ 下是否已有 features/ 或 data/ 資料夾？
  │  ├─ Yes → 已部分模組化，跳至「繼續重構決策」
  │  └─ No → 需要重構
  └─ 是否存在 main.dart.backup？
     ├─ Yes → 可能之前重構失敗，跳至「失敗恢復決策」
     └─ No → 開始新重構

  執行動作：
  # 判定腳本
  LINES=$(wc -l < lib/main.dart)
  if [ $LINES -gt 3000 ]; then
      echo "需要重構：main.dart 過大 ($LINES 行)"
      ACTION="START_REFACTOR"
  elif [ -d "lib/features" ] || [ -d "lib/data" ]; then
      echo "檢測到部分模組化"
      ACTION="CONTINUE_REFACTOR"
  else
      echo "專案結構良好，無需重構"
      ACTION="SKIP"
  fi

  決策點 1.2：繼續重構 vs 從頭開始

  如果 lib/features/ 已存在：
  ├─ 檢查 lib/features/ 下的模組數量
  │  ├─ < 3 個 → 可能是測試性拆分，詢問：「是否清空重來？」
  │  │  ├─ Yes → 刪除 lib/features, lib/data, lib/core
  │  │  └─ No → 分析現有模組，從缺失部分繼續
  │  └─ >= 3 個 → 分析現有模組完整性
  │     ├─ 缺少 data/models → 從階段 1 開始
  │     ├─ 缺少 data/services → 從階段 2 開始
  │     ├─ 缺少 core → 從階段 3 開始
  │     └─ 缺少特定 feature → 從對應階段開始
  └─ 檢查 main.dart 是否仍包含被拆分的程式碼
     ├─ 是 → 程式碼重複，決定保留哪一份
     └─ 否 → 正常繼續

  執行動作：
  # 模組完整性檢查
  check_module_integrity() {
      MODELS=$(find lib/data/models -name "*.dart" 2>/dev/null | wc -l)
      SERVICES=$(find lib/data/services -name "*.dart" 2>/dev/null | wc -l)
      FEATURES=$(find lib/features -name "*.dart" 2>/dev/null | wc -l)

      if [ $MODELS -lt 3 ]; then
          echo "階段 1 未完成：資料模型缺失"
          START_STAGE=1
      elif [ $SERVICES -lt 3 ]; then
          echo "階段 2 未完成：服務層缺失"
          START_STAGE=2
      elif [ $FEATURES -lt 4 ]; then
          echo "階段 4-5 未完成：功能模組缺失"
          START_STAGE=4
      else
          echo "主要模組已完成，進入工具層拆分"
          START_STAGE=6
      fi
  }

  ---
  二、拆分決策：程式碼定位與提取

  決策點 2.1：如何找到要拆分的類別？

  對於每個目標類別（如 BodyMetrics）：
  ├─ 步驟 1：精確搜尋類別定義
  │  └─ 指令: grep -n "^class BodyMetrics" lib/main.dart
  │     ├─ 找到 1 個結果 → 記錄行號，繼續
  │     ├─ 找到 >1 個結果 → 錯誤：重複定義，需人工檢查
  │     └─ 找到 0 個結果 → 嘗試模糊搜尋
  │        └─ 指令: grep -n "class.*BodyMetrics" lib/main.dart
  │           ├─ 找到 → 可能有前綴空格，繼續
  │           └─ 未找到 → 決策：該類別可能已被拆分或不存在
  │              ├─ 檢查是否在其他檔案: grep -r "class BodyMetrics" lib/
  │              │  ├─ 找到 → 跳過此類別
  │              │  └─ 未找到 → 警告：規劃中的類別不存在
  │              └─ 詢問：「BodyMetrics 類別不存在，是否繼續？」
  ├─ 步驟 2：確定類別結束位置
  │  └─ 方法：找到下一個 top-level 定義（class/enum/function）
  │     └─ 指令: awk '/^class BodyMetrics/,/^(class|enum|void|Future|[A-Z])/ {print NR": "$0}' lib/main.dart
  ├─ 步驟 3：檢查依賴關係
  │  └─ 類別內是否引用其他自定義類別？
  │     ├─ 例如：BodyMetrics 使用 NutrientData
  │     │  └─ 決策：NutrientData 必須先被拆分或同時拆分
  │     └─ 例如：使用 Flutter 內建類別（Color, TextStyle）
  │        └─ 決策：需要在新檔案 import 'package:flutter/material.dart'
  └─ 步驟 4：提取完整程式碼
     └─ 指令: sed -n '起始行,結束行p' lib/main.dart > 目標檔案

  決策流程圖：
  開始提取類別
      ↓
  搜尋類別定義
      ↓
  [找到幾個?]
  ├─ 0 個 → [已在其他檔案?] → Yes → 跳過
  │                        → No → 警告並詢問
  ├─ 1 個 → 繼續
  └─ >1 個 → 錯誤：重複定義
      ↓
  確定範圍（起始行~結束行）
      ↓
  [類別內有自定義類別引用?]
  ├─ Yes → [依賴類別已拆分?] → No → 先拆分依賴
  │                          → Yes → 繼續
  └─ No → 繼續
      ↓
  提取程式碼到新檔案
      ↓
  添加必要的 imports
      ↓
  完成

  決策點 2.2：Import 語句如何決定？

  對於新建的模組檔案，需要哪些 imports？

  決策規則：
  ├─ 規則 1：檢查程式碼中的 Flutter/Dart 類別使用
  │  ├─ 使用 Widget, State, StatefulWidget, StatelessWidget, BuildContext?
  │  │  → import 'package:flutter/material.dart';
  │  ├─ 使用 CupertinoXxx?
  │  │  → import 'package:flutter/cupertino.dart';
  │  ├─ 使用 SystemChrome, DeviceOrientation?
  │  │  → import 'package:flutter/services.dart';
  │  └─ 使用 math.sqrt, math.pi?
  │     → import 'dart:math' as math;
  │
  ├─ 規則 2：檢查第三方套件類別使用
  │  ├─ 使用 CameraController, CameraDescription?
  │  │  → import 'package:camera/camera.dart';
  │  ├─ 使用 GoogleSignIn?
  │  │  → import 'package:google_sign_in/google_sign_in.dart';
  │  └─ 使用 FirebaseFirestore, CollectionReference?
  │     → import 'package:cloud_firestore/cloud_firestore.dart';
  │
  ├─ 規則 3：檢查專案內自定義類別引用
  │  ├─ 引用同層級模組？
  │  │  └─ import '相對路徑.dart';  // 如 import 'measurement.dart';
  │  ├─ 引用上層模組？
  │  │  └─ import '../路徑.dart';   // 如 import '../models/nutrition.dart';
  │  └─ 引用跨層級模組？
  │     └─ import '../../路徑.dart'; // 如 import '../../data/models/nutrition.dart';
  │
  └─ 規則 4：循環依賴檢測
     └─ A imports B, B imports A？
        ├─ 檢測方法：建立依賴圖
        └─ 解決方案：
           ├─ 方案 1：提取共用部分到新檔案
           ├─ 方案 2：使用 part/part of（不推薦）
           └─ 方案 3：重新設計模組邊界

  Import 自動生成演算法：
  List<String> generateImports(String sourceCode, String modulePath) {
    Set<String> imports = {};

    // 規則 1：Flutter 核心
    if (sourceCode.contains(RegExp(r'\b(Widget|State|BuildContext|Scaffold)\b'))) {
      imports.add("import 'package:flutter/material.dart';");
    }

    // 規則 2：特定 Flutter 套件
    Map<RegExp, String> flutterPackages = {
      RegExp(r'\bSystemChrome\b'): "import 'package:flutter/services.dart';",
      RegExp(r'\bCupertino'): "import 'package:flutter/cupertino.dart';",
    };
    flutterPackages.forEach((pattern, import) {
      if (sourceCode.contains(pattern)) imports.add(import);
    });

    // 規則 3：第三方套件（從 pubspec.yaml 讀取）
    Map<String, String> thirdPartyClasses = {
      'CameraController': "import 'package:camera/camera.dart';",
      'GoogleSignIn': "import 'package:google_sign_in/google_sign_in.dart';",
      // ... 從 pubspec.yaml 自動生成
    };
    thirdPartyClasses.forEach((className, import) {
      if (sourceCode.contains(RegExp('\\b$className\\b'))) imports.add(import);
    });

    // 規則 4：專案內模組（從已建立的模組推斷）
    List<String> existingModules = findAllModules('lib/');
    for (var module in existingModules) {
      String className = extractClassName(module);
      if (sourceCode.contains(RegExp('\\b$className\\b'))) {
        String relativePath = calculateRelativePath(modulePath, module);
        imports.add("import '$relativePath';");
      }
    }

    return imports.toList()..sort();
  }

  決策點 2.3：程式碼提取範圍如何確定？

  問題：一個類別的完整範圍包含哪些部分？

  決策樹：
  ├─ 主類別定義（必須）
  │  └─ class XXX extends/implements YYY { ... }
  ├─ 相關的 enum（條件）
  │  ├─ enum 在類別內部？→ 必須包含
  │  ├─ enum 在類別外部但只被該類別使用？→ 應該包含
  │  └─ enum 被多個類別使用？→ 應提取到獨立檔案
  ├─ 相關的 typedef（條件）
  │  └─ 判定規則同 enum
  ├─ 相關的全域函數（條件）
  │  ├─ 函數名以 _ 開頭（私有）且只被該類別調用？→ 應該包含
  │  └─ 公開函數被多處調用？→ 應提取到 utils/
  ├─ 相關的常數（條件）
  │  ├─ const 定義在類別內部（static const）？→ 必須包含
  │  └─ const 定義在檔案頂層？
  │     ├─ 只被該類別使用？→ 應該包含
  │     └─ 被多處使用？→ 應提取到 constants.dart
  └─ 內部類別（必須）
     └─ class _XXXState, class XXXData 等

  範圍確定演算法：
  def determine_extraction_range(main_class_name, source_file):
      """
      確定提取範圍的演算法
      """
      # 步驟 1：找到主類別位置
      main_class_start = find_line(f"class {main_class_name}")
      main_class_end = find_matching_brace(main_class_start)

      # 步驟 2：向上搜尋相關定義
      search_start = main_class_start
      while search_start > 0:
          search_start -= 1
          line = get_line(search_start)

          # 遇到其他 top-level 定義，停止
          if line.startswith(('class ', 'enum ', 'void ', 'Future ', 'typedef ')):
              if is_used_only_by(line, main_class_name):
                  continue  # 繼續向上，包含此定義
              else:
                  search_start += 1
                  break  # 停止，不包含此定義

          # 遇到 import/export，停止
          if line.startswith(('import ', 'export ', 'part ')):
              search_start += 1
              break

      # 步驟 3：向下搜尋相關定義
      search_end = main_class_end
      while search_end < total_lines():
          search_end += 1
          line = get_line(search_end)

          # 檢查是否是內部類別（如 _XXXState）
          if line.startswith('class ') and main_class_name in line:
              inner_class_end = find_matching_brace(search_end)
              search_end = inner_class_end
              continue

          # 遇到無關的 top-level 定義，停止
          if line.startswith(('class ', 'enum ', 'void ', 'Future ')):
              search_end -= 1
              break

      return (search_start, search_end)


  def is_used_only_by(definition_line, target_class):
      """
      判斷某個定義是否只被目標類別使用
      """
      # 提取定義的名稱
      name = extract_name(definition_line)

      # 搜尋所有引用
      references = find_all_references(name)

      # 檢查引用是否都在目標類別內
      for ref in references:
          if not is_inside_class(ref, target_class):
              return False

      return True

  ---
  三、依賴決策：拆分順序與依賴解析

  決策點 3.1：如何確定拆分順序？

  問題：如果 A 依賴 B，B 依賴 C，應該先拆分誰？

  規則：依賴者必須在被依賴者之後拆分

  建立依賴圖：
  步驟 1：列出所有需要拆分的類別
  步驟 2：分析每個類別的依賴關係
  步驟 3：構建有向圖
  步驟 4：拓撲排序得到拆分順序

  範例：
  類別依賴關係：
  - BodyMetrics: 無依賴（只用 Flutter 內建類別）
  - NutrientData: 依賴 Color（Flutter 內建）
  - FoodEntry: 依賴 NutrientData
  - HomePageContent: 依賴 BodyMetrics, FoodEntry, NutrientData

  拓撲排序結果：
  1. BodyMetrics, NutrientData（無依賴，可平行）
  2. FoodEntry（依賴 NutrientData）
  3. HomePageContent（依賴前面三個）

  決策：先拆分 1，再拆分 2，最後拆分 3

  依賴分析演算法：
  class DependencyAnalyzer:
      def __init__(self, source_file):
          self.classes = self.extract_all_classes(source_file)
          self.dependencies = {}

      def analyze(self):
          """分析所有類別的依賴關係"""
          for cls in self.classes:
              self.dependencies[cls] = self.find_dependencies(cls)

          return self.topological_sort()

      def find_dependencies(self, class_name):
          """找出某個類別依賴的其他類別"""
          class_code = self.get_class_code(class_name)
          dependencies = set()

          # 規則 1：類別繼承
          # class A extends B → A 依賴 B
          extends_match = re.search(r'extends\s+(\w+)', class_code)
          if extends_match:
              parent = extends_match.group(1)
              if parent in self.classes:  # 只記錄專案內的依賴
                  dependencies.add(parent)

          # 規則 2：類別成員變數
          # final SomeClass variable; → 依賴 SomeClass
          for match in re.finditer(r'\b(\w+)\s+\w+;', class_code):
              type_name = match.group(1)
              if type_name in self.classes:
                  dependencies.add(type_name)

          # 規則 3：方法參數和返回值
          # void method(SomeClass param) → 依賴 SomeClass
          for match in re.finditer(r'\b(\w+)\s+\w+\([^)]*\)', class_code):
              return_type = match.group(1)
              if return_type in self.classes:
                  dependencies.add(return_type)

          # 規則 4：泛型參數
          # List<SomeClass> → 依賴 SomeClass
          for match in re.finditer(r'<(\w+)>', class_code):
              generic_type = match.group(1)
              if generic_type in self.classes:
                  dependencies.add(generic_type)

          return dependencies

      def topological_sort(self):
          """拓撲排序，返回拆分順序"""
          # Kahn's Algorithm
          in_degree = {cls: 0 for cls in self.classes}

          # 計算入度
          for cls in self.classes:
              for dep in self.dependencies[cls]:
                  in_degree[dep] += 1

          # 找出入度為 0 的節點（無依賴）
          queue = [cls for cls, degree in in_degree.items() if degree == 0]
          result = []

          while queue:
              # 可以平行處理的類別（同一層級）
              current_level = queue.copy()
              result.append(current_level)
              queue.clear()

              for cls in current_level:
                  # 移除此類別後，更新其他類別的入度
                  for other_cls in self.classes:
                      if cls in self.dependencies[other_cls]:
                          in_degree[other_cls] -= 1
                          if in_degree[other_cls] == 0:
                              queue.append(other_cls)

          # 檢查是否有循環依賴
          if sum(len(level) for level in result) < len(self.classes):
              remaining = [cls for cls in self.classes
                          if cls not in [c for level in result for c in level]]
              raise CircularDependencyError(f"檢測到循環依賴: {remaining}")

          return result

  # 使用範例
  analyzer = DependencyAnalyzer('lib/main.dart')
  split_order = analyzer.analyze()
  # 結果: [
  #   ['BodyMetrics', 'NutrientData'],  # Level 0: 無依賴
  #   ['FoodEntry'],                     # Level 1: 依賴 Level 0
  #   ['HomePageContent']                # Level 2: 依賴 Level 0-1
  # ]

  決策點 3.2：循環依賴如何處理？

  問題：A 依賴 B，B 也依賴 A

  檢測方法：
  └─ 在拓撲排序時，如果無法排序完所有類別 → 存在循環依賴

  解決方案決策樹：
  ├─ 方案 1：分析是否為「假依賴」
  │  └─ 情況：A 的方法返回 B，B 的方法返回 A
  │     └─ 解決：使用 forward declaration（Dart 不支援，跳過）
  │
  ├─ 方案 2：提取共用介面
  │  └─ 步驟：
  │     1. 創建 common/interfaces.dart
  │     2. 定義抽象類別 IAbstractA, IAbstractB
  │     3. A 依賴 IAbstractB, B 依賴 IAbstractA
  │     4. 在上層注入實作
  │
  ├─ 方案 3：合併到同一檔案
  │  └─ 決策：如果 A 和 B 邏輯緊密相關
  │     └─ 將 A 和 B 放在同一個模組檔案中
  │
  └─ 方案 4：重新設計架構（最佳但最費時）
     └─ 步驟：
        1. 分析循環依賴的根本原因
        2. 可能是職責劃分不清
        3. 重新設計類別邊界
        4. 引入中介者模式或觀察者模式

  決策流程：
  檢測到循環依賴
      ↓
  [依賴強度如何?]
  ├─ 弱耦合（僅型別引用）
  │  └─ 採用方案 2（提取介面）
  ├─ 強耦合（互相調用方法）
  │  └─ [類別是否邏輯相關?]
  │     ├─ Yes → 方案 3（合併檔案）
  │     └─ No → 方案 4（重新設計）
  └─ 不確定
     └─ 詢問：「A 和 B 互相依賴，建議合併或重新設計？」

  循環依賴檢測與處理：
  class CircularDependencyResolver {
    Map<String, Set<String>> dependencies;

    List<String> detectCycles() {
      List<String> cycles = [];
      Set<String> visited = {};
      Set<String> recursionStack = {};

      for (var node in dependencies.keys) {
        if (_detectCyclesDFS(node, visited, recursionStack, [], cycles)) {
          // 找到循環
        }
      }

      return cycles;
    }

    bool _detectCyclesDFS(String node, Set<String> visited,
                          Set<String> recStack, List<String> path,
                          List<String> cycles) {
      if (recStack.contains(node)) {
        // 找到循環：path 中從 node 到結尾的部分
        int cycleStart = path.indexOf(node);
        String cycle = path.sublist(cycleStart).join(' -> ') + ' -> $node';
        cycles.add(cycle);
        return true;
      }

      if (visited.contains(node)) {
        return false;
      }

      visited.add(node);
      recStack.add(node);
      path.add(node);

      for (var neighbor in dependencies[node] ?? {}) {
        if (_detectCyclesDFS(neighbor, visited, recStack, path, cycles)) {
          return true;
        }
      }

      recStack.remove(node);
      path.removeLast();
      return false;
    }

    void resolveCycle(String cycle) {
      List<String> nodes = cycle.split(' -> ');

      // 決策：分析耦合程度
      double coupling = analyzeCoupling(nodes);

      if (coupling < 0.3) {
        print("弱耦合，建議提取介面");
        extractInterface(nodes);
      } else if (coupling < 0.7) {
        print("中等耦合，建議合併到同一檔案");
        mergeToSameFile(nodes);
      } else {
        print("強耦合，建議重新設計架構");
        throw ArchitectureRedesignNeeded(
          "類別 ${nodes.join(', ')} 存在強耦合，需要重新設計"
        );
      }
    }

    double analyzeCoupling(List<String> classes) {
      // 計算耦合度：依賴數 / 總可能依賴數
      int actualDeps = 0;
      int possibleDeps = 0;

      for (var cls in classes) {
        for (var other in classes) {
          if (cls != other) {
            possibleDeps++;
            if (dependencies[cls]?.contains(other) ?? false) {
              actualDeps++;
            }
          }
        }
      }

      return possibleDeps > 0 ? actualDeps / possibleDeps : 0;
    }
  }

  ---
  四、錯誤決策：編譯錯誤處理邏輯

  決策點 4.1：如何分類錯誤？

  編譯錯誤分類決策樹：

  錯誤訊息
  ├─ 包含 "Couldn't resolve the package"
  │  └─ 類型：缺少套件依賴 → 跳至決策 4.2
  ├─ 包含 "Unresolved reference" 且來自 Kotlin/Java 檔案
  │  └─ 類型：原生代碼編譯錯誤 → 跳至決策 4.3
  ├─ 包含 "The getter 'XXX' isn't defined"
  │  └─ 類型：Dart 類別或方法未定義 → 跳至決策 4.4
  ├─ 包含 "The method 'XXX' isn't defined for the type"
  │  └─ 類型：API 變更或套件版本不相容 → 跳至決策 4.5
  ├─ 包含 "Circular dependency"
  │  └─ 類型：循環依賴 → 跳至決策 3.2
  ├─ 包含 "Target of URI doesn't exist"
  │  └─ 類型：Import 路徑錯誤 → 跳至決策 4.6
  ├─ 包含 "NDK" 或 "source.properties"
  │  └─ 類型：Android NDK 問題 → 跳至決策 4.7
  └─ 其他
     └─ 類型：未知錯誤 → 跳至決策 4.8

  決策點 4.2：缺少套件依賴

  錯誤: Couldn't resolve the package 'xxx'

  決策流程：
  ├─ 步驟 1：確認套件是否應該存在
  │  └─ 檢查: grep "package:xxx" lib/ -r
  │     ├─ 有引用 → 確實需要此套件
  │     └─ 無引用 → 可能是殘留 import
  │        └─ 決策：註解掉該 import
  │
  ├─ 步驟 2：檢查 pubspec.yaml
  │  └─ 套件是否已列在 dependencies？
  │     ├─ Yes → 跳至步驟 4
  │     └─ No → 繼續步驟 3
  │
  ├─ 步驟 3：決定套件版本
  │  └─ 查詢策略：
  │     ├─ 方法 A：pub.dev 搜尋最新穩定版
  │     │  └─ 指令: curl https://pub.dev/api/packages/xxx
  │     ├─ 方法 B：查看其他類似專案使用的版本
  │     └─ 方法 C：使用 Flutter 建議的版本
  │        └─ 指令: flutter pub add xxx
  │           ├─ 成功 → 自動添加到 pubspec.yaml
  │           └─ 失敗 → 套件不存在或名稱錯誤
  │              └─ 決策：尋找替代套件
  │
  ├─ 步驟 4：執行 pub get
  │  └─ 指令: flutter pub get
  │     ├─ 成功 → 問題解決
  │     └─ 失敗 → 分析失敗原因
  │        ├─ 版本衝突 → 跳至決策 4.5
  │        ├─ 網路問題 → 重試或使用鏡像
  │        └─ 套件已廢棄 → 跳至步驟 5
  │
  └─ 步驟 5：尋找替代套件
     └─ 常見替代方案：
        ├─ image_gallery_saver → gal
        ├─ path_provider → 無替代，必須修復
        └─ 其他 → 搜尋 "xxx flutter alternative"

  自動化腳本：
  handle_missing_package() {
      PACKAGE=$1

      # 步驟 1：確認是否真的需要
      USAGE_COUNT=$(grep -r "package:$PACKAGE" lib/ | wc -l)
      if [ $USAGE_COUNT -eq 0 ]; then
          echo "套件 $PACKAGE 未使用，移除 import"
          # 註解掉所有相關 import
          find lib/ -name "*.dart" -exec sed -i "s/^import 'package:$PACKAGE/\/\/ import 'package:$PACKAGE/" {} \;
          return 0
      fi

      # 步驟 2：檢查 pubspec.yaml
      if grep -q "^  $PACKAGE:" pubspec.yaml; then
          echo "套件已在 pubspec.yaml，執行 pub get"
          flutter pub get
          return $?
      fi

      # 步驟 3：嘗試自動添加
      echo "嘗試添加套件 $PACKAGE"
      flutter pub add $PACKAGE
      if [ $? -eq 0 ]; then
          echo "成功添加 $PACKAGE"
          return 0
      fi

      # 步驟 4：檢查替代方案
      case $PACKAGE in
          "image_gallery_saver")
              echo "使用 gal 替代 image_gallery_saver"
              flutter pub add gal
              replace_api "ImageGallerySaver" "Gal"
              ;;
          *)
              echo "錯誤：無法添加套件 $PACKAGE，且無已知替代方案"
              return 1
              ;;
      esac
  }

  決策點 4.3：原生代碼編譯錯誤（Kotlin/Java）

  錯誤: Unresolved reference 'Registrar' (Kotlin)
  錯誤: cannot find symbol (Java)

  決策流程：
  ├─ 步驟 1：識別錯誤來源
  │  └─ 錯誤來自哪個插件？
  │     └─ 從錯誤路徑提取: .pub-cache/hosted/pub.dev/xxx-1.2.3/android/
  │        └─ 插件名: xxx, 版本: 1.2.3
  │
  ├─ 步驟 2：判斷錯誤原因
  │  └─ 常見原因分類：
  │     ├─ 原因 A：插件版本與 Flutter 版本不相容
  │     │  └─ 關鍵字：Registrar, PluginRegistry（舊版 API）
  │     ├─ 原因 B：Gradle 版本問題
  │     │  └─ 關鍵字：Gradle, BuildConfig
  │     ├─ 原因 C：Kotlin 版本問題
  │     │  └─ 關鍵字：Kotlin compile
  │     └─ 原因 D：Android SDK 版本問題
  │        └─ 關鍵字：compileSdkVersion, targetSdkVersion
  │
  ├─ 步驟 3：針對原因 A（插件不相容）
  │  └─ 決策：
  │     ├─ 選項 1：升級插件到相容版本
  │     │  └─ 步驟：
  │     │     1. 查詢插件的 changelog: https://pub.dev/packages/xxx/changelog
  │     │     2. 找到支援當前 Flutter 版本的版本號
  │     │     3. 更新 pubspec.yaml: xxx: ^新版本
  │     │     4. 執行 flutter pub upgrade
  │     │     5. 測試編譯
  │     │
  │     ├─ 選項 2：降級 Flutter 版本（不推薦）
  │     │  └─ 只在無其他選擇時考慮
  │     │
  │     ├─ 選項 3：尋找替代插件
  │     │  └─ 步驟：
  │     │     1. 在 pub.dev 搜尋同類型插件
  │     │     2. 檢查是否有官方推薦的替代品
  │     │     3. 替換所有 API 調用
  │     │
  │     └─ 選項 4：完全移除該功能（最後手段）
  │        └─ 決策：功能是否為核心功能？
  │           ├─ Yes → 不可移除，必須找到解決方案
  │           └─ No → 註解掉相關程式碼
  │
  ├─ 步驟 4：針對原因 B/C/D（環境配置問題）
  │  └─ 更新配置文件：
  │     ├─ android/build.gradle（根層級）
  │     │  └─ 更新：
  │     │     - Gradle version
  │     │     - Kotlin version
  │     │     - Android Gradle Plugin version
  │     ├─ android/app/build.gradle.kts
  │     │  └─ 更新：
  │     │     - compileSdk
  │     │     - targetSdk
  │     │     - ndkVersion
  │     └─ gradle/wrapper/gradle-wrapper.properties
  │        └─ 更新：distributionUrl
  │
  └─ 步驟 5：清理並重新編譯
     └─ 指令序列：
        1. cd android && ./gradlew clean
        2. cd .. && flutter clean
        3. flutter pub get
        4. flutter build apk --debug

  決策矩陣（插件不相容）：
  | 情況 | Flutter 版本 | 插件狀態 | 決策 |
  |------|-------------|---------|------|
  | A | 最新 | 插件未更新 | 選項 3：尋找替代 |
  | B | 最新 | 插件已廢棄 | 選項 3：必須替代 |
  | C | 舊版 | 插件只支援新版 | 選項 1：升級插件後可能需升級 Flutter |
  | D | 任意 | 插件有相容版本 | 選項 1：升級/降級插件 |
  | E | 任意 | 無相容版本 | 選項 4：移除功能（或重大重構）|

  決策點 4.4：Dart 類別或方法未定義

  錯誤: The getter 'XXX' isn't defined for the class 'YYY'

  決策樹：
  ├─ 情況 1：XXX 是自定義類別
  │  └─ 原因分析：
  │     ├─ 原因 A：類別被拆分到其他檔案，但忘記 import
  │     │  └─ 檢查：find lib/ -name "*.dart" -exec grep -l "class XXX" {} \;
  │     │     ├─ 找到檔案 → 添加 import
  │     │     └─ 未找到 → 繼續檢查原因 B
  │     │
  │     ├─ 原因 B：類別在拆分時遺失
  │     │  └─ 檢查：grep "class XXX" lib/main.dart.backup
  │     │     ├─ 在備份中找到 → 從備份恢復
  │     │     └─ 未找到 → 類別可能從未存在，檢查程式碼邏輯
  │     │
  │     └─ 原因 C：類別名稱拼寫錯誤
  │        └─ 檢查：find lib/ -name "*.dart" -exec grep -i "class.*xxx" {} \;
  │           └─ 找到類似名稱 → 修正拼寫
  │
  ├─ 情況 2：XXX 是第三方套件的類別
  │  └─ 原因：套件未 import 或套件版本不相容
  │     └─ 解決：跳至決策 4.2
  │
  └─ 情況 3：XXX 是 YYY 的方法或屬性
     └─ 原因分析：
        ├─ 原因 A：方法在拆分時遺失
        │  └─ 檢查 main.dart.backup
        │     └─ 找到 → 補回方法定義
        │
        ├─ 原因 B：方法屬於父類別，但父類別未正確繼承
        │  └─ 檢查：class YYY extends ZZZ
        │     └─ ZZZ 是否正確 import？
        │
        └─ 原因 C：API 變更（套件版本升級導致）
           └─ 查詢：套件的 migration guide
              └─ 按照指南更新 API 調用

  自動修復腳本：
  fix_undefined_class() {
      CLASS_NAME=$1
      ERROR_FILE=$2

      echo "修復未定義的類別: $CLASS_NAME 在 $ERROR_FILE"

      # 步驟 1：搜尋類別定義
      DEFINITION_FILE=$(find lib/ -name "*.dart" -exec grep -l "^class $CLASS_NAME" {} \; | head -1)

      if [ -n "$DEFINITION_FILE" ]; then
          echo "找到類別定義: $DEFINITION_FILE"

          # 計算相對路徑
          REL_PATH=$(python3 -c "
  import os.path
  print(os.path.relpath('$DEFINITION_FILE', os.path.dirname('$ERROR_FILE')))
  ")

          # 檢查是否已 import
          if ! grep -q "import.*$REL_PATH" "$ERROR_FILE"; then
              echo "添加 import: $REL_PATH"
              # 在第一個 import 後插入
              sed -i "0,/^import/a import '$REL_PATH';" "$ERROR_FILE"
          else
              echo "已有 import，但仍報錯，可能是其他問題"
              return 1
          fi
      else
          echo "未找到類別定義，檢查備份檔案"
          if grep -q "class $CLASS_NAME" lib/main.dart.backup; then
              echo "在備份中找到，但已被刪除"
              echo "決策：詢問是否恢復此類別"
              return 2
          else
              echo "類別從未存在，可能是程式碼錯誤"
              return 3
          fi
      fi
  }

  決策點 4.5：API 變更或版本不相容

  錯誤: The method 'saveImage' isn't defined for the type 'ImageGallerySaver'

  這表示 API 已變更或套件版本不相容

  決策流程：
  ├─ 步驟 1：確認套件版本
  │  └─ 查看 pubspec.lock 中的實際版本
  │     └─ grep "image_gallery_saver:" pubspec.lock -A 2
  │
  ├─ 步驟 2：查詢 API 變更
  │  └─ 來源：
  │     ├─ 來源 A：pub.dev 的 Changelog
  │     │  └─ https://pub.dev/packages/xxx/changelog
  │     ├─ 來源 B：GitHub 的 CHANGELOG.md 或 Releases
  │     └─ 來源 C：Migration Guide（如果有）
  │
  ├─ 步驟 3：判斷變更類型
  │  └─ 變更分類：
  │     ├─ 類型 A：方法重命名
  │     │  └─ 例如：saveImage → save
  │     │     └─ 解決：全局替換方法名
  │     │
  │     ├─ 類型 B：參數變更
  │     │  └─ 例如：saveImage(bytes, name: 'x') → save(bytes, options: SaveOptions(name: 'x'))
  │     │     └─ 解決：更新所有調用點的參數格式
  │     │
  │     ├─ 類型 C：返回值變更
  │     │  └─ 例如：返回 Map → 返回 Future<void>（拋出異常）
  │     │     └─ 解決：更新錯誤處理邏輯
  │     │
  │     └─ 類型 D：完全移除該 API
  │        └─ 解決：尋找替代方法或替代套件
  │
  ├─ 步驟 4：決定處理策略
  │  └─ 策略決策：
  │     ├─ 策略 1：更新代碼以適應新 API
  │     │  └─ 條件：變更不大，且新 API 穩定
  │     │     └─ 步驟：
  │     │        1. 找出所有調用點
  │     │        2. 逐一更新
  │     │        3. 測試每個調用點
  │     │
  │     ├─ 策略 2：降級套件版本
  │     │  └─ 條件：舊版本仍可用且無安全問題
  │     │     └─ 步驟：
  │     │        1. 在 pubspec.yaml 指定舊版本
  │     │        2. flutter pub get
  │     │        3. 測試功能是否正常
  │     │
  │     └─ 策略 3：替換為其他套件
  │        └─ 條件：API 變更太大或套件已廢棄
  │           └─ 步驟：
  │              1. 研究替代套件的 API
  │              2. 創建適配層（adapter pattern）
  │              3. 逐步遷移
  │
  └─ 步驟 5：更新所有調用點
     └─ 使用統一的模式：
        ```dart
        // 舊 API
        final result = await OldPackage.oldMethod(param1, param2);
        if (result['success']) { ... }

        // 新 API（統一錯誤處理）
        try {
          await NewPackage.newMethod(param1, param2);
          // 成功
        } catch (e) {
          // 失敗
        }
        ```

  API 遷移自動化工具：
  class APIMigration:
      def __init__(self, old_package, new_package):
          self.old_package = old_package
          self.new_package = new_package
          self.mapping = self.load_api_mapping()

      def load_api_mapping(self):
          """
          載入 API 對照表
          格式: {
              'OldClass.oldMethod': {
                  'new': 'NewClass.newMethod',
                  'params': lambda old_params: new_params,
                  'return': lambda old_return: new_return,
              }
          }
          """
          # 範例：ImageGallerySaver → Gal
          return {
              'ImageGallerySaver.saveImage': {
                  'new': 'Gal.putImageBytes',
                  'params': lambda p: {
                      # saveImage(bytes, name: 'x', quality: 90)
                      # → putImageBytes(bytes)
                      'bytes': p.get('bytes') or p['positional'][0],
                      # 移除 name 和 quality 參數
                  },
                  'return': lambda old_code: f"""
  try {{
    await {old_code.replace('final result = await ', '')}
    // 成功（Gal 不返回值）
  }} catch (e) {{
    // 失敗
  }}
                  """.strip(),
              }
          }

      def migrate_file(self, file_path):
          """遷移單個檔案"""
          with open(file_path, 'r') as f:
              content = f.read()

          # 找出所有舊 API 調用
          for old_api, migration in self.mapping.items():
              old_class, old_method = old_api.split('.')

              # 匹配模式：OldClass.oldMethod(...)
              pattern = rf'{old_class}\.{old_method}\([^)]*\)'
              matches = re.finditer(pattern, content)

              for match in matches:
                  old_call = match.group(0)
                  # 解析參數
                  params = self.parse_params(old_call)
                  # 生成新調用
                  new_params = migration['params'](params)
                  new_call = self.generate_call(migration['new'], new_params)
                  # 替換
                  content = content.replace(old_call, new_call)

          # 寫回檔案
          with open(file_path, 'w') as f:
              f.write(content)

      def migrate_project(self):
          """遷移整個專案"""
          dart_files = self.find_all_dart_files()

          for file in dart_files:
              print(f"遷移 {file}...")
              self.migrate_file(file)

              # 更新 import
              self.update_imports(file, self.old_package, self.new_package)

          # 更新 pubspec.yaml
          self.update_pubspec(self.old_package, self.new_package)

  # 使用
  migrator = APIMigration('image_gallery_saver', 'gal')
  migrator.migrate_project()

  決策點 4.6：Import 路徑錯誤

  錯誤: Target of URI doesn't exist: 'package:xxx/yyy.dart'

  決策樹：
  ├─ 情況 1：相對路徑錯誤
  │  └─ 例如：import '../models/nutrition.dart'
  │     └─ 檔案實際位置：import '../../models/nutrition.dart'
  │        └─ 原因：檔案被移動或路徑計算錯誤
  │           └─ 解決步驟：
  │              1. 確認目標檔案實際位置
  │              2. 計算正確的相對路徑
  │              3. 更新 import 語句
  │
  ├─ 情況 2：套件路徑錯誤
  │  └─ 例如：import 'package:flutter_application_2/models/nutrition.dart'
  │     └─ 檔案不存在於該套件
  │        └─ 檢查：套件名稱是否正確？
  │           ├─ 套件名錯誤 → 檢查 pubspec.yaml 中的 name
  │           └─ 路徑錯誤 → 應使用相對路徑而非套件路徑
  │
  └─ 情況 3：檔案實際不存在
     └─ 原因：拆分時忘記創建該檔案
        └─ 解決：
           1. 檢查 main.dart.backup 是否有該類別
           2. 創建缺失的檔案
           3. 移動相應程式碼

  路徑計算工具：
  import os

  def calculate_relative_import(from_file, to_file):
      """
      計算從 from_file 到 to_file 的相對 import 路徑

      例如：
      from: lib/features/home/presentation/home_page.dart
      to:   lib/data/models/nutrition.dart
      結果: import '../../../data/models/nutrition.dart';
      """
      # 轉換為絕對路徑
      from_abs = os.path.abspath(from_file)
      to_abs = os.path.abspath(to_file)

      # 計算相對路徑
      rel_path = os.path.relpath(to_abs, os.path.dirname(from_abs))

      # 轉換 Windows 路徑分隔符
      rel_path = rel_path.replace('\\', '/')

      return f"import '{rel_path}';"

  # 使用範例
  print(calculate_relative_import(
      'lib/features/home/presentation/home_page.dart',
      'lib/data/models/nutrition.dart'
  ))
  # 輸出: import '../../../data/models/nutrition.dart';

  決策點 4.7：Android NDK 問題

  錯誤: NDK at ... did not have a source.properties file

  決策流程：
  ├─ 步驟 1：確認 NDK 安裝狀態
  │  └─ 檢查目錄：~/AppData/Local/Android/sdk/ndk/ (Windows)
  │     └─ ls -la ~/Library/Android/sdk/ndk/ (Mac)
  │        ├─ 資料夾存在但只有 .installer → NDK 下載未完成
  │        ├─ 資料夾存在且有 source.properties → NDK 正常
  │        └─ 資料夾不存在 → NDK 未安裝
  │
  ├─ 步驟 2：決定處理策略
  │  └─ 策略選擇：
  │     ├─ 策略 A：使用已安裝的其他 NDK 版本
  │     │  └─ 步驟：
  │     │     1. 列出所有已安裝的 NDK: ls ~/Android/sdk/ndk/
  │     │     2. 選擇最新的完整版本
  │     │     3. 更新 build.gradle.kts 中的 ndkVersion
  │     │     4. 重新編譯
  │     │  └─ 優點：快速，無需下載
  │     │  └─ 缺點：可能不是插件建議的版本（但通常向後相容）
  │     │
  │     ├─ 策略 B：下載所需的 NDK 版本
  │     │  └─ 步驟：
  │     │     1. 使用 sdkmanager: sdkmanager "ndk;27.0.12077973"
  │     │     2. 等待下載完成
  │     │     3. 驗證安裝
  │     │  └─ 優點：符合插件要求
  │     │  └─ 缺點：需要時間下載，可能遇到網路問題
  │     │
  │     └─ 策略 C：刪除不完整的 NDK 並使用其他版本
  │        └─ 步驟：
  │           1. rm -rf ~/Android/sdk/ndk/不完整版本/
  │           2. 使用策略 A
  │        └─ 推薦：當下載失敗且有其他可用版本時
  │
  ├─ 步驟 3：更新 build.gradle.kts
  │  └─ 位置：android/app/build.gradle.kts
  │     └─ 修改：
  │        ```kotlin
  │        android {
  │            ndkVersion = "選定的版本號"
  │        }
  │        ```
  │
  └─ 步驟 4：處理 NDK 版本警告
     └─ 警告：Plugin requires NDK X, but project uses NDK Y
        └─ 決策：
           ├─ Y > X（使用更新的版本）→ 忽略警告（向後相容）
           ├─ Y < X（使用較舊的版本）→ 考慮升級到 X
           └─ Y = X → 無警告

  NDK 管理腳本：
  manage_ndk() {
      NDK_DIR="$ANDROID_SDK_ROOT/ndk"
      REQUIRED_VERSION=$1  # 例如：27.0.12077973

      echo "檢查 NDK 安裝狀態..."

      # 列出所有已安裝的 NDK
      INSTALLED_NDKS=$(ls "$NDK_DIR" 2>/dev/null)

      if [ -z "$INSTALLED_NDKS" ]; then
          echo "未安裝任何 NDK"
          echo "決策：下載 NDK $REQUIRED_VERSION"
          sdkmanager "ndk;$REQUIRED_VERSION"
          return
      fi

      echo "已安裝的 NDK 版本："
      echo "$INSTALLED_NDKS"

      # 檢查所需版本是否已安裝
      if echo "$INSTALLED_NDKS" | grep -q "$REQUIRED_VERSION"; then
          echo "所需版本 $REQUIRED_VERSION 已安裝"

          # 驗證完整性
          if [ ! -f "$NDK_DIR/$REQUIRED_VERSION/source.properties" ]; then
              echo "警告：NDK $REQUIRED_VERSION 不完整，刪除並重新下載"
              rm -rf "$NDK_DIR/$REQUIRED_VERSION"
              sdkmanager "ndk;$REQUIRED_VERSION"
          else
              echo "NDK $REQUIRED_VERSION 完整，使用此版本"
          fi
      else
          echo "所需版本 $REQUIRED_VERSION 未安裝"

          # 尋找替代版本
          HIGHEST_NDK=$(echo "$INSTALLED_NDKS" | sort -V | tail -1)

          # 檢查替代版本是否完整
          if [ -f "$NDK_DIR/$HIGHEST_NDK/source.properties" ]; then
              echo "決策：使用已安裝的 NDK $HIGHEST_NDK（向後相容）"
              USE_NDK="$HIGHEST_NDK"
          else
              echo "已安裝的 NDK 都不完整，下載新版本"
              sdkmanager "ndk;$REQUIRED_VERSION"
              USE_NDK="$REQUIRED_VERSION"
          fi

          # 更新 build.gradle.kts
          sed -i "s/ndkVersion = \".*\"/ndkVersion = \"$USE_NDK\"/" \
              android/app/build.gradle.kts
      fi
  }

  # 使用
  manage_ndk "27.0.12077973"

  決策點 4.8：未知錯誤處理

  遇到未分類的錯誤時的通用決策流程：

  步驟 1：收集錯誤資訊
  ├─ 完整錯誤訊息
  ├─ 錯誤發生的檔案和行號
  ├─ 錯誤的上下文（前後幾行程式碼）
  └─ 錯誤發生的階段（編譯、執行、測試）

  步驟 2：初步分析
  ├─ 錯誤是否可重現？
  │  ├─ Yes → 系統性問題
  │  └─ No → 偶發性問題（可能是競態條件或環境問題）
  ├─ 錯誤是否在特定條件下出現？
  │  └─ 記錄觸發條件
  └─ 最近做了什麼改動？
     └─ 回顧最後 3-5 個操作

  步驟 3：搜尋已知解決方案
  ├─ 來源 A：搜尋引擎
  │  └─ 關鍵字：完整錯誤訊息 + "flutter"
  ├─ 來源 B：Stack Overflow
  │  └─ 搜尋：錯誤訊息的核心部分
  ├─ 來源 C：GitHub Issues
  │  └─ 搜尋：相關套件的 issues 頁面
  └─ 來源 D：Flutter 官方文檔
     └─ 搜尋：錯誤涉及的 API 或概念

  步驟 4：嘗試通用解決方案
  ├─ 方案 1：清理並重建
  │  └─ flutter clean && flutter pub get && flutter build
  ├─ 方案 2：檢查環境
  │  └─ flutter doctor -v
  ├─ 方案 3：回滾最近的更改
  │  └─ git revert 或從備份恢復
  └─ 方案 4：隔離問題
     └─ 創建最小可重現範例（minimal reproducible example）

  步驟 5：決策點
  ├─ 問題已解決 → 記錄解決方案，繼續
  ├─ 問題部分緩解 → 記錄當前狀態，決定是否可接受
  └─ 問題仍存在 → 決策：
     ├─ 選項 A：尋求人工協助
     │  └─ 準備詳細的問題報告
     ├─ 選項 B：繞過問題
     │  └─ 使用替代實現方式
     └─ 選項 C：暫時擱置
        └─ 標記為已知問題，繼續其他工作

  錯誤診斷框架：
  class ErrorDiagnostic:
      def __init__(self, error_message, file_path, context):
          self.error = error_message
          self.file = file_path
          self.context = context
          self.category = None
          self.solutions = []

      def diagnose(self):
          """自動診斷錯誤"""
          # 步驟 1：分類
          self.category = self.categorize_error()

          # 步驟 2：根據分類查找解決方案
          self.solutions = self.find_solutions()

          # 步驟 3：評估解決方案可行性
          self.rank_solutions()

          return self.generate_report()

      def categorize_error(self):
          """錯誤分類"""
          patterns = {
              'MISSING_PACKAGE': r"Couldn't resolve the package",
              'UNDEFINED_CLASS': r"isn't defined for the type",
              'API_CHANGE': r"The method .* isn't defined",
              'IMPORT_ERROR': r"Target of URI doesn't exist",
              'NATIVE_ERROR': r"(Kotlin|Java).*error",
              'NDK_ERROR': r"NDK.*source\.properties",
          }

          for category, pattern in patterns.items():
              if re.search(pattern, self.error):
                  return category

          return 'UNKNOWN'

      def find_solutions(self):
          """根據分類查找解決方案"""
          solution_map = {
              'MISSING_PACKAGE': [
                  {'action': 'add_to_pubspec', 'priority': 1},
                  {'action': 'comment_import', 'priority': 2},
              ],
              'API_CHANGE': [
                  {'action': 'check_changelog', 'priority': 1},
                  {'action': 'find_alternative', 'priority': 2},
              ],
              'NDK_ERROR': [
                  {'action': 'use_existing_ndk', 'priority': 1},
                  {'action': 'download_ndk', 'priority': 2},
              ],
              # ...
          }

          return solution_map.get(self.category, [
              {'action': 'search_online', 'priority': 1},
              {'action': 'create_minimal_example', 'priority': 2},
          ])

      def rank_solutions(self):
          """評估解決方案的可行性"""
          for solution in self.solutions:
              # 根據當前環境調整優先級
              if solution['action'] == 'download_ndk':
                  # 檢查網路速度
                  if self.is_slow_network():
                      solution['priority'] += 5  # 降低優先級

              if solution['action'] == 'use_existing_ndk':
                  # 檢查是否有其他 NDK
                  if not self.has_alternative_ndk():
                      solution['priority'] += 10  # 大幅降低優先級

          # 按優先級排序
          self.solutions.sort(key=lambda x: x['priority'])

      def generate_report(self):
          """生成診斷報告"""
          report = f"""
  錯誤診斷報告
  =============

  錯誤類型: {self.category}
  發生位置: {self.file}

  錯誤訊息:
  {self.error}

  建議解決方案（按優先級排序）:
  """
          for i, solution in enumerate(self.solutions, 1):
              report += f"\n{i}. {solution['action']} (優先級: {solution['priority']})"

          return report

  # 使用範例
  diagnostic = ErrorDiagnostic(
      error_message="Error: Couldn't resolve the package 'gal'",
      file_path="lib/main.dart",
      context={"line": 61, "code": "import 'package:gal/gal.dart';"}
  )

  print(diagnostic.diagnose())

  ---
  五、驗證決策：如何確認拆分成功

  決策點 5.1：編譯驗證

  問題：如何確認拆分後程式碼仍可正常編譯？

  驗證層級：
  ├─ Level 1：語法檢查（最快，約 5-10 秒）
  │  └─ 指令：flutter analyze
  │     ├─ 結果：0 errors → Level 1 通過
  │     ├─ 結果：只有 info/warning → Level 1 通過（可接受）
  │     └─ 結果：有 error → Level 1 失敗
  │        └─ 處理：修復所有 error 後重新檢查
  │
  ├─ Level 2：編譯檢查（中速，約 1-3 分鐘）
  │  └─ 指令：flutter build apk --debug
  │     ├─ 結果：Build succeeded → Level 2 通過
  │     └─ 結果：Build failed → Level 2 失敗
  │        └─ 處理：分析編譯錯誤，跳至錯誤決策樹
  │
  └─ Level 3：功能驗證（慢，約 5-10 分鐘）
     └─ 方法：
        ├─ 自動測試：flutter test
        │  └─ 如果有單元測試的話
        └─ 手動測試：flutter run
           └─ 測試檢查清單：
              ├─ App 能正常啟動
              ├─ 所有頁面能正常導航
              ├─ 關鍵功能能正常運作
              └─ 無明顯的執行時錯誤

  決策：何時執行哪個層級的驗證？
  ├─ 每個模組拆分完成後 → Level 1
  ├─ 每個階段完成後 → Level 2
  └─ 整個重構完成後 → Level 3

  決策點 5.2：功能完整性驗證

  問題：如何確認拆分後功能沒有遺失？

  驗證方法：
  ├─ 方法 1：代碼行數對比
  │  └─ 邏輯：拆分前後的總程式碼行數應該相近
  │     └─ 計算：
  │        ├─ 拆分前：wc -l lib/main.dart.backup
  │        └─ 拆分後：find lib/ -name "*.dart" -exec wc -l {} + | tail -1
  │           └─ 判斷：
  │              ├─ 相差 < 5% → 正常（註解和格式差異）
  │              ├─ 相差 5-10% → 需檢查（可能有重複或遺失）
  │              └─ 相差 > 10% → 異常（必須詳細檢查）
  │
  ├─ 方法 2：類別清單對比
  │  └─ 步驟：
  │     1. 拆分前：grep "^class " lib/main.dart.backup | sort > before.txt
  │     2. 拆分後：find lib/ -name "*.dart" -exec grep "^class " {} \; | sort > after.txt
  │     3. 對比：diff before.txt after.txt
  │        ├─ 無差異 → 所有類別都已正確拆分
  │        ├─ 有新增 → 檢查是否為拆分過程中創建的輔助類別
  │        └─ 有缺失 → 警告：某些類別可能遺失
  │
  ├─ 方法 3：Import 依賴檢查
  │  └─ 檢查所有被 import 的模組是否實際存在
  │     └─ 腳本：
  │        ```bash
  │        find lib/ -name "*.dart" -exec grep "^import " {} \; | \
  │        grep -v "package:" | \
  │        while read -r line; do
  │            path=$(echo "$line" | sed "s/import '\(.*\)';/\1/")
  │            # 檢查檔案是否存在
  │            # ...
  │        done
  │        ```
  │
  └─ 方法 4：功能測試檢查清單
     └─ 創建測試清單：
        ├─ 認證功能
        │  ├─ [ ] 登入畫面顯示
        │  ├─ [ ] 註冊畫面顯示
        │  └─ [ ] Google 登入可用
        ├─ 首頁功能
        │  ├─ [ ] 卡路里顯示
        │  ├─ [ ] 營養素圖表
        │  └─ [ ] AI 建議區塊
        ├─ 相機功能
        │  ├─ [ ] 相機預覽
        │  ├─ [ ] 拍照功能
        │  └─ [ ] 照片儲存
        └─ ... 其他功能

  自動化驗證腳本：
  class RefactoringValidator:
      def __init__(self, backup_file, lib_dir):
          self.backup = backup_file
          self.lib_dir = lib_dir
          self.report = []

      def validate_all(self):
          """執行所有驗證"""
          self.validate_line_count()
          self.validate_classes()
          self.validate_imports()
          self.validate_compilation()

          return self.generate_report()

      def validate_line_count(self):
          """驗證程式碼行數"""
          backup_lines = self.count_lines(self.backup)
          current_lines = sum(self.count_lines(f) for f in self.find_dart_files())

          diff_percent = abs(current_lines - backup_lines) / backup_lines * 100

          if diff_percent < 5:
              status = "✓ PASS"
          elif diff_percent < 10:
              status = "⚠ WARNING"
          else:
              status = "✗ FAIL"

          self.report.append({
              'test': 'Line Count',
              'status': status,
              'before': backup_lines,
              'after': current_lines,
              'diff': f"{diff_percent:.1f}%"
          })

      def validate_classes(self):
          """驗證類別完整性"""
          # 拆分前的類別
          backup_classes = self.extract_classes(self.backup)

          # 拆分後的類別
          current_classes = set()
          for file in self.find_dart_files():
              current_classes.update(self.extract_classes(file))

          # 對比
          missing = backup_classes - current_classes
          extra = current_classes - backup_classes

          if not missing and not extra:
              status = "✓ PASS"
          elif missing:
              status = "✗ FAIL"
          else:
              status = "⚠ WARNING"

          self.report.append({
              'test': 'Class Integrity',
              'status': status,
              'missing': list(missing),
              'extra': list(extra)
          })

      def validate_imports(self):
          """驗證 import 的檔案都存在"""
          broken_imports = []

          for file in self.find_dart_files():
              with open(file, 'r') as f:
                  for line in f:
                      if line.startswith('import ') and not 'package:' in line:
                          # 相對路徑 import
                          import_path = line.split("'")[1]
                          full_path = os.path.join(os.path.dirname(file), import_path)

                          if not os.path.exists(full_path):
                              broken_imports.append({
                                  'file': file,
                                  'import': import_path
                              })

          status = "✓ PASS" if not broken_imports else "✗ FAIL"

          self.report.append({
              'test': 'Import Validation',
              'status': status,
              'broken': broken_imports
          })

      def validate_compilation(self):
          """驗證編譯狀態"""
          # Level 1: Analyze
          analyze_result = subprocess.run(
              ['flutter', 'analyze'],
              capture_output=True,
              text=True
          )

          errors = self.count_errors(analyze_result.stdout)

          if errors == 0:
              status = "✓ PASS"
          else:
              status = "✗ FAIL"

          self.report.append({
              'test': 'Static Analysis',
              'status': status,
              'errors': errors
          })

      def generate_report(self):
          """生成驗證報告"""
          report = "重構驗證報告\n" + "="*50 + "\n\n"

          for item in self.report:
              report += f"{item['test']}: {item['status']}\n"
              for key, value in item.items():
                  if key not in ['test', 'status']:
                      report += f"  {key}: {value}\n"
              report += "\n"

          # 總結
          passed = sum(1 for item in self.report if '✓' in item['status'])
          total = len(self.report)

          report += f"總結: {passed}/{total} 測試通過\n"

          if passed == total:
              report += "\n✓ 重構成功！所有驗證通過。"
          else:
              report += "\n✗ 重構未完成，請修復失敗的驗證項目。"

          return report

  # 使用
  validator = RefactoringValidator('lib/main.dart.backup', 'lib/')
  print(validator.validate_all())

  ---
  六、回滾決策：失敗時如何恢復

  決策點 6.1：何時需要回滾？

  決策樹：
  ├─ 情況 1：拆分導致編譯錯誤
  │  └─ 錯誤嚴重程度判斷：
  │     ├─ 嚴重（>10 個 error）→ 建議回滾
  │     ├─ 中等（3-10 個 error）→ 嘗試修復，超過 30 分鐘未解決則回滾
  │     └─ 輕微（<3 個 error）→ 應該能快速修復，不建議回滾
  │
  ├─ 情況 2：拆分導致功能缺失
  │  └─ 缺失程度判斷：
  │     ├─ 核心功能缺失（如無法啟動）→ 立即回滾
  │     ├─ 主要功能缺失（如無法登入）→ 嘗試恢復，失敗則回滾
  │     └─ 次要功能缺失（如某個按鈕）→ 標記為已知問題，繼續
  │
  └─ 情況 3：拆分導致性能問題
     └─ 性能影響判斷：
        ├─ 嚴重（無法使用）→ 回滾並重新設計
        ├─ 明顯（明顯延遲）→ 分析原因，考慮部分回滾
        └─ 輕微（感覺不明顯）→ 記錄問題，後續優化

  決策：回滾範圍
  ├─ 完全回滾：恢復到拆分前狀態
  │  └─ 條件：
  │     - 無法確定問題原因
  │     - 修復時間預計 > 重新拆分時間
  │     - 多個階段都有問題
  │
  ├─ 部分回滾：只恢復最近的階段
  │  └─ 條件：
  │     - 問題發生在最近一個階段
  │     - 之前的階段都正常
  │     - 可以隔離問題範圍
  │
  └─ 不回滾：修復後繼續
     └─ 條件：
        - 問題明確且有解決方案
        - 修復時間 < 30 分鐘
        - 不影響後續工作

  決策點 6.2：如何執行回滾？

  回滾方法決策樹：

  ├─ 方法 A：使用 Git（最佳）
  │  └─ 前提：使用了版本控制
  │     └─ 步驟：
  │        1. 檢查當前狀態：git status
  │        2. 查看提交歷史：git log --oneline
  │        3. 回滾到指定提交：git reset --hard <commit-hash>
  │        4. 清理編譯產物：flutter clean
  │        5. 驗證：flutter build apk --debug
  │
  ├─ 方法 B：使用備份檔案
  │  └─ 前提：創建了 .backup 檔案
  │     └─ 步驟：
  │        1. 恢復 main.dart：cp lib/main.dart.backup lib/main.dart
  │        2. 刪除拆分的模組：rm -rf lib/core lib/data lib/features
  │        3. 清理：flutter clean
  │        4. 驗證：flutter pub get && flutter build apk
  │
  └─ 方法 C：手動撤銷
     └─ 前提：記得修改了哪些檔案
        └─ 步驟：
           1. 列出所有拆分階段創建的檔案
           2. 逐一刪除
           3. 從備份恢復 main.dart
           4. 清理並驗證

  決策：選擇哪種方法？
  ├─ 有 Git 倉庫 → 方法 A（最快最安全）
  ├─ 有備份檔案 → 方法 B（次佳）
  └─ 都沒有 → 方法 C（最麻煩，可能不完整）
     └─ 建議：下次重構前先創建 Git 倉庫或備份

  回滾自動化腳本：
  #!/bin/bash

  rollback() {
      ROLLBACK_TYPE=$1  # "full" 或 "partial" 或 "stage"

      echo "開始回滾：$ROLLBACK_TYPE"

      case $ROLLBACK_TYPE in
          "full")
              # 完全回滾到拆分前
              if [ -d ".git" ]; then
                  echo "使用 Git 回滾..."
                  # 找到重構開始前的提交
                  BEFORE_REFACTOR=$(git log --grep="開始重構\|START_REFACTOR" --format="%H" | tail -1)

                  if [ -n "$BEFORE_REFACTOR" ]; then
                      git reset --hard $BEFORE_REFACTOR
                  else
                      echo "未找到重構起始點，使用備份檔案"
                      rollback_from_backup
                  fi
              else
                  echo "未使用 Git，使用備份檔案回滾"
                  rollback_from_backup
              fi
              ;;

          "partial")
              # 部分回滾（保留某些階段）
              echo "請指定要保留到哪個階段（1-6）："
              read KEEP_STAGE

              # 刪除該階段之後的所有模組
              case $KEEP_STAGE in
                  1)  # 只保留資料模型
                      rm -rf lib/data/services lib/core lib/features lib/widgets lib/utils
                      ;;
                  2)  # 保留到服務層
                      rm -rf lib/core lib/features lib/widgets lib/utils
                      ;;
                  3)  # 保留到核心層
                      rm -rf lib/features lib/widgets lib/utils
                      ;;
                  # ... 其他階段
              esac

              # 從備份恢復被刪除模組的程式碼到 main.dart
              restore_code_to_main $KEEP_STAGE
              ;;

          "stage")
              # 只回滾最近一個階段
              echo "回滾最近的階段..."

              # 查找最近創建的目錄
              RECENT_DIR=$(find lib/ -type d -name "presentation" -o -name "models" -o -name "services" | \
                          xargs ls -dt | head -1)

              echo "刪除：$RECENT_DIR"
              rm -rf "$RECENT_DIR"

              # 恢復對應的程式碼
              # ...
              ;;
      esac

      # 清理編譯產物
      echo "清理編譯產物..."
      flutter clean
      flutter pub get

      # 驗證
      echo "驗證回滾結果..."
      flutter analyze

      if [ $? -eq 0 ]; then
          echo "✓ 回滾成功！"
      else
          echo "✗ 回滾後仍有錯誤，請手動檢查"
      fi
  }

  rollback_from_backup() {
      if [ -f "lib/main.dart.backup" ]; then
          echo "從備份恢復 main.dart"
          cp lib/main.dart.backup lib/main.dart

          echo "刪除所有拆分的模組"
          rm -rf lib/core lib/data lib/features lib/widgets lib/utils

          echo "✓ 備份恢復完成"
      else
          echo "✗ 錯誤：找不到備份檔案 lib/main.dart.backup"
          echo "無法自動回滾，需要手動處理"
          exit 1
      fi
  }

  # 使用範例
  # ./rollback.sh full      # 完全回滾
  # ./rollback.sh partial   # 部分回滾（互動式）
  # ./rollback.sh stage     # 回滾最近階段

  rollback $1

  ---
  七、總結：完整執行策略

  執行前檢查清單

  □ 專案備份
    □ 創建 main.dart.backup
    □ 創建 Git 倉庫（推薦）
    □ 記錄當前 pubspec.yaml 內容

  □ 環境確認
    □ flutter doctor 無錯誤
    □ 當前程式碼可編譯
    □ 所有依賴已安裝（flutter pub get）

  □ 工具準備
    □ 熟悉常用指令（grep, find, sed 等）
    □ 瞭解專案結構
    □ 準備好決策文檔（本文檔）

  執行流程圖

  開始
    ↓
  [前置檢查] → 不通過 → 修復環境 → 重新檢查
    ↓ 通過
  [分析依賴] → 建立拆分順序
    ↓
  開始階段 1（資料模型層）
    ↓
  提取模組 → [遇到問題?] → Yes → [查閱決策樹] → [解決/回滾]
    ↓ No
  階段驗證 → [通過?] → No → [修復/回滾]
    ↓ Yes
  階段 2、3、4、5、6...（循環上述流程）
    ↓
  全部階段完成
    ↓
  [最終驗證]
    ├─ 編譯檢查
    ├─ 功能檢查
    └─ 性能檢查
    ↓
  [驗證通過?]
    ├─ Yes → 生成報告 → 完成
    └─ No → [決定回滾範圍] → 回滾 → 重新分析

  關鍵決策點總覽

  1. 專案狀態判定（決策 1.1, 1.2）
     ↓ 確定起始點

  2. 依賴分析（決策 3.1）
     ↓ 確定拆分順序

  3. 對於每個模組：
     ├─ 程式碼定位（決策 2.1）
     ├─ Import 確定（決策 2.2）
     ├─ 範圍確定（決策 2.3）
     └─ 遇到錯誤 → 錯誤分類（決策 4.1）→ 對應處理（決策 4.2-4.8）

  4. 驗證（決策 5.1, 5.2）
     ↓

  5. 失敗處理（決策 6.1, 6.2）

  時間估計

  預計總時間：3-6 小時（取決於專案大小和熟練度）

  階段分解：
  - 前置準備：15-30 分鐘
  - 階段 1（資料模型）：30-45 分鐘
  - 階段 2（服務層）：30-45 分鐘
  - 階段 3（核心層）：20-30 分鐘
  - 階段 4（認證模組）：30-45 分鐘
  - 階段 5（功能模組）：60-90 分鐘
  - 階段 6（工具層）：30-45 分鐘
  - 驗證與修復：30-60 分鐘

  風險緩衝：30-60 分鐘（處理意外問題）

  ---
  使用說明

  將本決策邏輯文檔與前面的「可重現執行指引」配合使用：

  1. 執行前：閱讀本文檔的「前置檢查清單」
  2. 執行中：按照「可重現執行指引」的步驟進行，遇到問題時查閱本文檔的對應決策樹
  3. 執行後：使用「驗證決策」部分確認重構品質

  關鍵原則：
  - 遇到未預期的情況 → 先查決策樹
  - 決策樹中無解決方案 → 記錄問題並詢問
  - 始終保持可回滾狀態 → 定期提交或備份

你可以在新對話一開始就貼上這段提示詞：

  ---
  # Claude Code 工作規則設定

  ## 重要：執行前說明規則

  ### 規則 1：Bash Command 必須詳細說明
  在執行任何 bash command 之前，你必須先用台灣繁體中文進行詳細說明，包含：

  1. **要做什麼**（目標說明）
  2. **指令內容**（完整指令）
  3. **指令拆解**（逐行解釋每個參數的作用）
  4. **為什麼要這樣做**（原因分析）
  5. **預期結果**（執行後會看到什麼）

  **範例格式：**
  📋 要執行的操作詳述

  要做什麼：

  使用 awk 指令找出 EdgeDetectionPainter 類別的完整範圍

  指令：

  awk '/^class EdgeDetectionPainter/,/^class [A-Z]/' lib/main.dart | head -50

  詳細說明：

  指令拆解：
  1. awk '/^class EdgeDetectionPainter/,/^class [A-Z]/'
    - awk 是文字處理工具
    - /^class EdgeDetectionPainter/ - 從「以 class EdgeDetectionPainter 開頭的行」開始
    - , - 到
    - /^class [A-Z]/ - 「以 class 開頭的行」為止
    - 目的：提取從 EdgeDetectionPainter 開始到下一個類別為止的所有程式碼
  2. | head -50
    - 只顯示前 50 行
    - 目的：快速預覽類別內容，不要一次輸出太多

  為什麼要這樣做：
  - 需要知道 EdgeDetectionPainter 類別有多長
  - 需要確認類別的結束位置
  - 才能精確提取這個類別

  預期結果：
  - 會看到 EdgeDetectionPainter 的類別定義
  - 會看到類別的方法（如 paint, shouldRepaint）
  - 可以估算出這個類別大約有多少行

  ---
  現在是否執行這個操作？

  **說明必須達到這種詳細程度，否則我會一律先拒絕，看完你的詳述再決定是否執行。**

  ---

  ### 規則 2：讀取操作不需詢問
  以下操作不需要事前詢問，可以直接執行：
  - Read tool（讀取檔案）
  - Grep tool（搜尋內容）
  - Bash 的查詢指令（grep、find、ls、wc 等唯讀操作）

  但仍需要在執行後說明結果。

  ---

  ### 規則 3：寫入/修改操作必須詳述並詢問
  以下操作必須先詳細說明並等待確認：
  - Edit tool（修改檔案）
  - Write tool（建立新檔案）
  - Bash 的寫入指令（cp、mv、rm、mkdir 等）
  - 任何會改變檔案系統的操作

  說明格式同規則 1，必須包含：
  - 要修改什麼
  - 為什麼要修改
  - 修改的具體內容（old_string 和 new_string）
  - 修改後的影響

  ---

  ### 規則 4：註解不刪除原則
  遇到暫時不需要的 import 或程式碼時：
  - ✅ 用註解標記（推薦）
  - ❌ 不要直接刪除

  範例：
  ```dart
  // import 'package:old_package/old_package.dart';  // 已註解：不相容，改用新套件
  import 'package:new_package/new_package.dart';

  ---
  請確認你理解了以上所有規則，並在今後的對話中嚴格遵守。

  ---

  ## 💡 使用方式

  **步驟 1：** 在其他電腦開啟 Claude Code

  **步驟 2：** 在對話一開始就貼上上面的完整提示詞

  **步驟 3：** Claude Code 會回覆確認理解規則

  **步驟 4：** 開始正常工作，Claude Code 會自動遵守這些規則
你可以在新對話一開始就貼上這段提示詞：

  ---
  # Claude Code 工作規則設定

  ## 重要：執行前說明規則

  ### 規則 1：Bash Command 必須詳細說明
  在執行任何 bash command 之前，你必須先用台灣繁體中文進行詳細說明，包含：

  1. **要做什麼**（目標說明）
  2. **指令內容**（完整指令）
  3. **指令拆解**（逐行解釋每個參數的作用）
  4. **為什麼要這樣做**（原因分析）
  5. **預期結果**（執行後會看到什麼）

  **範例格式：**
  📋 要執行的操作詳述

  要做什麼：

  使用 awk 指令找出 EdgeDetectionPainter 類別的完整範圍

  指令：

  awk '/^class EdgeDetectionPainter/,/^class [A-Z]/' lib/main.dart | head -50

  詳細說明：

  指令拆解：
  1. awk '/^class EdgeDetectionPainter/,/^class [A-Z]/'
    - awk 是文字處理工具
    - /^class EdgeDetectionPainter/ - 從「以 class EdgeDetectionPainter 開頭的行」開始
    - , - 到
    - /^class [A-Z]/ - 「以 class 開頭的行」為止
    - 目的：提取從 EdgeDetectionPainter 開始到下一個類別為止的所有程式碼
  2. | head -50
    - 只顯示前 50 行
    - 目的：快速預覽類別內容，不要一次輸出太多

  為什麼要這樣做：
  - 需要知道 EdgeDetectionPainter 類別有多長
  - 需要確認類別的結束位置
  - 才能精確提取這個類別

  預期結果：
  - 會看到 EdgeDetectionPainter 的類別定義
  - 會看到類別的方法（如 paint, shouldRepaint）
  - 可以估算出這個類別大約有多少行

  ---
  現在是否執行這個操作？

  **說明必須達到這種詳細程度，否則我會一律先拒絕，看完你的詳述再決定是否執行。**

  ---

  ### 規則 2：讀取操作不需詢問
  以下操作不需要事前詢問，可以直接執行：
  - Read tool（讀取檔案）
  - Grep tool（搜尋內容）
  - Bash 的查詢指令（grep、find、ls、wc 等唯讀操作）

  但仍需要在執行後說明結果。

  ---

  ### 規則 3：寫入/修改操作必須詳述並詢問
  以下操作必須先詳細說明並等待確認：
  - Edit tool（修改檔案）
  - Write tool（建立新檔案）
  - Bash 的寫入指令（cp、mv、rm、mkdir 等）
  - 任何會改變檔案系統的操作

  說明格式同規則 1，必須包含：
  - 要修改什麼
  - 為什麼要修改
  - 修改的具體內容（old_string 和 new_string）
  - 修改後的影響

  ---

  ### 規則 4：註解不刪除原則
  遇到暫時不需要的 import 或程式碼時：
  - ✅ 用註解標記（推薦）
  - ❌ 不要直接刪除

  範例：
  ```dart
  // import 'package:old_package/old_package.dart';  // 已註解：不相容，改用新套件
  import 'package:new_package/new_package.dart';

  ---
  請確認你理解了以上所有規則，並在今後的對話中嚴格遵守。

  ---

  ## 💡 使用方式

  **步驟 1：** 在其他電腦開啟 Claude Code

  **步驟 2：** 在對話一開始就貼上上面的完整提示詞

  **步驟 3：** Claude Code 會回覆確認理解規則

  **步驟 4：** 開始正常工作，Claude Code 會自動遵守這些規則
你可以在新對話一開始就貼上這段提示詞：

  ---
  # Claude Code 工作規則設定

  ## 重要：執行前說明規則

  ### 規則 1：Bash Command 必須詳細說明
  在執行任何 bash command 之前，你必須先用台灣繁體中文進行詳細說明，包含：

  1. **要做什麼**（目標說明）
  2. **指令內容**（完整指令）
  3. **指令拆解**（逐行解釋每個參數的作用）
  4. **為什麼要這樣做**（原因分析）
  5. **預期結果**（執行後會看到什麼）

  **範例格式：**
  📋 要執行的操作詳述

  要做什麼：

  使用 awk 指令找出 EdgeDetectionPainter 類別的完整範圍

  指令：

  awk '/^class EdgeDetectionPainter/,/^class [A-Z]/' lib/main.dart | head -50

  詳細說明：

  指令拆解：
  1. awk '/^class EdgeDetectionPainter/,/^class [A-Z]/'
    - awk 是文字處理工具
    - /^class EdgeDetectionPainter/ - 從「以 class EdgeDetectionPainter 開頭的行」開始
    - , - 到
    - /^class [A-Z]/ - 「以 class 開頭的行」為止
    - 目的：提取從 EdgeDetectionPainter 開始到下一個類別為止的所有程式碼
  2. | head -50
    - 只顯示前 50 行
    - 目的：快速預覽類別內容，不要一次輸出太多

  為什麼要這樣做：
  - 需要知道 EdgeDetectionPainter 類別有多長
  - 需要確認類別的結束位置
  - 才能精確提取這個類別

  預期結果：
  - 會看到 EdgeDetectionPainter 的類別定義
  - 會看到類別的方法（如 paint, shouldRepaint）
  - 可以估算出這個類別大約有多少行

  ---
  現在是否執行這個操作？

  **說明必須達到這種詳細程度，否則我會一律先拒絕，看完你的詳述再決定是否執行。**

  ---

  ### 規則 2：讀取操作不需詢問
  以下操作不需要事前詢問，可以直接執行：
  - Read tool（讀取檔案）
  - Grep tool（搜尋內容）
  - Bash 的查詢指令（grep、find、ls、wc 等唯讀操作）

  但仍需要在執行後說明結果。

  ---

  ### 規則 3：寫入/修改操作必須詳述並詢問
  以下操作必須先詳細說明並等待確認：
  - Edit tool（修改檔案）
  - Write tool（建立新檔案）
  - Bash 的寫入指令（cp、mv、rm、mkdir 等）
  - 任何會改變檔案系統的操作

  說明格式同規則 1，必須包含：
  - 要修改什麼
  - 為什麼要修改
  - 修改的具體內容（old_string 和 new_string）
  - 修改後的影響

  ---

  ### 規則 4：註解不刪除原則
  遇到暫時不需要的 import 或程式碼時：
  - ✅ 用註解標記（推薦）
  - ❌ 不要直接刪除

  範例：
  ```dart
  // import 'package:old_package/old_package.dart';  // 已註解：不相容，改用新套件
  import 'package:new_package/new_package.dart';

  ---
  請確認你理解了以上所有規則，並在今後的對話中嚴格遵守。

  ---

  ## 💡 使用方式

  **步驟 1：** 在其他電腦開啟 Claude Code

  **步驟 2：** 在對話一開始就貼上上面的完整提示詞

  **步驟 3：** Claude Code 會回覆確認理解規則

  **步驟 4：** 開始正常工作，Claude Code 會自動遵守這些規則
