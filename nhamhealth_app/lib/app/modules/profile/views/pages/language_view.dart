import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/language_controller.dart';

class LanguageView extends GetView<LanguageController> {
  const LanguageView({super.key});

  static const green = Color(0xFF00A651);
  static const darkGreen = Color(0xFF006B38);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFBFB),
        body: Stack(
          children: [
            const _SettingsBackground(),

            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 37),

                            // HEADER
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

                            const SizedBox(height: 48),

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

                            const SizedBox(height: 27),

                            _buildLanguageCard(),
                          ],
                        ),

                        Positioned(
                          left: 4,
                          right: 4,
                          bottom: 83,
                          child: _buildInfo(),
                        ),
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
        borderRadius: BorderRadius.circular(13),
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
              languageIcon: 'ខ្មែរ',
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
              languageIcon: 'EN',
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
    return const Row(
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
                'The app will restart to apply your new\n'
                'Language preference',
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
    );
  }
}

class _LanguageItem extends StatelessWidget {
  final String languageIcon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageItem({
    required this.languageIcon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: SizedBox(
        height: 70,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE5F5E8),
                ),
                child: Text(
                  languageIcon,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF00A651),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
