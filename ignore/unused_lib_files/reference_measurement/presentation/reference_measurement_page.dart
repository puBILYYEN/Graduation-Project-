// ====================================================================
// 參考物體測量頁面 (Reference Measurement Page)
// ====================================================================
// 此模組包含參考物體校準和測量功能

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math' as math;
import '../../../data/models/measurement.dart';
import '../../../data/services/reference_database.dart';
import '../../../data/services/measurement_calculator.dart';
import '../../../widgets/custom_painters.dart';

/// 參考物體測量頁面
class ReferenceMeasurementPage extends StatefulWidget {
  final String imagePath;
  final Function(List<MeasurementResult>) onMeasurementComplete;

  const ReferenceMeasurementPage(
      {super.key,
      required this.imagePath,
      required this.onMeasurementComplete});

  @override
  State<ReferenceMeasurementPage> createState() =>
      _ReferenceMeasurementPageState();
}

class _ReferenceMeasurementPageState extends State<ReferenceMeasurementPage> {
  // 測量狀態變數
  MeasurementMode _currentMode = MeasurementMode.calibration;
  ReferenceObject? _selectedReference;
  double _measurementScale = 1.0;
  bool _isCalibrated = false;

  // 繪圖相關變數
  final List<MeasurementPoint> _referencePoints = [];
  final List<MeasurementPoint> _measurementPoints = [];
  final List<MeasurementResult> _results = [];

  // 圖片尺寸
  Size? _imageSize;
  final GlobalKey _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          _getModeTitle(),
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (_isCalibrated && _currentMode != MeasurementMode.calibration)
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: _clearMeasurements,
              tooltip: '清除測量',
            ),
        ],
      ),
      body: Column(
        children: [
          // 圖片顯示和繪圖區域
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  // 背景圖片
                  Center(
                    child: Image.file(
                      File(widget.imagePath),
                      key: _imageKey,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // 繪圖覆蓋層 - 限制在相機預覽區域，不覆蓋底部控制面板
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.of(context).size.height *
                        0.25, // 保留底部25%給控制面板
                    child: GestureDetector(
                      onTapDown: _handleTapDown,
                      child: CustomPaint(
                        painter: MeasurementPainter(
                          referencePoints: _referencePoints,
                          measurementPoints: _measurementPoints,
                          currentMode: _currentMode,
                          isCalibrated: _isCalibrated,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 底部控制面板
          _buildControlPanel(),
        ],
      ),
    );
  }

  /// 取得當前模式標題
  String _getModeTitle() {
    switch (_currentMode) {
      case MeasurementMode.calibration:
        return '校準參考物體';
      case MeasurementMode.length:
        return '長度測量';
      case MeasurementMode.area:
        return '面積測量';
      case MeasurementMode.volume:
        return '體積測量';
    }
  }

  /// 處理點擊事件
  void _handleTapDown(TapDownDetails details) {
    // 檢查點擊位置是否在允許的測量區域內（不在底部控制面板區域）
    final screenHeight = MediaQuery.of(context).size.height;
    final maxAllowedY = screenHeight * 0.75; // 只允許在螢幕上方75%區域點擊

    if (details.localPosition.dy > maxAllowedY) {
      // 點擊位置在底部控制面板區域，忽略此次點擊
      return;
    }

    if (_currentMode == MeasurementMode.calibration) {
      _handleCalibrationTap(details.localPosition);
    } else if (_isCalibrated) {
      _handleMeasurementTap(details.localPosition);
    }
  }

  /// 處理校準模式的點擊
  void _handleCalibrationTap(Offset position) {
    setState(() {
      if (_referencePoints.length < 2) {
        _referencePoints.add(MeasurementPoint(
          position: position,
          index: _referencePoints.length,
        ));

        // 如果有兩個點，進行校準
        if (_referencePoints.length == 2 && _selectedReference != null) {
          _performCalibration();
        }
      }
    });
  }

  /// 處理測量模式的點擊
  void _handleMeasurementTap(Offset position) {
    setState(() {
      _measurementPoints.add(MeasurementPoint(
        position: position,
        index: _measurementPoints.length,
      ));

      // 根據模式執行不同測量
      _performMeasurement();
    });
  }

  /// 執行校準
  void _performCalibration() {
    if (_referencePoints.length >= 2 && _selectedReference != null) {
      final double realSize = math.max(
        _selectedReference!.width,
        _selectedReference!.height,
      );

      _measurementScale = MeasurementCalculator.calculateScale(
        _referencePoints[0].position,
        _referencePoints[1].position,
        realSize,
      );

      setState(() {
        _isCalibrated = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('校準完成！比例: ${_measurementScale.toStringAsFixed(2)} px/cm'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// 執行測量
  void _performMeasurement() {
    if (!_isCalibrated || _measurementPoints.isEmpty) return;

    switch (_currentMode) {
      case MeasurementMode.length:
        if (_measurementPoints.length >= 2) {
          _measureLength();
        }
        break;
      case MeasurementMode.area:
        if (_measurementPoints.length >= 3) {
          _measureArea();
        }
        break;
      case MeasurementMode.volume:
        if (_measurementPoints.length >= 3) {
          _measureVolume();
        }
        break;
      default:
        break;
    }
  }

  /// 測量長度
  void _measureLength() {
    final points = _measurementPoints.length >= 2
        ? _measurementPoints.sublist(_measurementPoints.length - 2)
        : _measurementPoints;
    final distance = MeasurementCalculator.calculateRealDistance(
      points[0].position,
      points[1].position,
      _measurementScale,
    );

    final result = MeasurementResult(
      mode: MeasurementMode.length,
      value: distance,
      unit: 'cm',
      points: points,
      scale: _measurementScale,
    );

    setState(() {
      _results.add(result);
    });
  }

  /// 測量面積
  void _measureArea() {
    final area = MeasurementCalculator.calculatePolygonArea(
      _measurementPoints.map((p) => p.position).toList(),
      _measurementScale,
    );

    final result = MeasurementResult(
      mode: MeasurementMode.area,
      value: area,
      unit: 'cm',
      points: List.from(_measurementPoints),
      scale: _measurementScale,
    );

    setState(() {
      _results.add(result);
    });
  }

  /// 測量體積
  void _measureVolume() {
    final volume = MeasurementCalculator.estimateVolume(
      _measurementPoints.map((p) => p.position).toList(),
      _measurementScale,
    );

    final result = MeasurementResult(
      mode: MeasurementMode.volume,
      value: volume,
      unit: 'cm',
      points: List.from(_measurementPoints),
      scale: _measurementScale,
    );

    setState(() {
      _results.add(result);
    });
  }

  /// 清除測量結果
  void _clearMeasurements() {
    setState(() {
      _measurementPoints.clear();
      _results.clear();
    });
  }

  /// 建構控制面板
  Widget _buildControlPanel() {
    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 校準階段
          if (!_isCalibrated) ...[
            _buildReferenceSelector(),
            SizedBox(height: 12),
            Text(
              _getReferenceInstruction(),
              style: TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
          // 測量階段
          if (_isCalibrated) ...[
            _buildModeSelector(),
            SizedBox(height: 12),
            _buildInstructions(),
            if (_results.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildResultsDisplay(),
            ],
          ],
          SizedBox(height: 16),
          // 操作按鈕
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// 建構參考物體選擇器
  Widget _buildReferenceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '選擇參考物體:',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ReferenceObjectDatabase.getAllObjects()
              .map((obj) => _buildReferenceButton(obj))
              .toList(),
        ),
      ],
    );
  }

  /// 建構參考物體按鈕
  Widget _buildReferenceButton(ReferenceObject obj) {
    final isSelected = _selectedReference == obj;
    return GestureDetector(
      onTap: () => setState(() => _selectedReference = obj),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[700],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          obj.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 取得參考物體指示文字
  String _getReferenceInstruction() {
    if (_selectedReference == null) {
      return '請先選擇一個參考物體';
    } else if (_referencePoints.isEmpty) {
      return '點擊參考物體的兩個端點進行校準';
    } else if (_referencePoints.length == 1) {
      return '點擊參考物體的另一個端點';
    } else {
      return '校準中...';
    }
  }

  /// 建構測量模式選擇器
  Widget _buildModeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildModeButton(MeasurementMode.length, '長度', Icons.straighten),
        _buildModeButton(MeasurementMode.area, '面積', Icons.crop_square),
        _buildModeButton(MeasurementMode.volume, '體積', Icons.view_in_ar),
      ],
    );
  }

  /// 建構模式按鈕
  Widget _buildModeButton(MeasurementMode mode, String label, IconData icon) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _currentMode = mode;
        _measurementPoints.clear();
        _results.clear();
      }),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 建構指示文字
  Widget _buildInstructions() {
    String instruction;
    switch (_currentMode) {
      case MeasurementMode.length:
        instruction = '點擊兩個端點測量長度';
        break;
      case MeasurementMode.area:
        instruction = '點擊多個點圍成區域測量面積';
        break;
      case MeasurementMode.volume:
        instruction = '點擊多個點圍成底面估算體積';
        break;
      default:
        instruction = '';
    }

    return Text(
      instruction,
      style: TextStyle(color: Colors.white70, fontSize: 14),
      textAlign: TextAlign.center,
    );
  }

  /// 建構結果顯示
  Widget _buildResultsDisplay() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '測量結果:',
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ..._results.map((result) => Text(
                result.description,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              )),
        ],
      ),
    );
  }

  /// 建構操作按鈕
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (_isCalibrated)
          ElevatedButton(
            onPressed: _results.isNotEmpty ? _saveResults : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('完成測量'),
          ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
          child: Text('取消'),
        ),
        if (_isCalibrated)
          ElevatedButton(
            onPressed: _resetCalibration,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('重新校準'),
          ),
      ],
    );
  }

  /// 保存結果
  void _saveResults() {
    widget.onMeasurementComplete(_results);
    Navigator.of(context).pop();
  }

  /// 重置校準
  void _resetCalibration() {
    setState(() {
      _isCalibrated = false;
      _referencePoints.clear();
      _measurementPoints.clear();
      _results.clear();
      _currentMode = MeasurementMode.calibration;
    });
  }
}
