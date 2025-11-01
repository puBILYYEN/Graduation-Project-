import 'package:camera/camera.dart';
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
    final CameraController controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    return controller;
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