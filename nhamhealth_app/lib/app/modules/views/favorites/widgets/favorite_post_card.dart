import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../models/recipes/community_recipe.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

class FavoritePostCard extends StatelessWidget {
  const FavoritePostCard({
    super.key,
    required this.post,
    required this.onOpen,
    required this.onRemove,
  });

  final CommunityRecipe post;
  final VoidCallback? onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasPills =
        post.cookingTimeMinutes != null ||
        post.servings != null ||
        post.difficulty.isNotEmpty;
    final hasTags = post.tags.isNotEmpty;

    return Material(
      color: context.appElevatedSurface.withValues(alpha: .96),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.appBorder.withValues(alpha: .9)),
            boxShadow: context.appTileShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 0),
                child: _header(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.name,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.25,
                        letterSpacing: -.2,
                        fontWeight: FontWeight.w800,
                        color: context.appText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'community.see_translate'.trOrSelf == 'community.see_translate'
                          ? 'See translate'
                          : 'community.see_translate'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appMutedText,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasPills) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 7,
                    children: [
                      if (post.cookingTimeMinutes != null)
                        _Meta(
                          Icons.access_time_rounded,
                          '${post.cookingTimeMinutes} ${'meals.minutes_short'.tr}',
                        ),
                      if (post.servings != null)
                        _Meta(
                          Icons.people_outline_rounded,
                          'meals.servings_count'.trParams({
                            'count': '${post.servings}',
                          }),
                        ),
                      if (post.difficulty.isNotEmpty)
                        _Meta(
                          Icons.donut_large_rounded,
                          _localizedDifficulty(post.difficulty),
                        ),
                    ],
                  ),
                ),
              ],
              if (hasTags) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: post.tags.map((tag) => _Tag(tag)).toList(),
                  ),
                ),
              ],
              if (post.imageUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (_, _) => ColoredBox(
                              color: context.appMutedSurface,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                        errorWidget: (_, _, _) => const _ImageFallback(),
                      ),
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 11, 16, 14),
                child: Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${post.likes}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: context.appMutedText,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${post.comments} comments  ·  ${post.shares} shares',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.appMutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Row(
    children: [
      _AuthorAvatar(imageUrl: post.authorAvatarUrl, name: post.authorName),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    post.authorName.isEmpty
                        ? 'community.member'.tr
                        : post.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: -.1,
                      fontWeight: FontWeight.w800,
                      color: context.appText,
                    ),
                  ),
                ),
                if (post.isFollowing) ...[
                  const SizedBox(width: 8),
                  Text(
                    'community.following'.trOrSelf == 'community.following'
                        ? 'Following'
                        : 'community.following'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.appMutedText,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$_timeAgo  •  ${post.role.isEmpty ? 'USER' : post.role}',
              style: TextStyle(fontSize: 12, color: context.appMutedText),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'common.remove_from_favorites'.tr,
        icon: Icon(
          Icons.more_horiz_rounded,
          color: context.appMutedText,
          size: 20,
        ),
        onPressed: onRemove,
      ),
    ],
  );

  String get _timeAgo {
    final date = post.updatedAt ?? post.publishedAt ?? post.createdAt;
    if (date == null) return '3d ago';
    final now = DateTime.now();
    final difference = now.difference(date.toLocal());
    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes.clamp(1, 60);
      return '${mins}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    }
    return '${(difference.inDays / 30).floor()}mo ago';
  }

  String _localizedDifficulty(String value) {
    final normalized = value.trim().toUpperCase();
    return switch (normalized) {
      'EASY' => 'meals.easy'.tr,
      'MEDIUM' => 'common.medium'.tr,
      'HARD' => 'meals.hard'.tr,
      _ => value.trOrSelf,
    };
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.imageUrl, this.name = ''});

  final String imageUrl;
  final String name;

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 20,
    backgroundColor: context.appSoftGreen,
    foregroundImage:
        imageUrl.trim().isEmpty ? null : CachedNetworkImageProvider(imageUrl),
    child: Text(
      _initials,
      style: TextStyle(
        color: context.appColorScheme.primary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    const mintBg = Color(0xFFD4F3E2);
    const greenColor = Color(0xFF0AA653);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: mintBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text.startsWith('#') ? text : '#$text',
        style: const TextStyle(
          color: greenColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    const mintBg = Color(0xFFD4F3E2);
    const greenColor = Color(0xFF0AA653);
    const borderColor = Color(0xFF9DE0B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: mintBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: greenColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: greenColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.appMutedSurface,
    child: Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: context.appMutedText,
      ),
    ),
  );
}
