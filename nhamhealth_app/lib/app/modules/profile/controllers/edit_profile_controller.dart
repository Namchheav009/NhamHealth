import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'profile_controller.dart';

class EditProfileController extends GetxController {
  EditProfileController({required this.profileController});

  final ProfileController profileController;
  final ImagePicker _imagePicker = ImagePicker();

  // Top profile card
  final profileName = 'Sarah Smith'.obs;
  final membership = 'WellBite Member'.obs;
  final profileEmail = 'sarasmith009@gmail.com'.obs;
  final profileImagePath = ''.obs;

  // Personal information
  final fullName = 'Chhay Kimlang'.obs;
  final email = 'kimlang09@gmail.com'.obs;
  final phone = '+855 818 144 51'.obs;

  final dateOfBirth = DateTime(2006, 2, 12).obs;
  final gender = 'Female'.obs;

  // Health information
  final age = 21.obs;
  final height = 158.0.obs;
  final weight = 62.0.obs;

  String get formattedDateOfBirth {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final date = dateOfBirth.value;

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  int _calculateAge(DateTime birth) {
    final today = DateTime.now();
    var currentAge = today.year - birth.year;

    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      currentAge--;
    }

    return currentAge;
  }

  double get bmi {
    final heightMeter = height.value / 100;

    if (heightMeter <= 0) {
      return 0;
    }

    return weight.value / (heightMeter * heightMeter);
  }

  String get bmiStatus {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  @override
  void onInit() {
    super.onInit();
    profileName.value = profileController.name.value;
    profileEmail.value = profileController.email.value;
    fullName.value = profileController.name.value;
    email.value = profileController.email.value;
    membership.value = profileController.membership.value;
    profileImagePath.value = profileController.profileImagePath.value;
    age.value = profileController.age.value;
    height.value = profileController.height.value.toDouble();
    weight.value = profileController.weight.value.toDouble();
  }

  void goBack() {
    Get.until((route) => route.isFirst);
  }

  void saveProfile() {
    // Later connect this with Spring Boot API.
    //
    // Example:
    // await profileRepository.updateProfile(...);

    profileController.name.value = fullName.value;
    profileController.email.value = email.value;
    profileController.age.value = age.value;
    profileController.height.value = height.value.round();
    profileController.weight.value = weight.value.round();
    profileController.profileImagePath.value = profileImagePath.value;

    Get.back();

    Get.snackbar(
      'Profile Updated',
      'Your profile information has been saved.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF00A651),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> editFullName() async {
    await _showTextEditor(
      title: 'Full Name',
      initialValue: fullName.value,
      onSaved: (value) {
        fullName.value = value;
      },
    );
  }

  Future<void> pickProfileImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image != null) profileImagePath.value = image.path;
    } catch (_) {
      Get.snackbar(
        'Image selection failed',
        'Could not open the gallery. Please check photo permissions.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> editEmail() async {
    await _showTextEditor(
      title: 'Email',
      initialValue: email.value,
      keyboardType: TextInputType.emailAddress,
      onSaved: (value) {
        email.value = value;
      },
    );
  }

  Future<void> editPhone() async {
    await _showTextEditor(
      title: 'Phone Number',
      initialValue: phone.value,
      keyboardType: TextInputType.phone,
      onSaved: (value) {
        phone.value = value;
      },
    );
  }

  Future<void> editHeight() async {
    await _showTextEditor(
      title: 'Height (cm)',
      initialValue: height.value.toStringAsFixed(0),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onSaved: (value) {
        final number = double.tryParse(value);

        if (number != null && number >= 50 && number <= 300) {
          height.value = number;
        } else {
          _showInputError('Enter a height between 50 and 300 cm.');
        }
      },
    );
  }

  Future<void> editAge() async {
    await _showTextEditor(
      title: 'Age (years)',
      initialValue: age.value.toString(),
      keyboardType: TextInputType.number,
      onSaved: (value) {
        final number = int.tryParse(value);

        if (number != null && number > 0 && number <= 120) {
          age.value = number;
        } else {
          _showInputError('Enter an age between 1 and 120 years.');
        }
      },
    );
  }

  Future<void> editWeight() async {
    await _showTextEditor(
      title: 'Weight (kg)',
      initialValue: weight.value.toStringAsFixed(0),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onSaved: (value) {
        final number = double.tryParse(value);

        if (number != null && number >= 10 && number <= 500) {
          weight.value = number;
        } else {
          _showInputError('Enter a weight between 10 and 500 kg.');
        }
      },
    );
  }

  Future<void> selectDateOfBirth(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: dateOfBirth.value,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      dateOfBirth.value = selectedDate;
      age.value = _calculateAge(selectedDate);
    }
  }

  void selectGender() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Gender',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 15),

              _genderOption('Male'),
              _genderOption('Female'),
              _genderOption('Prefer not to say'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderOption(String value) {
    return Obx(
      () => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(value),
        trailing: gender.value == value
            ? const Icon(Icons.check_circle, color: Color(0xFF00A651))
            : null,
        onTap: () {
          gender.value = value;
          Get.back();
        },
      ),
    );
  }

  void _showInputError(String message) {
    Get.snackbar(
      'Invalid value',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _showTextEditor({
    required String title,
    required String initialValue,
    required ValueChanged<String> onSaved,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final value = await Get.dialog<String>(
      _TextEditorDialog(
        title: title,
        initialValue: initialValue,
        keyboardType: keyboardType,
      ),
    );

    if (value != null && value.isNotEmpty) onSaved(value);
  }
}

class _TextEditorDialog extends StatefulWidget {
  const _TextEditorDialog({
    required this.title,
    required this.initialValue,
    required this.keyboardType,
  });

  final String title;
  final String initialValue;
  final TextInputType keyboardType;

  @override
  State<_TextEditorDialog> createState() => _TextEditorDialogState();
}

class _TextEditorDialogState extends State<_TextEditorDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: _textController,
        keyboardType: widget.keyboardType,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.title,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<String>(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: _save,
          child: const Text(
            'Save',
            style: TextStyle(
              color: Color(0xFF00A651),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _save() {
    final value = _textController.text.trim();
    if (value.isNotEmpty) Get.back(result: value);
  }
}
