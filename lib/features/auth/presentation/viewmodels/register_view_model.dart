
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../../../core/services/profile_photo_service.dart';

class RegisterViewModel extends ChangeNotifier {
  final SignUpUseCase _signUpUseCase;
  final ProfilePhotoService _profilePhotoService = ProfilePhotoService();

  RegisterViewModel(this._signUpUseCase);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _setIsLoading(bool value) {
    _isLoading = value;
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password, {Uint8List? imageData}) async {
    _setIsLoading(true);
    try {
      final user = await _signUpUseCase(email, password);
      if (user != null) {
        if (imageData != null) {
          final photoUrl = await _profilePhotoService.uploadProfilePhoto(imageData);
          await user.updatePhotoURL(photoUrl);
        }
        return true;
      } else {
        return false;
      }
    } catch (error) {
      return false;
    } finally {
      _setIsLoading(false);
    }
  }
}
