// ====================================================================
// 相機服務 - CameraService
// ====================================================================
import 'package:camera/camera.dart';

/// 一個專門用來管理相機的服務
class CameraService {
  /// 可用的相機列表
  List<CameraDescription> cameras = [];

  /// 初始化相機，獲取所有可用的相機設備
  Future<void> initializeCameras() async {
    try {
      // 獲取所有可用的相機設備
      cameras = await availableCameras();
      print('找到 ${cameras.length} 個相機設備');

      // 列出所有可用相機的詳細信息
      for (int i = 0; i < cameras.length; i++) {
        print('相機 $i: ${cameras[i].name} - ${cameras[i].lensDirection}');
      }
    } catch (e) {
      // 如果相機初始化失敗，記錄錯誤但不中斷應用程式運行
      print('相機初始化失敗: $e');
      cameras = []; // 設置為空列表，應用程式仍可運行但無相機功能
    }
  }

  /// 獲取後置相機
  CameraDescription? get rearCamera {
    if (cameras.isEmpty) return null;
    try {
      return cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
    } catch (e) {
      // 如果沒有後置相機，返回第一個可用的相機
      return cameras.first;
    }
  }
}
