import 'package:flutter/material.dart';

import '../../../../../config/api_config.dart';
import '../../../models/community/community_post.dart';

class ProfilePostCard extends StatelessWidget {
  const ProfilePostCard({
    required this.post,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.membership,
    required this.onEdit,
    required this.onDelete,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    super.key,
  });

  final CommunityPost post;
  final String authorName;
  final String authorAvatarUrl;
  final String membership;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

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
                      authorName,
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
                      '${post.ageLabel}  •  $membership',
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

              IconButton(
                tooltip: 'Post options',
                icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF768178)),
                onPressed: () => _showPostOptions(context),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            post.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.42,
              color: Color(0xFF5E6961),
            ),
          ),

          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: post.tags.map((tag) => _Tag(text: '#$tag')).toList(),
            ),
          ],

          if (post.imageBytes != null || post.imageUrls.isNotEmpty || post.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 15),
            Semantics(
              button: true,
              label: 'View post image full screen',
              child: InkWell(
                onTap: () => _openImageViewer(context),
                borderRadius: BorderRadius.circular(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 218,
                    child: post.imageBytes != null
                        ? Image.memory(
                            post.imageBytes!,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                          )
                        : PageView(
                            children: _imageUrls
                                .map(
                                  (url) => Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.medium,
                                    errorBuilder: (_, _, _) => Container(
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
            ),
          ],

          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFEAF0EC))),
            ),
            child: Row(
              children: [
                _ProfilePostMetric(
                  icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  value: _compactCount(post.likes),
                  color: post.isLiked ? const Color(0xFFE64657) : const Color(0xFF69756D),
                  onTap: onLike,
                ),
                const _ProfileMetricDivider(),
                _ProfilePostMetric(
                  icon: Icons.chat_bubble_outline_rounded,
                  value: _compactCount(post.comments),
                  color: const Color(0xFF69756D),
                  onTap: onComment,
                ),
                const _ProfileMetricDivider(),
                _ProfilePostMetric(
                  icon: Icons.reply_rounded,
                  value: _compactCount(post.shares),
                  color: const Color(0xFF69756D),
                  onTap: onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider<Object>? get _avatarImage {
    final value = authorAvatarUrl.trim();
    if (value.isEmpty) return null;
    final imageUrl = value.startsWith('http://') || value.startsWith('https://')
        ? value
        : '${ApiConfig.baseUrl}${value.startsWith('/') ? '' : '/'}$value';
    return NetworkImage(imageUrl);
  }

  List<String> get _imageUrls =>
      post.imageUrls.isNotEmpty ? post.imageUrls : (post.imageUrl.isEmpty ? const [] : [post.imageUrl]);

  Future<void> _showPostOptions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProfilePostOptionsSheet(),
    );
    if (!context.mounted) return;
    if (action == 'edit') onEdit();
    if (action == 'delete') onDelete();
  }

  String get _initials {
    final words = authorName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  Future<void> _openImageViewer(BuildContext context) => showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    builder: (dialogContext) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: post.imageBytes != null
                  ? Image.memory(post.imageBytes!, fit: BoxFit.contain)
                  : PageView(
                      children: _imageUrls
                          .map(
                            (url) => Image.network(
                              url,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.image_outlined,
                                size: 42,
                                color: Colors.white70,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
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
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
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
  final VoidCallback onTap;

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
            Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
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
    final color = isDestructive ? const Color(0xFFD94545) : const Color(0xFF18231C);
    return ListTile(
      onTap: () => Navigator.of(context).pop(value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      leading: Icon(icon, color: color, size: 27),
      title: Text(label, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
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
