import 'package:camera/camera.dart';
import '../repositories/camera_repository.dart';

class InitializeCameraUseCase {
  final CameraRepository repository;

  InitializeCameraUseCase(this.repository);

  Future<CameraController> call(CameraDescription cameraDescription) {
    return repository.createCameraController(cameraDescription);
  }
}