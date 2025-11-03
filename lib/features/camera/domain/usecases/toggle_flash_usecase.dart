import 'package:camera/camera.dart';
import '../repositories/camera_repository.dart';

class ToggleFlashUseCase {
  final CameraRepository repository;

  ToggleFlashUseCase(this.repository);

  Future<void> call(CameraController controller, FlashMode mode) {
    return repository.setFlashMode(controller, mode);
  }
}