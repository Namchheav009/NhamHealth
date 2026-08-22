import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../config/api_config.dart';
import '../../../../theme/app_colors.dart';
import '../../../models/auth/authenticated_user_model.dart';

class AuthenticatedUserAvatar extends StatelessWidget {
  const AuthenticatedUserAvatar({
    super.key,
    required this.user,
    this.size = 44,
    this.showOnlineStatus = true,
  });

  final AuthenticatedUser? user;
  final double size;
  final bool showOnlineStatus;

  @override
  Widget build(BuildContext context) {
    final statusSize = size < 60 ? 11.0 : 18.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: const ValueKey<String>('authenticated-user-avatar'),
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: AppColors.softGreen,
            shape: BoxShape.circle,
          ),
          child: _avatarContent(),
        ),
        if (showOnlineStatus)
          Positioned(
            right: -1,
            bottom: 0,
            child: Container(
              width: statusSize,
              height: statusSize,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cardSurface,
                  width: size < 60 ? 2 : 3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _avatarContent() {
    final imageUrl = user?.profileImageUrl?.trim();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _resolveImageUrl(imageUrl),
        fit: BoxFit.cover,
        memCacheWidth: (size * 3).round(),
        placeholder: (_, _) => const ColoredBox(color: AppColors.softGreen),
        errorWidget: (_, _, _) => _Initials(user: user, size: size),
      );
    }
    return _Initials(user: user, size: size);
  }

  String _resolveImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    final separator = imageUrl.startsWith('/') ? '' : '/';
    return '${ApiConfig.baseUrl}$separator$imageUrl';
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.user, required this.size});

  final AuthenticatedUser? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        user?.initials ?? '?',
        key: const ValueKey<String>('authenticated-user-initials'),
        style: TextStyle(
          color: AppColors.darkGreen,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
