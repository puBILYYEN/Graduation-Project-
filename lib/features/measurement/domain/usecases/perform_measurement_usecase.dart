import '../entities/measurement_result.dart';
import '../repositories/measurement_repository.dart';
import 'measurement_calculator.dart';

/// 執行測量用例
class PerformMeasurementUseCase {
  final MeasurementRepository _repository;

  const PerformMeasurementUseCase(this._repository);

  /// 執行測量操作
  ///
  /// [type] 測量類型
  /// [points] 測量點列表
  /// [scale] 比例尺（像素/厘米）
  /// [referenceObject] 參考物體（可選）
  ///
  /// 業務規則：
  /// 1. 不同測量類型需要不同數量的測量點
  /// 2. 比例尺必須大於0
  /// 3. 自動生成測量ID和時間戳
  /// 4. 自動保存測量結果
  Future<MeasurementResult> call({
    required MeasurementType type,
    required List<MeasurementPoint> points,
    required double scale,
    ReferenceObject? referenceObject,
  }) async {
    // 驗證輸入參數
    _validateInput(type, points, scale);

    try {
      // 根據測量類型計算結果
      final value = _calculateValue(type, points, scale);

      // 生成測量結果
      final result = MeasurementResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        value: value,
        unit: _getUnit(type),
        points: points,
        scale: scale,
        measuredAt: DateTime.now(),
        metadata: MeasurementMetadata(
          deviceModel: 'Unknown', // 實際應用中會從設備信息獲取
          appVersion: '1.0.0',
          processingTime: 0.1, // 實際測量時間
          settings: {},
          referenceObject: referenceObject,
        ),
      );

      // 保存測量結果
      final success = await _repository.saveMeasurementResult(result);
      if (!success) {
        throw Exception('保存測量結果失敗');
      }

      return result;
    } catch (e) {
      throw Exception('執行測量失敗: $e');
    }
  }

  /// 驗證輸入參數
  void _validateInput(MeasurementType type, List<MeasurementPoint> points, double scale) {
    if (scale <= 0) {
      throw Exception('比例尺必須大於0');
    }

    switch (type) {
      case MeasurementType.length:
        if (points.length < 2) {
          throw Exception('長度測量需要至少2個測量點');
        }
        break;
      case MeasurementType.area:
        if (points.length < 3) {
          throw Exception('面積測量需要至少3個測量點');
        }
        break;
      case MeasurementType.volume:
        if (points.length < 3) {
          throw Exception('體積測量需要至少3個測量點');
        }
        break;
      case MeasurementType.calibration:
        if (points.length != 2) {
          throw Exception('校準模式需要恰好2個測量點');
        }
        break;
    }
  }

  /// 根據測量類型計算數值
  double _calculateValue(MeasurementType type, List<MeasurementPoint> points, double scale) {
    final offsets = points.map((p) => Offset(p.x, p.y)).toList();

    switch (type) {
      case MeasurementType.length:
        return MeasurementCalculator.calculateRealDistance(
          offsets.first,
          offsets.last,
          scale,
        );
      case MeasurementType.area:
        return MeasurementCalculator.calculatePolygonArea(offsets, scale);
      case MeasurementType.volume:
        return MeasurementCalculator.estimateVolume(offsets, scale);
      case MeasurementType.calibration:
        return MeasurementCalculator.calculatePixelDistance(
          offsets.first,
          offsets.last,
        );
    }
  }

  /// 獲取測量單位
  String _getUnit(MeasurementType type) {
    switch (type) {
      case MeasurementType.length:
        return 'cm';
      case MeasurementType.area:
        return 'cm²';
      case MeasurementType.volume:
        return 'cm³';
      case MeasurementType.calibration:
        return 'px';
    }
  }
}

// 為了編譯通過，添加 Offset 類別的定義
class Offset {
  final double dx;
  final double dy;

  const Offset(this.dx, this.dy);
}