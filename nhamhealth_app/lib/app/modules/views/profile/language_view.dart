import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile/language_controller.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/language_flag.dart';

class LanguageView extends GetView<LanguageController> {
  const LanguageView({super.key});

  static const green = Color(0xFF00A651);
  static const darkGreen = Color(0xFF006B38);

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFBFB),
        body: Stack(
          children: [
            const _SettingsBackground(),

            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: AppSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: controller.goBack,
                                  behavior: HitTestBehavior.opaque,
                                  child: const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      size: 23,
                                      color: darkGreen,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 5),

                                const Text(
                                  'Language',
                                  style: TextStyle(
                                    fontSize: 21,
                                    height: 1,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 26),

                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Text(
                                'Choose App Language',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF151515),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Text(
                                'Select your preferred language for the app',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF687185),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            _buildLanguageCard(),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildInfo(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EBE6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Obx(
        () => Column(
          children: [
            _LanguageItem(
              languageCode: 'km',
              title: 'Khmer',
              selected: controller.selectedLanguage.value == 'Khmer',
              onTap: controller.selectKhmer,
            ),

            const Padding(
              padding: EdgeInsets.only(left: 64),
              child: Divider(
                height: 1,
                thickness: 0.7,
                color: Color(0xFFD7D9DC),
              ),
            ),

            _LanguageItem(
              languageCode: 'en',
              title: 'English',
              selected: controller.selectedLanguage.value == 'English',
              onTap: controller.selectEnglish,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCDE9D5)),
      ),
      child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.info_outline_rounded, color: green, size: 17),
        ),

        SizedBox(width: 9),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Language will be applied immediately',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF294C81),
                ),
              ),

              SizedBox(height: 9),

              Text(
                'The new language is applied to supported content immediately.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  color: Color(0xFF294C81),
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }
}

class _LanguageItem extends StatelessWidget {
  final String languageCode;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageItem({
    required this.languageCode,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 76,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0FAF3) : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              LanguageFlag(languageCode: languageCode, size: 40),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF161616),
                  ),
                ),
              ),

              _RadioCircle(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioCircle extends StatelessWidget {
  const _RadioCircle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: selected ? LanguageView.green : const Color(0xFFB9BDC4),
          width: 1.5,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? LanguageView.green : Colors.transparent,
        ),
      ),
    );
  }
}

class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
