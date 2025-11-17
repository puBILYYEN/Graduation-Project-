import 'package:camera/camera.dart';
import '../../../../core/services/app_logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraDatasource {
  final ImagePicker _picker = ImagePicker();

  Future<List<CameraDescription>> getAvailableCameras() async {
    // 跳過 permission_handler 調用，避免在 Realme/OPPO/Xiaomi 設備上卡死
    // 權限已在 AndroidManifest.xml 中聲明，系統會在應用啟動時處理
    return availableCameras();
  }

  Future<CameraController> createCameraController(CameraDescription cameraDescription) async {
    int maxRetries = 2; // 減少重試次數從 3 到 2
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        print('[CAMERA DEBUG] 🎥 嘗試初始化相機 (第 ${retryCount + 1}/$maxRetries 次)');
        print('[CAMERA DEBUG] 📱 相機設備: ${cameraDescription.name}');

        final CameraController controller = CameraController(
          cameraDescription,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        print('[CAMERA DEBUG] ⏱️ 開始初始化相機控制器...');
        final startTime = DateTime.now();

        // 縮短超時時間從 10秒 到 5秒
        await controller.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('[CAMERA DEBUG] ⏰ 相機初始化超時 (5秒)');
            controller.dispose();
            throw Exception('相機初始化超時 (5秒)');
          },
        );

        final duration = DateTime.now().difference(startTime);
        print('[CAMERA DEBUG] ⏱️ 初始化耗時: ${duration.inMilliseconds}ms');

        // 確保相機真正初始化完成
        if (!controller.value.isInitialized) {
          print('[CAMERA DEBUG] ❌ 初始化驗證失敗');
          controller.dispose();
          throw Exception('相機初始化驗證失敗');
        }

        print('[CAMERA DEBUG] ✅ SUCCESS: 相機初始化成功');
        return controller;

      } on CameraException catch (e) {
        print('[CAMERA DEBUG] ❌ ERROR: 相機設備錯誤 (${e.code}): ${e.description}');

        if (e.code == 'cameraNotReadable') {
          print('[CAMERA DEBUG] 💡 HINT: 相機可能正被其他應用程式使用');
        }

        retryCount++;
        if (retryCount >= maxRetries) {
          throw Exception('相機初始化失敗 (${e.code}): ${e.description ?? "未知錯誤"}');
        }

        // 縮短重試等待時間
        final waitTime = Duration(milliseconds: 500 * retryCount);
        print('[CAMERA DEBUG] ⏳ 等待 ${waitTime.inMilliseconds}ms 後重試...');
        await Future.delayed(waitTime);

      } catch (e) {
        print('[CAMERA DEBUG] ❌ ERROR: ${e.toString()}');
        retryCount++;

        if (retryCount >= maxRetries) {
          throw Exception('相機控制器創建失敗: $e');
        }

        final waitTime = Duration(milliseconds: 500 * retryCount);
        print('[CAMERA DEBUG] ⏳ 等待 ${waitTime.inMilliseconds}ms 後重試...');
        await Future.delayed(waitTime);
      }
    }

    throw Exception('相機初始化失敗: 已達到最大重試次數');
  }

  Future<XFile> takePicture(CameraController controller) async {
    return controller.takePicture();
  }

  Future<void> setFlashMode(CameraController controller, FlashMode mode) async {
    await controller.setFlashMode(mode);
  }

  Future<List<XFile>> pickImagesFromGallery() async {
    // ✅ 修復：移除 permission_handler 調用以避免死鎖
    // 權限已在 AndroidManifest.xml 中聲明，ImagePicker 會自動處理權限請求
    // 如果權限不足，ImagePicker 會拋出異常或返回空列表

    /* ❌ 已移除：會導致 MethodChannel 死鎖
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      throw Exception("Photos permission denied");
    }
    */

    return _picker.pickMultiImage(imageQuality: 80, limit: 10);
  }
}