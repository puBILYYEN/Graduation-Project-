import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

abstract class CameraRepository {
  Future<List<CameraDescription>> getAvailableCameras();
  Future<CameraController> createCameraController(CameraDescription cameraDescription);
  Future<XFile> takePicture(CameraController controller);
  Future<void> setFlashMode(CameraController controller, FlashMode mode);
  Future<List<XFile>> pickImagesFromGallery();
  Future<Map<String, dynamic>> analyzeImage(String imagePath);
  Future<Map<String, dynamic>> performVolumeCalculation(String imagePath);
}