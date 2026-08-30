import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

abstract final class AppAlert {
  static Future<void> _transition = Future<void>.value();
  static int _latestRequest = 0;
  static SnackbarController? _activeController;

  static Future<void> success({
    required String title,
    required String message,
  }) => _show(title: title, message: message, tone: _AppAlertTone.success);

  static Future<void> error({required String title, required String message}) =>
      _show(title: title, message: message, tone: _AppAlertTone.error);

  static Future<void> _show({
    required String title,
    required String message,
    required _AppAlertTone tone,
  }) {
    final request = ++_latestRequest;
    final operation = _transition.then<void>(
      (_) => _present(
        request: request,
        title: title,
        message: message,
        tone: tone,
      ),
      onError:
          (_, _) => _present(
            request: request,
            title: title,
            message: message,
            tone: tone,
          ),
    );
    _transition = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }

  static Future<void> _present({
    required int request,
    required String title,
    required String message,
    required _AppAlertTone tone,
  }) async {
    if (request != _latestRequest) return;
    await _closeActiveAlert();
    if (request != _latestRequest) return;

    final disableAnimations = _animationsAreDisabled();
    final controller = Get.rawSnackbar(
      messageText: SafeArea(
        bottom: false,
        minimum: const EdgeInsets.only(top: 8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _AppAlertCard(title: title, message: message, tone: tone),
          ),
        ),
      ),
      snackPosition: SnackPosition.TOP,
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: EdgeInsets.zero,
      borderRadius: 22,
      boxShadows: const [],
      duration: const Duration(seconds: 4),
      animationDuration:
          disableAnimations ? Duration.zero : const Duration(milliseconds: 360),
      forwardAnimationCurve:
          disableAnimations ? Curves.linear : Curves.easeOutCubic,
      reverseAnimationCurve:
          disableAnimations ? Curves.linear : Curves.easeInCubic,
      isDismissible: true,
      dismissDirection: DismissDirection.up,
    );
    _activeController = controller;
    unawaited(
      controller.future.whenComplete(() {
        if (identical(_activeController, controller)) {
          _activeController = null;
        }
      }),
    );
  }

  static Future<void> dismiss() async {
    _latestRequest++;
    await _closeActiveAlert();
  }

  static Future<void> _closeActiveAlert() async {
    final controller = _activeController;
    if (controller == null) return;
    _activeController = null;
    try {
      await controller.close();
    } on Object {
      // A swipe or duration timer may already be closing this same alert.
    }
  }

  static bool _animationsAreDisabled() {
    final context = Get.overlayContext ?? Get.context;
    return context != null &&
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
  }
}

enum _AppAlertTone { success, error }

class _AppAlertCard extends StatelessWidget {
  const _AppAlertCard({
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final _AppAlertTone tone;

  bool get _isSuccess => tone == _AppAlertTone.success;

  @override
  Widget build(BuildContext context) {
    final accent = _isSuccess ? AppColors.primaryGreen : AppColors.errorCoral;
    final titleColor =
        _isSuccess
            ? context.appColorScheme.primary
            : context.appOnDangerSurface;
    final tint = _isSuccess ? context.appSoftGreen : context.appDangerSurface;
    final icon = _isSuccess ? Icons.check_rounded : Icons.priority_high_rounded;
    final localizedTitle = title.tr;
    final localizedMessage = message.tr;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: titleColor.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.appElevatedSurface.withValues(alpha: 0.96),
                  tint.withValues(alpha: 0.93),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: accent.withValues(alpha: 0.25),
                width: 1.1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AnimatedAlertIcon(
                    icon: icon,
                    accent: accent,
                    background: tint,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      container: true,
                      liveRegion: true,
                      excludeSemantics: true,
                      label:
                          '${_isSuccess ? 'Success' : 'Error'}: '
                          '$localizedTitle. $localizedMessage',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizedTitle,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 15,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizedMessage,
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 12.5,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Dismiss notification'.tr,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => unawaited(AppAlert.dismiss()),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 19,
                      color: titleColor.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedAlertIcon extends StatelessWidget {
  const _AnimatedAlertIcon({
    required this.icon,
    required this.accent,
    required this.background,
  });

  final IconData icon;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: disableAnimations ? 1 : 0.68, end: 1),
      curve: Curves.easeOutBack,
      duration:
          disableAnimations ? Duration.zero : const Duration(milliseconds: 460),
      builder:
          (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: accent, size: 23),
      ),
    );
  }
}
