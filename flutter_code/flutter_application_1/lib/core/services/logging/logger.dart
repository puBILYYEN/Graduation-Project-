import 'package:flutter/foundation.dart';

Future<void> log(String message) async {
  if (kDebugMode) {
    print('📝 $message');
  }
}

void logSync(String message) {
  if (kDebugMode) {
    print('📝 $message');
  }
}
