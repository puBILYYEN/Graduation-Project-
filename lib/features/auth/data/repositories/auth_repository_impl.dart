import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource datasource;

  AuthRepositoryImpl(this.datasource);

  @override
  Stream<User?> get authStateChanges => datasource.authStateChanges;

  @override
  User? get currentUser => datasource.currentUser;

  @override
  Future<User?> signInWithGoogle({GoogleSignInAccount? googleUser}) {
    return datasource.signInWithGoogle(googleUser: googleUser);
  }

  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) {
    return datasource.signInWithEmailAndPassword(email, password);
  }

  @override
  Future<User?> createUserWithEmailAndPassword(String email, String password) {
    return datasource.createUserWithEmailAndPassword(email, password);
  }

  @override
  Future<void> signOut() {
    return datasource.signOut();
  }
}