import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../home/models/home_dashboard_model.dart';
import '../../home/models/home_route_arguments.dart';
import '../../home/providers/home_provider.dart';
import '../../home/repositories/home_repository.dart';
import '../models/authenticated_user_model.dart';
import '../../../../core/services/app_security_service.dart';
import '../../profile/views/security_view.dart';

class AccountCreatedController extends GetxController {
  AccountCreatedController({
    HomeRepository? homeRepository,
    this.homeLoadTimeout = const Duration(milliseconds: 800),
  }) : _homeRepository =
           homeRepository ?? HomeRepository(provider: HomeProvider());

  final HomeRepository _homeRepository;
  final Duration homeLoadTimeout;
  bool _isOpeningHome = false;

  @override
  void onReady() {
    super.onReady();
    _prepareAndOpenHome();
  }

  Future<void> _prepareAndOpenHome() async {
    if (_isOpeningHome) return;
    _isOpeningHome = true;

    final user = Get.arguments;
    if (user is! AuthenticatedUser) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    await _promptForPin(user);
    if (isClosed) return;

    HomeDashboardModel? dashboard;
    try {
      dashboard = await _homeRepository.getHomeDashboard().timeout(
        homeLoadTimeout,
      );
    } on Object {
      // Open Home promptly; it retries its normal loading flow if needed.
    }

    if (isClosed) return;
    Get.offAllNamed(
      AppRoutes.home,
      arguments: HomeRouteArguments(user: user, initialDashboard: dashboard),
    );
  }

  Future<void> _promptForPin(AuthenticatedUser user) async {
    final security = Get.find<AppSecurityService>();
    security.syncPinState(user.hasPin);
    if (user.hasPin || !await security.isSetupPendingFor(user.id)) return;

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (Get.context == null) return;
    await Get.dialog<void>(
      AlertDialog(
        icon: const Icon(Icons.pin_rounded, color: Color(0xFF00A651), size: 42),
        title: const Text('Create your app PIN'),
        content: const Text(
          'Protect your health information with a 6-digit PIN. You can also enable fingerprint or Face ID afterward.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: Get.back,
            child: const Text('Create PIN'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    await security.markSetupPromptedFor(user.id);
    final created = await Get.to<bool>(
      () => SecurityView(
        promptCreatePin: true,
        requirePinCreation: true,
        onPinCreated: () => Get.back(result: true),
      ),
      transition: Transition.rightToLeft,
    );
    if (created == true) {
      await security.clearSetupPendingFor(user.id);
    }
  }
}
