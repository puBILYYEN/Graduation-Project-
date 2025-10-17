import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math' as math;

import '../../../../data/models/measurement_models.dart';
import '../../../../domain/usecases/measurement_calculator.dart';
import '../widgets/custom_painters.dart';

/// 參考物體測量頁面
class ReferenceMeasurementPage extends StatefulWidget {
  final String imagePath;
  final Function(List<MeasurementResult>) onMeasurementComplete;

  const ReferenceMeasurementPage({
    super.key,
    required this.imagePath,
    required this.onMeasurementComplete,
  });

  @override
  State<ReferenceMeasurementPage> createState() => _ReferenceMeasurementPageState();
}

class _ReferenceMeasurementPageState extends State<ReferenceMeasurementPage> {
  // 測量狀態
  MeasurementMode _currentMode = MeasurementMode.calibration;
  bool _isCalibrated = false;
  double _measurementScale = 1.0;

  // 參考物體
  ReferenceObject? _selectedReferenceObject;
  final List<ReferenceObject> _availableReferences = [
    const ReferenceObject(
      type: ReferenceObjectType.coin,
      name: '50元硬幣',
      width: 2.5,
      height: 2.5,
    ),
    const ReferenceObject(
      type: ReferenceObjectType.coin,
      name: '10元硬幣',
      width: 2.0,
      height: 2.0,
    ),
    const ReferenceObject(
      type: ReferenceObjectType.card,
      name: '信用卡',
      width: 8.56,
      height: 5.398,
    ),
    const ReferenceObject(
      type: ReferenceObjectType.utensil,
      name: '標準湯匙',
      width: 15.0,
      height: 3.0,
    ),
  ];

  // 測量點
  List<MeasurementPoint> _referencePoints = [];
  List<MeasurementPoint> _measurementPoints = [];
  List<MeasurementResult> _results = [];

  @override
  void initState() {
    super.initState();
    _selectedReferenceObject = _availableReferences[0];
  }

  /// 處理螢幕點擊
  void _handleTap(Offset position) {
    setState(() {
      switch (_currentMode) {
        case MeasurementMode.calibration:
          _handleCalibrationTap(position);
          break;
        case MeasurementMode.length:
        case MeasurementMode.area:
        case MeasurementMode.volume:
          _handleMeasurementTap(position);
          break;
      }
    });
  }

  /// 處理校準模式點擊
  void _handleCalibrationTap(Offset position) {
    if (_referencePoints.length < 2) {
      _referencePoints.add(MeasurementPoint(
        position: position,
        index: _referencePoints.length,
      ));

      if (_referencePoints.length == 2) {
        _calculateScale();
      }
    } else {
      // 重新校準
      _referencePoints.clear();
      _referencePoints.add(MeasurementPoint(
        position: position,
        index: 0,
      ));
      _isCalibrated = false;
    }
  }

  /// 處理測量模式點擊
  void _handleMeasurementTap(Offset position) {
    if (!_isCalibrated) {
      _showCalibrationWarning();
      return;
    }

    _measurementPoints.add(MeasurementPoint(
      position: position,
      index: _measurementPoints.length,
    ));

    // 根據模式判斷是否自動計算
    switch (_currentMode) {
      case MeasurementMode.length:
        if (_measurementPoints.length == 2) {
          _calculateLength();
        }
        break;
      case MeasurementMode.area:
        if (_measurementPoints.length >= 3) {
          _calculateArea();
        }
        break;
      case MeasurementMode.volume:
        if (_measurementPoints.length >= 3) {
          _calculateVolume();
        }
        break;
      case MeasurementMode.calibration:
        break;
    }
  }

  /// 計算比例
  void _calculateScale() {
    if (_referencePoints.length == 2 && _selectedReferenceObject != null) {
      final pixelDistance = MeasurementCalculator.calculatePixelDistance(
        _referencePoints[0].position,
        _referencePoints[1].position,
      );

      // 使用參考物體的寬度作為實際距離
      final realDistance = _selectedReferenceObject!.width;
      _measurementScale = pixelDistance / realDistance;
      _isCalibrated = true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '校準完成！比例: ${_measurementScale.toStringAsFixed(2)} px/cm',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// 計算長度
  void _calculateLength() {
    if (_measurementPoints.length >= 2) {
      final distance = MeasurementCalculator.calculateRealDistance(
        _measurementPoints[0].position,
        _measurementPoints[1].position,
        _measurementScale,
      );

      final result = MeasurementResult(
        mode: MeasurementMode.length,
        value: distance,
        unit: 'cm',
        points: List.from(_measurementPoints),
        scale: _measurementScale,
      );

      _results.add(result);
      _showResult(result);
    }
  }

  /// 計算面積
  void _calculateArea() {
    if (_measurementPoints.length >= 3) {
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

      _results.add(result);
      _showResult(result);
    }
  }

  /// 計算體積
  void _calculateVolume() {
    if (_measurementPoints.length >= 3) {
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

      _results.add(result);
      _showResult(result);
    }
  }

  /// 顯示結果
  void _showResult(MeasurementResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.description),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 顯示校準警告
  void _showCalibrationWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('請先完成校準！'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// 清除測量點
  void _clearMeasurementPoints() {
    setState(() {
      _measurementPoints.clear();
    });
  }

  /// 完成測量
  void _completeMeasurement() {
    widget.onMeasurementComplete(_results);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '參考物體測量',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _completeMeasurement,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 背景圖片
          Positioned.fill(
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.cover,
            ),
          ),

          // 測量繪圖層
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (details) => _handleTap(details.localPosition),
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

          // 頂部控制面板
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // 參考物體選擇
                  if (_currentMode == MeasurementMode.calibration)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<ReferenceObject>(
                        value: _selectedReferenceObject,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _availableReferences.map((ref) {
                          return DropdownMenuItem(
                            value: ref,
                            child: Text('${ref.name} (${ref.width}cm)'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedReferenceObject = value;
                            _referencePoints.clear();
                            _isCalibrated = false;
                          });
                        },
                      ),
                    ),

                  const SizedBox(height: 12),

                  // 模式選擇按鈕
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildModeButton('校準', MeasurementMode.calibration, Icons.straighten),
                      _buildModeButton('長度', MeasurementMode.length, Icons.linear_scale),
                      _buildModeButton('面積', MeasurementMode.area, Icons.crop_free),
                      _buildModeButton('體積', MeasurementMode.volume, Icons.view_in_ar),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 底部控制面板
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 狀態顯示
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCalibrated ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: _isCalibrated ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isCalibrated
                                ? '已校準 | 比例: ${_measurementScale.toStringAsFixed(2)} px/cm'
                                : '請先標記參考物體進行校準',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 操作按鈕
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        '清除點',
                        Icons.clear,
                        _clearMeasurementPoints,
                        Colors.orange,
                      ),
                      _buildActionButton(
                        '完成',
                        Icons.check,
                        _completeMeasurement,
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 說明文字
          if (_currentMode == MeasurementMode.calibration && !_isCalibrated)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '請在照片中標記 ${_selectedReferenceObject?.name ?? "參考物體"} 的兩端進行校準',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 建立模式按鈕
  Widget _buildModeButton(String label, MeasurementMode mode, IconData icon) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMode = mode;
          if (mode != MeasurementMode.calibration) {
            _measurementPoints.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 建立操作按鈕
  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed, Color color) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}