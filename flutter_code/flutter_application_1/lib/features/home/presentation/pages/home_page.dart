// ----- [pages/home/home_page.dart] 開始 -----
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/nutrient_data.dart';
import '../../../../data/models/chat_message.dart';
import '../../../../core/services/api/socket_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'dart:async';

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

// 首頁內容狀態管理類別 - 管理卡路里追蹤和營養素數據
class _HomePageContentState extends State<HomePageContent> {
  // 當前已攝取的卡路里數量
  double currentCalories = 1200;

  // 目標卡路里攝取量
  double targetCalories = 2000;

  // 宏量營養素比例數據：包含營養素名稱、百分比和顯示顏色
  List<NutrientData> nutrients = [
    NutrientData('蛋白質', 25, Colors.blue[300]!), // 蛋白質 25% - 藍色
    NutrientData('碳水化合物', 35, Colors.grey[400]!), // 碳水化合物 35% - 灰色
    NutrientData('脂肪', 25, Colors.grey[400]!), // 脂肪 25% - 灰色
    NutrientData('膳食纖維', 15, Colors.grey[400]!), // 膳食纖維 15% - 灰色
  ];

  // Socket.IO 相關狀態
  final SocketService _socketService = SocketService();
  bool _isConnected = false;
  bool _isConnecting = false;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Map<String, dynamic>>? _responseSubscription;

  // ====================================================================
  // 首頁建構方法和主要 UI
  // ====================================================================
  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _responseSubscription?.cancel();
    super.dispose();
  }

  /// 初始化 Socket.IO 連接
  void _initializeSocket() async {
    // 監聽連接狀態
    _connectionSubscription = _socketService.connectionStatus.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
          _isConnecting = false;
        });
      }
    });

    // 監聽 RAG 回應
    _responseSubscription = _socketService.ragResponses.listen((response) {
      if (mounted) {
        _handleRagResponse(response);
      }
    });

    // 嘗試連接
    setState(() {
      _isConnecting = true;
    });

    final connected = await _socketService.connect();
    if (!connected && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('無法連接到 AI 服務，請檢查網路連接'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// 建構首頁使用者介面 - 顯示營養追蹤和健康概覽
  @override
  Widget build(BuildContext context) {
    // 鎖定首頁為豎螢幕：確保用戶體驗一致性
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, // 允許正向直立
      DeviceOrientation.portraitDown, // 允許倒向直立
    ]);

    return Scaffold(
      backgroundColor: Colors.grey[50], // 設定頁面背景為淺灰色
      appBar: AppBar(
        // 頂部應用程式列
        backgroundColor: Colors.transparent, // 透明背景
        elevation: 0, // 無陰影效果
        // 左側選單按鈕
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.grey[800]), // 選單圖示
          onPressed: () {}, // 暫時無功能
        ),
        // 頁面標題
        title: Text(
          '首頁',
          style: TextStyle(
            color: Colors.grey[800], // 深灰色文字
            fontSize: 20, // 字體大小
            fontWeight: FontWeight.w500, // 中等粗細
          ),
        ),
        centerTitle: true, // 標題置中
        // 右側操作按鈕
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.grey[800]),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 每日熱量目標
            _buildCalorieSection(),
            const SizedBox(height: 20),

            // 宏量熱量比例
            _buildMacroSection(),
            const SizedBox(height: 20),

            // 個人化飲食建議
            _buildAISection(),
            const SizedBox(height: 20), // 底部額外間距
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // 首頁 UI 組件方法
  // ====================================================================

  // 熱量目標區塊
  Widget _buildCalorieSection() {
    double progress = currentCalories / targetCalories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '每日熱量目標',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            Text(
              '${currentCalories.toInt()}/${targetCalories.toInt()} kcal',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey[300],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress > 1 ? 1 : progress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 宏量營養素區塊
  Widget _buildMacroSection() {
    // 動態生成營養素比例文字
    String ratioText = nutrients
        .map((nutrient) =>
            '${nutrient.name} ${nutrient.percentage.toStringAsFixed(1)}%')
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '宏量熱量比例',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 20),

        // 營養素百分比顯示
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                ratioText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 營養素圖表
              Column(
                children: [
                  Text(
                    '本日',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: nutrients
                        .map((nutrient) => _buildNutrientBar(nutrient))
                        .toList(),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 測試功能區塊 (僅在大螢幕上顯示)
        if (MediaQuery.of(context).size.height > 700) ...[
          const SizedBox(height: 15),
          _buildTestSection(),
        ],
      ],
    );
  }

  // 營養素長條圖
  Widget _buildNutrientBar(NutrientData nutrient) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey[200],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 50,
                height: (80 * nutrient.percentage / 100).clamp(0, 80),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: nutrient.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          nutrient.name,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // 測試功能區塊
  Widget _buildTestSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '測試功能：',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildTestButton('更新蛋白質', () => _updateNutrientData('蛋白質', 30.0)),
              _buildTestButton(
                  '更新碳水', () => _updateNutrientData('碳水化合物', 40.0)),
              _buildTestButton('重置數據', _resetData),
            ],
          ),
        ],
      ),
    );
  }

  // 測試按鈕
  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.blue[700],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }

  // AI 建議區塊
  Widget _buildAISection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '個人化飲食建議',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI 健康助手',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    '為您量身打造營養建議',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 問題輸入區域 - 顯示連接狀態
          GestureDetector(
            onTap: _isConnected ? () {
              _showQuestionDialog();
            } : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.grey[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isConnected ? Colors.grey[200]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isConnecting
                          ? '正在連接 AI 服務...'
                          : _isConnected
                              ? '有什麼營養問題想諮詢嗎？'
                              : '無法連接到 AI 服務',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isConnected ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                  ),
                  if (_isConnecting)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey[400],
                      ),
                    )
                  else
                    Icon(
                      _isConnected ? Icons.mic_outlined : Icons.wifi_off_outlined,
                      color: _isConnected ? Colors.grey[400] : Colors.red[300],
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 首頁功能方法
  // ====================================================================

  // 更新營養素數據
  void _updateNutrientData(String name, double newPercentage) {
    setState(() {
      for (int i = 0; i < nutrients.length; i++) {
        if (nutrients[i].name == name) {
          nutrients[i] = NutrientData(name, newPercentage, Colors.blue[300]!);
          break;
        }
      }
    });
  }

  // 重置數據
  void _resetData() {
    setState(() {
      // 重置熱量數據
      currentCalories = 1200;
      targetCalories = 2000;

      // 重置營養素數據
      nutrients = [
        NutrientData('蛋白質', 25, Colors.blue[300]!),
        NutrientData('碳水化合物', 35, Colors.grey[400]!),
        NutrientData('脂肪', 25, Colors.grey[400]!),
        NutrientData('膳食纖維', 15, Colors.grey[400]!),
      ];
    });
  }

  // 顯示問題輸入對話框
  void _showQuestionDialog() {
    final TextEditingController questionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI 健康助手',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '請輸入您想諮詢的健康或營養問題：',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: questionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '例如：我應該如何增加蛋白質攝取？',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (questionController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  _handleAIQuestion(questionController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('發送'),
            ),
          ],
        );
      },
    );
  }

  // 處理 AI 問題 - 透過 Socket.IO 發送到 RAG 系統
  void _handleAIQuestion(String question) {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('無法發送問題，請檢查網路連接'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 顯示正在處理的提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在處理您的問題：$question'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );

    // 透過 Socket.IO 發送問題到 RAG 系統
    _socketService.sendRagQuestion(question);
  }

  // 處理 RAG 回應
  void _handleRagResponse(Map<String, dynamic> response) {
    if (response['error'] == true) {
      // 處理錯誤回應
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI 處理錯誤：${response['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // 處理正常回應
      final aiResponse = response['response'] ?? response['message'] ?? '收到回應';
      _showAIResponse(response['question'] ?? '您的問題', aiResponse);
    }
  }

  // 顯示 AI 回應對話框
  void _showAIResponse(String question, String response) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.blue[100],
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: Colors.blue[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI 健康助手回應',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '您的問題：',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'AI 回應：',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                response,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('關閉'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showQuestionDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('繼續提問'),
            ),
          ],
        );
      },
    );
  }
}

// ====================================================================
// ----- [pages/home/home_page.dart] 結束 -----