import 'lib/core/services/api/socket_service.dart';

/// 測試 Socket.IO 連接
void main() async {
  print('開始測試 Socket.IO 連接...');

  final socketService = SocketService();

  // 監聽連接狀態
  socketService.connectionStatus.listen((isConnected) {
    print('連接狀態: ${isConnected ? "已連接" : "未連接"}');
  });

  // 監聽 RAG 回應
  socketService.ragResponses.listen((response) {
    print('收到 RAG 回應: $response');
  });

  try {
    print('嘗試連接到 Socket.IO 伺服器...');
    final connected = await socketService.connect();

    if (connected) {
      print('✅ Socket.IO 連接成功!');

      // 測試發送問題
      print('測試發送問題...');
      socketService.sendRagQuestion('這是一個測試問題');

      // 等待 5 秒觀察回應
      await Future.delayed(Duration(seconds: 5));

    } else {
      print('❌ Socket.IO 連接失敗');
    }

  } catch (e) {
    print('❌ 測試過程中發生錯誤: $e');
  } finally {
    print('關閉連接...');
    socketService.disconnect();
    socketService.dispose();
    print('測試完成');
  }
}