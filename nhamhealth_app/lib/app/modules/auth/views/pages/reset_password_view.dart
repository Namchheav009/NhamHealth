import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'account_created_view.dart';

// --- GETX CONTROLLER ---
class ResetPasswordController extends GetxController {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final RxBool isNewPasswordObscured = true.obs;
  final RxBool isConfirmPasswordObscured = true.obs;

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordObscured.value = !isNewPasswordObscured.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordObscured.value = !isConfirmPasswordObscured.value;
  }

  void resetPassword() {
    String newPassword = newPasswordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      Get.snackbar(
        'Error',
        'Passwords do not match',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // TODO: Implement password reset logic
    Get.snackbar(
      'Success',
      'Password reset successfully',
      snackPosition: SnackPosition.BOTTOM,
    );

    // Navigate to account created / success screen
    Get.offAll(
      () => const PasswordSuccessView(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  void skip() {
    // Skip and go to account created / success screen
    Get.offAll(
      () => const PasswordSuccessView(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }
}

// --- GETX VIEW ---
class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});

  static const Color darkGreen = Color(0xFF0A3C2A);
  static const Color primaryGreen = Color(0xFF009B3E);
  static const Color subtitleGrey = Color(0xFF7A8B84);
  static const Color inputBg = Color(0xFFE5EDE6);

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    Get.put(ResetPasswordController());

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFF5F0),
              Color(0xFFEFF4ED),
              Color(0xFFEBF0DE),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Back Button
                  IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: darkGreen,
                      size: 28,
                    ),
                    onPressed: () => Get.back(),
                  ),

                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'Set new password?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: darkGreen,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Subtitle
                  const Text(
                    'No worries ,We got you .',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: subtitleGrey,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Illustration Image
                  Center(
                    child: Image.asset(
                      'assets/images/Login/reset.png',
                      height: 240,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            size: 90,
                            color: darkGreen,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // New Password Input Field
                  Obx(
                    () => _buildInputField(
                      controller: controller.newPasswordController,
                      hintText: 'New Password',
                      obscureText: controller.isNewPasswordObscured.value,
                      onToggleVisibility: controller.toggleNewPasswordVisibility,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Confirm Password Input Field
                  Obx(
                    () => _buildInputField(
                      controller: controller.confirmPasswordController,
                      hintText: 'confirm Password', // Fixed typo from design or kept optional
                      obscureText: controller.isConfirmPasswordObscured.value,
                      onToggleVisibility: controller.toggleConfirmPasswordVisibility,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Reset Password Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: controller.resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Reset password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Skip Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: controller.skip,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: const BorderSide(
                          color: primaryGreen,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget for Password Input Fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: inputBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkGreen,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: subtitleGrey,
            ),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: subtitleGrey,
                  size: 22,
                ),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ),
      ),
    );
  }
}