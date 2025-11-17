import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../../core/widgets/edge_detection_painter.dart' as core_edge;
import 'package:flutter_application_1/features/nutrition/presentation/pages/nutrition_label_screen.dart';
import 'package:flutter_application_1/features/nutrition/presentation/pages/multi_image_processing_screen.dart';
import 'package:flutter_application_1/features/measurement/presentation/pages/reference_measurement_page.dart';
import '../../../../data/models/reference_object.dart';
import '../../../analysis/data/models/container_analysis.dart';
import '../../../measurement/data/models/measurement.dart';
import 'package:flutter_application_1/core/services/logging/logger.dart';
import 'package:flutter_application_1/core/services/api/api_services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/features/camera/presentation/viewmodels/camera_view_model.dart';

// ====================================================================
// 相機頁面 (Camera Screen)
// ====================================================================
/*
模組化建議：【頁面模組 - pages/camera/camera_screen.dart】
CameraScreen 和 _CameraScreenState 是核心的相機功能模組。
包含相機控制、拍照、圖像處理等複雜邏輯，適合獨立成為相機模組。
可能需要額外的子模組：
- widgets/camera_controls.dart (相機控制元件)
- utils/image_processing.dart (圖像處理工具)
*/

// ----- [pages/camera/camera_screen.dart] 開始 -----
// 相機螢幕頁面 - 提供食物拍攝功能，支援前後鏡頭切換、閃光燈控制和圖庫選取
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

// 相機頁面狀態類別 (Camera Screen State Class)
class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  // ViewModel
  late final CameraViewModel _viewModel;

  // 錯誤狀態
  bool _hasError = false;
  String _errorMessage = '';

  // The state is now managed by the CameraViewModel.
  // We only keep UI-related state here.

  // ========== 測量功能已停用 ==========
  // 可拖拽測量框架相關變數
  // double _framePosX = 50.0;
  // double _framePosY = 100.0;
  // double _frameWidth = 200.0;
  // double _frameHeight = 150.0;
  // bool _showMeasurementFrame = true;

  // 邊界檢查常數
  // static const double _BOTTOM_SAFE_ZONE = 250.0;
  // static const double _TOP_SAFE_ZONE = 100.0;
  // static const double _SIDE_MARGIN = 15.0;
  // ========================================

  /// 初始化相機頁面狀態 - 設定觀察器、螢幕方向並啟動相機
  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<CameraViewModel>(context, listen: false);
    _viewModel.addListener(_onViewModelChanged);


    // 註冊應用程式生命週期觀察器：監聽應用程式前景/背景狀態變化
    WidgetsBinding.instance.addObserver(this);

    // 鎖定豎螢幕：確保相機介面在豎屏模式下使用
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // 延遲初始化測量框架位置，等待widget構建完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _initializeMeasurementFramePosition(); // 測量功能已停用
      _initializeCamera();
    });
  }

  /// 初始化相機
  Future<void> _initializeCamera() async {
    try {
      print('[CAMERA DEBUG] 開始初始化相機...');

      // 添加超時保護，最多等待 15 秒（考慮到所有內部超時）
      await _viewModel.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('[CAMERA DEBUG] ERROR: 整體初始化超時（15秒）');
          throw Exception('相機初始化超時（超過15秒）\n\n可能原因：\n1. 相機權限未授予\n2. 相機被其他應用程式佔用\n3. 設備相機硬體故障');
        },
      );

      print('[CAMERA DEBUG] 相機初始化完成');

      // 確認初始化狀態
      if (!_viewModel.isInitialized) {
        throw Exception('相機初始化狀態異常');
      }

    } catch (e) {
      print('[CAMERA DEBUG] ERROR: 相機初始化錯誤: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '相機初始化失敗: $e';
        });
      }
    }
  }

  void _onViewModelChanged() {
    debugPrint('📢 [UI] _onViewModelChanged 被調用!');
    debugPrint('   isInitialized: ${_viewModel.isInitialized}');
    debugPrint('   controller != null: ${_viewModel.controller != null}');
    setState(() {
      // The UI will be rebuilt whenever the view model notifies its listeners
    });
  }

  // ========== 測量功能已停用 ==========
  /// 初始化測量框架位置 - 將框架置中在相機預覽有效區域
  // void _initializeMeasurementFramePosition() {
  //   if (!mounted) return;

  //   // 獲取螢幕尺寸
  //   final Size screenSize = MediaQuery.of(context).size;

  //   // 計算有效相機預覽區域（扣除頂部和底部安全區域）
  //   final double availableWidth = screenSize.width - (2 * _SIDE_MARGIN);
  //   final double availableHeight =
  //       screenSize.height - _TOP_SAFE_ZONE - _BOTTOM_SAFE_ZONE;

  //   // 計算居中位置
  //   final double centerX = (availableWidth - _frameWidth) / 2 + _SIDE_MARGIN;
  //   final double centerY =
  //       (availableHeight - _frameHeight) / 2 + _TOP_SAFE_ZONE;

  //   setState(() {
  //     _framePosX = centerX.clamp(
  //         _SIDE_MARGIN, screenSize.width - _frameWidth - _SIDE_MARGIN);
  //     _framePosY = centerY.clamp(
  //         _TOP_SAFE_ZONE, screenSize.height - _BOTTOM_SAFE_ZONE - _frameHeight);
  //   });

  //   print(
  //       '測量框架已初始化至居中位置: (${_framePosX.toStringAsFixed(1)}, ${_framePosY.toStringAsFixed(1)})');
  // }
  // ========================================

  /// 清理資源方法 - 移除觀察器、取消訂閱並釋放相機資源
  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    WidgetsBinding.instance.removeObserver(this);
    // The view model will handle its own disposal of the controller and subscriptions
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // This is now handled by the CameraViewModel
  }

  Future<void> _showPermissionDialog(String permissionName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('需要${permissionName}權限'),
          content: Text('此應用需要${permissionName}權限才能正常運作。請在設置中手動開啟權限。'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('去設置'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // ====================================================================
  // UI建構函數 (UI Build Function)
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    // 步驟1：設定螢幕方向（拍照頁面鎖定為正常豎螢幕）
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // 步驟2：獲取螢幕尺寸和設備類型
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600; // 判斷是否為平板
    final isLargeScreen = screenSize.width > 900; // 判斷是否為大螢幕
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape; // 判斷系統方向

    // 步驟3：計算按鈕旋轉角度（根據設備實際物理方向決定）
    final double iconRotation = _viewModel.isDeviceLandscape ? 90.0 : 0.0;
    logSync('按鈕旋轉角度: ${_viewModel.isDeviceLandscape} -> $iconRotation度');

    // 步驟4：建構主要UI結構
    return Scaffold(
      backgroundColor: Colors.black, // 設定背景色為黑色
      body: Stack(
        children: [
          // 相機預覽或錯誤顯示（響應式全螢幕）
          if (_viewModel.isInitialized && _viewModel.controller != null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final previewSize = _viewModel.controller!.value.previewSize;
                  if (previewSize == null) {
                    print('[CameraScreen] ⚠️ previewSize is null!');
                    return const Center(child: CircularProgressIndicator());
                  }

                  print('[CameraScreen] Preview Size: $previewSize');
                  print('[CameraScreen] Screen Size: ${constraints.maxWidth} x ${constraints.maxHeight}');

                  // ✅ 使用 FittedBox 填滿整個螢幕（會裁切部分內容以填滿）
                  return FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: previewSize.height,
                      height: previewSize.width,
                      child: CameraPreview(_viewModel.controller!),
                    ),
                  );
                },
              ),
            ),
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _hasError = false;
                            _errorMessage = '';
                          });

                          // 主動請求所有權限並初始化相機
                          // await _requestAndInitializeCamera();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('重新嘗試'),
                      ),
                      if (_errorMessage.contains('永久拒絕') ||
                          _errorMessage.contains('設定'))
                        const SizedBox(width: 16),
                      if (_errorMessage.contains('永久拒絕') ||
                          _errorMessage.contains('設定'))
                        ElevatedButton(
                          onPressed: () {
                            openAppSettings();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('開啟設定'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (!_viewModel.isInitialized && !_hasError)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '正在初始化相機...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          // 頂部工具列
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + (isTablet ? 80 : 60),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 關閉按鈕
                    IconButton(
                      icon: Transform.rotate(
                        angle: iconRotation * math.pi / 180,
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: isTablet ? 32 : 28,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                    // 旋轉圖示 - 隨其他按鈕一起自動轉向
                    IconButton(
                      icon: Transform.rotate(
                        angle: iconRotation * math.pi / 180,
                        child: Icon(
                          Icons.screen_rotation,
                          color: Colors.orange,
                          size: isTablet ? 32 : 28,
                        ),
                      ),
                      onPressed: () {
                        // 移除手動測試功能，保留按鈕但不執行任何操作
                      },
                    ),

                    // 閃光燈按鈕
                    IconButton(
                      icon: Transform.rotate(
                        angle: iconRotation * math.pi / 180,
                        child: Icon(
                          _viewModel.isFlashOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                          size: isTablet ? 32 : 28,
                        ),
                      ),
                      onPressed: () => _viewModel.toggleFlash(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 方向指示箭頭 (已隱藏，移到屏幕外避免攔截觸摸事件)
          if (!_viewModel.isDeviceLandscape)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: -1000, // 移到屏幕外，完全不可見且不攔截觸摸
              child: Opacity(
                opacity: 0.0, // 雙重保險：透明 + 移出屏幕
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '朝上',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 底部控制區域
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: 10,
                    top: isLandscape ? 10 : 20,
                    left: 20,
                    right: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 建議距離文字 (橫向模式下隱藏以節省空間)
                      if (!isLandscape)
                        Padding(
                          padding: EdgeInsets.only(bottom: 15),
                          child: Text(
                            '建議距離：20-30 公分',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: isTablet ? 16 : 14,
                            ),
                          ),
                        ),

                      // 底部按鈕列
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 相簿按鈕
                          GestureDetector(
                            onTap: () => _viewModel.pickFromGallery(context),
                            child: Container(
                              width: isTablet ? 60 : 50,
                              height: isTablet ? 60 : 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                shape: BoxShape.circle,
                              ),
                              child: Transform.rotate(
                                angle: iconRotation * math.pi / 180,
                                child: Icon(
                                  Icons.photo_library,
                                  color: Colors.white,
                                  size: isTablet ? 28 : 24,
                                ),
                              ),
                            ),
                          ),

                          // 智慧拍照按鈕（食物辨識 + YOLO 分析）
                          GestureDetector(
                            onTap: () => _viewModel.takePictureAndNavigate(context),
                            child: Container(
                              width: isTablet ? 100 : 80,
                              height: isTablet ? 100 : 80,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Transform.rotate(
                                angle: iconRotation * math.pi / 180,
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: isTablet ? 40 : 32,
                                ),
                              ),
                            ),
                          ),

                          // 切換鏡頭按鈕
                          GestureDetector(
                            onTap: () => _viewModel.switchCamera(),
                            child: Container(
                              width: isTablet ? 60 : 50,
                              height: isTablet ? 60 : 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                shape: BoxShape.circle,
                              ),
                              child: Transform.rotate(
                                angle: iconRotation * math.pi / 180,
                                child: Icon(
                                  Icons.flip_camera_ios,
                                  color: Colors.white,
                                  size: isTablet ? 28 : 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (!isLandscape) SizedBox(height: 15),

                      // ========== 測量功能已停用 ==========
                      // 容積計算控制界面 (拍照前設定)
                      /* if (!_viewModel.isDeviceLandscape) ...[
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          margin: const EdgeInsets.symmetric(horizontal: 30),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              // 自動辨識結果顯示
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.auto_awesome,
                                            color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          '辨識: ${_viewModel.containerShape}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '直接拍照，系統會自動辨識容器形狀並計算容積',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              // 顯示計算結果
                              if (_viewModel.showVolumeResult) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.green, width: 1),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '計算結果',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${_viewModel.calculatedVolume.toStringAsFixed(2)} cm³',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '(${(_viewModel.calculatedVolume / 1000).toStringAsFixed(3)} 公升)',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ], */
                      // ========================================
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ========== 測量功能已停用 ==========
          // 邊緣檢測疊加層（有檢測結果時顯示）
          /* if (_viewModel.detectedEdges.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: core_edge.EdgeDetectionPainter(_viewModel.detectedEdges),
              ),
            ),

          // 可拖拽的紅色測量框架
          if (_showMeasurementFrame)
            Positioned(
              left: _framePosX,
              top: _framePosY,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final screenSize = MediaQuery.of(context).size;

                    // 使用預定義常數計算強化的安全區域
                    final double maxX =
                        screenSize.width - _frameWidth - _SIDE_MARGIN;
                    final double maxY =
                        screenSize.height - _BOTTOM_SAFE_ZONE - _frameHeight;
                    final double minX = _SIDE_MARGIN;
                    final double minY = _TOP_SAFE_ZONE;

                    // 計算新位置
                    double newX =
                        (_framePosX + details.delta.dx).clamp(minX, maxX);
                    double newY =
                        (_framePosY + details.delta.dy).clamp(minY, maxY);

                    // 多重安全檢查：確保測量框絕對不會覆蓋底部按鈕區域
                    final double frameBottom = newY + _frameHeight;
                    final double safeBottomLimit =
                        screenSize.height - _BOTTOM_SAFE_ZONE;

                    if (frameBottom > safeBottomLimit) {
                      newY = safeBottomLimit - _frameHeight;
                    }

                    // 最終邊界驗證
                    newX = newX.clamp(minX, maxX);
                    newY = newY.clamp(minY, maxY);

                    _framePosX = newX;
                    _framePosY = newY;

                    // Debug輸出檢查邊界
                    print(
                        '框架位置: (${newX.toStringAsFixed(1)}, ${newY.toStringAsFixed(1)}) 底部: ${(newY + _frameHeight).toStringAsFixed(1)} 安全限制: ${safeBottomLimit.toStringAsFixed(1)}');
                  });
                },
                child: Transform.rotate(
                  angle: iconRotation * math.pi / 180, // 使用與按鈕相同的旋轉角度
                  child: Container(
                    width: _frameWidth,
                    height: _frameHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.red,
                        width: 3.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '測量框架',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ), */
          // ========================================
        ],
      ),
    );
  }
}

// ===== 【UI頁面模組】結束 =====

// ===== 【工具類模組】開始 =====
// ====================================================================
// ----- [pages/camera/camera_screen.dart] 結束 -----===
// ----- [pages/camera/camera_screen.dart] 結束 -----
