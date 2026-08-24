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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(color: Color(0x1231543F), blurRadius: 18, offset: Offset(0, 6)),
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

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        controller.name.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1D2922),
                          fontSize: 20,
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
                          fontSize: 14,
                          color: green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          size: 17,
                          color: Color(0xFF7E9488),
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Obx(
                            () => Text(
                              controller.email.value,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF65766C),
                                fontSize: 12,
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
                label: const Text(
                  'Edit Profile',
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(88, 34),
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
