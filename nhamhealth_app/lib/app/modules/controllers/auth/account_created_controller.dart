import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../models/home/home_dashboard_model.dart';
import '../../models/home/home_route_arguments.dart';
import '../../providers/home/home_provider.dart';
import '../../repositories/home/home_repository.dart';
import '../../models/auth/authenticated_user_model.dart';
import '../../../../core/services/app_security_service.dart';
import '../../views/profile/security_view.dart';
import '../../../widgets/pin_setup_prompt.dart';

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
    await showPinSetupPrompt(Get.context!);
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
