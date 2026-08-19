import 'package:flutter/material.dart';

import '../../models/favorite_post.dart';

class FavoritePostCard extends StatelessWidget {
  const FavoritePostCard({super.key, required this.post, required this.onRemove});

  final FavoritePost post;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _authorHeader(),
          Text(post.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(post.body, style: const TextStyle(fontSize: 11, color: Color(0xFF666666), height: 1.25)),
          const SizedBox(height: 7),
          const Wrap(spacing: 7, runSpacing: 4, children: [_Tag('#HealthyMeal'), _Tag('#HighProtein')]),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1.75,
              child: Image.asset(
                post.image,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFFEAF4EE),
                  child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Metric(Icons.favorite_rounded, _short(post.likes), const Color(0xFFFF5364)),
              _Metric(Icons.chat_bubble_outline_rounded, '${post.comments}', Colors.grey),
              _Metric(Icons.reply_rounded, '${post.shares}', Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _authorHeader() {
    return Row(
      children: [
        const CircleAvatar(radius: 22, backgroundImage: AssetImage('assets/images/profile/profile.jpg')),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text('${post.timeAgo}  •  ${post.role}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(width: 4),
        const Text('Following', style: TextStyle(fontSize: 9, color: Colors.grey)),
        SizedBox(
          width: 32,
          height: 36,
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            iconSize: 20,
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (_) => onRemove(),
            itemBuilder: (_) => const [PopupMenuItem(value: 'remove', child: Text('Remove from favorites'))],
          ),
        ),
      ],
    );
  }

  static String _short(int value) => value >= 1000 ? '${value ~/ 1000}k' : '$value';
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFE6F7EB), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: Color(0xFF0AA653), fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
