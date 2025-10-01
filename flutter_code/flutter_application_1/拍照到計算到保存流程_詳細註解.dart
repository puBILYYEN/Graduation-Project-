// ====================================================================
// 【拍照到計算到保存的完整流程】- 逐步執行順序註解
// ====================================================================

/// 步驟1: 主要拍照功能入口
/// 位置: lib/main.dart:4314-4356
Future<void> _takeVolumePhoto() async {
  if (!_controller!.value.isInitialized) return;

  try {
    // ===== 第1步: 拍照前準備 =====
    await log('開始容積計算拍照...');

    // ===== 第2步: 建立檔案路徑 =====
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = path.join(
      directory.path,
      'volume_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    // ===== 第3步: 執行拍照操作 =====
    final XFile image = await _controller!.takePicture();

    // ===== 第4步: 將照片保存到本地檔案 =====
    await image.saveTo(imagePath);

    // ===== 第5步: 將照片保存到相簿 =====
    try {
      final result = await ImageGallerySaver.saveFile(imagePath);
      await log('容積計算照片保存結果: $result');
      if (result != null && (result['isSuccess'] == true || result['errorMessage'] == null)) {
        await log('容積計算照片已保存: $imagePath');
        await log('照片已保存到相簿，供YOLO處理');
      } else {
        await log('❌ 容積計算照片保存失敗');
      }
    } catch (e) {
      await log('保存照片到相簿失敗: $e');
    }

    // ===== 第6步: 立即進行邊緣檢測和容積計算 =====
    await _performAutoVolumeCalculation(imagePath);
  } catch (e) {
    await log('容積計算拍照錯誤: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('拍照失敗: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// 步驟2: 自動容積計算核心功能
/// 位置: lib/main.dart:4676-4730
Future<void> _performAutoVolumeCalculation(String imagePath) async {
  try {
    // ===== 第7步: 開始計算流程 =====
    await log('開始自動容積計算流程...');

    // ===== 第8步: 圖像邊緣檢測 =====
    setState(() {
      _detectedEdges = _performEdgeDetection(); // 模擬圖像處理和邊緣檢測
    });

    // ===== 第9步: 容器形狀識別 =====
    final detectedShape = _detectContainerShape(_detectedEdges);
    setState(() {
      _containerShape = detectedShape; // 自動辨識容器形狀 (長方體/圓柱體/立方體)
    });

    // ===== 第10步: 尺寸估算 =====
    final estimatedDimensions = _estimateDimensionsFromEdges(); // 根據邊緣估算尺寸

    // ===== 第11步: 容積計算 =====
    final volume = _calculateVolumeFromDimensions(estimatedDimensions); // 基於形狀計算容積

    // ===== 第12步: 更新UI狀態 =====
    setState(() {
      _calculatedVolume = volume;
      _showVolumeResult = false; // 不顯示界面結果區域，避免按鍵移位
    });

    await log('容積計算完成: ${volume.toStringAsFixed(2)} cm³');

    // ===== 第13步: 生成RAG系統數據 =====
    await _generateRagData(imagePath, volume);

    // ===== 第14步: 顯示計算結果給用戶 =====
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '容積計算完成！\n${volume.toStringAsFixed(2)} cm³ (${(volume / 1000).toStringAsFixed(3)} L)'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '查看詳細',
          textColor: Colors.white,
          onPressed: () => _showDetailedVolumeResult(),
        ),
      ),
    );
  } catch (e) {
    await log('自動容積計算錯誤: $e');
  }
}

/// 步驟3: 尺寸估算函數
/// 位置: lib/main.dart:4733-4760
Map<String, double> _estimateDimensionsFromEdges() {
  if (_detectedEdges.length < 4) {
    return {'length': 10.0, 'width': 8.0, 'height': 12.0}; // 預設值
  }

  // ===== 第15步: 計算邊緣框的尺寸 =====
  double minX = _detectedEdges.map((e) => e.dx).reduce((a, b) => a < b ? a : b);
  double maxX = _detectedEdges.map((e) => e.dx).reduce((a, b) => a > b ? a : b);
  double minY = _detectedEdges.map((e) => e.dy).reduce((a, b) => a < b ? a : b);
  double maxY = _detectedEdges.map((e) => e.dy).reduce((a, b) => a > b ? a : b);

  // ===== 第16步: 像素轉實際尺寸 =====
  double pixelToCm = 0.05; // 假設 1 像素 = 0.05 公分

  double width = (maxX - minX) * pixelToCm;
  double height = (maxY - minY) * pixelToCm;
  double depth = width * 0.8; // 假設深度是寬度的80%

  return {
    'length': width,
    'width': depth,
    'height': height,
  };
}

/// 步驟4: 容積計算函數
/// 位置: lib/main.dart:4763-4775
double _calculateVolumeFromDimensions(Map<String, double> dimensions) {
  // ===== 第17步: 根據容器形狀計算容積 =====
  switch (_containerShape) {
    case '長方體':
      // 長方體容積 = 長 × 寬 × 高
      return dimensions['length']! * dimensions['width']! * dimensions['height']!;

    case '圓柱體':
      // 圓柱體容積 = π × 半徑² × 高
      double radius = dimensions['length']! / 2; // 假設直徑是檢測寬度
      return math.pi * radius * radius * dimensions['height']!;

    case '立方體':
      // 立方體容積 = 邊長³
      double side = (dimensions['length']! + dimensions['width']!) / 2; // 平均值
      return side * side * side;

    default:
      // 預設為長方體計算
      return dimensions['length']! * dimensions['width']! * dimensions['height']!;
  }
}

/// 步驟5: RAG數據生成函數
/// 位置: lib/main.dart:4023-4078
Future<void> _generateRagData(String imagePath, double volume) async {
  try {
    // ===== 第18步: 創建容器分析數據結構 =====
    final ragData = ContainerAnalysisData(
      imagePath: imagePath,
      timestamp: DateTime.now().toIso8601String(),
      container: ContainerInfo(
        shape: _containerShape,           // 檢測到的容器形狀
        material: '推測材質',            // 材質推測
        color: '推測顏色',              // 顏色推測
        features: ['自動檢測特徵'],      // 檢測到的特徵
      ),
      measurements: MeasurementResults(
        volume: volume,                  // 計算出的容積
        confidence: 0.85,               // 信心度
        method: '智能視覺測量',          // 測量方法
        dimensions: {                   // 尺寸數據
          '長度': 10.0,
          '寬度': 8.0,
          '高度': 12.0,
        },
      ),
      metadata: AnalysisMetadata(
        deviceInfo: '智能手機',          // 設備信息
        algorithm: 'EdgeDetection+ShapeRecognition', // 使用算法
        processingTime: 1.5,            // 處理時間
        notes: '自動容積計算完成',       // 備註
      ),
    );

    // ===== 第19步: 將RAG數據轉換為JSON格式 =====
    final jsonData = ragData.toJson();

    // ===== 第20步: 記錄RAG數據 =====
    await log('RAG 數據已生成: ${jsonData.toString()}');

  } catch (e) {
    await log('RAG 數據生成失敗: $e');
  }
}

// ====================================================================
// 【完整執行流程總結】
// ====================================================================
/*
執行順序:
1. 用戶按下拍照按鈕 → _takeVolumePhoto() 被調用
2. 拍照前準備和檔案路徑設定
3. 執行相機拍照 → _controller!.takePicture()
4. 保存照片到本地檔案 → image.saveTo(imagePath)
5. 保存照片到相簿 → ImageGallerySaver.saveFile(imagePath)
6. 開始容積計算 → _performAutoVolumeCalculation(imagePath)
7. 圖像邊緣檢測 → _performEdgeDetection()
8. 容器形狀識別 → _detectContainerShape()
9. 尺寸估算 → _estimateDimensionsFromEdges()
10. 容積計算 → _calculateVolumeFromDimensions()
11. 更新UI狀態
12. 生成RAG數據 → _generateRagData()
13. 顯示結果給用戶

關鍵數據流:
拍照 → 圖像檔案 → 邊緣檢測 → 形狀識別 → 尺寸估算 → 容積計算 → RAG數據 → 結果顯示
*/