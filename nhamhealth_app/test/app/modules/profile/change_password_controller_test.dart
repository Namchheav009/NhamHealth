import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/profile/change_password_controller.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  test('PIN or biometrics must approve a valid password update', () async {
    final authService = _RecordingAuthService();
    String? authorizationReason;
    final controller = ChangePasswordController(
      authService: authService,
      authorize: (reason) async {
        authorizationReason = reason;
        return false;
      },
    );
    addTearDown(controller.onClose);

    controller.currentPasswordController.text = 'CurrentPass123!';
    controller.newPasswordController.text = 'NewPassword123!';
    controller.confirmPasswordController.text = 'NewPassword123!';

    await controller.updatePassword();

    expect(authorizationReason, 'Unlock to update your account password.');
    expect(authService.changePasswordCalls, 0);
    expect(controller.isLoading.value, isFalse);
  });
}

class _RecordingAuthService extends AuthService {
  int changePasswordCalls = 0;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalls++;
  }
}
