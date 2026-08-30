import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';

void main() {
  test('reads relationship flags from the community API response', () {
    final post = CommunityPost.fromJson({
      'id': 42,
      'description': 'A followed member post',
      'imageUrl': '',
      'author': 'Community member',
      'role': 'USER',
      'followingAuthor': true,
      'liked': true,
      'saved': true,
    });

    expect(post.isFollowingAuthor, isTrue);
    expect(post.isLiked, isTrue);
    expect(post.isSaved, isTrue);
  });

  test('continues to read normalized Flutter relationship flags', () {
    final post = CommunityPost.fromJson({
      'id': 43,
      'description': 'A local post',
      'imageUrl': '',
      'author': 'Community member',
      'role': 'USER',
      'isFollowingAuthor': true,
      'isLiked': true,
      'isSaved': true,
    });

    expect(post.isFollowingAuthor, isTrue);
    expect(post.isLiked, isTrue);
    expect(post.isSaved, isTrue);
  });
}
