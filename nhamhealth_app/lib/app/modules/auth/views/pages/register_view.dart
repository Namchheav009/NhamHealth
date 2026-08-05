import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../pages/login_view.dart';
import '../widgets/glass_container.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  static const Color pink = Color(0xFFFF5A73);
  static const Color deepGreen = Color(0xFF005B27);
  static const Color green = Color(0xFF009B3E);
  static const Color orange = Color(0xFFFFA31A);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void register() {
    // TODO: hook up your GetX register/sign-up controller here
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final bool smallScreen = screenSize.height < 750;

    final double logoWidth = smallScreen ? 100 : 120;
    final double titleFont = smallScreen ? 22 : 26;
    final double fieldHeight = smallScreen ? 52 : 56;
    final double fieldFont = smallScreen ? 15 : 16;
    final double buttonHeight = smallScreen ? 52 : 58;
    final double buttonFont = smallScreen ? 17 : 18;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF2EA),
              Color(0xFFECEFE2),
              Color(0xFFF0EFDC),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: smallScreen ? 20 : 28),

              Image.asset(
                'assets/icons/logo.png',
                width: logoWidth,
                fit: BoxFit.contain,
              ),

              SizedBox(height: smallScreen ? 10 : 14),

              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'NHAM ',
                      style: TextStyle(
                        fontSize: titleFont,
                        fontWeight: FontWeight.w900,
                        color: pink,
                        letterSpacing: 0.3,
                      ),
                    ),
                    TextSpan(
                      text: 'HEALTH',
                      style: TextStyle(
                        fontSize: titleFont,
                        fontWeight: FontWeight.w900,
                        color: green,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: smallScreen ? 18 : 22),

              Expanded(
                child: GlassContainer(
                  width: double.infinity,
                  padding: EdgeInsets.zero,
                  blur: 24,
                  opacity: 0.10,
                  borderRadius: 32,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      24,
                      smallScreen ? 22 : 26,
                      24,
                      20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tab Switch Header
                        Container(
                          height: smallScreen ? 46 : 50,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Get.off(
                                      () => const LoginScreen(),
                                      transition: Transition.noTransition,
                                    );
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    color: Colors.transparent,
                                    child: Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: smallScreen ? 15 : 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: green,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Text(
                                    'Register',
                                    style: TextStyle(
                                      fontSize: smallScreen ? 15 : 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: smallScreen ? 16 : 18),

                        Text(
                          'Create your account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: smallScreen ? 15 : 16,
                            fontWeight: FontWeight.w600,
                            color: deepGreen,
                          ),
                        ),

                        SizedBox(height: smallScreen ? 16 : 18),

                        // Full Name
                        _CustomInputField(
                          controller: _fullNameController,
                          hintText: 'Full Name',
                          height: fieldHeight,
                          fontSize: fieldFont,
                        ),

                        SizedBox(height: smallScreen ? 12 : 14),

                        // Email Field
                        _CustomInputField(
                          controller: _emailController,
                          hintText: 'Email or Phone number',
                          height: fieldHeight,
                          fontSize: fieldFont,
                        ),

                        SizedBox(height: smallScreen ? 12 : 14),

                        // Password Field
                        _CustomInputField(
                          controller: _passwordController,
                          hintText: 'Password',
                          obscureText: obscurePassword,
                          height: fieldHeight,
                          fontSize: fieldFont,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),

                        SizedBox(height: smallScreen ? 12 : 14),

                        // Confirm Password Field
                        _CustomInputField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          obscureText: obscureConfirmPassword,
                          height: fieldHeight,
                          fontSize: fieldFont,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureConfirmPassword =
                                    !obscureConfirmPassword;
                              });
                            },
                          ),
                        ),

                        SizedBox(height: smallScreen ? 16 : 18),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: Colors.grey.withValues(alpha: 0.35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Register',
                              style: TextStyle(
                                fontSize: buttonFont,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: smallScreen ? 14 : 16),

                        // Switch to Login
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: smallScreen ? 13 : 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Get.off(
                                    () => const LoginScreen(),
                                    transition: Transition.noTransition,
                                  );
                                },
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: smallScreen ? 13 : 14,
                                    fontWeight: FontWeight.w800,
                                    color: orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: smallScreen ? 6 : 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final double height;
  final double fontSize;
  final bool obscureText;
  final Widget? suffixIcon;

  const _CustomInputField({
    required this.controller,
    required this.hintText,
    required this.height,
    required this.fontSize,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}