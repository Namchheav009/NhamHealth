import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/services/auth_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../auth/models/authenticated_user_model.dart';
import '../../../auth/services/google_auth_service.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final user =
        Get.arguments is AuthenticatedUser
            ? Get.arguments as AuthenticatedUser
            : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nham Health'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await Get.find<AuthService>().logout();
              await Get.find<GoogleAuthService>().signOut();
              Get.offAllNamed(AppRoutes.login);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF009B3E),
                size: 76,
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome to Nham Health',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              if (user != null) ...[
                const SizedBox(height: 8),
                Text(user.email, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
