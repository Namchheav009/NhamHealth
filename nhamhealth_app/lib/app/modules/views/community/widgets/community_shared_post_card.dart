import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../models/community/community_post.dart';
import 'community_recipe_sheet.dart';

class CommunitySharedPostCard extends StatelessWidget {
  const CommunitySharedPostCard({
    required this.post,
    this.onTap,
    this.onAuthorTap,
    this.relationshipLabel,
    this.onRelationshipTap,
    this.onOptions,
    this.compact = false,
    this.showRecipeButton = true,
    super.key,
  });

  final CommunitySharedPost post;
  final VoidCallback? onTap;
  final VoidCallback? onAuthorTap;
  final String? relationshipLabel;
  final VoidCallback? onRelationshipTap;
  final VoidCallback? onOptions;
  final bool compact;
  final bool showRecipeButton;

  static const Color green = Color(0xFF08A936);

  String get _initials {
    final trimmed = post.author.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasPills =
        post.cookingTimeMinutes != null ||
        post.servings != null ||
        post.difficulty.isNotEmpty;
    final hasTags = post.tags.isNotEmpty;
    final images =
        post.imageUrls.isNotEmpty
            ? post.imageUrls
            : (post.imageUrl.isNotEmpty ? [post.imageUrl] : const <String>[]);
    final hasImages = images.isNotEmpty;
    final hasRecipe = showRecipeButton && post.hasRecipe;

    return Material(
      color: context.appElevatedSurface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.appBorder),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Row(
                children: [
                  InkWell(
                    onTap: onAuthorTap,
                    borderRadius: BorderRadius.circular(compact ? 18 : 20),
                    child: ClipOval(
                      child: SizedBox.square(
                        dimension: compact ? 36 : 40,
                        child: ColoredBox(
                          color: context.appSoftGreen,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Center(
                                child: Text(
                                  _initials,
                                  style: const TextStyle(
                                    color: green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (post.authorAvatarUrl.isNotEmpty)
                                Image.network(
                                  post.authorAvatarUrl,
                                  fit: BoxFit.cover,
                                  cacheWidth: 120,
                                  errorBuilder:
                                      (_, _, _) => const SizedBox.shrink(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: InkWell(
                      onTap: onAuthorTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: context.appText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_localSharedAge(post)}  ·  ${_localizedRole(post.role)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.appMutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (relationshipLabel != null &&
                      relationshipLabel!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: onRelationshipTap,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Text(
                            _localizedRelationship(relationshipLabel!),
                            style: TextStyle(
                              color: context.appMutedText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (onOptions != null)
                    IconButton(
                      tooltip: 'common.post_options'.tr,
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: context.appMutedSurface,
                        foregroundColor: context.appMutedText,
                      ),
                      icon: const Icon(Icons.more_horiz_rounded, size: 18),
                      onPressed: onOptions,
                    ),
                ],
              ),
            ),

            // Meal Name
            if (post.mealName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  post.mealName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.appText,
                  ),
                ),
              ),

            // Description
            if (post.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Text(
                  post.description,
                  maxLines: compact ? 4 : null,
                  overflow: compact ? TextOverflow.ellipsis : null,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: context.appText,
                  ),
                ),
              ),

            // Info Pills (Cooking Time, Servings, Difficulty)
            if (hasPills)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    if (post.cookingTimeMinutes != null)
                      _SharedInfoPill(
                        icon: Icons.timer_outlined,
                        label: '${post.cookingTimeMinutes} min',
                      ),
                    if (post.servings != null)
                      _SharedInfoPill(
                        icon: Icons.people_outline_rounded,
                        label: 'meals.servings_count'.trParams({
                          'count': '${post.servings}',
                        }),
                      ),
                    if (post.difficulty.isNotEmpty)
                      _SharedInfoPill(
                        icon: Icons.local_fire_department_outlined,
                        label: post.difficulty,
                      ),
                  ],
                ),
              ),

            // Tags
            if (hasTags)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: post.tags
                      .map((tag) => _SharedTag(text: '#$tag'))
                      .toList(growable: false),
                ),
              ),

            // Photos Carousel
            if (hasImages)
              _SharedImageCarousel(imageUrls: images),

            // View Full Recipe Button
            if (hasRecipe)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: _SharedViewRecipeButton(
                  onTap: () => showCommunityRecipeSheet(context, post.toPost()),
                ),
              ),

            // Bottom spacing when neither images nor recipe are present
            if (!hasImages && !hasRecipe)
              const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

class _SharedImageCarousel extends StatefulWidget {
  const _SharedImageCarousel({required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<_SharedImageCarousel> createState() => _SharedImageCarouselState();
}

class _SharedImageCarouselState extends State<_SharedImageCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageCount = widget.imageUrls.length;
    final showCarousel = imageCount > 1;

    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: AspectRatio(
          aspectRatio: 5 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (page) {
                  if (_currentPage != page) {
                    setState(() => _currentPage = page);
                  }
                },
                children: widget.imageUrls
                    .map(
                      (url) => Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, _, _) => ColoredBox(
                              color: context.appSubtleSurface,
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Color(0xFF8D9990),
                                ),
                              ),
                            ),
                      ),
                    )
                    .toList(growable: false),
              ),
              if (showCarousel)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPage + 1}/$imageCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SharedViewRecipeButton extends StatelessWidget {
  const _SharedViewRecipeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.appSubtleSurface,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      key: const ValueKey<String>('shared-view-full-recipe-button'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: context.appSoftGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 19,
                color: CommunitySharedPostCard.green,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'community.view_full_recipe'.tr,
                    style: const TextStyle(
                      color: CommunitySharedPostCard.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'community.recipe_button_help'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: context.appMutedText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: CommunitySharedPostCard.green,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SharedInfoPill extends StatelessWidget {
  const _SharedInfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: context.appSoftGreen,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: CommunitySharedPostCard.green.withValues(alpha: .12),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: CommunitySharedPostCard.green),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: context.appText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _SharedTag extends StatelessWidget {
  const _SharedTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: context.appSoftGreen,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: CommunitySharedPostCard.green,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

String _localSharedAge(CommunitySharedPost post) {
  final createdAt = post.createdAt?.toLocal();
  if (createdAt != null) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.isNegative || difference.inMinutes < 1) {
      return 'community.just_now'.tr;
    }
    if (difference.inHours < 1) {
      return 'community.minutes_ago'.trParams({
        'count': '${difference.inMinutes}',
      });
    }
    if (difference.inDays < 1) {
      return 'community.hours_ago'.trParams({'count': '${difference.inHours}'});
    }
    if (difference.inDays == 1) return 'community.yesterday'.tr;
    return 'community.days_ago'.trParams({'count': '${difference.inDays}'});
  }

  return _localizedAge(post.ageLabel);
}

String _localizedAge(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'just now') {
    return 'community.just_now'.tr;
  }
  if (trimmed.toLowerCase() == 'recently') return 'community.recently'.tr;
  if (trimmed.toLowerCase() == 'yesterday') return 'community.yesterday'.tr;
  final minMatch = RegExp(
    r'^(\d+)\s*m\s*ago$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (minMatch != null) {
    return 'community.minutes_ago'.trParams({'count': minMatch.group(1)!});
  }
  final hourMatch = RegExp(
    r'^(\d+)\s*h\s*ago$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (hourMatch != null) {
    return 'community.hours_ago'.trParams({'count': hourMatch.group(1)!});
  }
  final dayMatch = RegExp(
    r'^(\d+)\s*d\s*ago$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (dayMatch != null) {
    return 'community.days_ago'.trParams({'count': dayMatch.group(1)!});
  }
  return trimmed;
}

String _localizedRole(String? role) {
  final value = (role ?? '').trim();
  if (value.isEmpty ||
      value.toUpperCase() == 'USER' ||
      value.toLowerCase() == 'community member' ||
      value.toLowerCase() == 'member') {
    return 'community.member'.tr;
  }
  return value;
}

String _localizedRelationship(String label) {
  final trimmed = label.trim();
  if (trimmed.isEmpty) return trimmed;
  final lower = trimmed.toLowerCase();
  if (lower == 'follow') return 'community.follow'.tr;
  if (lower == 'following') return 'community.following'.tr;
  if (lower == 'friend') return 'community.friend'.tr;
  return trimmed;
}