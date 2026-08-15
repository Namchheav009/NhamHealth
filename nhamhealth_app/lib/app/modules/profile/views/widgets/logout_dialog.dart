import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LogoutDialog extends StatelessWidget {
  final VoidCallback onLogout;

  const LogoutDialog({super.key, required this.onLogout});

  static const Color green = Color(0xFF009B43);
  static const Color red = Color(0xFFFF1F24);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 48),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.fromLTRB(24, 25, 24, 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEFE),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFF1CFCF), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // -----------------------------------------
              // LOGOUT ICON
              // -----------------------------------------
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFE8E8),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.logout_rounded, size: 37, color: red),
              ),

              const SizedBox(height: 24),

              // -----------------------------------------
              // TITLE
              // -----------------------------------------
              const Text(
                'Are you logging out?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(height: 25),

              // -----------------------------------------
              // BUTTONS
              // -----------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // CANCEL
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 96,
                      height: 47,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFB1141B),
                          width: 1.3,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 28),

                  // LOGOUT
                  GestureDetector(
                    onTap: onLogout,
                    child: Container(
                      width: 96,
                      height: 47,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: green,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
