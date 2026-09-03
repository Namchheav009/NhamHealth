import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

import '../../../../../config/api_config.dart';
import '../../../models/auth/authenticated_user_model.dart';
import '../../../controllers/profile/profile_controller.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_alert.dart';

class ProfileHeader extends GetView<ProfileController> {
  const ProfileHeader({super.key});

  static const green = Color(0xFF009B3E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder.withValues(alpha: .8)),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Obx(
                () => _ProfileAvatar(
                  localPath: controller.profileImagePath.value,
                  user: controller.authenticatedUser.value,
                  onDelete: controller.deleteProfileImage,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: _ProfileStat(
                          value: '${controller.posts.length}',
                          label: 'Posts',
                        ),
                      ),
                      Expanded(
                        child: _ProfileStat(
                          value: '${controller.followerCount.value}',
                          label: 'Followers',
                        ),
                      ),
                      Expanded(
                        child: _ProfileStat(
                          value: '${controller.followingCount.value}',
                          label: 'Following',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(
                      () => Text(
                        controller.membership.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Obx(
                      () => Text(
                        controller.email.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: controller.editProfile,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(76, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$value $label',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: context.appText,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(color: context.appMutedText, fontSize: 12),
        ),
      ],
    ),
  );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.localPath,
    required this.user,
    required this.onDelete,
  });

  final String localPath;
  final AuthenticatedUser? user;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final selectedPath = localPath.trim();
    final remotePath = user?.profileImageUrl?.trim();
    final imageUrl =
        remotePath == null || remotePath.isEmpty
            ? null
            : remotePath.startsWith('http://') ||
                remotePath.startsWith('https://')
            ? remotePath
            : '${ApiConfig.baseUrl}${remotePath.startsWith('/') ? '' : '/'}$remotePath';
    final hasImage = selectedPath.isNotEmpty || imageUrl != null;

    return Semantics(
      button: hasImage,
      label: hasImage ? 'View full profile photo' : 'Profile photo',
      child: Tooltip(
        message: hasImage ? 'View profile photo' : 'Profile photo',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap:
              hasImage
                  ? () => _openFullImage(
                    context,
                    localPath: selectedPath,
                    imageUrl: imageUrl,
                    onDelete: onDelete,
                  )
                  : null,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ProfileHeader.green.withValues(alpha: .22),
                width: 1.5,
              ),
            ),
            child: _avatar(selectedPath, imageUrl),
          ),
        ),
      ),
    );
  }

  Widget _avatar(String selectedPath, String? imageUrl) {
    if (selectedPath.isNotEmpty) {
      return CircleAvatar(
        radius: 39,
        backgroundImage: FileImage(File(selectedPath)),
      );
    }
    if (imageUrl != null) {
      return CircleAvatar(
        radius: 39,
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
      radius: 39,
      backgroundColor: const Color(0xFFE8F5E9),
      child: _initials(user?.initials ?? '?'),
    );
  }

  void _openFullImage(
    BuildContext context, {
    required String localPath,
    required String? imageUrl,
    required Future<void> Function() onDelete,
  }) {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        barrierDismissible: true,
        barrierLabel: 'Close profile photo',
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder:
            (_, animation, _) => FadeTransition(
              opacity: animation,
              child: _FullProfileImage(
                localPath: localPath,
                imageUrl: imageUrl,
                onDelete: onDelete,
              ),
            ),
      ),
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

class _FullProfileImage extends StatefulWidget {
  const _FullProfileImage({
    required this.localPath,
    required this.imageUrl,
    required this.onDelete,
  });

  final String localPath;
  final String? imageUrl;
  final Future<void> Function() onDelete;

  @override
  State<_FullProfileImage> createState() => _FullProfileImageState();
}

class _FullProfileImageState extends State<_FullProfileImage> {
  final TransformationController _transformation = TransformationController();
  bool _isDeleting = false;

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  Future<void> _deletePhoto() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DeleteProfilePhotoSheet(),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isDeleting = true);
    try {
      await widget.onDelete();
      if (!mounted) return;
      Navigator.of(context).pop();
      await AppAlert.success(
        title: 'Profile photo removed',
        message: 'Your profile now uses your initials instead.',
      );
    } on Object {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      await AppAlert.error(
        title: 'Could not remove photo',
        message: 'Please check your connection and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder:
                  (context, constraints) => InteractiveViewer(
                    transformationController: _transformation,
                    minScale: .8,
                    maxScale: 4,
                    panEnabled: true,
                    scaleEnabled: true,
                    boundaryMargin: const EdgeInsets.all(80),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: _image(),
                    ),
                  ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filled(
                  tooltip: 'Photo options',
                  onPressed: _isDeleting ? null : _showPhotoOptions,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: .55),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: .55),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _showPhotoOptions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProfilePhotoOptionsSheet(),
    );
    if (!mounted || action != 'delete') return;
    await _deletePhoto();
  }

  Widget _image() {
    if (widget.localPath.isNotEmpty) {
      return Image.file(
        File(widget.localPath),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      );
    }
    return CachedNetworkImage(
      imageUrl: widget.imageUrl!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      placeholder:
          (_, _) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
      errorWidget:
          (_, _, _) => const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white70,
              size: 48,
            ),
          ),
    );
  }
}

class _ProfilePhotoOptionsSheet extends StatelessWidget {
  const _ProfilePhotoOptionsSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: context.appMutedText.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Photo options',
              style: TextStyle(
                color: context.appText,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.appMutedSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.appBorder),
            ),
            child: ListTile(
              onTap: () => Navigator.of(context).pop('delete'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 3,
              ),
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFD94545),
                size: 27,
              ),
              title: const Text(
                'Delete photo',
                style: TextStyle(
                  color: Color(0xFFD94545),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DeleteProfilePhotoSheet extends StatelessWidget {
  const _DeleteProfilePhotoSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: context.appMutedText.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Delete profile photo?',
            style: TextStyle(
              color: context.appText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your current profile photo will be removed. You can add a new one later.',
            style: TextStyle(color: context.appMutedText, height: 1.4),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD94545),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
