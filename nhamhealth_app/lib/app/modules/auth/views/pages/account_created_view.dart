import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- GETX CONTROLLER ---
class PasswordSuccessController extends GetxController {
  void backToLogin() {
    // TODO: Navigate user back to the Login screen
    // Get.offAll(() => const LoginScreen());
    Get.back();
  }
}

// --- GETX VIEW ---
class PasswordSuccessView extends GetView<PasswordSuccessController> {
  const PasswordSuccessView({super.key});

  static const Color darkGreen = Color(0xFF0A3C2A);
  static const Color primaryGreen = Color(0xFF009B3E);
  static const Color subtitleGrey = Color(0xFF7A8B84);

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    Get.put(PasswordSuccessController());

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
                  onPressed: controller.backToLogin,
                ),

                const SizedBox(height: 16),

                // Title
                const Text(
                  'Password Changed!',
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
                  'No worries anymore.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: subtitleGrey,
                  ),
                ),

                const Spacer(),

                // Success Illustration
                Center(
                  child: Image.asset(
                    'assets/images/Login/account_create.png',
                    height: 260,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 220,
                        width: 220,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(110),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 100,
                          color: primaryGreen,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 36),

                // Success Message
                Center(
                  child: Column(
                    children: const [
                      Text(
                        'Your password has been reset',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: darkGreen,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Succesfully!',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}