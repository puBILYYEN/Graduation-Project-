import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../viewmodels/exercise_viewmodel.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/api/socket_service.dart';
import '../../domain/entities/exercise_plan.dart';
import 'exercise_plan_detail_page.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({Key? key}) : super(key: key);

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  String selectedChart = '長條圖';
  String? selectedExerciseType;

  // Socket.IO 相關
  final SocketService _socketService = SocketService();
  bool _isConnected = false;
  String _aiRecommendation = '正在連接 AI 顧問...';
  bool _isLoadingRecommendation = true;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _ragResponseSubscription;

  // 運動計劃相關
  List<ExercisePlan> _recommendedPlans = [];
  bool _isLoadingPlans = false;
  String? _currentPlanRequestId; // 追蹤當前請求

  // 運動類型數據（用於 UI 顯示）
  final List<Map<String, dynamic>> exerciseTypes = [
    {'name': '跑步', 'icon': Icons.directions_run},
    {'name': '游泳', 'icon': Icons.pool},
    {'name': '騎車', 'icon': Icons.directions_bike},
    {'name': '重訓', 'icon': Icons.fitness_center},
    {'name': '瑜珈', 'icon': Icons.self_improvement},
    {'name': '其他', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    AppLogger.logEvent('運動頁面初始化');
    _initializeSocketConnection();
  }

  @override
  void dispose() {
    AppLogger.logEvent('離開運動頁面');
    _connectionSubscription?.cancel();
    _ragResponseSubscription?.cancel();
    super.dispose();
  }

  /// 初始化 Socket.IO 連接並自動獲取 AI 建議
  Future<void> _initializeSocketConnection() async {
    // 監聽連接狀態
    _connectionSubscription = _socketService.connectionStatus.listen((isConnected) {
      setState(() {
        _isConnected = isConnected;
      });

      if (isConnected) {
        AppLogger.logEvent('運動頁面 Socket.IO 已連接');
        // 連接成功後，自動獲取 AI 建議
        _requestAIRecommendation();
      } else {
        setState(() {
          _aiRecommendation = '連接已中斷，請重試';
          _isLoadingRecommendation = false;
        });
      }
    });

    // 監聽 RAG 回應
    _ragResponseSubscription = _socketService.ragResponses.listen((response) {
      _handleRagResponse(response);
    });

    // 開始連接
    final connected = await _socketService.connect();
    if (!connected && mounted) {
      setState(() {
        _aiRecommendation = '無法連接到 AI 顧問服務';
        _isLoadingRecommendation = false;
      });
    }
  }

  /// 根據用戶運動數據自動請求 AI 建議
  void _requestAIRecommendation() {
    final viewModel = context.read<ExerciseViewModel>();

    // 構建包含用戶運動數據的問題
    final aerobicGoal = viewModel.aerobicGoal;
    final strengthGoal = viewModel.strengthGoal;
    final weeklyTotal = viewModel.weeklyTotalHours;

    String question = '我是一位想要改善運動習慣的使用者。';

    if (aerobicGoal != null) {
      question += '本週有氧運動目標是${aerobicGoal.target.toInt()}${aerobicGoal.unit}，目前完成${aerobicGoal.current.toInt()}${aerobicGoal.unit}。';
    }

    if (strengthGoal != null) {
      question += '肌力訓練目標是每週${strengthGoal.target.toInt()}${strengthGoal.unit}，目前完成${strengthGoal.current.toInt()}${strengthGoal.unit}。';
    }

    question += '本週總運動時間是${weeklyTotal.toStringAsFixed(1)}小時。請根據我的運動數據，給我一些具體的運動建議和改進方向。';

    setState(() {
      _isLoadingRecommendation = true;
      _aiRecommendation = '正在分析您的運動數據...';
    });

    _socketService.sendRagQuestion(question);
  }

  /// 處理 RAG 回應
  void _handleRagResponse(Map<String, dynamic> response) {
    // 檢查是否是計劃生成的回應
    if (response['requestType'] == 'generatePlans') {
      _handlePlansResponse(response);
      return;
    }

    // 一般 AI 建議回應
    if (response['error'] == true) {
      setState(() {
        _aiRecommendation = '獲取建議失敗: ${response['message'] ?? '未知錯誤'}';
        _isLoadingRecommendation = false;
      });
    } else {
      final answer = response['answer'] ?? response['response'] ?? response['message'] ?? '未收到有效回應';
      setState(() {
        _aiRecommendation = answer;
        _isLoadingRecommendation = false;
      });
    }
  }

  /// 處理計劃生成回應
  void _handlePlansResponse(Map<String, dynamic> response) {
    if (response['error'] == true) {
      setState(() {
        _isLoadingPlans = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成計劃失敗: ${response['message'] ?? '未知錯誤'}')),
      );
      return;
    }

    final answer = response['answer'] ?? response['response'] ?? response['message'] ?? '';

    // 嘗試從 AI 回應中解析計劃數據
    try {
      // AI 應該返回 JSON 格式的計劃列表
      final plans = _parsePlansFromAIResponse(answer);
      setState(() {
        _recommendedPlans = plans;
        _isLoadingPlans = false;
      });
    } catch (e) {
      developer.log('解析計劃失敗: $e');
      // 如果解析失敗，創建一個簡單的計劃
      setState(() {
        _recommendedPlans = _createFallbackPlans(answer);
        _isLoadingPlans = false;
      });
    }
  }

  /// 從 AI 回應解析計劃
  List<ExercisePlan> _parsePlansFromAIResponse(String response) {
    try {
      // 嘗試找到 JSON 部分
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final List<dynamic> jsonList = json.decode(jsonStr);
        return jsonList.map((item) => ExercisePlan.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      developer.log('JSON 解析失敗: $e');
    }

    // 如果沒有找到 JSON，返回空列表
    return [];
  }

  /// 創建備用計劃（當 AI 回應無法解析時）
  List<ExercisePlan> _createFallbackPlans(String aiResponse) {
    return [
      ExercisePlan(
        id: '1',
        title: 'AI 推薦綜合訓練計劃',
        subtitle: '基於您當前的運動數據',
        description: '這是根據您的運動數據量身定制的綜合訓練計劃。',
        difficulty: 'intermediate',
        durationWeeks: 4,
        goals: ['提升心肺功能', '增強肌肉力量', '改善運動習慣'],
        detailedPlan: aiResponse,
      ),
    ];
  }

  // 系統日誌記錄函數
  Future<void> _logAction(String action) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/system_log.log');
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = '[$timestamp] 運動頁面: $action\n';

      await logFile.writeAsString(logEntry, mode: FileMode.append);
      developer.log(action, name: 'ExercisePage');
    } catch (e) {
      developer.log('日誌記錄錯誤: $e', name: 'ExercisePage', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox.shrink(),
        title: const Text(
          '運動',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExerciseTypes(),
              const SizedBox(height: 24),
              _buildExerciseReview(),
              const SizedBox(height: 24),
              _buildExerciseGoals(),
              const SizedBox(height: 24),
              _buildAIRecommendations(),
              const SizedBox(height: 24),
              _buildRecommendedPlans(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 運動類型選擇區塊
  Widget _buildExerciseTypes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '運動類型',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: exerciseTypes.length,
          itemBuilder: (context, index) {
            final type = exerciseTypes[index];
            final isSelected = selectedExerciseType == type['name'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedExerciseType = isSelected ? null : type['name'];
                });
                _logAction('選擇運動類型: ${type['name']}');

                // 如果選擇了類型，顯示新增運動記錄對話框
                if (!isSelected) {
                  _showAddExerciseDialog(type['name']);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    type['name'],
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.blue[800] : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 顯示新增運動記錄對話框
  void _showAddExerciseDialog(String exerciseType) {
    final durationController = TextEditingController();
    final notesController = TextEditingController();
    final caloriesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('新增 $exerciseType 記錄'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '時長（分鐘）*',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '消耗卡路里（選填）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: '備註（選填）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                selectedExerciseType = null;
              });
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (durationController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('請輸入時長')),
                );
                return;
              }

              final viewModel = context.read<ExerciseViewModel>();

              try {
                await viewModel.addExerciseRecord(
                  type: exerciseType,
                  duration: int.parse(durationController.text),
                  notes: notesController.text.isEmpty ? null : notesController.text,
                  calories: caloriesController.text.isEmpty
                      ? null
                      : int.parse(caloriesController.text),
                );

                setState(() {
                  selectedExerciseType = null;
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ 運動記錄新增成功！'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('新增失敗: $e')),
                  );
                }
              }
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  // 運動紀錄回顧區塊
  Widget _buildExerciseReview() {
    return Consumer<ExerciseViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '運動紀錄回顧',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedChart = '長條圖';
                        });
                        _logAction('切換至長條圖');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedChart == '長條圖'
                              ? Colors.grey[200]
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(child: Text('長條圖')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedChart = '曲線圖';
                        });
                        _logAction('切換至曲線圖');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedChart == '曲線圖'
                              ? Colors.grey[200]
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(child: Text('曲線圖')),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '每週運動總時間',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                '${viewModel.weeklyTotalHours.toStringAsFixed(1)} 小時',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '最近 4 週',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildWeeklyChart(),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              if (viewModel.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (viewModel.exerciseRecords.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '尚無運動記錄',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...viewModel.exerciseRecords
                    .map((record) => _buildExerciseRecordItem(record)),
            ],
          ),
        );
      },
    );
  }

  // 週次圖表
  Widget _buildWeeklyChart() {
    return Consumer<ExerciseViewModel>(
      builder: (context, viewModel, child) {
        final weeklyData = viewModel.weeklyData;
        if (weeklyData.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text(
                '暫無數據',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(weeklyData.length, (index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 40,
                    height: weeklyData[index] * 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '第 ${index + 1} 週',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // 運動紀錄項目
  Widget _buildExerciseRecordItem(dynamic record) {
    // 取得運動類型對應的圖標
    IconData getIconForType(String type) {
      switch (type) {
        case '跑步':
          return Icons.directions_run;
        case '游泳':
          return Icons.pool;
        case '騎車':
          return Icons.directions_bike;
        case '重訓':
          return Icons.fitness_center;
        case '瑜珈':
          return Icons.self_improvement;
        default:
          return Icons.more_horiz;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(getIconForType(record.type), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.type,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${record.duration} 分鐘${record.calories != null ? " · ${record.calories} kcal" : ""}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (record.notes != null)
                  Text(
                    record.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('刪除記錄'),
                  content: const Text('確定要刪除這筆運動記錄嗎？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('刪除'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                try {
                  await context.read<ExerciseViewModel>().deleteExerciseRecord(record.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ 記錄已刪除'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('刪除失敗: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // 運動目標區塊
  Widget _buildExerciseGoals() {
    return Consumer<ExerciseViewModel>(
      builder: (context, viewModel, child) {
        final aerobicGoal = viewModel.aerobicGoal;
        final strengthGoal = viewModel.strengthGoal;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '運動目標',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (aerobicGoal != null)
                _buildGoalItem(
                  '有氧運動',
                  aerobicGoal.current,
                  aerobicGoal.target,
                  unit: aerobicGoal.unit,
                  showSubtitle: false,
                ),
              const SizedBox(height: 16),
              if (strengthGoal != null)
                _buildGoalItem(
                  '肌力訓練',
                  strengthGoal.current,
                  strengthGoal.target,
                  unit: strengthGoal.unit,
                  showFraction: true,
                ),
            ],
          ),
        );
      },
    );
  }

  // 目標項目
  Widget _buildGoalItem(String title, double current, double target, {String unit = '分鐘', bool showSubtitle = true, bool showFraction = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSubtitle)
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (!showSubtitle)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${current.toInt()}/${target.toInt()} $unit',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        if (showFraction)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${current.toInt()}/${target.toInt()} $unit',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: current / target,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
          minHeight: 8,
        ),
      ],
    );
  }

  // AI 建議區塊
  Widget _buildAIRecommendations() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'AI 運動建議',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isConnected ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (_isConnected)
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: _isLoadingRecommendation ? Colors.grey : Colors.blue,
                      ),
                      onPressed: _isLoadingRecommendation ? null : _requestAIRecommendation,
                      tooltip: '重新獲取建議',
                    ),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.grey),
                    onPressed: () {
                      _showAIQuestionDialog();
                    },
                    tooltip: '詢問 AI',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingRecommendation)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('正在分析您的運動數據...'),
              ],
            )
          else
            Text(
              _aiRecommendation,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  /// 顯示 AI 問題對話框
  void _showAIQuestionDialog() {
    final questionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('詢問 AI 運動顧問'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '您可以詢問任何運動相關的問題',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: questionController,
              decoration: const InputDecoration(
                labelText: '輸入您的問題',
                border: OutlineInputBorder(),
                hintText: '例如：如何改善跑步姿勢？',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (questionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('請輸入問題')),
                );
                return;
              }

              setState(() {
                _isLoadingRecommendation = true;
                _aiRecommendation = '正在查詢相關資訊...';
              });

              _socketService.sendRagQuestion(questionController.text.trim());

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('問題已發送，請稍候...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('發送'),
          ),
        ],
      ),
    );
  }

  /// 請求 AI 生成運動計劃
  void _requestGeneratePlans() {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI 服務未連接，請稍候')),
      );
      return;
    }

    final viewModel = context.read<ExerciseViewModel>();
    final aerobicGoal = viewModel.aerobicGoal;
    final strengthGoal = viewModel.strengthGoal;
    final weeklyTotal = viewModel.weeklyTotalHours;

    String question = '''
請根據以下運動數據，為用戶生成 3 個不同難度級別的運動計劃（初階、中階、進階）。

用戶當前數據：
- 有氧運動目標：${aerobicGoal?.target.toInt() ?? 200}${aerobicGoal?.unit ?? '分鐘'}/週，當前完成：${aerobicGoal?.current.toInt() ?? 0}${aerobicGoal?.unit ?? '分鐘'}
- 肌力訓練目標：${strengthGoal?.target.toInt() ?? 2}${strengthGoal?.unit ?? '天'}/週，當前完成：${strengthGoal?.current.toInt() ?? 0}${strengthGoal?.unit ?? '天'}
- 本週總運動時間：${weeklyTotal.toStringAsFixed(1)}小時

請返回 JSON 格式的計劃列表，每個計劃包含：
- title: 計劃標題
- subtitle: 副標題
- description: 計劃概述（100字內）
- difficulty: 難度（beginner/intermediate/advanced）
- durationWeeks: 計劃週數
- goals: 訓練目標列表（3-5個目標）
- detailedPlan: 詳細的週次訓練計劃（包含每週的具體訓練內容、強度、休息安排）

JSON 格式範例：
[
  {
    "title": "八週跑步入門計劃",
    "subtitle": "適合初階跑者",
    "description": "這個計劃專為跑步新手設計...",
    "difficulty": "beginner",
    "durationWeeks": 8,
    "goals": ["建立跑步習慣", "提升心肺耐力", "完成5公里目標"],
    "detailedPlan": "第1-2週：每週跑3次，每次20分鐘...\\n第3-4週：..."
  }
]

請只返回 JSON 陣列，不要其他文字說明。
''';

    setState(() {
      _isLoadingPlans = true;
      _currentPlanRequestId = DateTime.now().millisecondsSinceEpoch.toString();
    });

    // 發送請求，標記為計劃生成請求
    final request = {
      'question': question,
      'timestamp': DateTime.now().toIso8601String(),
      'source': 'flutter_app',
      'requestType': 'generatePlans',
      'requestId': _currentPlanRequestId,
    };

    _socketService.sendRagQuestion(question);
  }

  // 推薦運動計畫區塊
  Widget _buildRecommendedPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '推薦運動計畫',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isConnected)
              TextButton.icon(
                onPressed: _isLoadingPlans ? null : _requestGeneratePlans,
                icon: Icon(
                  _isLoadingPlans ? Icons.hourglass_empty : Icons.refresh,
                  size: 16,
                ),
                label: Text(_isLoadingPlans ? '生成中...' : 'AI 生成'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // 顯示計劃列表
        if (_isLoadingPlans)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('AI 正在為您生成個性化運動計劃...'),
                ],
              ),
            ),
          )
        else if (_recommendedPlans.isEmpty)
          // 顯示預設計劃和提示
          Column(
            children: [
              _buildDefaultPlanCard('八週跑步計畫', '初階跑者適用', 'beginner'),
              const SizedBox(height: 12),
              _buildDefaultPlanCard('全身肌力訓練', '建立肌肉基礎', 'intermediate'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '點擊右上角「AI 生成」獲取基於您數據的個性化計劃',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          // 顯示 AI 生成的計劃
          Column(
            children: _recommendedPlans
                .map((plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPlanCard(plan),
                    ))
                .toList(),
          ),
      ],
    );
  }

  // AI 生成的計畫卡片
  Widget _buildPlanCard(ExercisePlan plan) {
    return GestureDetector(
      onTap: () {
        _logAction('點擊運動計畫: ${plan.title}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExercisePlanDetailPage(plan: plan),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(plan.difficultyColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.fitness_center,
                size: 24,
                color: Color(plan.difficultyColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(plan.difficultyColor).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          plan.difficultyText,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(plan.difficultyColor),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plan.durationWeeks} 週計劃',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // 預設計畫卡片
  Widget _buildDefaultPlanCard(String title, String subtitle, String difficulty) {
    // 創建簡單的預設計劃
    final plan = ExercisePlan(
      id: title,
      title: title,
      subtitle: subtitle,
      description: '這是一個經典的$title，適合$subtitle的訓練者。點擊查看詳細內容，或點擊右上角「AI 生成」獲取基於您數據的個性化計劃。',
      difficulty: difficulty,
      durationWeeks: difficulty == 'beginner' ? 8 : 6,
      goals: [
        '建立規律運動習慣',
        '提升整體體能水平',
        '達成個人運動目標',
      ],
      detailedPlan: '''
這是一個$title的基礎框架：

第 1-2 週：適應期
- 建立運動習慣
- 學習正確姿勢
- 逐步提升強度

第 3-4 週：強化期
- 增加訓練頻率
- 提升運動強度
- 注重動作質量

第 5-6 週：鞏固期
- 維持訓練節奏
- 挑戰更高強度
- 培養運動樂趣

建議：
1. 每週至少訓練 3 次
2. 注意休息和恢復
3. 保持循序漸進
4. 記錄運動數據

點擊右上角「AI 生成」，獲取更詳細的個性化訓練計劃！
''',
    );

    return _buildPlanCard(plan);
  }
}
