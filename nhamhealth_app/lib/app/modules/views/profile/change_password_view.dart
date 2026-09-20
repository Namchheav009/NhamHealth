import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../controllers/profile/change_password_controller.dart';

class ChangePasswordView extends GetView<ChangePasswordController> {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Scaffold(
        backgroundColor: context.appBackground,
        resizeToAvoidBottomInset: true,
        body: AppBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape =
                    MediaQuery.orientationOf(context) == Orientation.landscape;
                final isTablet = AppSpacing.isTabletFor(context);
                final wide =
                    (isLandscape && isTablet) || constraints.maxWidth >= 900;
                final contentMaxWidth =
                    isTablet
                        ? AppSpacing.maxWideContentWidth
                        : 520.0;
                final side =
                    constraints.maxWidth < 360
                        ? 16.0
                        : AppSpacing.pageHorizontalFor(context);
                final topPadding = wide ? AppSpacing.pageTop : 12.0;
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    side,
                    topPadding,
                    side,
                    32 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: contentMaxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _PageHeader(),
                          SizedBox(height: wide ? 28 : 22),
                          if (wide)
                            Row(
                              key: const ValueKey<String>(
                                'change-password-tablet-layout',
                              ),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  flex: 2,
                                  child: _SecurityIntro(isTablet: true),
                                ),
                                const SizedBox(width: 28),
                                Expanded(
                                  flex: 3,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 520,
                                      ),
                                      child: _PasswordForm(
                                        controller: controller,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            const _SecurityIntro(isTablet: false),
                            const SizedBox(height: 22),
                            _PasswordForm(controller: controller),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) =>
      AppBackHeader(title: 'profile.change_password'.tr, onBack: Get.back);
}

class _SecurityIntro extends StatelessWidget {
  const _SecurityIntro({this.isTablet = false});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    if (isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _IntroIcon(size: 58, iconSize: 30),
          const SizedBox(height: 18),
          Text(
            'profile.secure_your_account'.tr,
            style: TextStyle(
              color: context.appText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'profile.choose_a_strong_password_you_have_not_used_before'.tr,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          const _TabletSecurityCard(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _IntroIcon(),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'profile.secure_your_account'.tr,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'profile.choose_a_strong_password_you_have_not_used_before'.tr,
                style: TextStyle(
                  color: context.appMutedText,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabletSecurityCard extends StatelessWidget {
  const _TabletSecurityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorder, width: 1.2),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.appSoftGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'profile.password_security'.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TipItem(
            text: 'profile.use_at_least_8_characters'.tr,
          ),
          const SizedBox(height: 10),
          _TipItem(
            text:
                'profile.your_new_password_must_be_different_from_your_current_password'
                    .tr,
          ),
          const SizedBox(height: 10),
          _TipItem(
            text: 'profile.keep_your_nhamhealth_account_secure'.tr,
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_rounded,
            color: AppColors.primaryGreen,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroIcon extends StatelessWidget {
  const _IntroIcon({this.size = 52, this.iconSize = 28});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: context.appSoftGreen,
      borderRadius: BorderRadius.circular(size * 0.32),
    ),
    child: Icon(
      Icons.lock_reset_rounded,
      color: AppColors.primaryGreen,
      size: iconSize,
    ),
  );
}

class _PasswordForm extends StatelessWidget {
  const _PasswordForm({required this.controller});

  final ChangePasswordController controller;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
    decoration: BoxDecoration(
      color: context.appElevatedSurface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: context.appBorder, width: 1.2),
      boxShadow: context.appCardShadow,
    ),
    child: AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => _PasswordField(
              label: 'profile.current_password',
              hint: 'profile.enter_your_current_password',
              textController: controller.currentPasswordController,
              obscureText: controller.hideCurrentPassword.value,
              onVisibilityPressed: controller.toggleCurrentPassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.password],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: controller.forgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: context.appText,
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: Text(
                'common.forgot_password'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => _PasswordField(
              label: 'common.new_password',
              hint: 'profile.create_a_new_password',
              textController: controller.newPasswordController,
              obscureText: controller.hideNewPassword.value,
              onVisibilityPressed: controller.toggleNewPassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
          ),
          const SizedBox(height: 18),
          Obx(
            () => _PasswordField(
              label: 'profile.confirm_new_password',
              hint: 'profile.enter_the_new_password_again',
              textController: controller.confirmPasswordController,
              obscureText: controller.hideConfirmPassword.value,
              onVisibilityPressed: controller.toggleConfirmPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!controller.isLoading.value) controller.updatePassword();
              },
              autofillHints: const [AutofillHints.newPassword],
            ),
          ),
          const SizedBox(height: 18),
          const _PasswordGuidance(),
          const SizedBox(height: 24),
          Obx(
            () => _SubmitButton(
              loading: controller.isLoading.value,
              onPressed: controller.updatePassword,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.hint,
    required this.textController,
    required this.obscureText,
    required this.onVisibilityPressed,
    required this.textInputAction,
    required this.autofillHints,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController textController;
  final bool obscureText;
  final VoidCallback onVisibilityPressed;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.trOrSelf,
        style: TextStyle(
          color: context.appText,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: textController,
        obscureText: obscureText,
        enableSuggestions: false,
        autocorrect: false,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        cursorColor: AppColors.primaryGreen,
        style: TextStyle(
          color: context.appText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint.trOrSelf,
          hintStyle: TextStyle(color: context.appMutedText, fontSize: 14),
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
          suffixIcon: IconButton(
            tooltip:
                (obscureText ? 'common.show_password' : 'common.hide_password')
                    .tr,
            onPressed: onVisibilityPressed,
            icon: Icon(
              obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
            ),
          ),
          filled: true,
          fillColor: context.appField,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          prefixIconColor: context.appMutedText,
          suffixIconColor: context.appMutedText,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: context.appBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: AppColors.primaryGreen,
              width: 1.6,
            ),
          ),
        ),
      ),
    ],
  );
}

class _PasswordGuidance extends StatelessWidget {
  const _PasswordGuidance();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.appSoftGreen,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.appBorder),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: context.appColorScheme.primary,
          size: 19,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'profile.use_at_least_8_characters_your_new_password_must_be_different_from_your_current_password'
                .tr,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      backgroundColor: AppColors.primaryGreen,
      disabledBackgroundColor: AppColors.primaryGreen.withValues(alpha: 0.55),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: AppColors.darkGreen.withValues(alpha: 0.28),
    ),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child:
          loading
              ? const SizedBox(
                key: ValueKey('loading'),
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
              : Row(
                key: const ValueKey('label'),
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_reset_rounded, size: 20),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      'profile.update_password'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
    ),
  );
}
