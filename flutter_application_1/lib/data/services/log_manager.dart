// ====================================================================
// 日誌管理服務 (Log Manager Service)
// ====================================================================
// 這個檔案提供應用程式運作狀況的記錄功能

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// 日誌管理器類別 - 用來記錄程式運作狀況的工具(就像寫日記一樣)
class LogManager {
  static LogManager? _instance; // 私有靜態變數(確保只有一個日誌管理器在運作)
  static LogManager get instance =>
      _instance ??= LogManager._(); // 取得日誌管理器(如果還沒建立就建立一個)
  LogManager._(); // 私有建構函數(防止外部重複建立)

  File? _logFile; // 日誌檔案(用來存放記錄的檔案)

  // 初始化日誌檔案 - 建立用來存放記錄的檔案
  Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory(); // 取得App的文件存放資料夾
      final logPath =
          path.join(directory.path, 'app_log.log'); // 組合出日誌檔案的完整路徑
      _logFile = File(logPath); // 建立檔案物件

      // 如果檔案不存在就建立一個新的
      if (!await _logFile!.exists()) {
        await _logFile!.create(); // 建立檔案
      }

      // 記錄程式啟動的時間
      await writeLog('=== 應用啟動 ===');
    } catch (e) {
      print('日誌管理器初始化失敗: $e'); // 如果初始化失敗就印出錯誤訊息
    }
  }

  // 寫入日誌 - 把訊息記錄到檔案裡，同時也顯示在畫面上
  Future<void> writeLog(String message) async {
    try {
      final timestamp = DateTime.now().toString(); // 取得現在的時間
      final logEntry = '[$timestamp] $message\n'; // 把時間和訊息組合起來

      // 同時輸出到控制台 - 方便開發時即時看到
      print(message);

      // 寫入到檔案 - 永久保存這筆記錄
      if (_logFile != null) {
        await _logFile!
            .writeAsString(logEntry, mode: FileMode.append); // 使用附加模式(不會覆蓋掉之前的記錄)
      }
    } catch (e) {
      print('寫入日誌失敗: $e'); // 如果寫入失敗就印出錯誤訊息
    }
  }

  // 取得日誌檔案路徑 - 告訴你日誌檔案存在哪裡
  String? get logFilePath => _logFile?.path; // 安全取得路徑(如果檔案不存在就回傳null)
}

// 全域日誌函數 - 提供方便的記錄方式(在任何地方都可以直接呼叫)
Future<void> log(String message) async {
  await LogManager.instance.writeLog(message); // 呼叫日誌管理器來寫入訊息
}

// 同步日誌函數 - 用在不能等待的情況下(像是畫畫面的時候)
void logSync(String message) {
  // 只輸出到畫面上，不寫入檔案(避免畫面卡住)
  print(message);
  // 同時在背景寫入檔案(不用等它完成)
  LogManager.instance.writeLog(message);
}
