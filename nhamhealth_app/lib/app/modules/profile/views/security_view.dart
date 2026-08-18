import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/services/app_security_service.dart';
import 'change_password_view.dart';
import '../bindings/change_password_binding.dart';

class SecurityView extends StatefulWidget {
  const SecurityView({super.key});

  @override
  State<SecurityView> createState() => _SecurityViewState();
}

class _SecurityViewState extends State<SecurityView> {
  final _security = Get.find<AppSecurityService>();
  bool _loading = true;
  bool _hasPin = false;
  bool _biometrics = false;
  bool _canUseBiometrics = false;

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
    ]);
    if (!mounted) return;
    setState(() {
      _hasPin = values[0];
      _biometrics = values[1];
      _canUseBiometrics = values[2];
      _loading = false;
    });
  }

  Future<String?> _askPin(String title, {bool confirm = false}) async {
    final first = TextEditingController();
    final second = TextEditingController();
    String? error;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(title),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _pinField(
                        first,
                        confirm ? 'New 4-digit PIN' : 'Current PIN',
                      ),
                      if (confirm) ...[
                        const SizedBox(height: 12),
                        _pinField(second, 'Confirm PIN'),
                      ],
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        if (first.text.length != 4) {
                          setDialogState(
                            () => error = 'Enter exactly 4 digits.',
                          );
                        } else if (confirm && first.text != second.text) {
                          setDialogState(() => error = 'PINs do not match.');
                        } else {
                          Navigator.pop(dialogContext, first.text);
                        }
                      },
                      child: const Text('Continue'),
                    ),
                  ],
                ),
          ),
    );
    // showDialog completes when pop starts, before the reverse route animation
    // has released every TextField dependency. Disposing immediately can trip
    // Flutter's `_dependents.isEmpty` assertion in debug builds.
    _disposeControllersAfterRoute(first, second);
    return result;
  }

  Future<void> _disposeControllersAfterRoute(
    TextEditingController first,
    TextEditingController second,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    first.dispose();
    second.dispose();
  }

  Widget _pinField(TextEditingController controller, String label) => TextField(
    controller: controller,
    obscureText: true,
    keyboardType: TextInputType.number,
    maxLength: 4,
    autofocus: true,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: label,
      counterText: '',
      border: const OutlineInputBorder(),
    ),
  );

  Future<bool> _verifyCurrentPin() async {
    final pin = await _askPin('Verify your PIN');
    if (pin == null) return false;
    if (await _security.verifyPin(pin)) return true;
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incorrect PIN.')));
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
    await _security.setPin(pin);
    await _load();
  }

  Future<void> _toggleBiometrics(bool enabled) async {
    if (!_hasPin) {
      await _setOrChangePin();
      if (!_hasPin) return;
    }
    try {
      if (enabled &&
          !await _security.authenticateBiometrically(
            'Confirm biometrics for NhamHealth',
          )) {
        return;
      }
      await _security.setBiometricsEnabled(enabled);
      await _load();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometrics could not be enabled.')),
        );
      }
    }
  }

  Future<void> _disableLock() async {
    if (!await _verifyCurrentPin()) return;
    await _security.disable();
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFFBFC),
    body: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background/bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 36),
                        children: [
                          _statusCard(),
                          const SizedBox(height: 28),
                          const _SectionTitle(
                            title: 'App protection',
                            subtitle: 'Choose how you unlock private features',
                          ),
                          const SizedBox(height: 12),
                          _settingsCard(),
                          const SizedBox(height: 28),
                          const _SectionTitle(
                            title: 'Account security',
                            subtitle: 'Keep your NhamHealth account secure',
                          ),
                          const SizedBox(height: 12),
                          _accountCard(),
                          if (_hasPin) ...[
                            const SizedBox(height: 22),
                            _disableButton(),
                          ],
                        ],
                      ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 20, 10),
    child: Row(
      children: [
        IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_rounded),
          color: const Color(0xFF006B38),
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Text(
            'Password & Security',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.35,
              color: Color(0xFF17211B),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _statusCard() {
    final protected = _hasPin;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF007A43), Color(0xFF00A85A)],
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
                      ? 'Your privacy is protected'
                      : 'Add extra protection',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  protected
                      ? '${_biometrics ? 'Biometrics and PIN' : 'PIN'} required for private features'
                      : 'Secure AI Food Check and profile changes with a PIN.',
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
                ? 'Your 4-digit backup PIN is active'
                : 'Set a 4-digit unlock code',
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF6E7B73),
        ),
        onTap: _setOrChangePin,
      ),
      _divider(),
      _SecurityTile(
        icon: Icons.fingerprint_rounded,
        title: 'Fingerprint / Face ID',
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
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF6E7B73),
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
      color: Colors.white.withValues(alpha: .88),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white, width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10002F1A),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(children: children),
  );

  Widget _divider() => const Padding(
    padding: EdgeInsets.only(left: 76),
    child: Divider(height: 1, color: Color(0xFFE7ECE8)),
  );

  Widget _disableButton() => OutlinedButton.icon(
    onPressed: _disableLock,
    icon: const Icon(Icons.lock_open_rounded, size: 19),
    label: const Text('Turn off app protection'),
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFC84444),
      minimumSize: const Size.fromHeight(50),
      side: const BorderSide(color: Color(0xFFF0CACA)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white.withValues(alpha: .7),
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
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B241E),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF7A827D)),
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
                    enabled ? const Color(0xFFE8F7EC) : const Color(0xFFF1F3F1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color:
                    enabled ? const Color(0xFF00A651) : const Color(0xFFABB2AD),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color:
                          enabled
                              ? const Color(0xFF273029)
                              : const Color(0xFFA3AAA5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.25,
                      color:
                          enabled
                              ? const Color(0xFF7B847E)
                              : const Color(0xFFB4BAB6),
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
