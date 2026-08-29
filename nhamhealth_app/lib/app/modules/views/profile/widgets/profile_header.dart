import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

import '../../../../../config/api_config.dart';
import '../../../models/auth/authenticated_user_model.dart';
import '../../../controllers/profile/profile_controller.dart';
import '../../../../theme/app_colors.dart';

class ProfileHeader extends GetView<ProfileController> {
  const ProfileHeader({super.key});

  static const green = Color(0xFF009B3E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.appSurface,
                ),
                child: Obx(
                  () => _ProfileAvatar(
                    localPath: controller.profileImagePath.value,
                    user: controller.authenticatedUser.value,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        controller.name.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Obx(
                      () => Text(
                        controller.membership.value,
                        style: const TextStyle(
                          fontSize: 12,
                          color: green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Icon(
                          Icons.mail_outline_rounded,
                          size: 14,
                          color: context.appMutedText,
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Obx(
                            () => Text(
                              controller.email.value,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.appMutedText,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: controller.editProfile,
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: Text(
                  'Edit Profile'.tr,
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(92, 34),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.localPath, required this.user});

  final String localPath;
  final AuthenticatedUser? user;

  @override
  Widget build(BuildContext context) {
    final selectedPath = localPath.trim();
    if (selectedPath.isNotEmpty) {
      return CircleAvatar(
        radius: 36,
        backgroundImage: FileImage(File(selectedPath)),
      );
    }

    final remotePath = user?.profileImageUrl?.trim();
    if (remotePath != null && remotePath.isNotEmpty) {
      final imageUrl =
          remotePath.startsWith('http://') || remotePath.startsWith('https://')
              ? remotePath
              : '${ApiConfig.baseUrl}${remotePath.startsWith('/') ? '' : '/'}$remotePath';
      return CircleAvatar(
        radius: 36,
        backgroundColor: const Color(0xFFE8F5E9),
        foregroundImage: CachedNetworkImageProvider(
          imageUrl,
          maxWidth: 256,
          maxHeight: 256,
        ),
        child: _initials(user?.initials ?? '?'),
      );
    }

    return CircleAvatar(
      radius: 36,
      backgroundColor: const Color(0xFFE8F5E9),
      child: _initials(user?.initials ?? '?'),
    );
  }

  Widget _initials(String value) {
    return Text(
      value,
      style: const TextStyle(
        color: Color(0xFF087A35),
        fontSize: 21,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
