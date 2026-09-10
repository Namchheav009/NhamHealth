import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../theme/app_colors.dart';

abstract final class AppAlert {
  static Future<void> _transition = Future<void>.value();
  static Future<void> _actionTransition = Future<void>.value();
  static int _latestRequest = 0;
  static SnackbarController? _activeController;
  static BuildContext? _activeDialogContext;

  static Future<void> success({
    required String title,
    required String message,
  }) => Future<void>.value();

  static Future<void> error({required String title, required String message}) =>
      Future<void>.value();

  /// Presents blocking feedback for a completed user action.
  ///
  /// This intentionally remains separate from [success] and [error], which are
  /// quiet by default, so only high-value actions interrupt the current flow.
  static Future<void> actionSuccess({
    required String title,
    required String message,
    String confirmText = 'common.ok',
  }) => _showActionDialog(
    title: title,
    message: message,
    tone: _AppActionAlertTone.success,
    confirmText: confirmText,
  );

  static Future<void> actionError({
    required String title,
    required String message,
    String confirmText = 'common.ok',
  }) => _showActionDialog(
    title: title,
    message: message,
    tone: _AppActionAlertTone.error,
    confirmText: confirmText,
  );

  static Future<void> _showActionDialog({
    required String title,
    required String message,
    required _AppActionAlertTone tone,
    required String confirmText,
  }) {
    final operation = _actionTransition.then<void>(
      (_) => _presentActionDialog(
        title: title,
        message: message,
        tone: tone,
        confirmText: confirmText,
      ),
      onError:
          (_, _) => _presentActionDialog(
            title: title,
            message: message,
            tone: tone,
            confirmText: confirmText,
          ),
    );
    _actionTransition = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }

  static Future<void> _presentActionDialog({
    required String title,
    required String message,
    required _AppActionAlertTone tone,
    required String confirmText,
  }) async {
    await _closeActiveAlert();
    final context = Get.overlayContext ?? Get.context;
    if (context == null || !context.mounted) return;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'common.alert_dialog'.tr,
        barrierColor: Colors.black.withValues(alpha: 0.48),
        transitionDuration:
            disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) {
          _activeDialogContext = context;
          return _AppActionAlertOverlay(
            title: title,
            message: message,
            tone: tone,
            confirmText: confirmText,
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );
    } finally {
      _activeDialogContext = null;
    }
  }

  /// Notifications intentionally keep their in-app banner. General success
  /// and error feedback is silent so it does not interrupt the current task.
  static Future<void> notification({
    required String title,
    required String message,
  }) => _show(title: title, message: message, tone: _AppAlertTone.success);

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
    if (Get.key.currentState?.overlay == null && Get.overlayContext == null) {
      return;
    }

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
    final dialogContext = _activeDialogContext;
    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
      _activeDialogContext = null;
    }
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

enum _AppAlertTone { success }

enum _AppActionAlertTone { success, error }

class _AppActionAlertOverlay extends StatelessWidget {
  const _AppActionAlertOverlay({
    required this.title,
    required this.message,
    required this.tone,
    required this.confirmText,
  });

  final String title;
  final String message;
  final _AppActionAlertTone tone;
  final String confirmText;

  @override
  Widget build(BuildContext context) {
    final isSuccess = tone == _AppActionAlertTone.success;
    final iconColor = isSuccess ? AppColors.primaryGreen : AppColors.errorCoral;
    final icon = isSuccess ? Icons.check_rounded : Icons.close_rounded;
    final localizedTitle = title.trOrSelf;
    final localizedMessage = message.trOrSelf;
    final buttonColor = context.appColorScheme.primary;
    final buttonForeground = context.appOnBrand;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(22),
            child: Center(
              child: SingleChildScrollView(
                child: Semantics(
                  container: true,
                  scopesRoute: true,
                  namesRoute: true,
                  explicitChildNodes: true,
                  label:
                      '${isSuccess ? 'Success' : 'Error'}: '
                      '$localizedTitle. $localizedMessage',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 424),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 250),
                      padding: const EdgeInsets.fromLTRB(28, 29, 28, 28),
                      decoration: BoxDecoration(
                        color: context.appElevatedSurface,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: context.appElevatedSurface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(icon, color: iconColor, size: 34),
                          ),
                          const SizedBox(height: 29),
                          Text(
                            localizedTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 20,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (localizedMessage.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              localizedMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.appMutedText,
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 27),
                          SizedBox(
                            width: 160,
                            height: 53,
                            child: FilledButton(
                              key: const ValueKey<String>(
                                'app-action-alert-confirm',
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              style: FilledButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: buttonForeground,
                                elevation: 5,
                                shadowColor: buttonColor.withValues(
                                  alpha: 0.38,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(21),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Text(confirmText.trOrSelf),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final localizedTitle = title.trOrSelf;
    final localizedMessage = message.trOrSelf;

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
                    tooltip: 'common.dismiss_notification'.tr,
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
