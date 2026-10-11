import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const String _apiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const String _appId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const String _senderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String _authDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

  static FirebaseOptions get web {
    if (_apiKey.isEmpty ||
        _appId.isEmpty ||
        _senderId.isEmpty ||
        _projectId.isEmpty) {
      throw StateError(
        'Provide the Firebase web app values with --dart-define. See README.md.',
      );
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _senderId,
      projectId: _projectId,
      authDomain: _authDomain.isEmpty ? null : _authDomain,
    );
  }

  static FirebaseOptions get currentPlatform => web;
}
