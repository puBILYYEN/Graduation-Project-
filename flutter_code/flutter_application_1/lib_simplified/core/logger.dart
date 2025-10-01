// AK47 風格精簡版：日誌系統
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class Logger {
  static Logger? _instance;
  static Logger get i => _instance ??= Logger._();
  Logger._();

  File? _file;

  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File(path.join(dir.path, 'app.log'));
      if (!await _file!.exists()) await _file!.create();
      await log('=== App Started ===');
    } catch (e) {
      print('Logger init failed: $e');
    }
  }

  Future<void> log(String msg) async {
    final timestamp = DateTime.now().toString();
    final entry = '[$timestamp] $msg\n';
    print(msg);
    try {
      if (_file != null) await _file!.writeAsString(entry, mode: FileMode.append);
    } catch (e) {
      print('Log write failed: $e');
    }
  }

  String? get logPath => _file?.path;
}

// 全域簡潔日誌函數
Future<void> log(String msg) => Logger.i.log(msg);
void logSync(String msg) {
  print(msg);
  Logger.i.log(msg);  // 不等待完成
}