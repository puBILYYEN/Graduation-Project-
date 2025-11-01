import 'package:camera/camera.dart';
import '../repositories/camera_repository.dart';

class SwitchCameraUseCase {
  final CameraRepository repository;

  SwitchCameraUseCase(this.repository);

  Future<CameraController> call(CameraDescription cameraDescription) {
    return repository.createCameraController(cameraDescription);
  }
}