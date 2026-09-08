import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/auth/login_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/auth/register_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/login_request.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/login_response.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/register_request.dart';
import 'package:nhamhealth_flutter/app/modules/services/auth/google_auth_service.dart';
import 'package:nhamhealth_flutter/app/modules/views/auth/forgot_password_view.dart';
import 'package:nhamhealth_flutter/app/modules/views/auth/reset_password_view.dart';
import 'package:nhamhealth_flutter/app/modules/views/auth/widgets/password_field.dart';
import 'package:nhamhealth_flutter/app/theme/app_colors.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('authentication form validation', () {
    test('sign in marks missing identifier and password fields', () async {
      final controller = LoginController(
        authService: _RejectingAuthService(),
        googleAuth: _NoopGoogleAuthService(),
      );

      await controller.login('', '');

      expect(
        controller.identifierError.value,
        'Enter your email or phone number.',
      );
      expect(controller.passwordError.value, 'Enter your password.');
      expect(controller.credentialsInvalid.value, isFalse);
    });

    test(
      'sign in marks both credentials after an unauthorized response',
      () async {
        final controller = LoginController(
          authService: _RejectingAuthService(),
          googleAuth: _NoopGoogleAuthService(),
        );

        await controller.login('user@example.com', 'WrongPassword');

        expect(controller.credentialsInvalid.value, isTrue);
        expect(
          controller.submitError.value,
          'The email/phone number or password is incorrect.',
        );
      },
    );

    test('sign up reports every invalid field in one submission', () async {
      final controller = RegisterController(
        authService: _RejectingAuthService(),
        googleAuth: _NoopGoogleAuthService(),
      );

      await controller.register(
        fullName: '',
        email: 'invalid',
        password: 'short',
        confirmPassword: 'different',
      );

      expect(controller.fullNameError.value, isNotNull);
      expect(controller.identifierError.value, isNotNull);
      expect(controller.passwordError.value, isNotNull);
      expect(controller.confirmPasswordError.value, isNotNull);
    });

    test(
      'sign up marks an identifier already registered on the server',
      () async {
        final controller = RegisterController(
          authService: _RejectingAuthService(),
          googleAuth: _NoopGoogleAuthService(),
        );

        await controller.register(
          fullName: 'Nham User',
          email: 'user@example.com',
          password: 'StrongPass123!',
          confirmPassword: 'StrongPass123!',
        );

        expect(
          controller.identifierError.value,
          'An account with this email or phone number already exists.',
        );
      },
    );

    test('forgot password marks an invalid email or phone number', () async {
      final controller = ForgotPasswordController(
        authService: _RejectingAuthService(),
      );
      controller.emailOrPhoneController.text = 'invalid';

      await controller.sendCode();

      expect(
        controller.identifierError.value,
        'Please enter a valid email or phone number.',
      );
      controller.onClose();
    });

    test('reset password marks both missing password fields', () async {
      final controller = ResetPasswordController(
        authService: _RejectingAuthService(),
      );

      await controller.resetPassword();

      expect(controller.newPasswordError.value, 'Enter a new password.');
      expect(controller.confirmPasswordError.value, 'Confirm your password.');
      controller.onClose();
    });
  });

  testWidgets('auth text field displays an accessible red error state', (
    tester,
  ) async {
    final textController = TextEditingController();
    addTearDown(textController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthTextField(
            controller: textController,
            hintText: 'Email or Phone Number',
            errorText: 'Please enter a valid email or phone number.',
          ),
        ),
      ),
    );

    expect(
      find.text('Please enter a valid email or phone number.'),
      findsOneWidget,
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    final border = field.decoration!.enabledBorder! as OutlineInputBorder;
    expect(border.borderSide.color, AppColors.errorCoral);
  });
}

class _RejectingAuthService extends AuthService {
  @override
  Future<LoginResponse> login(LoginRequest request) {
    throw const AuthException(
      'Invalid email, phone number, or password',
      statusCode: 401,
    );
  }

  @override
  Future<void> register(RegisterRequest request) {
    throw const AuthException(
      'An account with this email or phone number already exists.',
      statusCode: 409,
    );
  }
}

class _NoopGoogleAuthService extends GoogleAuthService {
  @override
  Future<String?> signInAndGetIdToken() async => null;
}
