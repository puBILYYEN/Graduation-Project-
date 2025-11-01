import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/repositories/camera_repository.dart';
import '../datasources/camera_datasource.dart';
import '../datasources/image_processing_datasource.dart';

class CameraRepositoryImpl implements CameraRepository {
  final CameraDatasource _cameraDatasource;
  final ImageProcessingDatasource _imageProcessingDatasource;

  CameraRepositoryImpl(this._cameraDatasource, this._imageProcessingDatasource);

  @override
  Future<List<CameraDescription>> getAvailableCameras() {
    return _cameraDatasource.getAvailableCameras();
  }

  @override
  Future<CameraController> createCameraController(CameraDescription cameraDescription) {
    return _cameraDatasource.createCameraController(cameraDescription);
  }

  @override
  Future<XFile> takePicture(CameraController controller) {
    return _cameraDatasource.takePicture(controller);
  }

  @override
  Future<void> setFlashMode(CameraController controller, FlashMode mode) {
    return _cameraDatasource.setFlashMode(controller, mode);
  }

  @override
  Future<List<XFile>> pickImagesFromGallery() {
    return _cameraDatasource.pickImagesFromGallery();
  }

  @override
  Future<Map<String, dynamic>> analyzeImage(String imagePath) {
    return _imageProcessingDatasource.analyzeImage(imagePath);
  }

  @override
  Future<Map<String, dynamic>> performVolumeCalculation(String imagePath) {
    return _imageProcessingDatasource.performVolumeCalculation(imagePath);
  }
}