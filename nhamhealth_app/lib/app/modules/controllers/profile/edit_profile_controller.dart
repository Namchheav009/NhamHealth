import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../../core/services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_input_dialog.dart';
import '../../repositories/profile/profile_repository.dart';
import 'profile_controller.dart';

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
      subtitle: 'profile.enter_your_full_name_before_saving_your_profile',
      initialValue: fullName.value,
      icon: Icons.person_outline_rounded,
      prefixIcon: Icons.person_outline_rounded,
      maxLength: 70,
      validator: (val) {
        if (val.trim().length < 2) {
          return 'profile.enter_your_full_name_before_saving_your_profile';
        }
        return null;
      },
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
      subtitle: 'Enter your email address for account and security.',
      initialValue: email.value,
      icon: Icons.email_outlined,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      allowEmpty: true,
      validator: (val) {
        final trimmed = val.trim();
        if (trimmed.isNotEmpty && !GetUtils.isEmail(trimmed)) {
          return 'auth.invalid_email';
        }
        return null;
      },
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
      subtitle: 'Enter your phone number for SMS verification.',
      initialValue: phone.value,
      icon: Icons.phone_outlined,
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      allowEmpty: true,
      validator: (val) {
        final trimmed = val.trim();
        if (trimmed.isNotEmpty && !_isValidPhone(trimmed)) {
          return 'profile.invalid_phone';
        }
        return null;
      },
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

    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;

    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'profile.verify_phone_number'.tr,
        barrierColor: Colors.black.withValues(alpha: 0.48),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (dialogCtx, animation, secondaryAnimation) {
          return Obx(
            () => PopScope(
              canPop: !isSubmitting.value,
              child: Material(
                type: MaterialType.transparency,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: const SizedBox.expand(),
                    ),
                    SafeArea(
                      minimum: const EdgeInsets.all(22),
                      child: Center(
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 424),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                26,
                                28,
                                26,
                                26,
                              ),
                              decoration: BoxDecoration(
                                color: dialogCtx.appElevatedSurface,
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    blurRadius: 32,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: dialogCtx.appElevatedSurface,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.16,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.phonelink_ring_rounded,
                                        color: AppColors.primaryGreen,
                                        size: 34,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'profile.verify_phone_number'.tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: dialogCtx.appText,
                                      fontSize: 20,
                                      height: 1.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${'profile.phone_code_prompt'.tr}\n($phoneNumber)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: dialogCtx.appMutedText,
                                      fontSize: 14,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  _PhoneOtpCodeField(
                                    controller: codeController,
                                    focusNode: codeFocusNode,
                                    code: code.value,
                                    hasError: errorText.value.isNotEmpty,
                                    onChanged: (value) {
                                      code.value = value;
                                      if (errorText.value.isNotEmpty)
                                        errorText.value = '';
                                    },
                                  ),
                                  if (errorText.value.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(top: 12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: dialogCtx.appDangerSurface,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        errorText.value.trOrSelf,
                                        style: TextStyle(
                                          color: dialogCtx.appOnDangerSurface,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed:
                                              isSubmitting.value
                                                  ? null
                                                  : () =>
                                                      Navigator.of(
                                                        dialogCtx,
                                                      ).pop(),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 50),
                                            side: BorderSide(
                                              color: dialogCtx.appBorder,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(21),
                                            ),
                                          ),
                                          child: Text(
                                            'common.cancel'.tr,
                                            style: TextStyle(
                                              color: dialogCtx.appText,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed:
                                              isSubmitting.value
                                                  ? null
                                                  : () async {
                                                    final enteredCode =
                                                        codeController.text
                                                            .trim();
                                                    if (enteredCode.length !=
                                                        6) {
                                                      errorText.value =
                                                          'profile.please_enter_a_valid_6_digit_code'
                                                              .tr;
                                                      codeFocusNode
                                                          .requestFocus();
                                                      return;
                                                    }
                                                    try {
                                                      isSubmitting.value = true;
                                                      final response =
                                                          await authService
                                                              .verifyPhoneVerificationCode(
                                                                phone:
                                                                    phoneNumber,
                                                                code:
                                                                    enteredCode,
                                                              );
                                                      isSubmitting.value =
                                                          false;
                                                      final verifiedPhone =
                                                          response['phone'];
                                                      if (verifiedPhone
                                                              is String &&
                                                          verifiedPhone
                                                              .trim()
                                                              .isNotEmpty) {
                                                        phone.value =
                                                            verifiedPhone
                                                                .trim();
                                                      }
                                                      isPhoneVerified.value =
                                                          true;
                                                      verificationDetail.value =
                                                          'profile.phone_verified_save';
                                                      if (dialogCtx.mounted) {
                                                        Navigator.of(
                                                          dialogCtx,
                                                        ).pop();
                                                      }
                                                      unawaited(
                                                        profileController
                                                            .loadProfile(),
                                                      );
                                                      await AppAlert.success(
                                                        title:
                                                            'profile.verified'
                                                                .tr,
                                                        message:
                                                            'profile.phone_verified_successfully'
                                                                .tr,
                                                      );
                                                    } on AuthException catch (
                                                      e
                                                    ) {
                                                      isSubmitting.value =
                                                          false;
                                                      errorText.value =
                                                          e.message;
                                                    } catch (_) {
                                                      isSubmitting.value =
                                                          false;
                                                      errorText.value =
                                                          'profile.the_verification_code_is_incorrect'
                                                              .tr;
                                                    }
                                                  },
                                          style: FilledButton.styleFrom(
                                            minimumSize: const Size(0, 50),
                                            backgroundColor:
                                                AppColors.primaryGreen,
                                            foregroundColor: Colors.white,
                                            elevation: 2,
                                            shadowColor: AppColors.primaryGreen
                                                .withValues(alpha: 0.35),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(21),
                                            ),
                                          ),
                                          child:
                                              isSubmitting.value
                                                  ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                  : Text(
                                                    'profile.verify'.tr,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      );
    } finally {
      codeFocusNode.dispose();
      codeController.dispose();
    }
  }

  Future<void> editHeight() async {
    await _showTextEditor(
      title: 'profile.height',
      labelText: 'profile.height_cm',
      subtitle: 'Enter your height in centimeters.',
      initialValue: height.value > 0 ? height.value.toStringAsFixed(0) : '',
      icon: Icons.straighten_rounded,
      prefixIcon: Icons.straighten_rounded,
      exampleText: 'Example: 170 cm',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (val) {
        final number = double.tryParse(val);
        if (number == null || number < 50 || number > 300) {
          return 'Enter a height between 50 and 300 cm.';
        }
        return null;
      },
      onSaved: (value) {
        final number = double.tryParse(value);
        if (number != null && number >= 50 && number <= 300) {
          height.value = number;
        }
      },
    );
  }

  Future<void> editAge() async {
    await _showTextEditor(
      title: 'profile.age',
      labelText: 'profile.age_years',
      subtitle: 'Enter your age in years.',
      initialValue: age.value > 0 ? age.value.toString() : '',
      icon: Icons.cake_outlined,
      prefixIcon: Icons.cake_outlined,
      exampleText: 'Example: 25 years',
      keyboardType: TextInputType.number,
      validator: (val) {
        final number = int.tryParse(val);
        if (number == null || number <= 0 || number > 120) {
          return 'Enter an age between 1 and 120 years.';
        }
        return null;
      },
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
        }
      },
    );
  }

  Future<void> editWeight() async {
    await _showTextEditor(
      title: 'profile.weight',
      labelText: 'profile.weight_kg',
      subtitle: 'Enter your weight in kilograms.',
      initialValue: weight.value > 0 ? weight.value.toStringAsFixed(0) : '',
      icon: Icons.scale_outlined,
      prefixIcon: Icons.scale_outlined,
      exampleText: 'Example: 65 kg',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (val) {
        final number = double.tryParse(val);
        if (number == null || number < 10 || number > 500) {
          return 'Enter a weight between 10 and 500 kg.';
        }
        return null;
      },
      onSaved: (value) {
        final number = double.tryParse(value);
        if (number != null && number >= 10 && number <= 500) {
          weight.value = number;
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
    String? subtitle,
    String? labelText,
    String? helperText,
    String? exampleText,
    IconData icon = Icons.edit_note_rounded,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool allowEmpty = false,
    String? Function(String value)? validator,
  }) async {
    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;
    final value = await AppInputDialog.show(
      context: context,
      title: title,
      subtitle: subtitle,
      initialValue: initialValue,
      labelText: labelText,
      helperText: helperText,
      exampleText: exampleText,
      icon: icon,
      prefixIcon: prefixIcon,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      allowEmpty: allowEmpty,
      validator: validator,
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
