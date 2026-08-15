import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/edit_profile_controller.dart';
import '../widgets/edit_info_row.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  static const green = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(),

                    const SizedBox(height: 12),

                    _buildProfileHeader(),

                    const SizedBox(height: 12),

                    _buildPersonalInformation(context),

                    const SizedBox(height: 14),

                    _buildHealthInformation(),
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
    return Row(
      children: [
        IconButton(
          onPressed: controller.goBack,
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF006C3B),
            size: 25,
          ),
        ),

        const SizedBox(width: 5),

        const Text(
          'Edit Profile',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),

        const Spacer(),

        TextButton(
          onPressed: controller.saveProfile,
          child: const Text(
            'Save',
            style: TextStyle(
              color: green,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  // -----------------------------------------
  // PROFILE HEADER
  // -----------------------------------------

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Obx(
                  () => CircleAvatar(
                    radius: 39,
                    backgroundImage:
                        controller.profileImagePath.isEmpty
                            ? const AssetImage(
                              'assets/images/profile/profile.jpg',
                            )
                            : FileImage(
                              File(controller.profileImagePath.value),
                            ),
                  ),
                ),
              ),

              Positioned(
                right: -2,
                bottom: 0,
                child: GestureDetector(
                  onTap: controller.pickProfileImage,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: green),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 17,
                      color: green,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.profileName.value,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    controller.membership.value,
                    style: const TextStyle(
                      color: green,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.mail_outline, size: 17),

                      const SizedBox(width: 7),

                      Expanded(
                        child: Text(
                          controller.profileEmail.value,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------
  // PERSONAL INFORMATION
  // -----------------------------------------

  Widget _buildPersonalInformation(BuildContext context) {
    return _sectionCard(
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
              onTap: controller.editEmail,
            ),

            EditInfoRow(
              icon: Icons.phone_outlined,
              iconColor: green,
              iconBackground: const Color(0xFFE9F8EC),
              label: 'Phone',
              value: controller.phone.value,
              onTap: controller.editPhone,
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
              value: controller.gender.value,
              showDivider: false,
              onTap: controller.selectGender,
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------
  // BODY AND HEALTH
  // -----------------------------------------

  Widget _buildHealthInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Body and Health Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 2),

          const Text(
            'BMI is calculated automatically from your height and weight',
            style: TextStyle(color: Color(0xFF888888), fontSize: 10),
          ),

          const SizedBox(height: 7),

          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7E7E7)),
            ),
            child: Obx(
              () => Column(
                children: [
                  EditInfoRow(
                    icon: Icons.person_outline_rounded,
                    iconColor: green,
                    iconBackground: const Color(0xFFE9F8EC),
                    label: 'Age',
                    value: '${controller.age.value} years',
                    onTap: controller.editAge,
                  ),

                  EditInfoRow(
                    icon: Icons.accessibility_new_rounded,
                    iconColor: const Color(0xFF5275F5),
                    iconBackground: const Color(0xFFEDF1FF),
                    label: 'Height',
                    value: '${controller.height.value.toStringAsFixed(0)} cm',
                    onTap: controller.editHeight,
                  ),

                  EditInfoRow(
                    icon: Icons.monitor_weight_outlined,
                    iconColor: const Color(0xFF3D315B),
                    iconBackground: const Color(0xFFF0ECFF),
                    label: 'Weight',
                    value: '${controller.weight.value.toStringAsFixed(0)} kg',
                    showDivider: false,
                    onTap: controller.editWeight,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          _buildBmiCard(),
        ],
      ),
    );
  }

  // -----------------------------------------
  // BMI
  // -----------------------------------------

  Widget _buildBmiCard() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF2FFF4), Color(0xFFE8FFE2)],
          ),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFA8DDB0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.av_timer_outlined, size: 31, color: green),

            const SizedBox(width: 10),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your BMI',
                    style: TextStyle(
                      color: green,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 2),

                  Text(
                    'Auto-calculate from height & weight',
                    style: TextStyle(color: Color(0xFF777777), fontSize: 9),
                  ),
                ],
              ),
            ),

            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF9AE8B0),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${controller.bmi.toStringAsFixed(1)} '
                    '${controller.bmiStatus}',
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
          ],
        ),
      ),
    );
  }

  // -----------------------------------------
  // SECTION CARD
  // -----------------------------------------

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 9),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7E7E7)),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
