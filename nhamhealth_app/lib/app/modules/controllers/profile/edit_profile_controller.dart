import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../widgets/app_alert.dart';
import '../../repositories/profile/profile_repository.dart';
import 'profile_controller.dart';

class EditProfileController extends GetxController {
  EditProfileController({required this.profileController});

  final ProfileController profileController;
  final ImagePicker _imagePicker = ImagePicker();
  final isSaving = false.obs;

  // Top profile card
  final profileName = 'My Profile'.obs;
  final membership = 'WellBite Member'.obs;
  final profileEmail = ''.obs;
  final profileImagePath = ''.obs;

  // Personal information
  final fullName = ''.obs;
  final email = ''.obs;
  final phone = ''.obs;

  final Rxn<DateTime> dateOfBirth = Rxn<DateTime>();
  final gender = ''.obs;

  // Health information
  final age = 0.obs;
  final height = 0.0.obs;
  final weight = 0.0.obs;

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
    if (date == null) return 'Not set';

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
    fullName.value = profileController.dashboard.value?.fullName ?? '';
    email.value = profileController.email.value;
    membership.value = profileController.membership.value;
    profileImagePath.value = profileController.profileImagePath.value;
    age.value = profileController.age.value;
    height.value = profileController.height.value.toDouble();
    weight.value = profileController.weight.value.toDouble();
    final dashboard = profileController.dashboard.value;
    if (dashboard != null) {
      phone.value = dashboard.phone ?? '';
      dateOfBirth.value = dashboard.dateOfBirth;
      gender.value =
          dashboard.gender?.trim().isNotEmpty == true
              ? dashboard.gender!.trim()
              : '';
    }
  }

  void goBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
      return;
    }
    profileController.openProfile();
  }

  Future<void> saveProfile() async {
    if (isSaving.value) return;
    if (fullName.value.trim().length < 2) {
      await AppAlert.error(
        title: 'Add your name',
        message: 'Enter your full name before saving your profile.',
      );
      return;
    }
    isSaving.value = true;
    try {
      await profileController.saveProfile(
        fullName: fullName.value,
        email: email.value,
        phone: phone.value,
        dateOfBirth: dateOfBirth.value,
        gender: gender.value.isEmpty ? null : gender.value,
        heightCm: height.value > 0 ? height.value : null,
        weightKg: weight.value > 0 ? weight.value : null,
        imagePath: profileImagePath.value,
      );
      await AppAlert.dismiss();
      if (Get.isSnackbarOpen) {
        await Get.closeCurrentSnackbar();
      }
      Get.back<void>();
      await AppAlert.success(
        title: 'Profile saved',
        message:
            'Your photo and profile details are now available on your dashboard.',
      );
    } on ProfileException catch (error) {
      await AppAlert.error(
        title: 'Profile couldn\'t be saved',
        message: error.message,
      );
    } on TimeoutException {
      await AppAlert.error(
        title: 'Upload took too long',
        message: 'Check your connection and try saving your profile again.',
      );
    } on Object {
      await AppAlert.error(
        title: 'Profile couldn\'t be saved',
        message: 'Something went wrong while saving. Please try again.',
      );
    } finally {
      isSaving.value = false;
    }
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
      await AppAlert.error(
        title: 'Couldn\'t open your photos',
        message: 'Check photo permissions, then choose the image again.',
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
          final current = dateOfBirth.value ?? DateTime.now();
          final year = DateTime.now().year - number;
          dateOfBirth.value = DateTime(
            year,
            current.month,
            current.day
                .clamp(1, DateTime(year, current.month + 1, 0).day)
                .toInt(),
          );
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
      initialDate:
          dateOfBirth.value ?? DateTime(DateTime.now().year - 18, 1, 1),
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
        trailing:
            gender.value == value
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
    unawaited(AppAlert.error(title: 'Check this value', message: message));
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
