// ----- [services/log_manager.dart] 開始 -----
// 日誌管理器類別 - 採用單例模式管理應用程式的日誌記錄
class LogManager {
  static LogManager? _instance; // 私有静態變數儲存單例實體
  static LogManager get instance =>
      _instance ??= LogManager._(); // 單例取得器，使用空合併運算符確保只有一個實體
  LogManager._(); // 私有構造函數，防止外部直接實例化

  File? _logFile; // 日誌檔案物件引用

  // 初始化日誌文件 - 建立日誌檔案的存放位置和設定
  Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory(); // 取得應用程式文件目錄
      final logPath =
          path.join(directory.path, 'app_log.log'); // 組合檔案路徑，建立日誌檔案路徑
      _logFile = File(logPath); // 建立檔案物件

      // 如果文件不存在則創建 - 確保日誌檔案存在
      if (!await _logFile!.exists()) {
        await _logFile!.create(); // 非同步建立檔案
      }

      // 在應用啟動時記錄 - 記錄應用程式啟動時間點
      await writeLog('=== 應用啟動 ===');
    } catch (e) {
      print('日誌管理器初始化失敗: $e'); // 印出初始化錯誤訊息
    }
  }

  // 寫入日誌 - 將訊息記錄到日誌檔案並同時輸出到控制台
  Future<void> writeLog(String message) async {
    try {
      final timestamp = DateTime.now().toString(); // 取得目前時間戳
      final logEntry = '[$timestamp] $message\n'; // 格式化日誌項目，包含時間戳和訊息

      // 同時輸出到控制台 - 便於除錯和即時監控
      print(message);

      // 寫入到文件 - 持久化儲存日誌資料
      if (_logFile != null) {
        await _logFile!
            .writeAsString(logEntry, mode: FileMode.append); // 使用附加模式不覆蓋既有內容
      }
    } catch (e) {
      print('寫入日誌失敗: $e'); // 印出錯誤訊息，防止無窮遞迴
    }
  }

  // 獲取日誌文件路徑 - 提供日誌檔案的完整路徑供外部存取
  String? get logFilePath => _logFile?.path; // 使用安全導航運算符避免空指針錯誤
}

// 全局日誌函數 - 提供簡潔的日誌記錄接口
Future<void> log(String message) async {
  await LogManager.instance.writeLog(message); // 調用單例的寫入日誌方法
}

// 同步日誌函數 - 用於 build 方法等不允許異步操作的同步上下文
void logSync(String message) {
  // 只輸出到控制台，不寫入文件以避免同步環境中的異步問題
  print(message);
  // 異步寫入文件，但不等待完成 - 避免阻塞 UI 繪製
  LogManager.instance.writeLog(message);
}
// ----- [services/log_manager.dart] 結束 -----