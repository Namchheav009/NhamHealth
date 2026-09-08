import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_alert.dart';
import '../../repositories/profile/profile_repository.dart';
import 'profile_controller.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

class EditProfileController extends GetxController {
  EditProfileController({required this.profileController});

  final ProfileController profileController;
  final ImagePicker _imagePicker = ImagePicker();
  final isSaving = false.obs;
  final isContactVerificationBusy = false.obs;
  final verificationDetail = ''.obs;
  final verifyingContactType = ''.obs;

  bool get isBusy => isSaving.value || isContactVerificationBusy.value;

  // Top profile card
  final profileName = 'My Profile'.obs;
  final membership = 'WellBite Member'.obs;
  final profileEmail = ''.obs;
  final profileImagePath = ''.obs;

  // Personal information
  final fullName = ''.obs;
  final email = ''.obs;
  final isEmailVerified = false.obs;
  final phone = ''.obs;
  final isPhoneVerified = false.obs;

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
    isEmailVerified.value = email.value.trim().isNotEmpty;
    membership.value = profileController.membership.value;
    profileImagePath.value = profileController.profileImagePath.value;
    age.value = profileController.age.value;
    height.value = profileController.height.value.toDouble();
    weight.value = profileController.weight.value.toDouble();
    final dashboard = profileController.dashboard.value;
    if (dashboard != null) {
      phone.value = dashboard.phone ?? '';
      isPhoneVerified.value = dashboard.phoneVerified;
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
    if (isBusy) return;
    if (fullName.value.trim().length < 2) {
      await AppAlert.actionError(
        title: 'profile.add_your_name',
        message: 'profile.enter_your_full_name_before_saving_your_profile',
      );
      return;
    }
    final emailAddress = email.value.trim();
    final phoneNumber = phone.value.trim();
    if (emailAddress.isEmpty && phoneNumber.isEmpty) {
      await AppAlert.actionError(
        title: 'profile.contact_required',
        message: 'profile.contact_required_help',
      );
      return;
    }
    if (emailAddress.isNotEmpty && !GetUtils.isEmail(emailAddress)) {
      await AppAlert.actionError(
        title: 'common.check_your_email',
        message: 'auth.invalid_email',
      );
      return;
    }
    if (phoneNumber.isNotEmpty && !_isValidPhone(phoneNumber)) {
      await AppAlert.actionError(
        title: 'profile.check_phone',
        message: 'profile.invalid_phone',
      );
      return;
    }
    if (phoneNumber.isNotEmpty && !isPhoneVerified.value) {
      verificationDetail.value = 'profile.verify_phone_before_save';
      await AppAlert.actionError(
        title: 'profile.verification_required',
        message: 'profile.phone_not_verified_help',
      );
      return;
    }
    if (emailAddress.isEmpty && !isPhoneVerified.value) {
      await AppAlert.actionError(
        title: 'profile.verify_phone',
        message: 'profile.verify_phone_before_remove_email',
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
      await AppAlert.actionSuccess(
        title: 'profile.profile_saved',
        message:
            'profile.your_photo_and_profile_details_are_now_available_on_your_dashboard',
      );
    } on ProfileException catch (error) {
      await AppAlert.actionError(
        title: 'profile.save_failed',
        message: error.message,
      );
    } on TimeoutException {
      await AppAlert.actionError(
        title: 'profile.upload_took_too_long',
        message:
            'profile.check_your_connection_and_try_saving_your_profile_again',
      );
    } on Object {
      await AppAlert.actionError(
        title: 'profile.save_failed',
        message: 'profile.something_went_wrong_while_saving_please_try_again',
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> editFullName() async {
    await _showTextEditor(
      title: 'profile.full_name',
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
        title: 'profile.photo_pick_failed',
        message: 'profile.photo_pick_failed_help',
      );
    }
  }

  Future<void> editEmail() async {
    if (isContactVerificationBusy.value) return;
    final previousEmail = email.value.trim().toLowerCase();
    String? updatedEmail;
    await _showTextEditor(
      title: 'profile.email',
      initialValue: email.value,
      keyboardType: TextInputType.emailAddress,
      allowEmpty: true,
      onSaved: (value) {
        updatedEmail = value.trim().toLowerCase();
      },
    );
    if (updatedEmail == null || updatedEmail == previousEmail) return;
    if (updatedEmail!.isEmpty) {
      email.value = '';
      isEmailVerified.value = false;
      return;
    }
    if (!GetUtils.isEmail(updatedEmail!)) {
      await AppAlert.error(
        title: 'common.check_your_email',
        message: 'auth.invalid_email',
      );
      return;
    }
    await _verifyEmailChange(updatedEmail!);
  }

  Future<void> editPhone() async {
    if (isContactVerificationBusy.value) return;
    final previousPhone = phone.value;
    final wasVerified = isPhoneVerified.value;
    await _showTextEditor(
      title: 'profile.phone_number',
      initialValue: phone.value,
      keyboardType: TextInputType.phone,
      allowEmpty: true,
      onSaved: (value) {
        final trimmed = value.trim();
        phone.value = trimmed;
        if (_phoneComparisonKey(previousPhone) !=
            _phoneComparisonKey(trimmed)) {
          isPhoneVerified.value = false;
        }
      },
    );
    if (phone.value.isNotEmpty &&
        _phoneComparisonKey(previousPhone) !=
            _phoneComparisonKey(phone.value)) {
      await verifyPhone();
      if (!isPhoneVerified.value) {
        phone.value = previousPhone;
        isPhoneVerified.value = wasVerified;
        verificationDetail.value =
            'Phone change was not saved. Enter the new number again to request another code.';
      }
    }
  }

  Future<void> _verifyEmailChange(String emailAddress) async {
    isEmailVerified.value = false;
    verifyingContactType.value = 'email';
    verificationDetail.value = 'profile.sending_email_code'.trParams({
      'email': emailAddress,
    });
    isContactVerificationBusy.value = true;
    try {
      final authService = Get.find<AuthService>();
      await authService.sendEmailVerificationCode(emailAddress);
      isContactVerificationBusy.value = false;
      verificationDetail.value = 'profile.email_code_detail'.trParams({
        'email': emailAddress,
      });
      await _showContactOtpDialog(
        destination: emailAddress,
        title: 'profile.verify_email',
        instruction: 'profile.email_code_sent',
        icon: Icons.mark_email_read_outlined,
        verify:
            (code) => authService.verifyEmailVerificationCode(
              email: emailAddress,
              code: code,
            ),
        responseField: 'email',
        onVerified: (verifiedEmail) {
          email.value = verifiedEmail;
          isEmailVerified.value = true;
          profileController.email.value = verifiedEmail;
          verificationDetail.value = 'profile.email_verified_save';
        },
      );
      if (email.value.trim().toLowerCase() != emailAddress) {
        verificationDetail.value =
            'Email change was not saved. Edit the email again to request another code.';
      }
    } on AuthException catch (error) {
      await AppAlert.error(
        title: 'profile.verification_error',
        message: error.message,
      );
    } on Object {
      await AppAlert.error(
        title: 'profile.verification_error',
        message: 'profile.could_not_send_verification_code_please_try_again',
      );
    } finally {
      isContactVerificationBusy.value = false;
      verifyingContactType.value = '';
      if (email.value.trim().toLowerCase() != emailAddress) {
        isEmailVerified.value = email.value.trim().isNotEmpty;
      }
    }
  }

  Future<void> _showContactOtpDialog({
    required String destination,
    required String title,
    required String instruction,
    required IconData icon,
    required Future<Map<String, dynamic>> Function(String code) verify,
    required String responseField,
    required ValueChanged<String> onVerified,
  }) async {
    final codeController = TextEditingController();
    final codeFocusNode = FocusNode();
    final code = ''.obs;
    final isSubmitting = false.obs;
    final errorText = ''.obs;
    try {
      await Get.dialog<void>(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE9F8EC),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF00A651), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.trOrSelf,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${instruction.trOrSelf}\n($destination)',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Obx(
                () => _PhoneOtpCodeField(
                  controller: codeController,
                  focusNode: codeFocusNode,
                  code: code.value,
                  hasError: errorText.value.isNotEmpty,
                  onChanged: (value) {
                    code.value = value;
                    errorText.value = '';
                  },
                ),
              ),
              Obx(
                () =>
                    errorText.value.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            errorText.value,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: Text('common.cancel'.tr)),
            Obx(
              () =>
                  isSubmitting.value
                      ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : TextButton(
                        onPressed: () async {
                          final enteredCode = codeController.text.trim();
                          if (!RegExp(r'^\d{6}$').hasMatch(enteredCode)) {
                            errorText.value =
                                'profile.please_enter_a_valid_6_digit_code'.tr;
                            codeFocusNode.requestFocus();
                            return;
                          }
                          try {
                            isSubmitting.value = true;
                            final response = await verify(enteredCode);
                            final verified = response[responseField];
                            onVerified(
                              verified is String && verified.trim().isNotEmpty
                                  ? verified.trim()
                                  : destination,
                            );
                            Get.back<void>();
                            unawaited(profileController.loadProfile());
                            await AppAlert.success(
                              title: 'profile.verified'.tr,
                              message: 'profile.verified_successfully'.trParams(
                                {'field': title.trOrSelf},
                              ),
                            );
                          } on AuthException catch (error) {
                            errorText.value = error.message;
                          } on Object {
                            errorText.value =
                                'profile.the_verification_code_is_incorrect'.tr;
                          } finally {
                            isSubmitting.value = false;
                          }
                        },
                        child: Text(
                          'profile.verify'.tr,
                          style: const TextStyle(
                            color: Color(0xFF00A651),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
            ),
          ],
        ),
      );
    } finally {
      codeFocusNode.dispose();
      codeController.dispose();
    }
  }

  Future<void> verifyPhone() async {
    if (isContactVerificationBusy.value) return;
    final phoneNumber = phone.value.trim();
    if (phoneNumber.isEmpty) {
      await AppAlert.error(
        title: 'profile.phone_number_required'.tr,
        message: 'profile.please_enter_your_phone_number_first'.tr,
      );
      return;
    }

    verifyingContactType.value = 'phone';
    verificationDetail.value = 'Sending a verification code to $phoneNumber…';
    isContactVerificationBusy.value = true;
    try {
      final authService = Get.find<AuthService>();
      await authService.sendPhoneVerificationCode(phoneNumber);
      isContactVerificationBusy.value = false;
      verificationDetail.value =
          'Enter the 6-digit code sent to $phoneNumber. The new phone number will not be saved until it is verified.';
      await _showPhoneOtpDialog(phoneNumber);
      if (!isPhoneVerified.value) {
        verificationDetail.value =
            'Phone number is still unverified. Request a code and verify it before saving.';
      }
    } on AuthException catch (e) {
      await AppAlert.error(
        title: 'profile.verification_error'.tr,
        message: e.message,
      );
    } catch (_) {
      await AppAlert.error(
        title: 'profile.verification_error'.tr,
        message: 'profile.could_not_send_verification_code_please_try_again'.tr,
      );
    } finally {
      isContactVerificationBusy.value = false;
      verifyingContactType.value = '';
    }
  }

  Future<void> _showPhoneOtpDialog(String phoneNumber) async {
    final authService = Get.find<AuthService>();
    final codeController = TextEditingController();
    final codeFocusNode = FocusNode();
    final code = ''.obs;
    final isSubmitting = false.obs;
    final errorText = ''.obs;

    try {
      await Get.dialog<void>(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE9F8EC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phonelink_ring_rounded,
                  color: Color(0xFF00A651),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'profile.verify_phone_number'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${'profile.phone_code_prompt'.tr}\n($phoneNumber)',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Obx(
                () => _PhoneOtpCodeField(
                  controller: codeController,
                  focusNode: codeFocusNode,
                  code: code.value,
                  hasError: errorText.value.isNotEmpty,
                  onChanged: (value) {
                    code.value = value;
                    if (errorText.value.isNotEmpty) errorText.value = '';
                  },
                ),
              ),
              Obx(
                () =>
                    errorText.value.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            errorText.value.trOrSelf,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'common.cancel'.tr,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            Obx(
              () =>
                  isSubmitting.value
                      ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : TextButton(
                        onPressed: () async {
                          final enteredCode = codeController.text.trim();
                          if (enteredCode.length != 6) {
                            errorText.value =
                                'profile.please_enter_a_valid_6_digit_code'.tr;
                            codeFocusNode.requestFocus();
                            return;
                          }
                          try {
                            isSubmitting.value = true;
                            final response = await authService
                                .verifyPhoneVerificationCode(
                                  phone: phoneNumber,
                                  code: enteredCode,
                                );
                            isSubmitting.value = false;
                            final verifiedPhone = response['phone'];
                            if (verifiedPhone is String &&
                                verifiedPhone.trim().isNotEmpty) {
                              phone.value = verifiedPhone.trim();
                            }
                            isPhoneVerified.value = true;
                            verificationDetail.value =
                                'profile.phone_verified_save';
                            Get.back();
                            unawaited(profileController.loadProfile());
                            await AppAlert.success(
                              title: 'profile.verified'.tr,
                              message: 'profile.phone_verified_successfully'.tr,
                            );
                          } on AuthException catch (e) {
                            isSubmitting.value = false;
                            errorText.value = e.message;
                          } catch (_) {
                            isSubmitting.value = false;
                            errorText.value =
                                'profile.the_verification_code_is_incorrect'.tr;
                          }
                        },
                        child: Text(
                          'profile.verify'.tr,
                          style: const TextStyle(
                            color: Color(0xFF00A651),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
            ),
          ],
        ),
      );
    } finally {
      codeFocusNode.dispose();
      codeController.dispose();
    }
  }

  Future<void> editHeight() async {
    await _showTextEditor(
      title: 'profile.height_cm',
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
      title: 'profile.age_years',
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
      title: 'profile.weight_kg',
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
      Builder(
        builder:
            (context) => Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              decoration: BoxDecoration(
                color: context.appElevatedSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile.select_gender'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 15),

                    _genderOption(context, 'Male'),
                    _genderOption(context, 'Female'),
                    _genderOption(context, 'Prefer not to say'),
                  ],
                ),
              ),
            ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _genderOption(BuildContext context, String value) {
    return Obx(
      () => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(value.trOrSelf, style: TextStyle(color: context.appText)),
        trailing:
            gender.value == value
                ? const Icon(Icons.check_circle, color: AppColors.primaryGreen)
                : null,
        onTap: () {
          gender.value = value;
          Get.back();
        },
      ),
    );
  }

  void _showInputError(String message) {
    unawaited(
      AppAlert.error(title: 'profile.check_this_value', message: message),
    );
  }

  Future<void> _showTextEditor({
    required String title,
    required String initialValue,
    required ValueChanged<String> onSaved,
    TextInputType keyboardType = TextInputType.text,
    bool allowEmpty = false,
  }) async {
    final value = await Get.dialog<String>(
      _TextEditorDialog(
        title: title,
        initialValue: initialValue,
        keyboardType: keyboardType,
        allowEmpty: allowEmpty,
      ),
    );

    if (value != null && (allowEmpty || value.isNotEmpty)) onSaved(value);
  }

  bool _isValidPhone(String value) => RegExp(
    r'^\+?[0-9]{8,15}$',
  ).hasMatch(value.replaceAll(RegExp(r'[\s()-]'), ''));

  String _phoneComparisonKey(String value) {
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      digits = '855${digits.substring(1)}';
    } else if (!digits.startsWith('855') &&
        digits.length >= 8 &&
        digits.length <= 9) {
      digits = '855$digits';
    }
    return digits;
  }
}

class _PhoneOtpCodeField extends StatelessWidget {
  const _PhoneOtpCodeField({
    required this.controller,
    required this.focusNode,
    required this.code,
    required this.hasError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String code;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const codeLength = 6;
    const gap = 6.0;
    return Semantics(
      label: 'common.six_digit_verification_code'.tr,
      textField: true,
      child: SizedBox(
        height: 52,
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(codeLength, (index) {
                final digit = index < code.length ? code[index] : '';
                final isActive =
                    index == code.length && code.length < codeLength;
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == codeLength - 1 ? 0 : gap,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 36,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FBF9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            hasError
                                ? Colors.red
                                : isActive
                                ? const Color(0xFF00A651)
                                : const Color(0xFFD7E3DB),
                        width: hasError || isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      digit,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: .01,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  enableSuggestions: false,
                  autocorrect: false,
                  showCursor: false,
                  maxLength: codeLength,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(codeLength),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextEditorDialog extends StatefulWidget {
  const _TextEditorDialog({
    required this.title,
    required this.initialValue,
    required this.keyboardType,
    required this.allowEmpty,
  });

  final String title;
  final String initialValue;
  final TextInputType keyboardType;
  final bool allowEmpty;

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
          child: Text('common.cancel'.tr, style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: _save,
          child: Text(
            'common.save'.tr,
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
    if (widget.allowEmpty || value.isNotEmpty) Get.back(result: value);
  }
}
