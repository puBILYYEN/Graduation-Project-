import '../repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<User?> call(String email, String password) {
    return repository.createUserWithEmailAndPassword(email, password);
  }
}