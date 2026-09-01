import 'package:get/get.dart';

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

  void emailSupport() {
    // Add url_launcher later.
  }

  void callSupport() {
    // Add url_launcher later.
  }

  void goBack() {
    Get.back();
  }
}
