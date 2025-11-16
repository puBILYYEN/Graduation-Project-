 import 'dart:async';
  import 'package:socket_io_client/socket_io_client.dart' as IO;
  import 'api_endpoints.dart';

  /// Socket.IO 服務類別 - 處理即時通訊
  class SocketService {
    static SocketService? _instance;
    IO.Socket? _socket;

    // 連接狀態流
    final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

    // RAG 回應流
    final StreamController<Map<String, dynamic>> _ragResponseController = StreamController<Map<String, dynamic>>.broadcast();

    SocketService._internal();

    factory SocketService() {
      return _instance ??= SocketService._internal();
    }

    /// 獲取連接狀態流
    Stream<bool> get connectionStatus => _connectionController.stream;

    /// 獲取 RAG 回應流
    Stream<Map<String, dynamic>> get ragResponses => _ragResponseController.stream;

    /// 檢查是否已連接
    bool get isConnected => _socket?.connected ?? false;

    /// 連接到 Socket.IO 伺服器
    Future<bool> connect() async {
      try {
        if (_socket?.connected == true) {
          print('Socket.IO 已經連接');
          return true;
        }

        print('正在連接 Socket.IO 伺服器...');
        print('URL: ${ApiEndpoints.baseUrl}');

        // 使用 socket_io_client 3.x 的新 API
        _socket = IO.io(
          ApiEndpoints.baseUrl,
          IO.OptionBuilder()
              .setTransports(['websocket', 'polling'])  // 3.x 版本應優先使用 websocket
              .disableAutoConnect()
              .setTimeout(60000)  // 60秒超時以應對 Cloud Run 冷啟動
              .setReconnectionAttempts(5)
              .setReconnectionDelay(2000)
              .enableForceNew()
              .build(),
        );

        // 設置連接事件監聽器
        _setupEventListeners();

        // 連接到伺服器
        _socket!.connect();

        // 等待連接完成
        final completer = Completer<bool>();

        late StreamSubscription subscription;
        subscription = connectionStatus.listen((isConnected) {
          if (isConnected) {
            subscription.cancel();
            completer.complete(true);
          }
        });

        // 60秒超時以應對 Cloud Run 冷啟動
        Timer(const Duration(seconds: 60), () {
          if (!completer.isCompleted) {
            subscription.cancel();
            completer.complete(false);
          }
        });

        return await completer.future;
      } catch (e) {
        print('Socket.IO 連接錯誤: $e');
        return false;
      }
    }

    /// 設置事件監聽器
    void _setupEventListeners() {
      if (_socket == null) return;

      _socket!.onConnect((_) {
        print('Socket.IO 連接成功');
        _connectionController.add(true);
      });

      _socket!.onDisconnect((_) {
        print('Socket.IO 連接中斷');
        _connectionController.add(false);
      });

      _socket!.onConnectError((error) {
        print('Socket.IO 連接錯誤: $error');
        _connectionController.add(false);
      });

      _socket!.onError((error) {
        print('Socket.IO 錯誤: $error');
      });

      // RAG 相關事件監聽器
      _socket!.on('rag_response', (data) {
        print('收到 RAG 回應: $data');
        if (data is Map<String, dynamic>) {
          _ragResponseController.add(data);
        }
      });

      _socket!.on('rag_error', (data) {
        print('RAG 處理錯誤: $data');
        _ragResponseController.add({
          'error': true,
          'message': data.toString(),
        });
      });
    }

    /// 發送 RAG 問題
    void sendRagQuestion(String question) {
      if (!isConnected) {
        print('Socket.IO 未連接，無法發送問題');
        _ragResponseController.add({
          'error': true,
          'message': '連接已中斷，請重新連接',
        });
        return;
      }

      print('發送 RAG 問題: $question');
      _socket!.emit('rag_question', {
        'question': question,
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'flutter_app',
      });
    }

    /// 發送營養數據給 RAG 系統
    void sendNutritionData(Map<String, dynamic> nutritionData) {
      if (!isConnected) {
        print('Socket.IO 未連接，無法發送營養數據');
        return;
      }

      print('發送營養數據給 RAG: $nutritionData');
      _socket!.emit('nutrition_data', nutritionData);
    }

    /// 斷開連接
    void disconnect() {
      if (_socket?.connected == true) {
        print('正在斷開 Socket.IO 連接...');
        _socket!.disconnect();
      }
      _socket = null;
    }

    /// 釋放資源
    void dispose() {
      disconnect();
      _connectionController.close();
      _ragResponseController.close();
      _instance = null;
    }
  }
