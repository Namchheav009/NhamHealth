import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../home/models/home_dashboard_model.dart';
import '../../home/models/home_route_arguments.dart';
import '../../home/providers/home_provider.dart';
import '../../home/repositories/home_repository.dart';
import '../models/authenticated_user_model.dart';

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
}
