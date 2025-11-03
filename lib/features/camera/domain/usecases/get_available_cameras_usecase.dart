import 'package:camera/camera.dart';
import '../repositories/camera_repository.dart';

class GetAvailableCamerasUseCase {
  final CameraRepository repository;

  GetAvailableCamerasUseCase(this.repository);

  Future<List<CameraDescription>> call() {
    return repository.getAvailableCameras();
  }
}