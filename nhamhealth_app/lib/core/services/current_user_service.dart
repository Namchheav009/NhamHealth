import 'dart:async';

import 'package:get/get.dart';

import '../../app/modules/models/auth/authenticated_user_model.dart';
import 'auth_service.dart';

/// Single reactive source for the signed-in user's public profile details.
///
/// Every main tab observes this state, so a saved display name or photo is
/// reflected immediately without requiring navigation or an app restart.
class CurrentUserService extends GetxService {
  CurrentUserService({required AuthService authService}) : _authService = authService;

  final AuthService _authService;
  final user = Rxn<AuthenticatedUser>();
  Timer? _refreshTimer;
  bool _refreshing = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(refresh());
    if (!Get.testMode) {
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => unawaited(refresh()),
      );
    }
  }

  void setUser(AuthenticatedUser? value) {
    user.value = value;
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      user.value = await _authService.restoreSession();
    } finally {
      _refreshing = false;
    }
  }

  void clear() => user.value = null;

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }
}
