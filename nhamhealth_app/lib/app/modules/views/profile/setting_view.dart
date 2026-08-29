import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/profile/setting_controller.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/page_skeleton.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SizedBox.expand(
          child: Stack(
            children: [
              // --------------------------------------------
              // BACKGROUND
              // --------------------------------------------
              Positioned.fill(
                child: Opacity(
                  opacity: isDark ? 0.12 : 1,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/background/bg.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

              if (isDark)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.16),
                  ),
                ),

              // Soft pink left background
              Positioned(
                left: -130,
                top: -80,
                child: Container(
                  width: 390,
                  height: 620,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        isDark
                            ? const Color(0x203B1820)
                            : const Color(0x55FFF0F3),
                        isDark
                            ? const Color(0x1027181C)
                            : const Color(0x22FFF4F6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Soft green top-right
              Positioned(
                right: -130,
                top: -100,
                child: Container(
                  width: 360,
                  height: 420,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        isDark
                            ? const Color(0x2039D879)
                            : const Color(0x55E8FFD9),
                        isDark
                            ? const Color(0x101D4A2E)
                            : const Color(0x22F4FFE9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Soft green bottom-right
              Positioned(
                right: -160,
                bottom: -120,
                child: Container(
                  width: 430,
                  height: 470,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        isDark
                            ? const Color(0x2039D879)
                            : const Color(0x55EEFFD8),
                        isDark
                            ? const Color(0x101D4A2E)
                            : const Color(0x22F6FFE9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Soft pink bottom-left
              Positioned(
                left: -180,
                bottom: -100,
                child: Container(
                  width: 400,
                  height: 450,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        isDark
                            ? const Color(0x203B1820)
                            : const Color(0x44FFF0F2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // --------------------------------------------
              // PAGE CONTENT
              // --------------------------------------------
              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: AppSpacing.pagePaddingWithNavigation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),

                      const SizedBox(height: 24),
                      Obx(
                        () => AnimatedSize(
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: LoadingContentTransition(
                            isLoading: controller.isLoading.value,
                            loading: const PageSkeleton.settings(),
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  context,
                                  'settings_account'.tr,
                                ),
                                const SizedBox(height: 10),
                                _buildAccountCard(context),
                                const SizedBox(height: 21),
                                _buildSectionTitle(
                                  context,
                                  'settings_preferences'.tr,
                                ),
                                const SizedBox(height: 10),
                                _buildPreferenceCard(context),
                                const SizedBox(height: 21),
                                _buildSectionTitle(
                                  context,
                                  'settings_support'.tr,
                                ),
                                const SizedBox(height: 10),
                                _buildSupportCard(context),
                                const SizedBox(height: 13),
                                _buildLogoutCard(context),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: AppSpacing.navigationMargin,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: AppBottomNavigation(
                selectedIndex: 4,
                onSelect: controller.selectBottomMenu,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return AppBackHeader(
      title: 'settings'.tr,
      backButtonKey: const ValueKey('settings-back-button'),
      onBack: controller.goBack,
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          height: 1.1,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  // ============================================================
  // ACCOUNT
  // ============================================================

  Widget _buildAccountCard(BuildContext context) {
    return _groupCard(
      context,
      children: [
        _SettingsItem(
          icon: Icons.lock_outline_rounded,
          title: 'password_security'.tr,
          subtitle: 'password_security_description'.tr,
          onTap: controller.openPasswordSecurity,
        ),
        _divider(context),
        _SettingsItem(
          icon: Icons.favorite_border_rounded,
          title: 'favorites'.tr,
          subtitle: 'favorites_description'.tr,
          onTap: controller.openFavorites,
        ),
      ],
    );
  }

  // ============================================================
  // PREFERENCES
  // ============================================================

  Widget _buildPreferenceCard(BuildContext context) {
    return _groupCard(
      context,
      children: [
        _SettingsItem(
          icon: Icons.dark_mode_outlined,
          title: 'appearance'.tr,
          subtitle: 'appearance_description'.tr,
          onTap: controller.openAppearance,
        ),

        _divider(context),

        _SettingsItem(
          icon: Icons.language_rounded,
          title: 'language'.tr,
          subtitle: 'language_setting_description'.tr,
          trailingText:
              Get.locale?.languageCode == 'km'
                  ? 'language_khmer'.tr
                  : 'language_english'.tr,
          onTap: controller.openLanguage,
        ),
      ],
    );
  }

  // ============================================================
  // SUPPORT
  // ============================================================

  Widget _buildSupportCard(BuildContext context) {
    return _groupCard(
      context,
      children: [
        _SettingsItem(
          icon: Icons.help_outline_rounded,
          title: 'help_support'.tr,
          subtitle: 'help_support_description'.tr,
          onTap: controller.openHelpSupport,
        ),

        _divider(context),

        _SettingsItem(
          icon: Icons.description_outlined,
          title: 'terms_privacy'.tr,
          subtitle: 'terms_privacy_description'.tr,
          onTap: controller.openTermsPrivacy,
        ),
      ],
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Widget _buildLogoutCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors:
              isDark
                  ? [colors.surface, colors.surfaceContainer, colors.surface]
                  : const [
                    Color(0xFFFFF6F7),
                    Color(0xFFFFFFFF),
                    Color(0xFFF2FFED),
                  ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.outline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _SettingsItem(
        icon: Icons.logout_rounded,
        title: 'log_out'.tr,
        subtitle: 'log_out_description'.tr,
        isLogout: true,
        onTap: controller.logout,
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _groupCard(BuildContext context, {required List<Widget> children}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _divider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: Divider(
        height: 1,
        thickness: 0.7,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

// ================================================================
// SETTINGS ITEM
// ================================================================

class _SettingsItem extends StatelessWidget {
  final IconData icon;

  final String title;

  final String subtitle;

  final String? trailingText;

  final VoidCallback onTap;

  final bool isLogout;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingText,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: double.infinity,
          height: 72,
          child: Padding(
            padding: const EdgeInsets.only(left: 13, right: 13),
            child: Row(
              children: [
                // ----------------------------------------
                // ICON
                // ----------------------------------------
                Container(
                  width: 41,
                  height: 41,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isLogout
                            ? (isDark
                                ? const Color(0xFF4B252A)
                                : const Color(0xFFFFE1E4))
                            : colors.primaryContainer.withValues(
                              alpha: isDark ? 0.45 : 0.65,
                            ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 22,
                    color:
                        isLogout
                            ? (isDark
                                ? const Color(0xFFFF8B94)
                                : const Color(0xFFFF202A))
                            : colors.primary,
                  ),
                ),

                const SizedBox(width: 14),

                // ----------------------------------------
                // TEXT
                // ----------------------------------------
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color:
                              isLogout
                                  ? (isDark
                                      ? const Color(0xFFFFA2A9)
                                      : const Color(0xFFFF151E))
                                  : colors.onSurface,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          height: 1,
                          fontWeight: FontWeight.w400,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // ----------------------------------------
                // LANGUAGE
                // ----------------------------------------
                if (trailingText != null) ...[
                  Text(
                    trailingText!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colors.secondary,
                    ),
                  ),
                  const SizedBox(width: 9),
                ],

                // ----------------------------------------
                // ARROW
                // ----------------------------------------
                Icon(
                  Icons.chevron_right_rounded,
                  size: 29,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
