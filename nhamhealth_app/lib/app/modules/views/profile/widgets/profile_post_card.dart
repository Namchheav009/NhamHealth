import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../../../../../config/api_config.dart';
import '../../../models/community/community_post.dart';

class ProfilePostCard extends StatelessWidget {
  const ProfilePostCard({
    required this.post,
    this.authorName,
    this.authorAvatarUrl,
    this.membership,
    this.onEdit,
    this.onDelete,
    this.onOptions,
    required this.onLike,
    this.isLiking = false,
    required this.onComment,
    super.key,
  });

  final CommunityPost post;
  final String? authorName;
  final String? authorAvatarUrl;
  final String? membership;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onOptions;
  final VoidCallback onLike;
  final bool isLiking;
  final VoidCallback onComment;

  static const green = Color(0xFF009B46);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5ECE7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A173D25),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFEAF7EE),
                foregroundImage: _avatarImage,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: green,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayAuthorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF18231C),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '${post.ageLabel}  •  ${membership ?? post.role}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A857D),
                      ),
                    ),
                  ],
                ),
              ),

              if (onOptions != null || onEdit != null || onDelete != null)
                IconButton(
                  tooltip: 'Post options',
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Color(0xFF768178),
                  ),
                  onPressed: onOptions ?? () => _showPostOptions(context),
                ),
            ],
          ),

          if (post.description.isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              post.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.42,
                color: Color(0xFF5E6961),
              ),
            ),
          ],

          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: post.tags.map((tag) => _Tag(text: '#$tag')).toList(),
            ),
          ],

          if (post.imageBytes != null ||
              post.imageUrls.isNotEmpty ||
              post.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 15),
            _ProfileImageCarousel(
              imageBytes: post.imageBytes,
              imageUrls: _imageUrls,
              onTap: () => _openImageViewer(context),
            ),
          ],

          if (post.likes > 0 || post.comments > 0) ...[
            const SizedBox(height: 11),
            _EngagementSummary(post: post),
          ],
          Container(
            padding: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFEAF0EC))),
            ),
            child: Row(
              children: [
                _ProfilePostMetric(
                  icon:
                      post.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                  value: post.isLiked ? 'Liked' : 'Like',
                  color:
                      post.isLiked
                          ? const Color(0xFFE64657)
                          : const Color(0xFF69756D),
                  onTap: isLiking ? null : onLike,
                ),
                const _ProfileMetricDivider(),
                _ProfilePostMetric(
                  icon: Icons.chat_bubble_outline_rounded,
                  value: 'Comment',
                  color: const Color(0xFF69756D),
                  onTap: onComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider<Object>? get _avatarImage {
    final value = (authorAvatarUrl ?? post.authorAvatarUrl).trim();
    if (value.isEmpty) return null;
    final imageUrl =
        value.startsWith('http://') || value.startsWith('https://')
            ? value
            : '${ApiConfig.baseUrl}${value.startsWith('/') ? '' : '/'}$value';
    return NetworkImage(imageUrl);
  }

  List<String> get _imageUrls =>
      post.imageUrls.isNotEmpty
          ? post.imageUrls
          : (post.imageUrl.isEmpty ? const [] : [post.imageUrl]);

  Future<void> _showPostOptions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProfilePostOptionsSheet(),
    );
    if (!context.mounted) return;
    if (action == 'edit') onEdit?.call();
    if (action == 'delete') onDelete?.call();
  }

  String get _displayAuthorName {
    final value = authorName?.trim() ?? '';
    return value.isEmpty ? post.author : value;
  }

  String get _initials {
    final words = _displayAuthorName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  Future<void> _openImageViewer(BuildContext context) => showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    builder:
        (dialogContext) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child:
                    post.imageBytes != null
                        ? InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4,
                          child: Image.memory(post.imageBytes!, fit: BoxFit.contain),
                        )
                        : _ProfileFullscreenCarousel(
                          imageUrls: _imageUrls,
                        ),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: SafeArea(
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Close image',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
  );
}

String _compactCount(int value) {
  if (value < 1000) return '$value';
  final compact = value / 1000;
  return '${compact == compact.roundToDouble() ? compact.toStringAsFixed(0) : compact.toStringAsFixed(1)}k';
}

class _ProfilePostMetric extends StatelessWidget {
  const _ProfilePostMetric({
    required this.icon,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileMetricDivider extends StatelessWidget {
  const _ProfileMetricDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 18,
    child: VerticalDivider(width: 1, color: Color(0xFFDCE6DF)),
  );
}

class _EngagementSummary extends StatelessWidget {
  const _EngagementSummary({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Row(
      children: [
        if (post.likes > 0) ...[
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFE64657),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _compactCount(post.likes),
            style: const TextStyle(fontSize: 12, color: Color(0xFF69756D)),
          ),
        ],
        const Spacer(),
        if (post.comments > 0)
          Text(
            '${_compactCount(post.comments)} ${post.comments == 1 ? 'comment' : 'comments'}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF69756D)),
          ),
        if (post.comments > 0 && post.shares > 0)
          const Text('  ·  ', style: TextStyle(color: Color(0xFF98A19A))),
        if (post.shares > 0)
          Text(
            '${_compactCount(post.shares)} ${post.shares == 1 ? 'share' : 'shares'}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF69756D)),
          ),
      ],
    ),
  );
}

class _ProfilePostOptionsSheet extends StatelessWidget {
  const _ProfilePostOptionsSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFF9AA19C),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: const [
                _ProfilePostOption(
                  value: 'edit',
                  label: 'Edit post',
                  icon: Icons.edit_outlined,
                ),
                Divider(height: 1, indent: 64, color: Color(0xFFE0E5E1)),
                _ProfilePostOption(
                  value: 'delete',
                  label: 'Delete post',
                  icon: Icons.delete_outline_rounded,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfilePostOption extends StatelessWidget {
  const _ProfilePostOption({
    required this.value,
    required this.label,
    required this.icon,
    this.isDestructive = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? const Color(0xFFD94545) : const Color(0xFF18231C);
    return ListTile(
      onTap: () => Navigator.of(context).pop(value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      title: Text(label, style: TextStyle(color: color, fontSize: 15)),
      leading: Icon(icon, color: color, size: 24),
    );
  }
}

class _ProfileImageCarousel extends StatefulWidget {
  const _ProfileImageCarousel({
    required this.imageBytes,
    required this.imageUrls,
    required this.onTap,
  });

  final Uint8List? imageBytes;
  final List<String> imageUrls;
  final VoidCallback onTap;

  @override
  State<_ProfileImageCarousel> createState() => _ProfileImageCarouselState();
}

class _ProfileImageCarouselState extends State<_ProfileImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.toInt() ?? 0;
      });
    });
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

    return Semantics(
      button: true,
      label: 'View post image full screen',
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: AspectRatio(
                        aspectRatio: 5 / 4,
                        child:
                            widget.imageBytes != null
                                ? Image.memory(
                                  widget.imageBytes!,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.medium,
                                )
                                : PageView(
                                  controller: _pageController,
                                  children: widget.imageUrls
                                      .map(
                                        (url) => Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                          filterQuality: FilterQuality.medium,
                                          errorBuilder:
                                              (_, _, _) => Container(
                                                color: const Color(0xFFF3F7F4),
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
                      ),
                    ),
                  ),
                  // Carousel Counter
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
            // Pagination Dots
            if (showCarousel) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  imageCount,
                  (index) => GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 8 : 6,
                      height: _currentPage == index ? 8 : 6,
                      decoration: BoxDecoration(
                        color:
                            _currentPage == index
                                ? const Color(0xFF1F2937)
                                : const Color(0xFFD1D5DB),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileFullscreenCarousel extends StatefulWidget {
  const _ProfileFullscreenCarousel({required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<_ProfileFullscreenCarousel> createState() =>
      _ProfileFullscreenCarouselState();
}

class _ProfileFullscreenCarouselState extends State<_ProfileFullscreenCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.toInt() ?? 0;
      });
    });
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

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView(
                controller: _pageController,
                children: widget.imageUrls
                    .map(
                      (url) => InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4,
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (_, _, _) => const Icon(
                                Icons.image_outlined,
                                size: 42,
                                color: Colors.white70,
                              ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
              // Carousel Counter
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
        // Pagination Dots
        if (showCarousel) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              imageCount,
              (index) => GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 8 : 6,
                  height: _currentPage == index ? 8 : 6,
                  decoration: BoxDecoration(
                    color:
                        _currentPage == index
                            ? Colors.white
                            : Colors.white54,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F6EA),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: ProfilePostCard.green,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
