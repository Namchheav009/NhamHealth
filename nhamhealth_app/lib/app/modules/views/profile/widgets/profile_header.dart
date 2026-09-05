import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../config/api_config.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_alert.dart';
import '../../../controllers/profile/profile_controller.dart';
import '../../../models/auth/authenticated_user_model.dart';

class ProfileHeader extends GetView<ProfileController> {
  const ProfileHeader({super.key});

  static const green = Color(0xFF009B3E);

  Widget _editButton(BuildContext context) => OutlinedButton.icon(
    onPressed: controller.editProfile,
    icon: const Icon(Icons.edit_outlined, size: 15),
    label: const Text('Edit Profile'),
    style: OutlinedButton.styleFrom(
      backgroundColor:
          context.appIsDark ? context.appElevatedSurface : Colors.white,
      foregroundColor:
          context.appIsDark ? context.appColorScheme.primary : green,
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const StadiumBorder(),
      side: BorderSide(
        color: context.appIsDark ? context.appBorder : const Color(0xFFBDE8C9),
      ),
      textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder.withValues(alpha: .7)),
        boxShadow: context.appHomeTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Obx(
                  () => _ProfileAvatar(
                    localPath: controller.profileImagePath.value,
                    user: controller.authenticatedUser.value,
                    onDelete: controller.deleteProfileImage,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 94,
                  child: Stack(
                    children: [
                      Positioned(top: 0, right: 0, child: _editButton(context)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(
                                () => Text(
                                  controller.name.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.appText,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Obx(
                                () => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.appSoftGreen,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color:
                                            context.appIsDark
                                                ? context.appColorScheme.primary
                                                : green,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        controller.membership.value,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color:
                                              context.appIsDark
                                                  ? context
                                                      .appColorScheme
                                                      .primary
                                                  : green,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Obx(
                                () => Text(
                                  controller.contact,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.appMutedText,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _ProfileStat(
                    icon: Icons.article_outlined,
                    value: '${controller.posts.length}',
                    label: 'Posts',
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _ProfileStat(
                    icon: Icons.group_outlined,
                    value: '${controller.followerCount.value}',
                    label: 'Follower',
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _ProfileStat(
                    icon: Icons.person_outline,
                    value: '${controller.followingCount.value}',
                    label: 'Following',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$value $label',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: context.appSoftGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.green, size: 18),
        ),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: context.appText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: context.appMutedText, fontSize: 8),
            ),
          ],
        ),
      ],
    ),
  );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: context.appBorder);
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
              () => _showPhotoOptions(
                context,
                selectedPath: selectedPath,
                imageUrl: imageUrl,
                hasImage: hasImage,
                onDelete: onDelete,
              ),
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

  Future<void> _showPhotoOptions(
    BuildContext context, {
    required String selectedPath,
    required String? imageUrl,
    required bool hasImage,
    required Future<void> Function() onDelete,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _ProfilePhotoOptionsSheet(
            image: _avatar(selectedPath, imageUrl),
            hasImage: hasImage,
            onView: () async {
              if (!hasImage) {
                Get.snackbar('No profile photo', 'Choose a photo first.');
                return;
              }
              _openFullImage(
                context,
                localPath: selectedPath,
                imageUrl: imageUrl,
                onDelete: onDelete,
              );
            },
            onChoose: () => Get.find<ProfileController>().chooseProfileImage(),
            onRemove: () async {
              if (!hasImage) {
                Get.snackbar(
                  'No profile photo',
                  'There is no photo to remove.',
                );
                return;
              }
              final confirmed = await showModalBottomSheet<bool>(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => const _DeleteProfilePhotoSheet(),
              );
              if (confirmed == true) await onDelete();
            },
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
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _ProfilePhotoOptionsSheet(
            image: _image(),
            hasImage: true,
            onView: () async {},
            onChoose: () => Get.find<ProfileController>().chooseProfileImage(),
            onRemove: _deletePhoto,
          ),
    );
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
  const _ProfilePhotoOptionsSheet({
    required this.image,
    required this.hasImage,
    required this.onView,
    required this.onChoose,
    required this.onRemove,
  });

  final Widget image;
  final bool hasImage;
  final Future<void> Function() onView;
  final Future<void> Function() onChoose;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
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
          Center(
            child: Text(
              'Profile photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Manage your profile photo',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appMutedText, fontSize: 14),
            ),
          ),
          const SizedBox(height: 18),
          Center(child: SizedBox(width: 92, height: 92, child: image)),
          const SizedBox(height: 20),
          _PhotoAction(
            icon: Icons.visibility_outlined,
            title: 'View photo',
            subtitle: 'See your current profile photo',
            color: const Color(0xFF5B2295),
            background: const Color(0xFFF1ECFF),
            enabled: true,
            onTap: onView,
          ),
          const SizedBox(height: 10),
          _PhotoAction(
            icon: Icons.image_outlined,
            title: 'Choose new photo',
            subtitle: 'Select a new photo from your gallery',
            color: const Color(0xFF1769E0),
            background: const Color(0xFFEAF2FF),
            onTap: onChoose,
          ),
          const SizedBox(height: 10),
          _PhotoAction(
            icon: Icons.delete_outline_rounded,
            title: 'Remove current photo',
            subtitle: 'Delete your current profile photo',
            color: const Color(0xFFE3262E),
            background: const Color(0xFFFFECEC),
            enabled: true,
            onTap: onRemove,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor:
                    context.appIsDark
                        ? context.appColorScheme.surfaceContainerHighest
                        : const Color(0xFFF5F5F7),
                foregroundColor:
                    context.appIsDark ? context.appText : Colors.black87,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PhotoAction extends StatelessWidget {
  const _PhotoAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final Future<void> Function() onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : .45,
    child: Material(
      color: context.appIsDark ? context.appElevatedSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color:
              context.appIsDark ? context.appBorder : const Color(0xFFE5E5E5),
        ),
      ),
      child: InkWell(
        onTap:
            enabled
                ? () async {
                  Navigator.of(context).pop();
                  await onTap();
                }
                : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.appMutedText, size: 30),
            ],
          ),
        ),
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
