import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportController extends GetxController {
  final expandedIndex = (-1).obs;

  final List<Map<String, String>> faqs = [
    {
      'question': 'profile.how_do_i_change_my_password',
      'answer':
          'security.go_to_settings_password_and_security_change_password_enter_your_current_password_then_create_and_confirm_your_new_password',
    },
    {
      'question': 'profile.how_do_i_update_my_profile',
      'answer':
          'profile.go_to_settings_manage_profile_you_can_update_your_name_email_phone_number_age_height_and_weight_tap_save_changes_when_finished',
    },
    {
      'question': 'common.how_do_i_change_the_app_language',
      'answer':
          'settings.go_to_settings_language_choose_english_or_khmer_the_app_language_will_update_after_you_select_it',
    },
    {
      'question': 'profile.how_is_bmi_calculated',
      'answer':
          'profile.bmi_is_calculated_from_your_height_and_weight_enter_your_height_in_cm_and_weight_in_kg_and_the_app_will_calculate_your_bmi_automatically',
    },
  ];

  void toggleFaq(int index) {
    if (expandedIndex.value == index) {
      expandedIndex.value = -1;
    } else {
      expandedIndex.value = index;
    }
  }

  static const supportEmail = 'NhamHealth@gmail.com';
  static const supportPhone = '+85581814451';

  Future<void> emailSupport() => _openSupportLink(
    Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: const {'subject': 'NhamHealth support request'},
    ),
  );

  Future<void> callSupport() =>
      _openSupportLink(Uri(scheme: 'tel', path: supportPhone));

  Future<void> _openSupportLink(Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) return;
    } on Object {
      // The fallback below gives a clear, non-crashing result on devices that
      // do not have an email or phone handler installed.
    }
    Get.snackbar(
      'profile.unable_to_open'.tr,
      'profile.no_compatible_app_is_available_on_this_device'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void goBack() {
    Get.back();
  }
}
