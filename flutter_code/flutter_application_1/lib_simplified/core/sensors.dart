// AK47 風格精簡版：感測器管理
import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'logger.dart';
import 'models.dart';

class SensorManager {
  static SensorManager? _instance;
  static SensorManager get i => _instance ??= SensorManager._();
  SensorManager._();

  // 感測器數據流
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // 當前設備方向
  DeviceOrientation _currentOrientation = DeviceOrientation.up;
  DeviceOrientation get currentOrientation => _currentOrientation;

  // 方向變化回調
  Function(DeviceOrientation)? _onOrientationChanged;

  // 初始化感測器
  Future<void> init() async {
    try {
      await log('初始化感測器管理器');
      _startAccelerometerListening();
    } catch (e) {
      await log('感測器初始化失敗: $e');
    }
  }

  // 設定方向變化回調
  void setOrientationCallback(Function(DeviceOrientation) callback) {
    _onOrientationChanged = callback;
  }

  // 開始監聽加速度計
  void _startAccelerometerListening() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        _updateOrientation(event.x, event.y, event.z);
      },
      onError: (error) async {
        await log('加速度計錯誤: $error');
      },
    );
  }

  // 更新設備方向
  void _updateOrientation(double x, double y, double z) {
    DeviceOrientation newOrientation;

    // 簡化的方向檢測邏輯
    if (y.abs() > x.abs()) {
      if (y > 5) {
        newOrientation = DeviceOrientation.up;
      } else if (y < -5) {
        newOrientation = DeviceOrientation.down;
      } else {
        return; // 保持當前方向
      }
    } else {
      if (x > 5) {
        newOrientation = DeviceOrientation.right;
      } else if (x < -5) {
        newOrientation = DeviceOrientation.left;
      } else {
        return; // 保持當前方向
      }
    }

    if (newOrientation != _currentOrientation) {
      _currentOrientation = newOrientation;
      _onOrientationChanged?.call(newOrientation);
    }
  }

  // 獲取模擬健康數據
  BodyMetrics getSimulatedHealthData() {
    final random = math.Random();

    return BodyMetrics(
      sleep: 7 + random.nextInt(3), // 7-9 小時
      sleepChange: (random.nextDouble() - 0.5) * 2, // -1 到 +1
      height: 165 + random.nextInt(20), // 165-185 cm
      heightChange: 0.0, // 身高通常不變
      weight: 60 + random.nextInt(30), // 60-90 kg
      weightChange: (random.nextDouble() - 0.5) * 4, // -2 到 +2 kg
      heartRate: 60 + random.nextInt(40), // 60-100 bpm
      heartRateChange: (random.nextDouble() - 0.5) * 20, // -10 到 +10
      bloodPressure: '${110 + random.nextInt(30)}/${70 + random.nextInt(20)}',
      bloodPressureChange: (random.nextDouble() - 0.5) * 10, // -5 到 +5
    );
  }

  // 模擬步數數據
  int getSimulatedStepCount() {
    final random = math.Random();
    return 5000 + random.nextInt(10000); // 5000-15000 步
  }

  // 模擬卡路里消耗
  int getSimulatedCaloriesBurned() {
    final random = math.Random();
    return 1500 + random.nextInt(1000); // 1500-2500 卡路里
  }

  // 獲取當前方向描述
  String getOrientationDescription() {
    switch (_currentOrientation) {
      case DeviceOrientation.up:
        return '豎直向上';
      case DeviceOrientation.down:
        return '豎直向下';
      case DeviceOrientation.left:
        return '左側橫向';
      case DeviceOrientation.right:
        return '右側橫向';
    }
  }

  // 清理資源
  void dispose() async {
    try {
      await _accelerometerSubscription?.cancel();
      _accelerometerSubscription = null;
      await log('感測器管理器已清理');
    } catch (e) {
      await log('感測器清理失敗: $e');
    }
  }
}

// 全域便捷函數
Future<BodyMetrics> getHealthData() async {
  await log('獲取健康數據');
  return SensorManager.i.getSimulatedHealthData();
}

Future<int> getStepCount() async {
  await log('獲取步數數據');
  return SensorManager.i.getSimulatedStepCount();
}

Future<int> getCaloriesBurned() async {
  await log('獲取卡路里消耗數據');
  return SensorManager.i.getSimulatedCaloriesBurned();
}