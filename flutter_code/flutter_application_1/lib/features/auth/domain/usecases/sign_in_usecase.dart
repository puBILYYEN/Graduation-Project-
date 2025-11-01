import '../repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<User?> call(String email, String password) {
    return repository.signInWithEmailAndPassword(email, password);
  }
}