import 'package:camera/camera.dart';
import '../../../../core/services/app_logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraDatasource {
  final ImagePicker _picker = ImagePicker();

  Future<List<CameraDescription>> getAvailableCameras() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      throw Exception("Camera permission denied");
    }
    return availableCameras();
  }

  Future<CameraController> createCameraController(CameraDescription cameraDescription) async {
    try {
      final CameraController controller = CameraController(
        cameraDescription,
        ResolutionPreset.medium, // 將解析度調整為中等以提高相容性
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // 添加超時機制，避免無限等待
      await controller.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          controller.dispose();
          throw Exception('相機初始化超時');
        },
      );

      // 確保相機真正初始化完成
      if (!controller.value.isInitialized) {
        controller.dispose();
        throw Exception('相機初始化驗證失敗');
      }

      return controller;
    } catch (e) {
      throw Exception('相機控制器創建失敗: $e');
    }
  }

  Future<XFile> takePicture(CameraController controller) async {
    return controller.takePicture();
  }

  Future<void> setFlashMode(CameraController controller, FlashMode mode) async {
    await controller.setFlashMode(mode);
  }

  Future<List<XFile>> pickImagesFromGallery() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      throw Exception("Photos permission denied");
    }
    return _picker.pickMultiImage(imageQuality: 80, limit: 10);
  }
}