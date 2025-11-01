/// 聊天訊息模型
class ChatMessage {
  final String id;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  /// 從 JSON 創建 ChatMessage
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      message: json['message'] ?? '',
      isUser: json['is_user'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }

  /// 創建用戶訊息
  factory ChatMessage.user({
    required String id,
    required String message,
  }) {
    return ChatMessage(
      id: id,
      message: message,
      isUser: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
  }

  /// 創建 AI 回應訊息
  factory ChatMessage.aiResponse({
    required String id,
    required String message,
  }) {
    return ChatMessage(
      id: id,
      message: message,
      isUser: false,
      timestamp: DateTime.now(),
      status: MessageStatus.received,
    );
  }

  /// 創建錯誤訊息
  factory ChatMessage.error({
    required String id,
    required String errorMessage,
  }) {
    return ChatMessage(
      id: id,
      message: '抱歉，處理您的問題時發生錯誤：$errorMessage',
      isUser: false,
      timestamp: DateTime.now(),
      status: MessageStatus.error,
    );
  }

  /// 複製並修改狀態
  ChatMessage copyWithStatus(MessageStatus newStatus) {
    return ChatMessage(
      id: id,
      message: message,
      isUser: isUser,
      timestamp: timestamp,
      status: newStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage(id: $id, message: $message, isUser: $isUser, timestamp: $timestamp, status: $status)';
  }
}

/// 訊息狀態枚舉
enum MessageStatus {
  sending,    // 發送中
  sent,       // 已發送
  received,   // 已接收
  error,      // 錯誤
}

/// 聊天會話模型
class ChatSession {
  final String id;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime lastUpdated;

  ChatSession({
    required this.id,
    required this.messages,
    required this.createdAt,
    required this.lastUpdated,
  });

  /// 從 JSON 創建 ChatSession
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] ?? '',
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromJson(m))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messages': messages.map((m) => m.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  /// 創建新的聊天會話
  factory ChatSession.create({required String id}) {
    final now = DateTime.now();
    return ChatSession(
      id: id,
      messages: [],
      createdAt: now,
      lastUpdated: now,
    );
  }

  /// 添加訊息
  ChatSession addMessage(ChatMessage message) {
    final newMessages = List<ChatMessage>.from(messages)..add(message);
    return ChatSession(
      id: id,
      messages: newMessages,
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
    );
  }

  /// 更新訊息狀態
  ChatSession updateMessageStatus(String messageId, MessageStatus status) {
    final newMessages = messages.map((msg) {
      if (msg.id == messageId) {
        return msg.copyWithStatus(status);
      }
      return msg;
    }).toList();

    return ChatSession(
      id: id,
      messages: newMessages,
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
    );
  }

  /// 獲取最後一條訊息
  ChatMessage? get lastMessage {
    return messages.isEmpty ? null : messages.last;
  }

  /// 獲取未讀訊息數量
  int get unreadCount {
    return messages
        .where((msg) => !msg.isUser && msg.status == MessageStatus.received)
        .length;
  }

  @override
  String toString() {
    return 'ChatSession(id: $id, messages: ${messages.length}, createdAt: $createdAt, lastUpdated: $lastUpdated)';
  }
}