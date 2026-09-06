import 'package:flutter/material.dart';
import '../../../widgets/app_alert.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/app_security_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/pin_keypad_dialog.dart';
import 'change_password_view.dart';
import '../../bindings/profile/change_password_binding.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/page_skeleton.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

class SecurityView extends StatefulWidget {
  const SecurityView({
    super.key,
    this.promptCreatePin = false,
    this.requirePinCreation = false,
    this.onPinCreated,
  });

  final bool promptCreatePin;
  final bool requirePinCreation;
  final VoidCallback? onPinCreated;

  @override
  State<SecurityView> createState() => _SecurityViewState();
}

class _SecurityViewState extends State<SecurityView> {
  final _security = Get.find<AppSecurityService>();
  bool _loading = true;
  bool _hasPin = false;
  bool _biometrics = false;
  bool _canUseBiometrics = false;
  AppBiometricKind _biometricKind = AppBiometricKind.generic;
  bool _didAutoPrompt = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      _security.hasPin,
      _security.biometricsEnabled,
      _security.canUseBiometrics(),
      _security.biometricKind,
    ]);
    if (!mounted) return;
    setState(() {
      _hasPin = values[0] as bool;
      _biometrics = values[1] as bool;
      _canUseBiometrics = values[2] as bool;
      _biometricKind = values[3] as AppBiometricKind;
      _loading = false;
    });
    if (widget.promptCreatePin && !_hasPin && !_didAutoPrompt) {
      _didAutoPrompt = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setOrChangePin();
      });
    }
  }

  Future<String?> _askPin(String title, {bool confirm = false}) async {
    return showPinKeypadDialog(
      context: context,
      title: title,
      subtitle:
          confirm ? 'Choose a memorable 6-digit PIN' : 'Enter your 6-digit PIN',
      confirmPin: confirm,
      allowCancel: !widget.requirePinCreation,
    );
  }

  Future<bool> _verifyCurrentPin() async {
    final pin = await _askPin('Verify your PIN');
    if (pin == null) return false;
    try {
      if (await _security.verifyPin(pin)) return true;
      _showSecurityError('Incorrect PIN', 'The PIN you entered is incorrect.');
    } on AuthException catch (error) {
      await _handleAuthFailure(error, action: 'Could not verify PIN');
    } on Object {
      _showSecurityError(
        'Could not verify PIN',
        'Something went wrong. Please try again.',
      );
    }
    return false;
  }

  Future<void> _setOrChangePin() async {
    if (_hasPin && !await _verifyCurrentPin()) return;
    if (!mounted) return;
    final pin = await _askPin(
      _hasPin ? 'Choose a new PIN' : 'Create app PIN',
      confirm: true,
    );
    if (pin == null) return;
    try {
      await _security.setPin(pin);
      await _load();
      if (widget.requirePinCreation && _canUseBiometrics && !_biometrics) {
        final enabled = await _security.confirmDeviceBiometrics(
          'Use your fingerprint or biometrics to protect private features',
        );
        if (enabled) {
          await _security.setBiometricsEnabled(true);
          await _load();
        }
      }
      await AppAlert.success(
        title: 'App protection enabled',
        message:
            _biometrics
                ? 'Your PIN and biometric unlock are ready.'
                : 'Your app PIN is ready. You can enable fingerprint or biometrics from Security.',
      );
      widget.onPinCreated?.call();
    } on AuthException catch (error) {
      await _handleAuthFailure(error, action: 'Could not save PIN');
    } on FormatException catch (error) {
      _showSecurityError('Could not save PIN', error.message);
    } on Object {
      _showSecurityError(
        'Could not save PIN',
        'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> _toggleBiometrics(bool enabled) async {
    if (!_hasPin) {
      await _setOrChangePin();
      if (!_hasPin) return;
    }
    try {
      if (enabled &&
          !await _security.confirmDeviceBiometrics(
            'Confirm biometrics for NhamHealth',
          )) {
        return;
      }
      await _security.setBiometricsEnabled(enabled);
      await _load();
    } on Object {
      if (mounted) {
        AppAlert.error(
          title: 'Biometrics unavailable',
          message: 'Biometrics could not be enabled.',
        );
      }
    }
  }

  Future<void> _disableLock() async {
    if (!await _verifyCurrentPin()) return;
    try {
      await _security.disable();
      await _load();
    } on AuthException catch (error) {
      await _handleAuthFailure(
        error,
        action: 'Could not turn off app protection',
      );
    } on Object {
      _showSecurityError(
        'Could not update security',
        'Could not turn off app protection.',
      );
    }
  }

  Future<void> _handleAuthFailure(
    AuthException error, {
    required String action,
  }) async {
    final sessionInvalid =
        error.statusCode == 401 ||
        error.statusCode == 403 ||
        error.message.toLowerCase().contains('session has expired') ||
        error.message.toLowerCase().contains('session is no longer valid');
    if (!sessionInvalid) {
      _showSecurityError(action, error.message);
      return;
    }

    await _security.clearInvalidSession();
    if (!mounted) return;
    AppAlert.error(
      title: 'Session expired',
      message:
          'This account is no longer available in the configured database. '
          'Please sign in or create the account again.',
    );
    Get.offAllNamed<void>(AppRoutes.login);
  }

  void _showSecurityError(String title, String message) {
    if (!mounted) return;
    AppAlert.error(title: title, message: message);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    body: AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child:
                  _loading
                      ? SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.pageHorizontalFor(context),
                          12,
                          AppSpacing.pageHorizontalFor(context),
                          36,
                        ),
                        child: const PageSkeleton.settings(),
                      )
                      : LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 820;
                          return ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.pageHorizontalFor(context),
                              12,
                              AppSpacing.pageHorizontalFor(context),
                              36,
                            ),
                            children: [
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: AppSpacing.maxWideContentWidth,
                                  ),
                                  child:
                                      wide
                                          ? Row(
                                            key: const ValueKey<String>(
                                              'security-tablet-layout',
                                            ),
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: _securityOverview(),
                                              ),
                                              const SizedBox(width: 20),
                                              Expanded(
                                                child: _protectionSettings(),
                                              ),
                                            ],
                                          )
                                          : _compactSecurityContent(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _header() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppSpacing.maxWideContentWidth,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 20, 10),
        child: Row(
          children: [
            if (widget.requirePinCreation && !_hasPin)
              const SizedBox(width: AppBackButton.layoutSize)
            else
              AppBackButton(onPressed: Get.back),
            const SizedBox(width: AppBackButton.headerGap),
            Expanded(
              child: Text(
                'Password & Security'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                  color: context.appText,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _compactSecurityContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _statusCard(),
      const SizedBox(height: 28),
      _protectionSettings(),
      const SizedBox(height: 28),
      _accountSettings(),
    ],
  );

  Widget _securityOverview() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [_statusCard(), const SizedBox(height: 24), _accountSettings()],
  );

  Widget _protectionSettings() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _SectionTitle(
        title: 'App protection',
        subtitle: 'Choose how you unlock private features',
      ),
      const SizedBox(height: 12),
      _settingsCard(),
    ],
  );

  Widget _accountSettings() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _SectionTitle(
        title: 'Account security',
        subtitle: 'Keep your NhamHealth account secure',
      ),
      const SizedBox(height: 12),
      _accountCard(),
      if (_hasPin) ...[const SizedBox(height: 22), _disableButton()],
    ],
  );

  Widget _statusCard() {
    final protected = _hasPin;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              context.appIsDark
                  ? const [Color(0xFF0A3D28), Color(0xFF087B46)]
                  : const [Color(0xFF007A43), Color(0xFF00A85A)],
        ),
        border: Border.all(
          color:
              context.appIsDark
                  ? const Color(0xFF4ADE80).withValues(alpha: .28)
                  : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007A43).withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .17),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .25)),
            ),
            child: Icon(
              protected ? Icons.verified_user_rounded : Icons.shield_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  protected
                      ? 'Your privacy is protected'.tr
                      : 'Add extra protection'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  protected
                      ? '@method required for private features'.trParams({
                        'method':
                            (_biometrics ? 'Biometrics and PIN' : 'PIN').tr,
                      })
                      : 'Secure AI Food Check and profile changes with a PIN.'
                          .tr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .84),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard() => _card(
    children: [
      _SecurityTile(
        icon: Icons.pin_rounded,
        title: _hasPin ? 'Change app PIN' : 'Create app PIN',
        subtitle:
            _hasPin
                ? 'Your 6-digit backup PIN is active'
                : 'Set a 6-digit unlock code',
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: context.appMutedText,
        ),
        onTap: _setOrChangePin,
      ),
      _divider(),
      _SecurityTile(
        icon:
            _biometricKind == AppBiometricKind.face
                ? Icons.face_rounded
                : Icons.fingerprint_rounded,
        title: switch (_biometricKind) {
          AppBiometricKind.face => 'Face ID',
          AppBiometricKind.fingerprint => 'Fingerprint',
          AppBiometricKind.generic => 'Biometric unlock',
        },
        subtitle:
            _canUseBiometrics
                ? (_biometrics
                    ? 'Quick unlock is enabled'
                    : 'Unlock quickly with your device')
                : 'No biometrics enrolled on this device',
        enabled: _canUseBiometrics,
        trailing: Switch.adaptive(
          value: _biometrics && _canUseBiometrics,
          activeTrackColor: const Color(0xFF00A651),
          onChanged: _canUseBiometrics ? _toggleBiometrics : null,
        ),
        onTap: _canUseBiometrics ? () => _toggleBiometrics(!_biometrics) : null,
      ),
    ],
  );

  Widget _accountCard() => _card(
    children: [
      _SecurityTile(
        icon: Icons.password_rounded,
        title: 'Change account password',
        subtitle: 'Update the password used to sign in',
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: context.appMutedText,
        ),
        onTap:
            () => Get.to<void>(
              () => const ChangePasswordView(),
              binding: ChangePasswordBinding(),
            ),
      ),
    ],
  );

  Widget _card({required List<Widget> children}) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: context.appElevatedSurface.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.appBorder, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: context.appShadow,
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(children: children),
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.only(left: 76),
    child: Divider(height: 1, color: context.appBorder),
  );

  Widget _disableButton() => OutlinedButton.icon(
    onPressed: _disableLock,
    icon: const Icon(Icons.lock_open_rounded, size: 19),
    label: Text('Turn off app protection'.tr),
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFC84444),
      minimumSize: const Size.fromHeight(50),
      side: BorderSide(color: context.appOnDangerSurface.withValues(alpha: .4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: context.appDangerSurface,
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.appText,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle.tr,
          style: TextStyle(fontSize: 12, color: context.appMutedText),
        ),
      ],
    ),
  );
}

class _SecurityTile extends StatelessWidget {
  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 15, 12, 15),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color:
                    enabled
                        ? context.appSelectedSurface
                        : context.appMutedSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color:
                    enabled
                        ? context.appColorScheme.primary
                        : context.appMutedText,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.tr,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color:
                          enabled
                              ? context.appText
                              : context.appMutedText.withValues(alpha: .62),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle.tr,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.25,
                      color: context.appMutedText.withValues(
                        alpha: enabled ? 1 : .62,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    ),
  );
}
