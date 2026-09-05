import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../controllers/profile/edit_profile_controller.dart';
import 'widgets/edit_info_row.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  static const green = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: AppSpacing.pagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(),

                    const SizedBox(height: 12),

                    // _buildProfileHeader(context),
                    const SizedBox(height: 12),

                    _buildPersonalInformation(context),

                    const SizedBox(height: 14),

                    _buildHealthInformation(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------
  // APP BAR
  // -----------------------------------------

  Widget _buildAppBar() {
    return AppBackHeader(
      title: 'Edit Profile',
      onBack: controller.goBack,
      trailing: Obx(
        () => TextButton(
          onPressed: controller.isBusy ? null : controller.saveProfile,
          child:
              controller.isBusy
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: green,
                    ),
                  )
                  : Text(
                    'Save'.tr,
                    style: const TextStyle(
                      color: green,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
        ),
      ),
    );
  }

  // -----------------------------------------
  // PROFILE HEADER
  // -----------------------------------------

  // Widget _buildProfileHeader(BuildContext context) {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(10),
  //     decoration: BoxDecoration(
  //       color: context.appElevatedSurface.withValues(alpha: 0.94),
  //       borderRadius: BorderRadius.circular(17),
  //       border: Border.all(color: context.appBorder),
  //       boxShadow: context.appCardShadow,
  //     ),
  //     child: Row(
  //       children: [
  //         Stack(
  //           clipBehavior: Clip.none,
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(3),
  //               decoration: BoxDecoration(
  //                 color: context.appSurface,
  //                 shape: BoxShape.circle,
  //               ),
  //               child: Obx(() {
  //                 final image = _editAvatarImage();
  //                 return CircleAvatar(
  //                   radius: 39,
  //                   backgroundColor: context.appSoftGreen,
  //                   backgroundImage: image,
  //                   child:
  //                       image == null
  //                           ? const Icon(
  //                             Icons.person_outline_rounded,
  //                             size: 40,
  //                             color: green,
  //                           )
  //                           : null,
  //                 );
  //               }),
  //             ),

  //             Positioned(
  //               right: -2,
  //               bottom: 0,
  //               child: GestureDetector(
  //                 onTap: controller.pickProfileImage,
  //                 child: Container(
  //                   width: 28,
  //                   height: 28,
  //                   decoration: BoxDecoration(
  //                     color: context.appSurface,
  //                     shape: BoxShape.circle,
  //                     border: Border.all(color: green),
  //                   ),
  //                   child: const Icon(
  //                     Icons.camera_alt_outlined,
  //                     size: 17,
  //                     color: green,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),

  //         const SizedBox(width: 15),

  //         Expanded(
  //           child: Obx(
  //             () => Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   controller.profileName.value,
  //                   style: const TextStyle(
  //                     fontSize: 19,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),

  //                 const SizedBox(height: 3),

  //                 Container(
  //                   padding: const EdgeInsets.symmetric(
  //                     horizontal: 7,
  //                     vertical: 3,
  //                   ),
  //                   decoration: BoxDecoration(
  //                     color: const Color(0xFFE4F8E9),
  //                     borderRadius: BorderRadius.circular(20),
  //                   ),
  //                   child: Row(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       const Icon(Icons.check_circle, color: green, size: 14),
  //                       const SizedBox(width: 3),
  //                       Text(
  //                         controller.membership.value.tr,
  //                         style: const TextStyle(
  //                           color: green,
  //                           fontSize: 10,
  //                           fontWeight: FontWeight.w700,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),

  //                 const SizedBox(height: 8),

  //                 Row(
  //                   children: [
  //                     const Icon(Icons.mail_outline, size: 17),

  //                     const SizedBox(width: 7),

  //                     Expanded(
  //                       child: Text(
  //                         controller.profileEmail.value,
  //                         overflow: TextOverflow.ellipsis,
  //                         style: const TextStyle(fontSize: 11),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ImageProvider<Object>? _editAvatarImage() {
  //   final localPath = controller.profileImagePath.value.trim();
  //   if (localPath.isNotEmpty) return FileImage(File(localPath));

  //   final remotePath =
  //       controller.profileController.authenticatedUser.value?.profileImageUrl
  //           ?.trim();
  //   if (remotePath != null && remotePath.isNotEmpty) {
  //     final url =
  //         remotePath.startsWith('http://') || remotePath.startsWith('https://')
  //             ? remotePath
  //             : '${ApiConfig.baseUrl}${remotePath.startsWith('/') ? '' : '/'}$remotePath';
  //     return NetworkImage(url);
  //   }
  //   return null;
  // }

  // -----------------------------------------
  // PERSONAL INFORMATION
  // -----------------------------------------

  Widget _buildPersonalInformation(BuildContext context) {
    return _sectionCard(
      context,
      title: 'Personal Information',
      child: Obx(
        () => Column(
          children: [
            EditInfoRow(
              icon: Icons.person_outline_rounded,
              iconColor: green,
              iconBackground: const Color(0xFFE9F8EC),
              label: 'Full Name',
              value: controller.fullName.value,
              onTap: controller.editFullName,
            ),

            EditInfoRow(
              icon: Icons.email_outlined,
              iconColor: const Color(0xFF5275F5),
              iconBackground: const Color(0xFFEEF1FF),
              label: 'Email',
              value: controller.email.value,
              onTap:
                  controller.isContactVerificationBusy.value
                      ? null
                      : controller.editEmail,
              trailing:
                  controller.isContactVerificationBusy.value &&
                          controller.verifyingContactType.value == 'email'
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : controller.email.value.isNotEmpty &&
                          controller.isEmailVerified.value
                      ? _verifiedBadge()
                      : null,
            ),

            EditInfoRow(
              icon: Icons.phone_outlined,
              iconColor: green,
              iconBackground: const Color(0xFFE9F8EC),
              label: 'Phone',
              value:
                  controller.phone.value.isEmpty
                      ? 'Not set'
                      : controller.phone.value,
              onTap:
                  controller.isContactVerificationBusy.value
                      ? null
                      : controller.editPhone,
              trailing:
                  controller.isContactVerificationBusy.value &&
                          controller.verifyingContactType.value == 'phone'
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : controller.phone.value.isEmpty
                      ? null
                      : controller.isPhoneVerified.value
                      ? _verifiedBadge()
                      : InkWell(
                        onTap: controller.verifyPhone,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFF9800)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_outlined,
                                size: 12,
                                color: Color(0xFFE65100),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Verify'.tr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
            ),

            if (controller.verificationDetail.value.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8F3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: green.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      controller.isContactVerificationBusy.value
                          ? Icons.hourglass_top_rounded
                          : Icons.info_outline_rounded,
                      color: green,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        controller.verificationDetail.value,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Color(0xFF3E5B48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            EditInfoRow(
              icon: Icons.calendar_month_outlined,
              iconColor: const Color(0xFFD958FF),
              iconBackground: const Color(0xFFF8E7FF),
              label: 'Date of Birth',
              value: controller.formattedDateOfBirth,
              onTap: () {
                controller.selectDateOfBirth(context);
              },
            ),

            EditInfoRow(
              icon: Icons.male_rounded,
              iconColor: const Color(0xFF9C56FF),
              iconBackground: const Color(0xFFF2E5FF),
              label: 'Gender',
              value:
                  controller.gender.value.isEmpty
                      ? 'Not set'
                      : controller.gender.value,
              showDivider: false,
              onTap: controller.selectGender,
            ),
          ],
        ),
      ),
    );
  }

  Widget _verifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F8E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: green.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 12,
            color: green,
          ),
          const SizedBox(width: 4),
          Text(
            'Verified'.tr,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: green,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------
  // BODY AND HEALTH
  // -----------------------------------------

  Widget _buildHealthInformation(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Body and Health Information'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 2),

          Text(
            'BMI is calculated automatically from your height and weight'.tr,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 10),
          ),

          const SizedBox(height: 7),

          Container(
            decoration: BoxDecoration(
              color: context.appMutedSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appBorder),
            ),
            child: Obx(
              () => Column(
                children: [
                  EditInfoRow(
                    icon: Icons.person_outline_rounded,
                    iconColor: green,
                    iconBackground: const Color(0xFFE9F8EC),
                    label: 'Age',
                    value:
                        controller.age.value > 0
                            ? '@value years'.trParams({
                              'value': '${controller.age.value}',
                            })
                            : 'Not set',
                    onTap: controller.editAge,
                  ),

                  EditInfoRow(
                    icon: Icons.accessibility_new_rounded,
                    iconColor: const Color(0xFF5275F5),
                    iconBackground: const Color(0xFFEDF1FF),
                    label: 'Height',
                    value:
                        controller.height.value > 0
                            ? '${controller.height.value.toStringAsFixed(0)} cm'
                            : 'Not set',
                    onTap: controller.editHeight,
                  ),

                  EditInfoRow(
                    icon: Icons.monitor_weight_outlined,
                    iconColor: const Color(0xFF3D315B),
                    iconBackground: const Color(0xFFF0ECFF),
                    label: 'Weight',
                    value:
                        controller.weight.value > 0
                            ? '${controller.weight.value.toStringAsFixed(0)} kg'
                            : 'Not set',
                    showDivider: false,
                    onTap: controller.editWeight,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          _buildBmiCard(context),
        ],
      ),
    );
  }

  // -----------------------------------------
  // BMI
  // -----------------------------------------

  Widget _buildBmiCard(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.appSoftGreen, context.appElevatedSurface],
          ),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.av_timer_outlined, size: 31, color: green),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your BMI'.tr,
                    style: const TextStyle(
                      color: green,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    'Auto-calculate from height & weight'.tr,
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9AE8B0),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      controller.bmi > 0
                          ? '${controller.bmi.toStringAsFixed(1)} '
                              '${controller.bmiStatus.tr}'
                          : 'Not set'.tr,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF008F42),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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

  // -----------------------------------------
  // SECTION CARD
  // -----------------------------------------

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 9),
            child: Text(
              title.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: context.appMutedSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appBorder),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
