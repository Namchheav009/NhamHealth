import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum PageSkeletonType { home, profile, wellness }

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

  const PageSkeleton.wellness({
    super.key,
    this.duration = const Duration(milliseconds: 1650),
  }) : type = PageSkeletonType.wellness;

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
        _AvatarRow(),
        SizedBox(height: 18),
        _SkeletonBox(height: 48, radius: 24),
        SizedBox(height: 18),
        _TextLines(widths: [.56, .82]),
        SizedBox(height: 18),
        _SkeletonCard(height: 150),
        SizedBox(height: 16),
        _SkeletonCard(height: 190),
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

class _AvatarRow extends StatelessWidget {
  const _AvatarRow();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _SkeletonBox(width: 54, height: 54, radius: 27),
      SizedBox(width: 14),
      Expanded(child: _TextLines(widths: [.62, .38])),
      SizedBox(width: 14),
      _SkeletonBox(width: 40, height: 40, radius: 20),
      SizedBox(width: 9),
      _SkeletonBox(width: 40, height: 40, radius: 20),
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
