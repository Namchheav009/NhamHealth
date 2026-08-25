import 'package:flutter/material.dart';

import '../../../models/community/community_post.dart';

class CommunitySharedPostCard extends StatelessWidget {
  const CommunitySharedPostCard({
    required this.post,
    this.onTap,
    this.compact = false,
    super.key,
  });

  final CommunitySharedPost post;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFBFDFC),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFDDE6E0)),
    ),
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
            child: Row(
              children: [
                CircleAvatar(
                  radius: compact ? 18 : 20,
                  backgroundColor: const Color(0xFFEAF7EE),
                  backgroundImage:
                      post.authorAvatarUrl.isEmpty
                          ? null
                          : NetworkImage(post.authorAvatarUrl),
                  child:
                      post.authorAvatarUrl.isEmpty
                          ? const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF08A936),
                            size: 20,
                          )
                          : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF18231C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${post.ageLabel}  ·  ${post.role}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF778078),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (post.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 13),
              child: Text(
                post.description,
                maxLines: compact ? 4 : null,
                overflow: compact ? TextOverflow.ellipsis : null,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF505951),
                ),
              ),
            ),
          if (post.imageUrls.isNotEmpty || post.imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: compact ? 2 : 1.7,
              child: PageView(
                children: (post.imageUrls.isNotEmpty
                        ? post.imageUrls
                        : [post.imageUrl])
                    .map(
                      (url) => Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, _, _) => const ColoredBox(
                              color: Color(0xFFEAF7EE),
                              child: Center(
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
        ],
      ),
    ),
  );
}
