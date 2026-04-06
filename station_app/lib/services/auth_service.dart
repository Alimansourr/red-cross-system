import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanedEmail = email.trim();
    final cleanedPassword = password.trim();

    if (cleanedEmail.isEmpty || cleanedPassword.isEmpty) {
      throw Exception('Please enter email and password.');
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanedEmail,
        password: cleanedPassword,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Login failed. No user returned.');
      }

      final doc = await _db.collection('users').doc(user.uid).get();

      Map<String, dynamic> profile = {};
      if (doc.exists) {
        profile = doc.data() ?? {};
      }

      return {
        'uid': user.uid,
        'email': user.email,
        ...profile,
      };
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyError(e.code));
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Database error occurred.');
    } catch (_) {
      throw Exception('Login failed. Please try again.');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return 'Login failed. Please try again.';
    }
  }
}