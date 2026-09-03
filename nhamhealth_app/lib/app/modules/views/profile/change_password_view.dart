import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_back_header.dart';
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
                final wide = constraints.maxWidth >= 820;
                final side =
                    constraints.maxWidth < 360
                        ? 16.0
                        : AppSpacing.pageHorizontalFor(context);
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    side,
                    8,
                    side,
                    32 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: wide ? AppSpacing.maxWideContentWidth : 520,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _PageHeader(),
                          const SizedBox(height: 26),
                          if (wide)
                            Row(
                              key: const ValueKey<String>(
                                'change-password-tablet-layout',
                              ),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(child: _SecurityIntro()),
                                const SizedBox(width: 28),
                                Expanded(
                                  flex: 2,
                                  child: _PasswordForm(controller: controller),
                                ),
                              ],
                            )
                          else ...[
                            const _SecurityIntro(),
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
  Widget build(BuildContext context) => SizedBox(
    height: AppBackButton.layoutSize,
    child: Row(
      children: [
        AppBackButton(onPressed: Get.back),
        const SizedBox(width: AppBackButton.headerGap),
        Expanded(
          child: Text(
            'Change password'.tr,
            style: TextStyle(
              color: context.appText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SecurityIntro extends StatelessWidget {
  const _SecurityIntro();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _IntroIcon(),
      const SizedBox(width: 15),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Secure your account'.tr,
              style: TextStyle(
                color: context.appText,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Choose a strong password you have not used before.'.tr,
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

class _IntroIcon extends StatelessWidget {
  const _IntroIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: context.appSoftGreen,
      borderRadius: BorderRadius.circular(17),
    ),
    child: const Icon(
      Icons.lock_reset_rounded,
      color: AppColors.primaryGreen,
      size: 28,
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
              label: 'Current password',
              hint: 'Enter your current password',
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
                'Forgot password?'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => _PasswordField(
              label: 'New password',
              hint: 'Create a new password',
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
              label: 'Confirm new password',
              hint: 'Enter the new password again',
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
        label.tr,
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
          hintText: hint.tr,
          hintStyle: TextStyle(color: context.appMutedText, fontSize: 14),
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
          suffixIcon: IconButton(
            tooltip: (obscureText ? 'Show password' : 'Hide password').tr,
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
            'Use at least 8 characters. Your new password must be different from your current password.'
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
                children: [
                  const Icon(Icons.lock_reset_rounded, size: 20),
                  const SizedBox(width: 9),
                  Text(
                    'Update password'.tr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
    ),
  );
}
