import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<String?> signUpUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return 'We could not create your account at the moment. Please try again.';
      }

      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'photoUrl': '',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await user.sendEmailVerification();
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapSignupError(e);
    } catch (_) {
      return 'We could not create your account at the moment. Please try again.';
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null) {
        return {
          'success': false,
          'message': 'We could not verify your session. Please try again.',
        };
      }

      final doc = await _firestore
          .collection('users')
          .doc(refreshedUser.uid)
          .get();

      final role = (doc.data()?['role'] ?? 'user').toString().toLowerCase();

      if (role != 'admin' && !refreshedUser.emailVerified) {
        await _auth.signOut();
        return {
          'success': false,
          'message':
              'Please verify your email before logging in. Check inbox or spam.',
        };
      }

      return {
        'success': true,
        'role': role,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _mapLoginError(e),
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Sign in failed. Please try again in a moment.',
      };
    }
  }

  Future<String?> sendPasswordResetLink(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-not-found':
        case 'invalid-credential':
          return 'No account was found for this email address.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection and try again.';
        default:
          return 'We could not send a password reset link right now.';
      }
    } catch (_) {
      return 'We could not send a password reset link right now.';
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Future<String?> updateCurrentUserProfile({
    required String name,
    required String photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'No active account was found. Please sign in again.';
      }

      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'photoUrl': photoUrl,
      });

      return null;
    } catch (_) {
      return 'We could not save your profile changes. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _mapSignupError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Your password is too weak. Please choose a stronger password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      default:
        return 'We could not create your account at the moment. Please try again.';
    }
  }

  String _mapLoginError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'The email address or password you entered is incorrect.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few minutes and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      default:
        return 'We could not sign you in. Please check your details and try again.';
    }
  }
}
