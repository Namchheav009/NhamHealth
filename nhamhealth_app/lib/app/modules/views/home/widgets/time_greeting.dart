import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/home/home_controller.dart';

class TimeGreeting extends GetView<HomeController> {
  const TimeGreeting({super.key});

  String get _wellnessQuote {
    const key = 'home.wellness_quote';
    final translated = key.tr;
    if (translated != key) return translated;
    return Get.locale?.languageCode == 'km'
        ? 'ចិត្តស្ងប់ស្ងាត់ បង្កើតថ្ងៃស្អែកដ៏ភ្លឺស្វាង។'
        : 'A calmer mind builds a brighter tomorrow.';
  }

  ({String title, String subtitle}) _copyFor(DateTime time) {
    if (time.hour < 5) {
      return (title: 'home.good_night', subtitle: 'home.rest_for_tomorrow');
    }
    if (time.hour < 12) {
      return (
        title: 'home.good_morning',
        subtitle: 'home.healthy_choices_today',
      );
    }
    if (time.hour < 17) {
      return (title: 'home.good_afternoon', subtitle: 'home.keep_momentum');
    }
    if (time.hour < 21) {
      return (title: 'home.good_evening', subtitle: 'home.finish_healthy');
    }
    return (title: 'home.good_night', subtitle: 'home.slow_down_rest');
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copyFor(DateTime.now());
    return Obx(() {
      final displayName =
          controller.authenticatedUser.value?.displayName.trim();
      final lastName = displayName == null || displayName.isEmpty
          ? null
          : displayName.split(RegExp(r'\s+')).last;
      final localizedGreeting = copy.title.tr;

      return Semantics(
        header: true,
        label: '$localizedGreeting ${lastName ?? ''} ${copy.subtitle.tr}',
        child: Container(
          height: 210,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: context.appIsDark
                  ? const [Color(0xFF16221D), Color(0xFF20382D)]
                  : const [
                      Color(0xFFFFF2F3),
                      Color(0xFFFFF7F0),
                      Color(0xFFEAF8EC),
                    ],
            ),
            border: Border.all(
              color: context.appIsDark
                  ? context.appBorder
                  : Colors.white.withValues(alpha: 0.74),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: context.appIsDark ? 0.34 : 0.72,
                  child: Image.asset(
                    'assets/images/homepage/wellness_landscape_hero.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 14,
                right: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedGreeting.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lastName == null ? localizedGreeting : '$lastName!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 32,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            copy.subtitle.tr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.appMutedText,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.eco_rounded,
                          color: AppColors.primaryGreen,
                          size: 19,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                bottom: 8,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 210),
                  padding: const EdgeInsets.fromLTRB(11, 8, 11, 7),
                  decoration: BoxDecoration(
                    color: context.appElevatedSurface.withValues(alpha: 0.76),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.56),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        color: AppColors.primaryGreen.withValues(alpha: 0.72),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _wellnessQuote,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 11.5,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '— NhamHealth',
                              style: TextStyle(
                                color: context.appMutedText,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
