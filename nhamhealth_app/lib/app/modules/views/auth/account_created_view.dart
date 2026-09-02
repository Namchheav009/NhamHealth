import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';
import '../../controllers/auth/account_created_controller.dart';

class AccountCreatedView extends GetView<AccountCreatedController> {
  const AccountCreatedView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: Scaffold(
          body: AppBackground(
            lightDecoration: const BoxDecoration(
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
                        Text(
                          'Account created!'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 24,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Welcome to NhamHealth'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Center(
                            child: Semantics(
                              label: 'Account successfully created'.tr,
                              image: true,
                              child: Image.asset(
                                'assets/images/auth/account_create.png',
                                width: constraints.maxWidth.clamp(230.0, 330.0),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Your account has been created'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Successfully!'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appText,
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
                                'Preparing your home...'.tr,
                                style: TextStyle(
                                  color: context.appMutedText,
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
