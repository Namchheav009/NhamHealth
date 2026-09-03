import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../models/community/community_person.dart';
import '../../../models/community/community_post.dart';
import '../../../repositories/community/community_repository.dart';

Future<void> showPostLikers(
  BuildContext context, {
  required CommunityPost post,
  required CommunityRepository repository,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder:
      (_) => _PostLikersSheet(
        postId: post.id,
        likeCount: post.likes,
        repository: repository,
      ),
);

class _PostLikersSheet extends StatefulWidget {
  const _PostLikersSheet({
    required this.postId,
    required this.likeCount,
    required this.repository,
  });

  final String postId;
  final int likeCount;
  final CommunityRepository repository;

  @override
  State<_PostLikersSheet> createState() => _PostLikersSheetState();
}

class _PostLikersSheetState extends State<_PostLikersSheet> {
  late Future<List<CommunityPerson>> _likers;

  @override
  void initState() {
    super.initState();
    _likers = widget.repository.getPostLikers(widget.postId);
  }

  void _retry() =>
      setState(() => _likers = widget.repository.getPostLikers(widget.postId));

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .72,
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: context.appMutedText.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              widget.likeCount == 1 ? '1 like' : '${widget.likeCount} likes',
              style: TextStyle(
                color: context.appText,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * .48,
            child: FutureBuilder<List<CommunityPerson>>(
              future: _likers,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _LikersError(onRetry: _retry);
                }
                final likers = snapshot.data ?? const <CommunityPerson>[];
                if (likers.isEmpty) return const _NoLikers();
                return ListView.separated(
                  padding: const EdgeInsets.only(top: 2),
                  itemCount: likers.length,
                  separatorBuilder:
                      (_, _) => Divider(
                        height: 1,
                        indent: 76,
                        color: context.appBorder,
                      ),
                  itemBuilder:
                      (context, index) => _LikerTile(
                        person: likers[index],
                        onTap: () => _openProfile(likers[index]),
                      ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  void _openProfile(CommunityPerson person) {
    final userId = int.tryParse(person.id);
    if (userId == null || userId <= 0) return;
    Navigator.of(context).pop();
    Get.toNamed<void>(AppRoutes.communityPersonProfilePath(userId));
  }
}

class _LikerTile extends StatelessWidget {
  const _LikerTile({required this.person, required this.onTap});

  final CommunityPerson person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = person.name.trim().isEmpty ? 'Community member' : person.name;
    final detail = person.detail?.trim() ?? '';
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: _LikerAvatar(person: person, name: name),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: context.appText,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle:
          detail.isEmpty
              ? null
              : Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.appMutedText, fontSize: 12),
              ),
      trailing: Icon(Icons.chevron_right_rounded, color: context.appMutedText),
    );
  }
}

class _LikerAvatar extends StatelessWidget {
  const _LikerAvatar({required this.person, required this.name});

  final CommunityPerson person;
  final String name;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: context.appSoftGreen,
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return Semantics(
      image: true,
      label: '$name profile photo',
      child: Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: .20),
          ),
        ),
        child: ClipOval(
          child:
              person.avatarUrl.trim().isEmpty
                  ? fallback
                  : Image.network(
                    person.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => fallback,
                  ),
        ),
      ),
    );
  }
}

class _NoLikers extends StatelessWidget {
  const _NoLikers();

  @override
  Widget build(BuildContext context) => Center(
    child: Text('No likes yet.', style: TextStyle(color: context.appMutedText)),
  );
}

class _LikersError extends StatelessWidget {
  const _LikersError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off_rounded, color: context.appMutedText, size: 30),
        const SizedBox(height: 8),
        Text(
          'Could not load likes.',
          style: TextStyle(color: context.appMutedText),
        ),
        const SizedBox(height: 6),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}
