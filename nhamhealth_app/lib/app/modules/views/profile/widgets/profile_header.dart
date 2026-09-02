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

  void _zoom(double factor) {
    final current = _transformation.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(.8, 4.0);
    _transformation.value = Matrix4.diagonal3Values(next, next, 1);
  }

  void _resetZoom() => _transformation.value = Matrix4.identity();

  Future<void> _deletePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete profile photo?'),
            content: const Text(
              'Your current profile photo will be removed. You can add a new one later.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD94545),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete'),
              ),
            ],
          ),
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
            child: InteractiveViewer(
              transformationController: _transformation,
              minScale: .8,
              maxScale: 4,
              panEnabled: true,
              scaleEnabled: true,
              boundaryMargin: const EdgeInsets.all(80),
              child: Center(child: _image()),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: IconButton.filled(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: .55),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 18,
            child: FilledButton.icon(
              onPressed: _isDeleting ? null : _deletePhoto,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD94545),
                foregroundColor: Colors.white,
              ),
              icon:
                  _isDeleting
                      ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.delete_outline_rounded, size: 19),
              label: Text(_isDeleting ? 'Removing...' : 'Delete photo'),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 18,
            child: _ZoomControls(
              onZoomIn: () => _zoom(1.35),
              onZoomOut: () => _zoom(1 / 1.35),
              onReset: _resetZoom,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _image() {
    if (widget.localPath.isNotEmpty) {
      return Image.file(File(widget.localPath), fit: BoxFit.contain);
    }
    return CachedNetworkImage(
      imageUrl: widget.imageUrl!,
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

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black.withValues(alpha: .58),
    borderRadius: BorderRadius.circular(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Zoom in',
          onPressed: onZoomIn,
          color: Colors.white,
          icon: const Icon(Icons.add_rounded),
        ),
        IconButton(
          tooltip: 'Reset zoom',
          onPressed: onReset,
          color: Colors.white,
          icon: const Icon(Icons.center_focus_strong_rounded, size: 20),
        ),
        IconButton(
          tooltip: 'Zoom out',
          onPressed: onZoomOut,
          color: Colors.white,
          icon: const Icon(Icons.remove_rounded),
        ),
      ],
    ),
  );
}
