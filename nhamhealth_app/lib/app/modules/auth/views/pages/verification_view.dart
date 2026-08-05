import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'reset_password_view.dart';

// --- GETX CONTROLLER ---
class VerificationController extends GetxController {
  final List<TextEditingController> otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

  final RxString userEmailOrPhone = 'YourEmail@gmail.com Or your SMS'.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args['emailOrPhone'] != null) {
      userEmailOrPhone.value = args['emailOrPhone'] as String;
    }
  }

  @override
  void onClose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.onClose();
  }

  void verifyCode() {
    String code = otpControllers.map((c) => c.text).join();
    if (code.length == 4) {
      // TODO: Implement your verification logic here
      Get.snackbar(
        'Verification',
        'Submitted Code: $code',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate to reset password screen after successful OTP input
      Get.to(
        () => const ResetPasswordView(),
        arguments: {'emailOrPhone': userEmailOrPhone.value},
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  void resendCode() {
    // TODO: Implement resend OTP logic here
    Get.snackbar(
      'Resend Code',
      'A new verification code has been sent.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

// --- GETX VIEW ---
class VerificationView extends GetView<VerificationController> {
  const VerificationView({super.key});

  static const Color darkGreen = Color(0xFF0A3C2A);
  static const Color subtitleGrey = Color(0xFF7A8B84);
  static const Color orangeText = Color(0xFFEAA235);
  static const Color cardBg = Color(0xFFE4EDE7);

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    Get.put(VerificationController());

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
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
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
                  'Verification',
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
                  'Enter the code to continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: subtitleGrey,
                  ),
                ),

                const SizedBox(height: 32),

                // Illustration Image
                Center(
                  child: Image.asset(
                    'assets/images/Login/verification.png',
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if asset image is missing
                      return Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          size: 90,
                          color: darkGreen,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 36),

                // "We sent a code to..." Message
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'We sent  a code to',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(
                        () => Text(
                          controller.userEmailOrPhone.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: darkGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 4-Digit OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    return _buildOtpBox(context, index);
                  }),
                ),

                const Spacer(),

                // Resend Code Bottom Text
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text(
                        "Don't receive the code? ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkGreen,
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.resendCode,
                        child: const Text(
                          'Send Again',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: orangeText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // OTP Input Box Helper Widget
  Widget _buildOtpBox(BuildContext context, int index) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: cardBg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: TextField(
          controller: controller.otpControllers[index],
          focusNode: controller.focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < 3) {
                // Move focus to next field
                FocusScope.of(context)
                    .requestFocus(controller.focusNodes[index + 1]);
              } else {
                // Last box completed: unfocus keyboard & trigger verify
                controller.focusNodes[index].unfocus();
                controller.verifyCode();
              }
            } else if (value.isEmpty && index > 0) {
              // Backspace pressed: move focus back
              FocusScope.of(context)
                  .requestFocus(controller.focusNodes[index - 1]);
            }
          },
        ),
      ),
    );
  }
}
