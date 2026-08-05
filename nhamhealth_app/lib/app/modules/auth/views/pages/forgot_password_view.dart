import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'verification_view.dart';

class ForgotPasswordController extends GetxController {
  final TextEditingController emailOrPhoneController =
      TextEditingController();

  final RxBool isLoading = false.obs;

  Future<void> sendCode() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final value = emailOrPhoneController.text.trim();

    if (value.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter your email or phone number.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    // Temporary loading. Connect your API here later.
    await Future.delayed(const Duration(seconds: 2));

    isLoading.value = false;

    Get.snackbar(
      'Code sent',
      'Verification code sent successfully.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFF00A63D),
      colorText: Colors.white,
    );

    // Navigate to verification screen and pass the entered email/phone
    Get.to(
      () => const VerificationView(),
      arguments: {'emailOrPhone': value},
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void onClose() {
    emailOrPhoneController.dispose();
    super.onClose();
  }
}

class ForgotPasswordPage extends StatelessWidget {
  ForgotPasswordPage({super.key});

  final ForgotPasswordController controller =
      Get.put(ForgotPasswordController());

  static const Color darkGreen = Color(0xFF075E2D);
  static const Color lightGreen = Color(0xFF7BA98B);
  static const Color buttonGreen = Color(0xFF00A63D);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF2FFFB),
              Color(0xFFF8FFF5),
              Color(0xFFFFFCE8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                IconButton(
                  onPressed: Get.back,
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 32,
                    color: darkGreen,
                  ),
                ),

                const SizedBox(height: 15),

                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: darkGreen,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    'No worries, We got you.',
                    style: TextStyle(
                      fontSize: 20,
                      color: lightGreen,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Illustration
                Center(
                  child: SizedBox(
                    height: screenHeight * 0.37,
                    child: Image.asset(
                      'assets/images/Login/forgot_password.png',
                      fit: BoxFit.contain,

                      // Temporary fallback when image is missing
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.lock_reset_rounded,
                            size: 180,
                            color: Color(0xFF8DDFAB),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Input
                TextField(
                  controller: controller.emailOrPhoneController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Email or Phone number',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.35),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 21,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40),
                      borderSide: const BorderSide(
                        color: buttonGreen,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Send code button
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 68,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.sendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonGreen,
                        disabledBackgroundColor: buttonGreen.withValues(
                          alpha: 0.6,
                        ),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: buttonGreen.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 27,
                              height: 27,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Send code',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
