import 'package:flutter/material.dart';

class PageSkeleton extends StatelessWidget {
  const PageSkeleton.home({super.key}) : _type = _SkeletonType.home;
  const PageSkeleton.profile({super.key}) : _type = _SkeletonType.profile;
  const PageSkeleton.wellness({super.key}) : _type = _SkeletonType.wellness;

  final _SkeletonType _type;

  @override
  Widget build(BuildContext context) {
    final children = switch (_type) {
      _SkeletonType.home => const [
        SkeletonAvatarRow(animated: false),
        SizedBox(height: 16),
        _SkeletonBox(height: 44, radius: 22),
        SizedBox(height: 14),
        SkeletonText(animated: false, lines: 2),
        SizedBox(height: 14),
        SkeletonCard(animated: false, mediaHeight: 112),
        SizedBox(height: 14),
        SkeletonCard(animated: false, mediaHeight: 160),
      ],
      _SkeletonType.profile => const [
        SkeletonAvatarRow(animated: false, avatarSize: 68),
        SizedBox(height: 14),
        SkeletonCard(animated: false, mediaHeight: 90),
        SizedBox(height: 10),
        SkeletonText(animated: false, lines: 3),
        SizedBox(height: 10),
        SkeletonCard(animated: false, mediaHeight: 100),
      ],
      _SkeletonType.wellness => const [
        SkeletonCard(animated: false, mediaHeight: 170),
        SizedBox(height: 14),
        SkeletonCard(animated: false, mediaHeight: 85),
        SizedBox(height: 14),
        SkeletonText(animated: false, lines: 4),
      ],
    };
    return _Shimmer(child: Column(children: children));
  }
}

enum _SkeletonType { home, profile, wellness }

class SkeletonAvatarRow extends StatelessWidget {
  const SkeletonAvatarRow({
    super.key,
    this.avatarSize = 52,
    this.animated = true,
  });

  final double avatarSize;
  final bool animated;

  @override
  Widget build(BuildContext context) => _animate(
    animated,
    Row(
      children: [
        _SkeletonBox(
          width: avatarSize,
          height: avatarSize,
          radius: avatarSize / 2,
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FractionallySizedBox(
                widthFactor: .72,
                child: _SkeletonBox(height: 16, radius: 8),
              ),
              SizedBox(height: 9),
              FractionallySizedBox(
                widthFactor: .45,
                child: _SkeletonBox(height: 13, radius: 7),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class SkeletonText extends StatelessWidget {
  const SkeletonText({super.key, this.lines = 4, this.animated = true});

  final int lines;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    const widths = [.66, 1.0, .92, .78, .55];
    return _animate(
      animated,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          lines,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == lines - 1 ? 0 : 9),
            child: FractionallySizedBox(
              widthFactor: widths[index % widths.length],
              child: const _SkeletonBox(height: 14, radius: 7),
            ),
          ),
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.mediaHeight = 150, this.animated = true});

  final double mediaHeight;
  final bool animated;

  @override
  Widget build(BuildContext context) => _animate(
    animated,
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E6E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FractionallySizedBox(
            widthFactor: .72,
            child: _SkeletonBox(height: 16, radius: 8),
          ),
          const SizedBox(height: 9),
          const FractionallySizedBox(
            widthFactor: .48,
            child: _SkeletonBox(height: 13, radius: 7),
          ),
          const SizedBox(height: 16),
          _SkeletonBox(height: mediaHeight, radius: 14),
        ],
      ),
    ),
  );
}

Widget _animate(bool animated, Widget child) =>
    animated ? _Shimmer(child: child) : child;

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, required this.height, this.radius = 16});
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

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder:
        (_, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback:
              (bounds) => LinearGradient(
                begin: Alignment(-1.5 + (_controller.value * 3), 0),
                end: Alignment(-0.5 + (_controller.value * 3), 0),
                colors: const [
                  Color(0xFFE4EAE6),
                  Color(0xFFF7FAF8),
                  Color(0xFFE4EAE6),
                ],
              ).createShader(bounds),
          child: child,
        ),
  );
}
