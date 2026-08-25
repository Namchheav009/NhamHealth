import 'community_comment.dart';

/// Formats the visible addressee placed at the start of a reply, similar to
/// Facebook's reply composer.
class CommunityReplyAddress {
  CommunityReplyAddress._(this.displayName);

  factory CommunityReplyAddress.fromComment(CommunityComment comment) {
    final normalizedName = comment.author.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return CommunityReplyAddress._(
      normalizedName.isEmpty ? 'Community member' : normalizedName,
    );
  }

  final String displayName;

  String get prefix => '@$displayName ';

  String applyTo(String text, {CommunityReplyAddress? replacing}) {
    var message = text;
    if (replacing != null) {
      message = replacing.removeFrom(message);
    }
    if (message.startsWith(prefix)) return message;
    return '$prefix${message.trimLeft()}';
  }

  String removeFrom(String text) =>
      text.startsWith(prefix) ? text.substring(prefix.length) : text;
}
