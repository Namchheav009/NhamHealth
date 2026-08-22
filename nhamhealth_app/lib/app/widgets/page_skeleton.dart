import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum PageSkeletonType {
  home,
  meals,
  profile,
  wellness,
  notifications,
  favorites,
  community,
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
        child: _layout(),
        builder:
            (context, child) => ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                final position = -1.7 + (_controller.value * 3.4);
                return LinearGradient(
                  begin: Alignment(position, 0),
                  end: Alignment(position + .9, 0),
                  colors: const [
                    Color(0xFFE6ECE8),
                    Color(0xFFF9FCFA),
                    Color(0xFFE6ECE8),
                  ],
                  stops: const [0, .5, 1],
                ).createShader(bounds);
              },
              child: child,
            ),
      ),
    ),
  );

  Widget _layout() => switch (widget.type) {
    PageSkeletonType.home => const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBox(height: 48, radius: 24),
        SizedBox(height: 18),
        _TextLines(widths: [.56, .82]),
        SizedBox(height: 18),
        _SkeletonCard(height: 150),
        SizedBox(height: 16),
        _SkeletonCard(height: 190),
      ],
    ),
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
    PageSkeletonType.profile => const Column(
      children: [
        _ProfileHeaderPlaceholder(),
        SizedBox(height: 16),
        _MetricRow(),
        SizedBox(height: 14),
        _SkeletonCard(height: 120),
        SizedBox(height: 14),
        _SkeletonCard(height: 150),
      ],
    ),
    PageSkeletonType.wellness => const Column(
      children: [
        _SkeletonCard(height: 210),
        SizedBox(height: 16),
        _SkeletonCard(height: 120),
        SizedBox(height: 16),
        _TextLines(widths: [.45, .92, .78]),
      ],
    ),
    PageSkeletonType.notifications => const _NotificationsPlaceholder(),
    PageSkeletonType.favorites => const _FavoritesPlaceholder(),
    PageSkeletonType.community => const _CommunityPlaceholder(),
  };
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
      color: const Color(0xFFE6ECE8),
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
      color: AppColors.cardSurface.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2EAE5)),
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
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 6,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 16,
      childAspectRatio: .67,
    ),
    itemBuilder: (_, _) => const _MealCardPlaceholder(),
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
      color: AppColors.cardSurface.withValues(alpha: .72),
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
      final columns = constraints.maxWidth < 330 ? 2 : 3;
      return GridView.builder(
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
  Widget build(BuildContext context) => const Column(
    children: [
      _CommunityPostPlaceholder(),
      SizedBox(height: 14),
      _CommunityPostPlaceholder(),
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
      color: AppColors.cardSurface.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE2EAE5)),
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
