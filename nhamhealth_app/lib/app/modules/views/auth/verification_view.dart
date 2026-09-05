import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/services/app_security_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_alert.dart';
import 'reset_password_view.dart';
import 'widgets/auth_flow_scaffold.dart';

class VerificationController extends GetxController {
  VerificationController({AuthService? authService})
    : _authService = authService ?? Get.find<AuthService>();

  static const int codeLifetimeSeconds = 3 * 60;
  static const int resendCooldownSeconds = 30;
  static const int codeLength = 6;

  final AuthService _authService;
  final TextEditingController codeController = TextEditingController();
  final FocusNode codeFocusNode = FocusNode();
  final RxString userEmail = 'Your email'.obs;
  final RxString code = ''.obs;
  final RxBool codeHasFocus = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isResending = false.obs;
  final RxBool isRegistration = false.obs;
  final RxBool isLogin = false.obs;
  final RxInt codeSeconds = codeLifetimeSeconds.obs;
  final RxInt resendSeconds = resendCooldownSeconds.obs;
  Timer? _countdownTimer;

  String get formattedCodeTime {
    final minutes = codeSeconds.value ~/ 60;
    final seconds = codeSeconds.value % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isExpired => codeSeconds.value == 0;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['email'] is String) {
      userEmail.value = args['email'] as String;
      isRegistration.value = args['purpose'] == 'registration';
      isLogin.value = args['purpose'] == 'login';
    }
    codeSeconds.value = isRegistration.value ? 5 * 60 : codeLifetimeSeconds;
    codeFocusNode.addListener(_syncFocusState);
    _restartCountdowns(resetCodeLifetime: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) codeFocusNode.requestFocus();
    });
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    codeFocusNode.removeListener(_syncFocusState);
    codeFocusNode.dispose();
    codeController.dispose();
    super.onClose();
  }

  void _syncFocusState() {
    codeHasFocus.value = codeFocusNode.hasFocus;
  }

  void onCodeChanged(String value) {
    code.value = value;
    clearError();
    if (value.length == codeLength && !isExpired && !isLoading.value) {
      codeFocusNode.unfocus();
      unawaited(verifyCode());
    }
  }

  Future<void> verifyCode() async {
    if (isLoading.value || isResending.value) return;
    if (isExpired) {
      _showCodeError('This code has expired. Send a new code to continue.');
      return;
    }
    if (code.value.length != codeLength) {
      _showCodeError('Enter the complete six-digit code.');
      codeFocusNode.requestFocus();
      return;
    }

    hasError.value = false;
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      isLoading.value = true;
      if (isRegistration.value) {
        final response = await _authService.verifyRegistration(
          email: userEmail.value,
          code: code.value,
        );
        final security = Get.find<AppSecurityService>();
        security.syncPinState(response.user.hasPin);
        _countdownTimer?.cancel();
        Get.offAllNamed(AppRoutes.accountCreated, arguments: response.user);
      } else if (isLogin.value) {
        final response = await _authService.verifyLogin(
          email: userEmail.value,
          code: code.value,
        );
        final security = Get.find<AppSecurityService>();
        security.syncPinState(response.user.hasPin);
        _countdownTimer?.cancel();
        Get.offAllNamed(AppRoutes.home, arguments: response.user);
      } else {
        final resetToken = await _authService.verifyPasswordResetCode(
          email: userEmail.value,
          code: code.value,
        );
        _countdownTimer?.cancel();
        Get.off(
          () => const ResetPasswordView(),
          arguments: {'resetToken': resetToken},
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
        );
      }
    } on AuthException catch (error) {
      if (error.message.toLowerCase().contains('expired')) {
        codeSeconds.value = 0;
      }
      _showCodeError(error.message);
      codeController.clear();
      code.value = '';
      codeFocusNode.requestFocus();
    } finally {
      isLoading.value = false;
    }
  }

  void clearError() {
    if (hasError.value) hasError.value = false;
  }

  Future<void> resendCode() async {
    if (resendSeconds.value > 0 || isResending.value || isLoading.value) return;
    try {
      isResending.value = true;
      if (isRegistration.value) {
        await _authService.resendRegistrationCode(userEmail.value);
      } else if (isLogin.value) {
        await _authService.resendLoginCode(userEmail.value);
      } else {
        await _authService.requestPasswordReset(userEmail.value);
      }
      codeController.clear();
      code.value = '';
      hasError.value = false;
      _restartCountdowns(resetCodeLifetime: true);
      codeFocusNode.requestFocus();
      final isPhone = !userEmail.value.contains('@');
      AppAlert.success(
        title: 'New code sent'.tr,
        message:
            isPhone
                ? 'Check your phone messages. The new code is valid for @minutes minutes.'
                    .trParams({'minutes': '${isRegistration.value ? 5 : 3}'})
                : 'Check your email. The new code is valid for @minutes minutes.'
                    .trParams({'minutes': '${isRegistration.value ? 5 : 3}'}),
      );
    } on AuthException catch (error) {
      AppAlert.error(title: 'Could not resend code'.tr, message: error.message);
    } finally {
      isResending.value = false;
    }
  }

  void _showCodeError(String message) {
    errorMessage.value = message;
    hasError.value = true;
  }

  void _restartCountdowns({required bool resetCodeLifetime}) {
    _countdownTimer?.cancel();
    if (resetCodeLifetime) {
      codeSeconds.value = isRegistration.value ? 5 * 60 : codeLifetimeSeconds;
    }
    resendSeconds.value = resendCooldownSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (codeSeconds.value > 0) {
        codeSeconds.value--;
        if (codeSeconds.value == 0 && !isLoading.value) {
          _showCodeError('This code has expired. Send a new code to continue.');
        }
      }
      if (resendSeconds.value > 0) resendSeconds.value--;
      if (codeSeconds.value == 0 && resendSeconds.value == 0) timer.cancel();
    });
  }
}

class VerificationView extends StatelessWidget {
  const VerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VerificationController());

    return Theme(
      data: AppTheme.light,
      child: Builder(
        builder:
            (context) => AuthFlowScaffold(
              title: 'Verification',
              subtitle: 'Enter the six-digit code to continue.',
              illustrationAsset: 'assets/images/auth/verification.png',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Obx(
                    () => Text(
                      controller.userEmail.value.contains('@')
                          ? 'We sent a code to'.tr
                          : 'We sent an SMS code to'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      controller.userEmail.value,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Obx(
                    () => _VerificationCodeField(
                      controller: controller,
                      code: controller.code.value,
                      hasFocus: controller.codeHasFocus.value,
                      hasError: controller.hasError.value,
                    ),
                  ),
                  Obx(
                    () => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child:
                          controller.hasError.value
                              ? Padding(
                                key: const ValueKey('verification-error'),
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  controller.errorMessage.value.tr,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.errorCoral,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                              : const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => _ExpiryPill(
                      time: controller.formattedCodeTime,
                      expired: controller.isExpired,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code?".tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.appText,
                          ),
                        ),
                        TextButton(
                          onPressed:
                              controller.resendSeconds.value == 0 &&
                                      !controller.isResending.value &&
                                      !controller.isLoading.value
                                  ? controller.resendCode
                                  : null,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 44),
                            foregroundColor: AppColors.accentOrange,
                          ),
                          child: Text(
                            controller.isResending.value
                                ? 'Sending...'.tr
                                : controller.resendSeconds.value > 0
                                ? 'Send again in @seconds'.trParams({
                                  'seconds':
                                      '${controller.resendSeconds.value}s',
                                })
                                : 'Send again'.tr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _ExpiryPill extends StatelessWidget {
  const _ExpiryPill({required this.time, required this.expired});

  final String time;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final color = expired ? AppColors.errorCoral : AppColors.primaryGreen;
    return Align(
      alignment: Alignment.center,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded, size: 15, color: color),
              const SizedBox(width: 5),
              Text(
                expired
                    ? 'Code expired'.tr
                    : 'Code expires in @time'.trParams({'time': time}),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationCodeField extends StatelessWidget {
  const _VerificationCodeField({
    required this.controller,
    required this.code,
    required this.hasFocus,
    required this.hasError,
  });

  final VerificationController controller;
  final String code;
  final bool hasFocus;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Six digit verification code'.tr,
      textField: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 7.0;
          final boxSize = ((constraints.maxWidth - gap * 5) / 6).clamp(
            36.0,
            52.0,
          );
          return SizedBox(
            height: 60,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(VerificationController.codeLength, (
                      index,
                    ) {
                      final isActive = hasFocus && index == code.length;
                      final digit = index < code.length ? code[index] : '';
                      return Padding(
                        padding: EdgeInsets.only(
                          right:
                              index == VerificationController.codeLength - 1
                                  ? 0
                                  : gap,
                        ),
                        child: AnimatedContainer(
                          key: ValueKey('verification-digit-$index'),
                          duration: const Duration(milliseconds: 160),
                          width: boxSize,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.appField,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  hasError
                                      ? AppColors.errorCoral
                                      : isActive
                                      ? AppColors.primaryGreen
                                      : context.appBorder,
                              width: hasError || isActive ? 1.5 : 1.2,
                            ),
                            boxShadow:
                                isActive
                                    ? [
                                      BoxShadow(
                                        color: AppColors.primaryGreen
                                            .withValues(alpha: .12),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Text(
                            digit,
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.01,
                    child: TextField(
                      key: const ValueKey('verification-code-input'),
                      controller: controller.codeController,
                      focusNode: controller.codeFocusNode,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      enableSuggestions: false,
                      autocorrect: false,
                      showCursor: false,
                      maxLength: VerificationController.codeLength,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                          VerificationController.codeLength,
                        ),
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: controller.onCodeChanged,
                      onSubmitted: (_) => controller.verifyCode(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
