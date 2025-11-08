import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/camera_view_model.dart';

/// 測試用的簡化相機頁面 - 用於調試按鈕問題
class TestCameraPage extends StatelessWidget {
  const TestCameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('測試相機頁面', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            debugPrint('🔙 返回按鈕被點擊');
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<CameraViewModel>(
        builder: (context, viewModel, child) {
          debugPrint('🔄 TestCameraPage rebuilding');
          debugPrint('   isInitialized: ${viewModel.isInitialized}');
          debugPrint('   isLoading: ${viewModel.isLoading}');

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 狀態顯示
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'ViewModel 狀態',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'isInitialized: ${viewModel.isInitialized}',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        'isLoading: ${viewModel.isLoading}',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        'controller: ${viewModel.controller != null}',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 測試按鈕 1: 無條件按鈕
                ElevatedButton(
                  onPressed: () {
                    debugPrint('✅ 測試按鈕 1 被點擊（無條件）');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('測試按鈕 1 有效！')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    '測試按鈕 1（無條件）',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 16),

                // 測試按鈕 2: 調用 ViewModel 方法
                ElevatedButton(
                  onPressed: viewModel.isInitialized
                      ? () {
                          debugPrint('✅ 測試按鈕 2 被點擊（調用 toggleFlash）');
                          viewModel.toggleFlash();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(
                    '測試按鈕 2（toggleFlash）\n${viewModel.isInitialized ? "啟用" : "禁用"}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 16),

                // 測試按鈕 3: 調用初始化
                ElevatedButton(
                  onPressed: () {
                    debugPrint('✅ 測試按鈕 3 被點擊（調用 initialize）');
                    viewModel.initialize();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    '測試按鈕 3（初始化）',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 16),

                // 測試按鈕 4: 調用相簿
                ElevatedButton(
                  onPressed: () {
                    debugPrint('✅ 測試按鈕 4 被點擊（調用 pickFromGallery）');
                    viewModel.pickFromGallery(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    '測試按鈕 4（相簿）',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
