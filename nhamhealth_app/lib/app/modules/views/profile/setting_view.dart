import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/forest_glow_background.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/profile/setting_controller.dart';

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
        // Let the shared forest background remain visible in dark mode.
        // Painting an opaque scaffold here previously hid it completely.
        backgroundColor:
            isDark ? Colors.transparent : theme.scaffoldBackgroundColor,
        body: SizedBox.expand(
          child: Stack(
            children: [
              if (isDark)
                const Positioned.fill(
                  child: ForestGlowBackground(
                    force: true,
                    child: SizedBox.expand(),
                  ),
                ),

              // --------------------------------------------
              // BACKGROUND
              // --------------------------------------------
              if (!isDark)
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/background/bg.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

              if (!isDark)
                Positioned(
                  left: -130,
                  top: -80,
                  child: Container(
                    width: 390,
                    height: 620,
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Color(0x55FFF0F3),
                          Color(0x22FFF4F6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              if (!isDark)
                Positioned(
                  right: -130,
                  top: -100,
                  child: Container(
                    width: 360,
                    height: 420,
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Color(0x55E8FFD9),
                          Color(0x22F4FFE9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              if (!isDark)
                Positioned(
                  right: -160,
                  bottom: -120,
                  child: Container(
                    width: 430,
                    height: 470,
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Color(0x55EEFFD8),
                          Color(0x22F6FFE9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              if (!isDark)
                Positioned(
                  left: -180,
                  bottom: -100,
                  child: Container(
                    width: 400,
                    height: 450,
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Color(0x44FFF0F2), Colors.transparent],
                      ),
                    ),
                  ),
                ),

              // --------------------------------------------
              // PAGE CONTENT
              // --------------------------------------------
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontalFor(context),
                        AppSpacing.pageTop,
                        AppSpacing.pageHorizontalFor(context),
                        0,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: _contentMaxWidth(context),
                          ),
                          child: _buildHeader(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.pageHorizontalFor(context),
                          20,
                          AppSpacing.pageHorizontalFor(context),
                          AppSpacing.pageBottom,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: _contentMaxWidth(context),
                            ),
                            child: Obx(
                              () => AnimatedSize(
                                duration: const Duration(milliseconds: 360),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.topCenter,
                                child: LoadingContentTransition(
                                  isLoading: controller.isLoading.value,
                                  loading: const PageSkeleton.settings(),
                                  content: _buildContent(context),
                                ),
                              ),
                            ),
                          ),
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

  double _contentMaxWidth(BuildContext context) {
    final isTablet = AppSpacing.isTabletFor(context);
    if (isTablet) return AppSpacing.maxWideContentWidth;
    return AppSpacing.maxContentWidth;
  }

  Widget _buildContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            key: const ValueKey('settings-tablet-two-column'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'profile.settings_account'.tr),
                    const SizedBox(height: 10),
                    _buildAccountCard(context),
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      context,
                      'profile.settings_preferences'.tr,
                    ),
                    const SizedBox(height: 10),
                    _buildPreferenceCard(context),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'profile.settings_support'.tr),
                    const SizedBox(height: 10),
                    _buildSupportCard(context),
                    const SizedBox(height: 24),
                    _buildLogoutCard(context),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          key: const ValueKey('settings-single-column'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'profile.settings_account'.tr),
            const SizedBox(height: 10),
            _buildAccountCard(context),
            const SizedBox(height: 21),
            _buildSectionTitle(context, 'profile.settings_preferences'.tr),
            const SizedBox(height: 10),
            _buildPreferenceCard(context),
            const SizedBox(height: 21),
            _buildSectionTitle(context, 'profile.settings_support'.tr),
            const SizedBox(height: 10),
            _buildSupportCard(context),
            const SizedBox(height: 13),
            _buildLogoutCard(context),
          ],
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return AppBackHeader(
      title: 'common.settings'.tr,
      backButtonKey: const ValueKey('settings-back-button'),
      onBack: controller.goBack,
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isTablet = AppSpacing.isTabletFor(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isTablet ? 17 : 16,
          height: 1.1,
          fontWeight: isTablet ? FontWeight.w700 : FontWeight.w600,
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
          title: 'profile.password_security'.tr,
          subtitle: 'profile.password_security_description'.tr,
          onTap: controller.openPasswordSecurity,
        ),
        _divider(context),
        _SettingsItem(
          icon: Icons.favorite_border_rounded,
          title: 'profile.favorites'.tr,
          subtitle: 'profile.favorites_description'.tr,
          onTap: controller.openFavorites,
        ),
        _divider(context),
        _SettingsItem(
          icon: Icons.bookmark_outline_rounded,
          title: 'profile.saved_posts'.tr,
          subtitle: 'profile.saved_posts_description'.tr,
          onTap: controller.openSavedPosts,
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
          title: 'profile.appearance_2'.tr,
          subtitle: 'profile.appearance_description'.tr,
          onTap: controller.openAppearance,
        ),

        _divider(context),

        _SettingsItem(
          icon: Icons.language_rounded,
          title: 'settings.change_language'.tr,
          subtitle: 'profile.language_setting_description'.tr,
          trailingText:
              Get.locale?.languageCode == 'km'
                  ? 'settings.language_khmer'.tr
                  : 'settings.language_english'.tr,
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
          icon: Icons.flag_outlined,
          title: 'settings.my_reports'.tr,
          subtitle: 'settings.my_reports_description'.tr,
          onTap: controller.openMyReports,
        ),

        _divider(context),

        _SettingsItem(
          icon: Icons.help_outline_rounded,
          title: 'profile.help_support'.tr,
          subtitle: 'profile.help_support_description'.tr,
          onTap: controller.openHelpSupport,
        ),

        _divider(context),

        _SettingsItem(
          icon: Icons.description_outlined,
          title: 'profile.terms_privacy'.tr,
          subtitle: 'profile.terms_privacy_description'.tr,
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
    final isTablet = AppSpacing.isTabletFor(context);
    final cardRadius = isTablet ? 16.0 : 13.0;

    return Container(
      width: double.infinity,
      height: isTablet ? 76 : 65,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors:
              isDark
                  ? [
                    colors.surface.withValues(alpha: .9),
                    colors.surfaceContainer.withValues(alpha: .86),
                    colors.surface.withValues(alpha: .9),
                  ]
                  : const [
                    Color(0xFFFFF6F7),
                    Color(0xFFFFFFFF),
                    Color(0xFFF2FFED),
                  ],
        ),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: colors.outline, width: 1),
        boxShadow: context.appCardShadow,
      ),
      child: _SettingsItem(
        icon: Icons.logout_rounded,
        title: 'profile.log_out_2'.tr,
        subtitle: 'profile.log_out_description'.tr,
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
    final isTablet = AppSpacing.isTabletFor(context);
    final cardRadius = isTablet ? 16.0 : 13.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(
          alpha: context.appIsDark ? 0.88 : 0.92,
        ),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: context.appCardShadow,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _divider(BuildContext context) {
    final isTablet = AppSpacing.isTabletFor(context);
    return Padding(
      padding: EdgeInsets.only(left: isTablet ? 76 : 64),
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
    final isTablet = AppSpacing.isTabletFor(context);
    final itemRadius = isTablet ? 16.0 : 13.0;
    final itemHeight = isTablet ? 76.0 : 72.0;
    final iconContainerSize = isTablet ? 45.0 : 41.0;
    final iconSize = isTablet ? 23.0 : 22.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(itemRadius),
        child: SizedBox(
          width: double.infinity,
          height: itemHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 13),
            child: Row(
              children: [
                // ----------------------------------------
                // ICON
                // ----------------------------------------
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
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
                    size: iconSize,
                    color:
                        isLogout
                            ? (isDark
                                ? const Color(0xFFFF8B94)
                                : const Color(0xFFFF202A))
                            : colors.primary,
                  ),
                ),

                SizedBox(width: isTablet ? 16 : 14),

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
                          fontSize: isTablet ? 15 : 13.5,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                          color:
                              isLogout
                                  ? (isDark
                                      ? const Color(0xFFFFA2A9)
                                      : const Color(0xFFFF151E))
                                  : colors.onSurface,
                        ),
                      ),

                      SizedBox(height: isTablet ? 5 : 4),

                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 10.5,
                          height: 1.1,
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
                      fontSize: isTablet ? 13 : 11.5,
                      fontWeight: FontWeight.w600,
                      color: colors.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // ----------------------------------------
                // ARROW
                // ----------------------------------------
                Icon(
                  Icons.chevron_right_rounded,
                  size: isTablet ? 26 : 28,
                  color: colors.onSurfaceVariant.withValues(alpha: .7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
