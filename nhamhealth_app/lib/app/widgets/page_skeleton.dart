import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  reports,
  reportDetail,
  aiFoodAnalysis,
  mealPlanner,
  plannerCategories,
  plannerMeals,
  plannerDetail,
  plannerWeek,
  plannerGrocery,
  plannerSlots,
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

  const PageSkeleton.reports({
    super.key,
    this.duration = const Duration(milliseconds: 1500),
  }) : type = PageSkeletonType.reports;

  const PageSkeleton.reportDetail({
    super.key,
    this.duration = const Duration(milliseconds: 1550),
  }) : type = PageSkeletonType.reportDetail;

  const PageSkeleton.aiFoodAnalysis({
    super.key,
    this.duration = const Duration(milliseconds: 1600),
  }) : type = PageSkeletonType.aiFoodAnalysis;

  const PageSkeleton.mealPlanner({
    super.key,
    this.duration = const Duration(milliseconds: 1550),
  }) : type = PageSkeletonType.mealPlanner;

  const PageSkeleton.plannerCategories({
    super.key,
    this.duration = const Duration(milliseconds: 1550),
  }) : type = PageSkeletonType.plannerCategories;

  const PageSkeleton.plannerMeals({
    super.key,
    this.duration = const Duration(milliseconds: 1550),
  }) : type = PageSkeletonType.plannerMeals;

  const PageSkeleton.plannerDetail({
    super.key,
    this.duration = const Duration(milliseconds: 1550),
  }) : type = PageSkeletonType.plannerDetail;

  const PageSkeleton.plannerWeek({
    super.key,
    this.duration = const Duration(milliseconds: 1550),
  }) : type = PageSkeletonType.plannerWeek;

  const PageSkeleton.plannerGrocery({
    super.key,
    this.duration = const Duration(milliseconds: 1550),
  }) : type = PageSkeletonType.plannerGrocery;

  const PageSkeleton.plannerSlots({
    super.key,
    this.duration = const Duration(milliseconds: 1550),
  }) : type = PageSkeletonType.plannerSlots;

  static Widget box({
    Key? key,
    double? width,
    required double height,
    double radius = 14,
    Duration duration = const Duration(milliseconds: 1550),
  }) => PageSkeletonBox(
    key: key,
    width: width,
    height: height,
    radius: radius,
    duration: duration,
  );

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
    label: 'common.loading_page'.tr,
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
    PageSkeletonType.reports => const _ReportsPlaceholder(),
    PageSkeletonType.reportDetail => const _ReportDetailPlaceholder(),
    PageSkeletonType.aiFoodAnalysis => const _AiFoodAnalysisPlaceholder(),
    PageSkeletonType.mealPlanner => const _MealPlannerPlaceholder(),
    PageSkeletonType.plannerCategories => const _PlannerCategoriesPlaceholder(),
    PageSkeletonType.plannerMeals => const _PlannerMealsPlaceholder(),
    PageSkeletonType.plannerDetail => const _PlannerDetailPlaceholder(),
    PageSkeletonType.plannerWeek => const _PlannerWeekPlaceholder(),
    PageSkeletonType.plannerGrocery => const _PlannerGroceryPlaceholder(),
    PageSkeletonType.plannerSlots => const _PlannerSlotsPlaceholder(),
  };
}

class PageSkeletonBox extends StatefulWidget {
  const PageSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 14,
    this.duration = const Duration(milliseconds: 1550),
  });

  final double? width;
  final double height;
  final double radius;
  final Duration duration;

  @override
  State<PageSkeletonBox> createState() => _PageSkeletonBoxState();
}

class _PageSkeletonBoxState extends State<PageSkeletonBox>
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
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
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: context.appMutedSurface,
              borderRadius: BorderRadius.circular(widget.radius),
            ),
          ),
        ),
  );
}

class _MealPlannerPlaceholder extends StatelessWidget {
  const _MealPlannerPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    key: ValueKey<String>('meal-planner-skeleton'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SkeletonCard(height: 142),
      SizedBox(height: 16),
      _SkeletonCard(height: 126),
      SizedBox(height: 20),
      _SkeletonBox(width: 150, height: 18, radius: 9),
      SizedBox(height: 12),
      _SkeletonCard(height: 112),
      SizedBox(height: 12),
      _SkeletonCard(height: 112),
      SizedBox(height: 12),
      _SkeletonCard(height: 112),
      SizedBox(height: 12),
      _SkeletonCard(height: 112),
    ],
  );
}

class _PlannerCategoriesPlaceholder extends StatelessWidget {
  const _PlannerCategoriesPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    key: ValueKey<String>('planner-categories-skeleton'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SkeletonBox(height: 52, radius: 16),
      SizedBox(height: 14),
      _SkeletonChipRow(),
      SizedBox(height: 22),
      _SkeletonBox(width: 170, height: 18, radius: 9),
      SizedBox(height: 14),
      Row(
        children: [
          Expanded(child: _SkeletonCard(height: 158)),
          SizedBox(width: 12),
          Expanded(child: _SkeletonCard(height: 158)),
        ],
      ),
      SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _SkeletonCard(height: 158)),
          SizedBox(width: 12),
          Expanded(child: _SkeletonCard(height: 158)),
        ],
      ),
    ],
  );
}

class _PlannerMealsPlaceholder extends StatelessWidget {
  const _PlannerMealsPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    key: ValueKey<String>('planner-meals-skeleton'),
    children: [
      _SkeletonBox(height: 52, radius: 16),
      SizedBox(height: 12),
      _SkeletonChipRow(),
      SizedBox(height: 18),
      _SkeletonCard(height: 106),
      SizedBox(height: 12),
      _SkeletonCard(height: 106),
      SizedBox(height: 12),
      _SkeletonCard(height: 106),
      SizedBox(height: 12),
      _SkeletonCard(height: 106),
    ],
  );
}

class _PlannerDetailPlaceholder extends StatelessWidget {
  const _PlannerDetailPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    key: ValueKey<String>('planner-detail-skeleton'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SkeletonBox(height: 260, radius: 24),
      SizedBox(height: 20),
      _SkeletonBox(width: 230, height: 24, radius: 12),
      SizedBox(height: 10),
      _SkeletonBox(width: 150, height: 14, radius: 7),
      SizedBox(height: 20),
      _SkeletonCard(height: 92),
      SizedBox(height: 18),
      _SkeletonBox(width: 120, height: 18, radius: 9),
      SizedBox(height: 12),
      _SkeletonCard(height: 150),
    ],
  );
}

class _PlannerWeekPlaceholder extends StatelessWidget {
  const _PlannerWeekPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    key: ValueKey<String>('planner-week-skeleton'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SkeletonCard(height: 92),
      SizedBox(height: 16),
      _SkeletonCard(height: 90),
      SizedBox(height: 18),
      _SkeletonBox(width: 120, height: 18, radius: 9),
      SizedBox(height: 12),
      _SkeletonCard(height: 126),
      SizedBox(height: 12),
      _SkeletonCard(height: 126),
      SizedBox(height: 12),
      _SkeletonCard(height: 126),
    ],
  );
}

class _PlannerGroceryPlaceholder extends StatelessWidget {
  const _PlannerGroceryPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    key: ValueKey<String>('planner-grocery-skeleton'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SkeletonCard(height: 92),
      SizedBox(height: 20),
      _SkeletonBox(width: 110, height: 18, radius: 9),
      SizedBox(height: 12),
      _SkeletonCard(height: 178),
      SizedBox(height: 18),
      _SkeletonBox(width: 130, height: 18, radius: 9),
      SizedBox(height: 12),
      _SkeletonCard(height: 142),
    ],
  );
}

class _PlannerSlotsPlaceholder extends StatelessWidget {
  const _PlannerSlotsPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    key: ValueKey<String>('planner-slots-skeleton'),
    children: [
      _PlannerSlotCardSkeleton(),
      SizedBox(height: 12),
      _PlannerSlotCardSkeleton(),
      SizedBox(height: 12),
      _PlannerSlotCardSkeleton(),
      SizedBox(height: 12),
      _PlannerSlotCardSkeleton(),
    ],
  );
}

class _PlannerSlotCardSkeleton extends StatelessWidget {
  const _PlannerSlotCardSkeleton();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: context.appElevatedSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.appBorder.withValues(alpha: 0.8)),
    ),
    child: const Row(
      children: [
        _SkeletonBox(width: 60, height: 60, radius: 14),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SkeletonBox(width: 72, height: 12, radius: 6),
              SizedBox(height: 7),
              _SkeletonBox(width: 140, height: 15, radius: 7),
              SizedBox(height: 7),
              _SkeletonBox(width: 110, height: 11, radius: 5),
            ],
          ),
        ),
        SizedBox(width: 8),
        _SkeletonBox(width: 24, height: 24, radius: 12),
      ],
    ),
  );
}

class _SkeletonChipRow extends StatelessWidget {
  const _SkeletonChipRow();

  @override
  Widget build(BuildContext context) => Row(
    children: const [
      _SkeletonBox(width: 64, height: 34, radius: 17),
      SizedBox(width: 8),
      _SkeletonBox(width: 86, height: 34, radius: 17),
      SizedBox(width: 8),
      Expanded(child: _SkeletonBox(height: 34, radius: 17)),
    ],
  );
}

class _ReportsPlaceholder extends StatelessWidget {
  const _ReportsPlaceholder();

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>('reports-skeleton'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        height: 104,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appSurface.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appBorder),
        ),
        child: const Row(
          children: [
            _SkeletonBox(width: 42, height: 42, radius: 21),
            SizedBox(width: 12),
            Expanded(child: _TextLines(widths: [.58, .94, .72])),
            SizedBox(width: 12),
            _SkeletonBox(width: 32, height: 32, radius: 16),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            _SkeletonBox(width: 72, height: 34, radius: 17),
            SizedBox(width: 8),
            _SkeletonBox(width: 96, height: 34, radius: 17),
            SizedBox(width: 8),
            _SkeletonBox(width: 94, height: 34, radius: 17),
            SizedBox(width: 8),
            _SkeletonBox(width: 110, height: 34, radius: 17),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const _ReportRowPlaceholder(),
      const SizedBox(height: 10),
      const _ReportRowPlaceholder(),
      const SizedBox(height: 10),
      const _ReportRowPlaceholder(),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        height: 70,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appSurface.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.appBorder),
        ),
        child: const Row(
          children: [
            _SkeletonBox(width: 38, height: 38, radius: 19),
            SizedBox(width: 12),
            Expanded(child: _TextLines(widths: [.4, .78])),
            SizedBox(width: 12),
            _SkeletonBox(width: 18, height: 18, radius: 9),
          ],
        ),
      ),
    ],
  );
}

class _ReportRowPlaceholder extends StatelessWidget {
  const _ReportRowPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: 108,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.appSurface.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.appBorder),
    ),
    child: const Row(
      children: [
        _SkeletonBox(width: 44, height: 44, radius: 22),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FractionallySizedBox(
                widthFactor: .58,
                child: _SkeletonBox(height: 14, radius: 7),
              ),
              SizedBox(height: 7),
              FractionallySizedBox(
                widthFactor: .84,
                child: _SkeletonBox(height: 11, radius: 6),
              ),
              SizedBox(height: 7),
              Row(
                children: [
                  _SkeletonBox(width: 68, height: 11, radius: 6),
                  SizedBox(width: 10),
                  _SkeletonBox(width: 62, height: 22, radius: 11),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        _SkeletonBox(width: 18, height: 18, radius: 9),
      ],
    ),
  );
}

class _ReportDetailPlaceholder extends StatelessWidget {
  const _ReportDetailPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('report-detail-skeleton'),
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.appElevatedSurface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.appBorder),
      boxShadow: context.appTileShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            _SkeletonBox(width: 40, height: 40, radius: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: 120, height: 16, radius: 8),
                  SizedBox(height: 6),
                  _SkeletonBox(width: 72, height: 20, radius: 10),
                ],
              ),
            ),
            _SkeletonBox(width: 40, height: 14, radius: 7),
          ],
        ),
        const SizedBox(height: 14),
        const _SkeletonBox(width: 110, height: 12, radius: 6),
        const SizedBox(height: 5),
        const _SkeletonBox(width: 140, height: 12, radius: 6),
        const SizedBox(height: 14),
        Divider(height: 28, color: context.appBorder),
        const _SkeletonBox(width: 110, height: 14, radius: 7),
        const SizedBox(height: 8),
        const _SkeletonBox(width: double.infinity, height: 13, radius: 6),
        const SizedBox(height: 6),
        const FractionallySizedBox(
          widthFactor: .65,
          child: _SkeletonBox(height: 13, radius: 6),
        ),
        const SizedBox(height: 20),
        const _SkeletonBox(width: 130, height: 14, radius: 7),
        const SizedBox(height: 8),
        const _SkeletonBox(width: double.infinity, height: 38, radius: 10),
        const SizedBox(height: 22),
        for (var i = 0; i < 3; i++) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SkeletonBox(width: 14, height: 14, radius: 7),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(
                        width: i == 0 ? 110 : (i == 1 ? 140 : 90),
                        height: 14,
                        radius: 7,
                      ),
                      if (i < 2) ...[
                        const SizedBox(height: 6),
                        _SkeletonBox(
                          width: i == 0 ? 130 : 100,
                          height: 12,
                          radius: 6,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
    decoration: BoxDecoration(
      color: context.appSurface.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.appBorder),
    ),
    child: const Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: _SkeletonBox(width: 84, height: 84, radius: 42),
            ),
            SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 94,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _SkeletonBox(width: 82, height: 36, radius: 18),
                    ),
                    Positioned(
                      left: 0,
                      top: 28,
                      right: 0,
                      child: _TextLines(widths: [.54, .35, .68]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        _ProfileSocialStatsPlaceholder(),
      ],
    ),
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
          SizedBox(height: 8),
          _ProfileHealthStatsPlaceholder(),
          SizedBox(height: 8),
          _ProfileInsightPlaceholder(),
        ],
      );
      const feed = Column(
        children: [
          _ProfileComposerPlaceholder(),
          _ProfileFeedHeaderPlaceholder(),
          SizedBox(height: 10),
          _CommunityPostPlaceholder(),
        ],
      );

      if (constraints.maxWidth < 820) {
        return const Column(children: [overview, SizedBox(height: 8), feed]);
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

class _ProfileSocialStatsPlaceholder extends StatelessWidget {
  const _ProfileSocialStatsPlaceholder();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: _ProfileStatPlaceholder()),
      SizedBox(width: 8),
      Expanded(child: _ProfileStatPlaceholder()),
      SizedBox(width: 8),
      Expanded(child: _ProfileStatPlaceholder()),
    ],
  );
}

class _ProfileStatPlaceholder extends StatelessWidget {
  const _ProfileStatPlaceholder();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _SkeletonBox(width: 32, height: 32, radius: 16),
      SizedBox(width: 5),
      Flexible(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBox(height: 10, radius: 5),
            SizedBox(height: 4),
            FractionallySizedBox(
              widthFactor: .75,
              child: _SkeletonBox(height: 7, radius: 4),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ProfileHealthStatsPlaceholder extends StatelessWidget {
  const _ProfileHealthStatsPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    height: 66,
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
    decoration: BoxDecoration(
      color: context.appSurface.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: context.appBorder),
    ),
    child: const Row(
      children: [
        Expanded(child: _ProfileHealthStatPlaceholder()),
        SizedBox(width: 4),
        Expanded(child: _ProfileHealthStatPlaceholder()),
        SizedBox(width: 4),
        Expanded(child: _ProfileHealthStatPlaceholder()),
        SizedBox(width: 4),
        Expanded(child: _ProfileHealthStatPlaceholder()),
      ],
    ),
  );
}

class _ProfileHealthStatPlaceholder extends StatelessWidget {
  const _ProfileHealthStatPlaceholder();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _SkeletonBox(width: 28, height: 28, radius: 14),
      SizedBox(width: 4),
      Flexible(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBox(height: 6, radius: 3),
            SizedBox(height: 3),
            _SkeletonBox(height: 10, radius: 5),
            SizedBox(height: 3),
            FractionallySizedBox(
              widthFactor: .7,
              child: _SkeletonBox(height: 6, radius: 3),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ProfileInsightPlaceholder extends StatelessWidget {
  const _ProfileInsightPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    height: 76,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: context.appSurface.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.appBorder),
    ),
    child: const Row(
      children: [
        _SkeletonBox(width: 54, height: 54, radius: 27),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FractionallySizedBox(
                widthFactor: .58,
                child: _SkeletonBox(height: 12, radius: 6),
              ),
              SizedBox(height: 6),
              _SkeletonBox(height: 9, radius: 5),
              SizedBox(height: 5),
              FractionallySizedBox(
                widthFactor: .72,
                child: _SkeletonBox(height: 9, radius: 5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileComposerPlaceholder extends StatelessWidget {
  const _ProfileComposerPlaceholder();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Column(
      children: [
        Row(
          children: [
            _SkeletonBox(width: 42, height: 42, radius: 21),
            SizedBox(width: 10),
            Expanded(child: _SkeletonBox(height: 46, radius: 23)),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            _SkeletonBox(width: 94, height: 38, radius: 19),
            SizedBox(width: 8),
            _SkeletonBox(width: 126, height: 38, radius: 19),
          ],
        ),
      ],
    ),
  );
}

class _ProfileFeedHeaderPlaceholder extends StatelessWidget {
  const _ProfileFeedHeaderPlaceholder();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _SkeletonBox(width: 92, height: 18, radius: 9),
      Spacer(),
      _SkeletonBox(width: 62, height: 26, radius: 13),
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
    clipBehavior: Clip.antiAlias,
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
    decoration: BoxDecoration(
      color: context.appSurface.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.appBorder),
    ),
    child: LayoutBuilder(
      builder:
          (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FractionallySizedBox(
                widthFactor: .48,
                child: _SkeletonBox(height: 15, radius: 8),
              ),
              if (constraints.maxHeight > 55) ...[
                const SizedBox(height: 8),
                const FractionallySizedBox(
                  widthFactor: .76,
                  child: _SkeletonBox(height: 12, radius: 6),
                ),
              ],
              if (constraints.maxHeight > 95) ...[
                const Spacer(),
                const FractionallySizedBox(
                  widthFactor: .9,
                  child: _SkeletonBox(height: 38, radius: 13),
                ),
              ],
            ],
          ),
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
        < 600 => 2,
        < 900 => 3,
        _ => 4,
      };
      final spacing = constraints.maxWidth >= 600 ? 12.0 : 10.0;
      final cardWidth =
          (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
      return GridView.builder(
        key: const ValueKey<String>('favorites-skeleton-grid'),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: columns * 3,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          mainAxisExtent: cardWidth * 1.38,
        ),
        itemBuilder: (_, _) => const _FavoriteCardPlaceholder(),
      );
    },
  );
}

class _FavoriteCardPlaceholder extends StatelessWidget {
  const _FavoriteCardPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.appElevatedSurface.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.appBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: _SkeletonBox(height: double.infinity, radius: 0),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: _SkeletonBox(width: 28, height: 28, radius: 14),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(7, 7, 7, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(height: 12, radius: 6),
              SizedBox(height: 6),
              FractionallySizedBox(
                widthFactor: .68,
                child: _SkeletonBox(height: 10, radius: 5),
              ),
            ],
          ),
        ),
      ],
    ),
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
