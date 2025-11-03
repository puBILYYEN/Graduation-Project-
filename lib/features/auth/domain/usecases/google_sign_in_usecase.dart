import '../repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added

class GoogleSignInUseCase {
  final AuthRepository repository;

  GoogleSignInUseCase(this.repository);

  Future<User?> call() {
    return repository.signInWithGoogle();
  }
}
