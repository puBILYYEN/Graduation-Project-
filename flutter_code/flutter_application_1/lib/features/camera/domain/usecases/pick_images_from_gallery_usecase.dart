import 'package:image_picker/image_picker.dart';
import '../repositories/camera_repository.dart';

class PickImagesFromGalleryUseCase {
  final CameraRepository repository;

  PickImagesFromGalleryUseCase(this.repository);

  Future<List<XFile>> call() {
    return repository.pickImagesFromGallery();
  }
}