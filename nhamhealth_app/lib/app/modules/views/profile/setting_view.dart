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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: const Color(0xFFFFFDFD),
        body: SizedBox.expand(
          child: Stack(
            children: [
              // --------------------------------------------
              // BACKGROUND
              // --------------------------------------------
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

              // Soft pink left background
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
                        Color(0x00FFFFFF),
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
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Color(0x55E8FFD9),
                        Color(0x22F4FFE9),
                        Color(0x00FFFFFF),
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
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Color(0x55EEFFD8),
                        Color(0x22F6FFE9),
                        Color(0x00FFFFFF),
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
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0x44FFF0F2), Color(0x00FFFFFF)],
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
                                _buildSectionTitle('settings_account'.tr),
                                const SizedBox(height: 10),
                                _buildAccountCard(),
                                const SizedBox(height: 21),
                                _buildSectionTitle('settings_preferences'.tr),
                                const SizedBox(height: 10),
                                _buildPreferenceCard(),
                                const SizedBox(height: 21),
                                _buildSectionTitle('settings_support'.tr),
                                const SizedBox(height: 10),
                                _buildSupportCard(),
                                const SizedBox(height: 13),
                                _buildLogoutCard(),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          height: 1.1,
          fontWeight: FontWeight.w600,
          color: Color(0xFF101010),
        ),
      ),
    );
  }

  // ============================================================
  // ACCOUNT
  // ============================================================

  Widget _buildAccountCard() {
    return _groupCard(
      children: [
        _SettingsItem(
          icon: Icons.lock_outline_rounded,
          title: 'password_security'.tr,
          subtitle: 'password_security_description'.tr,
          onTap: controller.openPasswordSecurity,
        ),
        _divider(),
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

  Widget _buildPreferenceCard() {
    return _groupCard(
      children: [
        _SettingsItem(
          icon: Icons.dark_mode_outlined,
          title: 'appearance'.tr,
          subtitle: 'appearance_description'.tr,
          onTap: controller.openAppearance,
        ),

        _divider(),

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

  Widget _buildSupportCard() {
    return _groupCard(
      children: [
        _SettingsItem(
          icon: Icons.help_outline_rounded,
          title: 'help_support'.tr,
          subtitle: 'help_support_description'.tr,
          onTap: controller.openHelpSupport,
        ),

        _divider(),

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

  Widget _buildLogoutCard() {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFFF6F7), Color(0xFFFFFFFF), Color(0xFFF2FFED)],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white, width: 1),
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

  Widget _groupCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.80),
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

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.only(left: 64),
      child: Divider(height: 1, thickness: 0.7, color: Color(0xFFD9D9D9)),
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

  static const Color green = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) {
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
                            ? const Color(0xFFFFE1E4)
                            : const Color(0xFFE4F4E7),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 22,
                    color: isLogout ? const Color(0xFFFF202A) : green,
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
                                  ? const Color(0xFFFF151E)
                                  : const Color(0xFF161616),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          height: 1,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6F7380),
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
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF415D87),
                    ),
                  ),
                  const SizedBox(width: 9),
                ],

                // ----------------------------------------
                // ARROW
                // ----------------------------------------
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 29,
                  color: Color(0xFF3E3E3E),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
