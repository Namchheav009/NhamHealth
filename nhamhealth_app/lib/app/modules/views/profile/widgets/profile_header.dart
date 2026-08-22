import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

import '../../../../../config/api_config.dart';
import '../../../models/auth/authenticated_user_model.dart';
import '../../../controllers/profile/profile_controller.dart';

class ProfileHeader extends GetView<ProfileController> {
  const ProfileHeader({super.key});

  static const green = Color(0xFF009B3E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
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
                    Row(
                      children: [
                        Expanded(
                          child: Obx(
                            () => Text(
                              controller.name.value,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: controller.editProfile,
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 17,
                          ),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Obx(
                      () => Text(
                        controller.membership.value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.mail_outline_rounded, size: 18),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Obx(
                            () => Text(
                              controller.email.value,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
        radius: 32,
        backgroundImage: FileImage(File(selectedPath)),
      );
    }

    final remotePath = user?.profileImageUrl?.trim();
    if (remotePath != null && remotePath.isNotEmpty) {
      final imageUrl = remotePath.startsWith('http://') ||
              remotePath.startsWith('https://')
          ? remotePath
          : '${ApiConfig.baseUrl}${remotePath.startsWith('/') ? '' : '/'}$remotePath';
      return CircleAvatar(
        radius: 32,
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
      radius: 32,
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
