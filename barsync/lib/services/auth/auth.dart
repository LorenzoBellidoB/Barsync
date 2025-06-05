import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Iniciar sesión
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        throw FirebaseAuthException(
          code: "user-not-logged-in",
          message: "No hay ningún usuario autenticado.",
        );
      }

      await user.updatePassword(newPassword);
      await user.reload(); // Para asegurar que los cambios se reflejen
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");
      rethrow; // Deja que quien llame maneje el error
    } catch (e) {
      print("Error general en updatePassword: $e");
      rethrow;
    }
  }

  Future<void> deleteUserByEmail(String email) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'deleteUserByEmail',
      );
      final response = await callable.call({'email': email});
      print("Resultado: ${response.data['message']}");
    } catch (e) {
      print("Error al eliminar usuario: $e");
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
