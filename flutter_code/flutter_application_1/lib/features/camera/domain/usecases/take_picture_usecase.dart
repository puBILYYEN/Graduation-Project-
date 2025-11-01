import 'package:camera/camera.dart';
import '../repositories/camera_repository.dart';

class TakePictureUseCase {
  final CameraRepository repository;

  TakePictureUseCase(this.repository);

  Future<XFile> call(CameraController controller) {
    return repository.takePicture(controller);
  }
}