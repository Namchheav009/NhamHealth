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
  Widget build(BuildContext context) => Material(
    color: context.appElevatedSurface.withValues(alpha: .96),
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
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
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
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
                  if (post.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      post.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.42,
                        color: context.appText,
                      ),
                    ),
                  ],
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: post.tags.map((tag) => _Tag(tag)).toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (post.imageUrl.isNotEmpty)
              AspectRatio(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 7,
                children: [
                  if (post.cookingTimeMinutes != null)
                    _Meta(
                      Icons.schedule_rounded,
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
                      Icons.signal_cellular_alt_rounded,
                      _localizedDifficulty(post.difficulty),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _header(BuildContext context) => Row(
    children: [
      _AuthorAvatar(imageUrl: post.authorAvatarUrl),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.authorName.isEmpty ? 'community.member'.tr : post.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                letterSpacing: -.1,
                fontWeight: FontWeight.w800,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _savedDate,
              style: TextStyle(fontSize: 12, color: context.appMutedText),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'common.remove_from_favorites'.tr,
        onPressed: onRemove,
        icon: const Icon(
          Icons.bookmark_remove_rounded,
          color: AppColors.primaryPink,
        ),
      ),
    ],
  );

  String get _savedDate {
    final date = post.updatedAt ?? post.publishedAt ?? post.createdAt;
    if (date == null) return 'community.saved_post'.tr;
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
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
  const _AuthorAvatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 22,
    backgroundColor: context.appSoftGreen,
    foregroundImage:
        imageUrl.trim().isEmpty ? null : CachedNetworkImageProvider(imageUrl),
    child:
        imageUrl.trim().isEmpty
            ? const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primaryGreen,
            )
            : null,
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: context.appSoftGreen,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text.startsWith('#') ? text : '#$text',
      style: TextStyle(
        color: context.appColorScheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: context.appSubtleSurface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.appMutedText),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 12, color: context.appMutedText)),
      ],
    ),
  );
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
