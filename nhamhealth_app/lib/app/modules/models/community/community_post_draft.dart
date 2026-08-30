import 'dart:typed_data';

import 'community_post.dart';

/// The validated input collected by the community post editor.
///
/// Keeping this value object in the model layer lets controllers process an
/// edit without depending on a Flutter page class.
class CommunityPostDraft {
  const CommunityPostDraft({
    required this.description,
    required this.imageBytes,
    required this.removeImage,
    required this.visibility,
    required this.allowComments,
    required this.allowReplies,
    required this.tagIds,
  });

  final String description;
  final List<Uint8List> imageBytes;
  final bool removeImage;
  final CommunityPostVisibility visibility;
  final bool allowComments;
  final bool allowReplies;
  final List<int> tagIds;
}
