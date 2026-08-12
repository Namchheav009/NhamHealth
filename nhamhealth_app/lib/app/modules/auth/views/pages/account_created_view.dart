import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../controllers/account_created_controller.dart';

class AccountCreatedView extends GetView<AccountCreatedController> {
  const AccountCreatedView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF1FAF5), Color(0xFFF6F5D8)],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 42, 28, 34),
                    child: Column(
                      children: [
                        const Text(
                          'Account created!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 24,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Welcome to NhamHealth',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Center(
                            child: Semantics(
                              label: 'Account successfully created',
                              image: true,
                              child: Image.asset(
                                'assets/images/Login/account_create.png',
                                width: constraints.maxWidth.clamp(230.0, 330.0),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Your account has been created',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Successfully!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 22,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Semantics(
                          liveRegion: true,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Preparing your home...',
                                style: TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
