import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../models/recipes/community_recipe.dart';

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
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.appBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 10),
            Text(
              post.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.appText,
              ),
            ),
            if (post.description.trim().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                post.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: context.appMutedText,
                ),
              ),
            ],
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 5,
                children: post.tags.map((tag) => _Tag(tag)).toList(),
              ),
            ],
            if (post.imageUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1.75,
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
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (post.cookingTimeMinutes != null)
                  _Meta(Icons.schedule_rounded, '${post.cookingTimeMinutes} min'),
                if (post.servings != null)
                  _Meta(Icons.people_outline_rounded, '${post.servings}'),
                if (post.difficulty.isNotEmpty)
                  _Meta(Icons.signal_cellular_alt_rounded, post.difficulty.tr),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _header(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 20,
        backgroundColor: context.appSoftGreen,
        child: const Icon(
          Icons.person_outline_rounded,
          color: AppColors.primaryGreen,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.authorName.isEmpty ? 'Community member'.tr : post.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _savedDate,
              style: TextStyle(fontSize: 10, color: context.appMutedText),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Remove from favorites'.tr,
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
    if (date == null) return 'Saved post'.tr;
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: context.appSoftGreen,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text.startsWith('#') ? text : '#$text',
      style: TextStyle(
        color: context.appColorScheme.primary,
        fontSize: 9,
        fontWeight: FontWeight.w600,
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
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: context.appSubtleSurface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.appMutedText),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 10, color: context.appMutedText)),
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
