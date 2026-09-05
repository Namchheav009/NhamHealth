import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum PageSkeletonType {
  home,
  meals,
  allMeals,
  foodDetail,
  foodDetailContent,
  profile,
  wellness,
  notifications,
  favorites,
  community,
  communityPost,
  comments,
  communityPeople,
  recipes,
  settings,
  aiFoodAnalysis,
}

class PageSkeleton extends StatefulWidget {
  const PageSkeleton({
    super.key,
    required this.type,
    this.duration = const Duration(milliseconds: 1600),
  });

  const PageSkeleton.home({
    super.key,
    this.duration = const Duration(milliseconds: 1600),
  }) : type = PageSkeletonType.home;

  const PageSkeleton.profile({
    super.key,
    this.duration = const Duration(milliseconds: 1750),
  }) : type = PageSkeletonType.profile;

  const PageSkeleton.meals({
    super.key,
    this.duration = const Duration(milliseconds: 1550),
  }) : type = PageSkeletonType.meals;

  const PageSkeleton.allMeals({
    super.key,
    this.duration = const Duration(milliseconds: 1550),
  }) : type = PageSkeletonType.allMeals;

  const PageSkeleton.foodDetail({
    super.key,
    this.duration = const Duration(milliseconds: 1600),
  }) : type = PageSkeletonType.foodDetail;

  const PageSkeleton.foodDetailContent({
    super.key,
    this.duration = const Duration(milliseconds: 1400),
  }) : type = PageSkeletonType.foodDetailContent;

  const PageSkeleton.wellness({
    super.key,
    this.duration = const Duration(milliseconds: 1650),
  }) : type = PageSkeletonType.wellness;

  const PageSkeleton.notifications({
    super.key,
    this.duration = const Duration(milliseconds: 1500),
  }) : type = PageSkeletonType.notifications;

  const PageSkeleton.favorites({
    super.key,
    this.duration = const Duration(milliseconds: 1550),
  }) : type = PageSkeletonType.favorites;

  const PageSkeleton.community({
    super.key,
    this.duration = const Duration(milliseconds: 1600),
  }) : type = PageSkeletonType.community;

  const PageSkeleton.communityPost({
    super.key,
    this.duration = const Duration(milliseconds: 1600),
  }) : type = PageSkeletonType.communityPost;

  const PageSkeleton.comments({
    super.key,
    this.duration = const Duration(milliseconds: 1500),
  }) : type = PageSkeletonType.comments;

  const PageSkeleton.communityPeople({
    super.key,
    this.duration = const Duration(milliseconds: 1500),
  }) : type = PageSkeletonType.communityPeople;

  const PageSkeleton.recipes({
    super.key,
    this.duration = const Duration(milliseconds: 1550),
  }) : type = PageSkeletonType.recipes;

  const PageSkeleton.settings({
    super.key,
    this.duration = const Duration(milliseconds: 1550),
  }) : type = PageSkeletonType.settings;

  const PageSkeleton.aiFoodAnalysis({
    super.key,
    this.duration = const Duration(milliseconds: 1600),
  }) : type = PageSkeletonType.aiFoodAnalysis;

  final PageSkeletonType type;
  final Duration duration;

  @override
  State<PageSkeleton> createState() => _PageSkeletonState();
}

class _PageSkeletonState extends State<PageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Loading page content',
    child: ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        child: _layout(context),
        builder:
            (context, child) => ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                final position = -1.7 + (_controller.value * 3.4);
                return LinearGradient(
                  begin: Alignment(position, 0),
                  end: Alignment(position + .9, 0),
                  colors: [
                    context.appMutedSurface,
                    context.appElevatedSurface,
                    context.appMutedSurface,
                  ],
                  stops: const [0, .5, 1],
                ).createShader(bounds);
              },
              child: child,
            ),
      ),
    ),
  );

  Widget _layout(BuildContext context) => switch (widget.type) {
    PageSkeletonType.home => const _HomePlaceholder(),
    PageSkeletonType.meals => const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBox(height: 54, radius: 27),
        SizedBox(height: 14),
        _MealCategoryPlaceholder(),
        SizedBox(height: 22),
        _SkeletonBox(height: 205, radius: 17),
        SizedBox(height: 10),
        Center(child: _SkeletonBox(width: 42, height: 7, radius: 4)),
        SizedBox(height: 23),
        _MealGridPlaceholder(),
      ],
    ),
    PageSkeletonType.allMeals => const _MealGridPlaceholder(),
    PageSkeletonType.foodDetail => const _FoodDetailPlaceholder(),
    PageSkeletonType.foodDetailContent => const _FoodDetailContentPlaceholder(),
    PageSkeletonType.profile => const _ProfilePlaceholder(),
    PageSkeletonType.wellness => const _WellnessPlaceholder(),
    PageSkeletonType.notifications => const _NotificationsPlaceholder(),
    PageSkeletonType.favorites => const _FavoritesPlaceholder(),
    PageSkeletonType.community => const _CommunityPlaceholder(),
    PageSkeletonType.communityPost => const _CommunityPostDetailPlaceholder(),
    PageSkeletonType.comments => const _CommentsPlaceholder(),
    PageSkeletonType.communityPeople => const _CommunityPeoplePlaceholder(),
    PageSkeletonType.recipes => const _RecipesPlaceholder(),
    PageSkeletonType.settings => const _SettingsPlaceholder(),
    PageSkeletonType.aiFoodAnalysis => const _AiFoodAnalysisPlaceholder(),
  };
}

class _WellnessPlaceholder extends StatelessWidget {
  const _WellnessPlaceholder();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const summary = _SkeletonCard(height: 210);
        const aiCards = Column(
          children: [
            _SkeletonCard(height: 120),
            SizedBox(height: 16),
            _TextLines(widths: [.45, .92, .78]),
          ],
        );

        if (constraints.maxWidth < 820) {
          return const Column(
            children: [summary, SizedBox(height: 16), aiCards],
          );
        }

        return const Row(
          key: ValueKey<String>('wellness-skeleton-tablet-layout'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: summary),
            SizedBox(width: 20),
            Expanded(flex: 6, child: aiCards),
          ],
        );
      },
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SkeletonBox(width: 72, height: 13, radius: 7),
      SizedBox(height: 10),
      _SkeletonCard(height: 145),
      SizedBox(height: 21),
      _SkeletonBox(width: 92, height: 13, radius: 7),
      SizedBox(height: 10),
      _SkeletonCard(height: 145),
      SizedBox(height: 21),
      _SkeletonBox(width: 64, height: 13, radius: 7),
      SizedBox(height: 10),
      _SkeletonCard(height: 145),
    ],
  );
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const search = _SkeletonBox(height: 48, radius: 24);
      if (constraints.maxWidth < AppSpacing.twoColumnBreakpoint) {
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            search,
            SizedBox(height: 18),
            _TextLines(widths: [.56, .82]),
            SizedBox(height: 18),
            _SkeletonCard(height: 150),
            SizedBox(height: 16),
            _SkeletonCard(height: 190),
          ],
        );
      }

      return const Column(
        key: ValueKey<String>('home-skeleton-tablet-layout'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          search,
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _SkeletonCard(height: 150),
                    SizedBox(height: 16),
                    _SkeletonCard(height: 190),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _SkeletonCard(height: 272),
                    SizedBox(height: 16),
                    _SkeletonCard(height: 120),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, required this.height, this.radius = 14});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.appMutedSurface,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _TextLines extends StatelessWidget {
  const _TextLines({required this.widths});

  final List<double> widths;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var index = 0; index < widths.length; index++) ...[
        FractionallySizedBox(
          widthFactor: widths[index],
          child: const _SkeletonBox(height: 13, radius: 7),
        ),
        if (index != widths.length - 1) const SizedBox(height: 10),
      ],
    ],
  );
}

class _ProfileHeaderPlaceholder extends StatelessWidget {
  const _ProfileHeaderPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      _SkeletonBox(width: 82, height: 82, radius: 41),
      SizedBox(height: 13),
      _SkeletonBox(width: 150, height: 17, radius: 9),
      SizedBox(height: 9),
      _SkeletonBox(width: 205, height: 12, radius: 6),
    ],
  );
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const overview = Column(
        children: [
          _ProfileHeaderPlaceholder(),
          SizedBox(height: 16),
          _MetricRow(),
          SizedBox(height: 14),
          _SkeletonCard(height: 120),
        ],
      );
      const feed = Column(
        children: [
          _SkeletonCard(height: 150),
          SizedBox(height: 14),
          _CommunityPostPlaceholder(),
        ],
      );

      if (constraints.maxWidth < 820) {
        return const Column(children: [overview, SizedBox(height: 14), feed]);
      }

      return const Row(
        key: ValueKey<String>('profile-skeleton-tablet-layout'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: overview),
          SizedBox(width: 20),
          Expanded(child: feed),
        ],
      );
    },
  );
}

class _MetricRow extends StatelessWidget {
  const _MetricRow();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: _SkeletonBox(height: 82, radius: 17)),
      SizedBox(width: 10),
      Expanded(child: _SkeletonBox(height: 82, radius: 17)),
      SizedBox(width: 10),
      Expanded(child: _SkeletonBox(height: 82, radius: 17)),
    ],
  );
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: height,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: context.appSurface.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.appBorder),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FractionallySizedBox(
          widthFactor: .48,
          child: _SkeletonBox(height: 15, radius: 8),
        ),
        SizedBox(height: 11),
        FractionallySizedBox(
          widthFactor: .76,
          child: _SkeletonBox(height: 12, radius: 6),
        ),
        Spacer(),
        FractionallySizedBox(
          widthFactor: .9,
          child: _SkeletonBox(height: 38, radius: 13),
        ),
      ],
    ),
  );
}

class _MealCategoryPlaceholder extends StatelessWidget {
  const _MealCategoryPlaceholder();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _SkeletonBox(width: 56, height: 36, radius: 16),
      SizedBox(width: 8),
      _SkeletonBox(width: 94, height: 36, radius: 16),
      SizedBox(width: 8),
      _SkeletonBox(width: 72, height: 36, radius: 16),
      SizedBox(width: 8),
      Expanded(child: _SkeletonBox(height: 36, radius: 16)),
    ],
  );
}

class _MealGridPlaceholder extends StatelessWidget {
  const _MealGridPlaceholder();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = switch (constraints.maxWidth) {
        < 330 => 2,
        < AppSpacing.tabletBreakpoint => 3,
        < 840 => 4,
        _ => 5,
      };
      return GridView.builder(
        key: const ValueKey<String>('meal-skeleton-grid'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: columns * 2,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 16,
          childAspectRatio: columns == 2 ? .72 : .67,
        ),
        itemBuilder: (_, _) => const _MealCardPlaceholder(),
      );
    },
  );
}

class _MealCardPlaceholder extends StatelessWidget {
  const _MealCardPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _SkeletonBox(height: 96, radius: 14)),
      SizedBox(height: 8),
      _SkeletonBox(height: 11, radius: 6),
      SizedBox(height: 6),
      FractionallySizedBox(
        widthFactor: .72,
        child: _SkeletonBox(height: 11, radius: 6),
      ),
      SizedBox(height: 10),
      FractionallySizedBox(
        widthFactor: .5,
        child: _SkeletonBox(height: 10, radius: 5),
      ),
    ],
  );
}

class _NotificationsPlaceholder extends StatelessWidget {
  const _NotificationsPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SkeletonBox(width: 42, height: 13, radius: 7),
      SizedBox(height: 9),
      _NotificationTilePlaceholder(),
      SizedBox(height: 7),
      _NotificationTilePlaceholder(),
      SizedBox(height: 15),
      _SkeletonBox(width: 52, height: 13, radius: 7),
      SizedBox(height: 9),
      _NotificationTilePlaceholder(),
      SizedBox(height: 7),
      _NotificationTilePlaceholder(),
      SizedBox(height: 15),
      _SkeletonBox(width: 48, height: 13, radius: 7),
      SizedBox(height: 9),
      _NotificationTilePlaceholder(),
    ],
  );
}

class _NotificationTilePlaceholder extends StatelessWidget {
  const _NotificationTilePlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: context.appSurface.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      children: [
        _SkeletonBox(width: 43, height: 43, radius: 22),
        SizedBox(width: 11),
        Expanded(child: _TextLines(widths: [.88, .42])),
        SizedBox(width: 12),
        _SkeletonBox(width: 6, height: 6, radius: 3),
      ],
    ),
  );
}

class _FavoritesPlaceholder extends StatelessWidget {
  const _FavoritesPlaceholder();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = switch (constraints.maxWidth) {
        < 330 => 2,
        < AppSpacing.tabletBreakpoint => 3,
        _ => 4,
      };
      return GridView.builder(
        key: const ValueKey<String>('favorites-skeleton-grid'),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: 6,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 8,
          mainAxisSpacing: 10,
          childAspectRatio: .68,
        ),
        itemBuilder: (_, _) => const _FavoriteCardPlaceholder(),
      );
    },
  );
}

class _FavoriteCardPlaceholder extends StatelessWidget {
  const _FavoriteCardPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _SkeletonBox(height: 130, radius: 16)),
      SizedBox(height: 8),
      _SkeletonBox(height: 12, radius: 6),
      SizedBox(height: 6),
      FractionallySizedBox(
        widthFactor: .68,
        child: _SkeletonBox(height: 10, radius: 5),
      ),
    ],
  );
}

class _CommunityPlaceholder extends StatelessWidget {
  const _CommunityPlaceholder();

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppSpacing.maxWideContentWidth,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 820) {
            return const Column(
              children: [
                _CommunityPostPlaceholder(),
                SizedBox(height: 14),
                _CommunityPostPlaceholder(),
              ],
            );
          }

          return const Row(
            key: ValueKey<String>('community-skeleton-tablet-layout'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 290, child: _CommunityControlsPlaceholder()),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _CommunityPostPlaceholder(),
                    SizedBox(height: 14),
                    _CommunityPostPlaceholder(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _CommunityControlsPlaceholder extends StatelessWidget {
  const _CommunityControlsPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      _SkeletonCard(height: 150),
      SizedBox(height: 14),
      _SkeletonBox(height: 40, radius: 20),
      SizedBox(height: 10),
      _SkeletonBox(height: 44, radius: 15),
    ],
  );
}

class _CommunityPostPlaceholder extends StatelessWidget {
  const _CommunityPostPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: 286,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.appSurface.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: context.appBorder),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SkeletonBox(width: 44, height: 44, radius: 22),
            SizedBox(width: 11),
            Expanded(child: _TextLines(widths: [.48, .28])),
          ],
        ),
        SizedBox(height: 14),
        _TextLines(widths: [.62, .94, .76]),
        SizedBox(height: 14),
        Expanded(child: _SkeletonBox(height: 150, radius: 18)),
        SizedBox(height: 12),
        _SkeletonBox(height: 34, radius: 17),
      ],
    ),
  );
}

class _FoodDetailPlaceholder extends StatelessWidget {
  const _FoodDetailPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SkeletonBox(width: 42, height: 42, radius: 21),
          _SkeletonBox(width: 42, height: 42, radius: 21),
        ],
      ),
      SizedBox(height: 14),
      _SkeletonBox(height: 220, radius: 24),
      SizedBox(height: 20),
      _SkeletonBox(width: 180, height: 22, radius: 11),
      SizedBox(height: 10),
      Row(
        children: [
          _SkeletonBox(width: 65, height: 28, radius: 14),
          SizedBox(width: 8),
          _SkeletonBox(width: 85, height: 28, radius: 14),
        ],
      ),
      SizedBox(height: 18),
      _TextLines(widths: [.94, .82, .6]),
      SizedBox(height: 20),
      Row(
        children: [
          Expanded(child: _SkeletonBox(height: 72, radius: 16)),
          SizedBox(width: 10),
          Expanded(child: _SkeletonBox(height: 72, radius: 16)),
          SizedBox(width: 10),
          Expanded(child: _SkeletonBox(height: 72, radius: 16)),
        ],
      ),
      SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _SkeletonBox(height: 52, radius: 14)),
          SizedBox(width: 10),
          Expanded(child: _SkeletonBox(height: 52, radius: 14)),
        ],
      ),
      SizedBox(height: 22),
      _SkeletonBox(height: 44, radius: 22),
      SizedBox(height: 18),
      _FoodDetailContentPlaceholder(),
    ],
  );
}

class _FoodDetailContentPlaceholder extends StatelessWidget {
  const _FoodDetailContentPlaceholder();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < 4; i++) ...[
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.appSurface.withValues(alpha: .82),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              _SkeletonBox(width: 34, height: 34, radius: 17),
              SizedBox(width: 12),
              Expanded(child: _TextLines(widths: [.72, .38])),
            ],
          ),
        ),
        if (i < 3) const SizedBox(height: 10),
      ],
    ],
  );
}

class _CommunityPostDetailPlaceholder extends StatelessWidget {
  const _CommunityPostDetailPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _CommunityPostPlaceholder(),
      SizedBox(height: 22),
      _SkeletonBox(width: 120, height: 16, radius: 8),
      SizedBox(height: 14),
      _CommentItemPlaceholder(),
      SizedBox(height: 12),
      _CommentItemPlaceholder(),
      SizedBox(height: 12),
      _CommentItemPlaceholder(),
    ],
  );
}

class _CommentsPlaceholder extends StatelessWidget {
  const _CommentsPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SkeletonCard(height: 110),
      SizedBox(height: 20),
      _SkeletonBox(width: 110, height: 16, radius: 8),
      SizedBox(height: 14),
      _CommentItemPlaceholder(),
      SizedBox(height: 12),
      _CommentItemPlaceholder(),
      SizedBox(height: 12),
      _CommentItemPlaceholder(),
    ],
  );
}

class _CommentItemPlaceholder extends StatelessWidget {
  const _CommentItemPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.appSurface.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.appBorder),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBox(width: 38, height: 38, radius: 19),
        SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: 90, height: 12, radius: 6),
              SizedBox(height: 8),
              _TextLines(widths: [.92, .6]),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CommunityPeoplePlaceholder extends StatelessWidget {
  const _CommunityPeoplePlaceholder();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < 5; i++) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.appSurface.withValues(alpha: .82),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.appBorder),
          ),
          child: const Row(
            children: [
              _SkeletonBox(width: 48, height: 48, radius: 24),
              SizedBox(width: 12),
              Expanded(child: _TextLines(widths: [.52, .32])),
              SizedBox(width: 10),
              _SkeletonBox(width: 78, height: 34, radius: 17),
            ],
          ),
        ),
        if (i < 4) const SizedBox(height: 10),
      ],
    ],
  );
}

class _RecipesPlaceholder extends StatelessWidget {
  const _RecipesPlaceholder();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < 3; i++) ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appSurface.withValues(alpha: .82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appBorder),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SkeletonBox(width: 38, height: 38, radius: 19),
                  SizedBox(width: 10),
                  Expanded(child: _TextLines(widths: [.45, .28])),
                  Spacer(),
                  _SkeletonBox(width: 24, height: 24, radius: 12),
                ],
              ),
              SizedBox(height: 12),
              _SkeletonBox(height: 150, radius: 16),
              SizedBox(height: 12),
              _TextLines(widths: [.88, .62]),
              SizedBox(height: 12),
              Row(
                children: [
                  _SkeletonBox(width: 80, height: 32, radius: 16),
                  SizedBox(width: 8),
                  _SkeletonBox(width: 70, height: 32, radius: 16),
                ],
              ),
            ],
          ),
        ),
        if (i < 2) const SizedBox(height: 14),
      ],
    ],
  );
}

class _AiFoodAnalysisPlaceholder extends StatelessWidget {
  const _AiFoodAnalysisPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SkeletonBox(width: 140, height: 16, radius: 8),
      SizedBox(height: 12),
      _SkeletonCard(height: 130),
      SizedBox(height: 12),
      _SkeletonCard(height: 160),
      SizedBox(height: 12),
      _SkeletonCard(height: 110),
    ],
  );
}
