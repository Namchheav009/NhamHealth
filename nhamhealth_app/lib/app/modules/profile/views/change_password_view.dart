import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/change_password_controller.dart';

class ChangePasswordView extends GetView<ChangePasswordController> {
  const ChangePasswordView({super.key});

  static const Color green = Color(0xFF009B43);
  static const Color darkGreen = Color(0xFF00652E);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return MediaQuery(
      // Keeps text size stable like your design.
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            // The reference frame is 393 logical pixels wide.
            final double scale = (constraints.maxWidth / 393).clamp(0.90, 1.12);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: constraints.maxWidth,
                height:
                    constraints.maxHeight < 720 ? 720 : constraints.maxHeight,
                child: Stack(
                  children: [
                    // ==========================================
                    // BACKGROUND
                    // ==========================================
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/images/background/bg.png',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    // Pink glow top left
                    Positioned(
                      top: -110 * scale,
                      left: -150 * scale,
                      child: _backgroundGlow(
                        width: 410 * scale,
                        height: 440 * scale,
                        color: const Color(0xFFFFE9ED),
                      ),
                    ),

                    // Green glow top right
                    Positioned(
                      top: -90 * scale,
                      right: -140 * scale,
                      child: _backgroundGlow(
                        width: 400 * scale,
                        height: 440 * scale,
                        color: const Color(0xFFE9FFD9),
                      ),
                    ),

                    // Pink glow middle left
                    Positioned(
                      top: 330 * scale,
                      left: -160 * scale,
                      child: _backgroundGlow(
                        width: 390 * scale,
                        height: 400 * scale,
                        color: const Color(0xFFFFECEF),
                      ),
                    ),

                    // Green glow center/right
                    Positioned(
                      top: 310 * scale,
                      right: -160 * scale,
                      child: _backgroundGlow(
                        width: 420 * scale,
                        height: 410 * scale,
                        color: const Color(0xFFE9FFE5),
                      ),
                    ),

                    // Pink bottom
                    Positioned(
                      bottom: -140 * scale,
                      left: -160 * scale,
                      child: _backgroundGlow(
                        width: 430 * scale,
                        height: 450 * scale,
                        color: const Color(0xFFFFEDF0),
                      ),
                    ),

                    // Green bottom right
                    Positioned(
                      bottom: -110 * scale,
                      right: -150 * scale,
                      child: _backgroundGlow(
                        width: 420 * scale,
                        height: 460 * scale,
                        color: const Color(0xFFE9FFDD),
                      ),
                    ),

                    // ==========================================
                    // MAIN CONTENT
                    // ==========================================
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 28 * scale,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 44 * scale),

                            // Header
                            _buildHeader(scale),

                            SizedBox(height: 35 * scale),

                            // Subtitle
                            Padding(
                              padding: EdgeInsets.only(left: 4 * scale),
                              child: Text(
                                "No worries, we've got you.",
                                style: TextStyle(
                                  fontSize: 12 * scale,
                                  height: 1,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF83A991),
                                ),
                              ),
                            ),

                            SizedBox(height: 25 * scale),

                            // Password card
                            _buildPasswordCard(scale),

                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(double scale) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: Get.back,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 24 * scale,
            height: 34 * scale,
            child: Icon(
              Icons.arrow_back_rounded,
              size: 22 * scale,
              color: darkGreen,
            ),
          ),
        ),

        SizedBox(width: 7 * scale),

        Text(
          'Change Password',
          style: TextStyle(
            fontSize: 20 * scale,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MAIN CARD
  // ============================================================

  Widget _buildPasswordCard(double scale) {
    return Container(
      width: double.infinity,
      height: 350 * scale,
      padding: EdgeInsets.fromLTRB(
        5 * scale,
        25 * scale,
        5 * scale,
        36 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 20 * scale,
            offset: Offset(0, 8 * scale),
          ),
        ],
      ),
      child: Column(
        children: [
          Obx(
            () => _passwordField(
              scale: scale,
              controller: controller.currentPasswordController,
              hint: 'Current password',
              obscureText: controller.hideCurrentPassword.value,
              onEyeTap: controller.toggleCurrentPassword,
            ),
          ),

          SizedBox(height: 15 * scale),

          Obx(
            () => _passwordField(
              scale: scale,
              controller: controller.newPasswordController,
              hint: 'New password',
              obscureText: controller.hideNewPassword.value,
              onEyeTap: controller.toggleNewPassword,
            ),
          ),

          SizedBox(height: 15 * scale),

          Obx(
            () => _passwordField(
              scale: scale,
              controller: controller.confirmPasswordController,
              hint: 'Confirm new password',
              obscureText: controller.hideConfirmPassword.value,
              onEyeTap: controller.toggleConfirmPassword,
            ),
          ),

          SizedBox(height: 11 * scale),

          // Forgot password
          Padding(
            padding: EdgeInsets.only(left: 28 * scale),
            child: GestureDetector(
              onTap: controller.forgotPassword,
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  fontSize: 11.5 * scale,
                  height: 1,
                  fontWeight: FontWeight.w400,
                  color: darkGreen,
                  decoration: TextDecoration.underline,
                  decorationColor: darkGreen,
                  decorationThickness: 1,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Update password button
          _buildUpdateButton(scale),
        ],
      ),
    );
  }

  // ============================================================
  // PASSWORD FIELD
  // ============================================================

  Widget _passwordField({
    required double scale,
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onEyeTap,
  }) {
    return Container(
      width: double.infinity,
      height: 47 * scale,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(25 * scale),
        border: Border(
          top: BorderSide(color: Colors.white, width: 1.2 * scale),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.012),
            blurRadius: 10 * scale,
            offset: Offset(0, 3 * scale),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(
          fontSize: 13.5 * scale,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF404040),
        ),
        cursorColor: green,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 13.5 * scale,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB8BCC2),
          ),
          contentPadding: EdgeInsets.only(left: 28 * scale, right: 12 * scale),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,

          // Eye icon
          suffixIcon: GestureDetector(
            onTap: onEyeTap,
            child: Padding(
              padding: EdgeInsets.only(right: 18 * scale),
              child: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 19 * scale,
                color: const Color(0xFFB7BBC0),
              ),
            ),
          ),
          suffixIconConstraints: BoxConstraints(minWidth: 48 * scale),
        ),
      ),
    );
  }

  // ============================================================
  // UPDATE BUTTON
  // ============================================================

  Widget _buildUpdateButton(double scale) {
    return Obx(
      () => GestureDetector(
        onTap: controller.isLoading.value ? null : controller.updatePassword,
        child: Container(
          width: double.infinity,
          height: 47 * scale,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: green,
            borderRadius: BorderRadius.circular(25 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 5 * scale,
                offset: Offset(0, 5 * scale),
              ),
            ],
          ),
          child:
              controller.isLoading.value
                  ? SizedBox(
                    width: 23 * scale,
                    height: 23 * scale,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                  : Text(
                    'Update Password',
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
        ),
      ),
    );
  }

  // ============================================================
  // BACKGROUND GLOW
  // ============================================================

  Widget _backgroundGlow({
    required double width,
    required double height,
    required Color color,
  }) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width),
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.55),
              color.withValues(alpha: 0.25),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.48, 1],
          ),
        ),
      ),
    );
  }
}
