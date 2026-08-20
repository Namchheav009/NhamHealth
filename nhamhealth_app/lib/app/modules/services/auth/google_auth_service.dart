import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService();

  static const _clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const _androidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
  );
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const _androidConfigChannel = MethodChannel(
    'com.example.nhamhealth_flutter/google_oauth_config',
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
      if (error.description?.toLowerCase().contains(
            'no credential available',
          ) ??
          false) {
        throw const GoogleAuthException(
          'No Google account is available on this device. Add a Google '
          'account in Android Settings, then try again.',
        );
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

  Future<void> _initialize() async {
    var serverClientId = _serverClientId;
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        serverClientId.isEmpty) {
      serverClientId =
          await _androidConfigChannel.invokeMethod<String>(
            'getServerClientId',
          ) ??
          '';
    }

    if (!kIsWeb && serverClientId.isEmpty) {
      throw const GoogleAuthException(
        'Google sign-in configuration is missing. Create '
        'config/google_oauth.json from the provided example and rebuild.',
      );
    }

    if (!kIsWeb &&
        _androidClientId.isNotEmpty &&
        serverClientId == _androidClientId) {
      throw const GoogleAuthException(
        'GOOGLE_SERVER_CLIENT_ID must be a Web OAuth client ID, not the '
        'Android OAuth client ID.',
      );
    }

    final platformClientId =
        kIsWeb && _clientId.isEmpty ? _serverClientId : _clientId;
    await _googleSignIn.initialize(
      clientId: platformClientId.isEmpty ? null : platformClientId,
      serverClientId:
          kIsWeb || serverClientId.isEmpty ? null : serverClientId,
    );
  }
}

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
