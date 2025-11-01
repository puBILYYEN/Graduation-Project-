import '../repositories/camera_repository.dart';

class PerformVolumeCalculationUseCase {
  final CameraRepository repository;

  PerformVolumeCalculationUseCase(this.repository);

  Future<Map<String, dynamic>> call(String imagePath) {
    return repository.performVolumeCalculation(imagePath);
  }
}