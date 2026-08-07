import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService();

  static const _clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '197065287162-2t743hltpkorhfn91c3h92h07gtv8sru.apps.googleusercontent.com',
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _initialization;

  Future<void> initialize() => _initialization ??= _initialize();

  Stream<String> get authenticationTokens async* {
    await initialize();

    await for (final event in _googleSignIn.authenticationEvents) {
      if (event is! GoogleSignInAuthenticationEventSignIn) continue;

      final idToken = event.user.authentication.idToken;
      if (idToken != null && idToken.isNotEmpty) {
        yield idToken;
      }
    }
  }

  Future<String?> signInAndGetIdToken() async {
    await initialize();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const GoogleAuthException(
        'Google sign-in is not available with this button on this platform.',
      );
    }

    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleAuthException(
          'Google did not return an identity token.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw GoogleAuthException(
        error.description ?? 'Could not sign in with Google.',
      );
    }
  }

  Future<void> signOut() async {
    if (_initialization == null) return;
    await _initialization;
    await _googleSignIn.signOut();
  }

  Future<void> _initialize() {
    final platformClientId =
        kIsWeb && _clientId.isEmpty ? _serverClientId : _clientId;
    return _googleSignIn.initialize(
      clientId: platformClientId.isEmpty ? null : platformClientId,
      serverClientId:
          kIsWeb || _serverClientId.isEmpty ? null : _serverClientId,
    );
  }
}

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
