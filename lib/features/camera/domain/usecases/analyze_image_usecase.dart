import '../repositories/camera_repository.dart';

class AnalyzeImageUseCase {
  final CameraRepository repository;

  AnalyzeImageUseCase(this.repository);

  Future<Map<String, dynamic>> call(String imagePath) {
    return repository.analyzeImage(imagePath);
  }
}