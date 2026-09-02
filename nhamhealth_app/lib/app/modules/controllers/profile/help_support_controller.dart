import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportController extends GetxController {
  final expandedIndex = (-1).obs;

  final List<Map<String, String>> faqs = [
    {
      'question': 'How do I Change my password?',
      'answer':
          'Go to Settings > Password & Security > Change Password. '
          'Enter your current password, then create and confirm your new password.',
    },
    {
      'question': 'How do I update my profile?',
      'answer':
          'Go to Settings > Manage Profile. You can update your name, email, '
          'phone number, age, height, and weight. Tap Save Changes when finished.',
    },
    {
      'question': 'How do I change the app language?',
      'answer':
          'Go to Settings > Language. Choose English or Khmer. '
          'The app language will update after you select it.',
    },
    {
      'question': 'How is BMI calculated?',
      'answer':
          'BMI is calculated from your height and weight. Enter your height '
          'in cm and weight in kg, and the app will calculate your BMI automatically.',
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
      'Unable to open'.tr,
      'No compatible app is available on this device.'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void goBack() {
    Get.back();
  }
}
