import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../../config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/community/community_person.dart';
import '../../models/community/community_comment.dart';
import '../../models/community/community_post.dart';
import '../../models/community/community_tag.dart';
import '../../models/community/community_types.dart';

class CommunityRepository {
  CommunityRepository({required AuthService authService, http.Client? client})
    : _authService = authService,
      _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  Future<List<CommunityPost>> getPosts({bool following = false}) async {
    final payload = await _getList(
      '/api/v1/community/posts?following=$following',
    );
    return payload
        .map((item) => _post(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Map<FriendsView, List<CommunityPerson>>> getPeople() async {
    final results = await Future.wait(FriendsView.values.map(_getPeople));
    return {
      for (var i = 0; i < FriendsView.values.length; i++)
        FriendsView.values[i]: results[i],
    };
  }

  Future<List<CommunityTag>> getTags() async {
    final payload = await _getList('/api/v1/community/tags');
    return payload
        .map((item) => CommunityTag.fromJson(Map<String, dynamic>.from(item as Map)))
        .where((tag) => tag.id > 0 && tag.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<CommunityPost> createPost({
    required String title,
    required String description,
    List<Uint8List> imageBytes = const [],
    CommunityPostVisibility visibility = CommunityPostVisibility.public,
    bool allowComments = true,
    bool allowReplies = true,
    List<int> tagIds = const [],
  }) async {
    final request =
        http.MultipartRequest('POST', _uri('/api/v1/community/posts'))
          ..headers.addAll(await _headers(includeContentType: false))
          ..fields['title'] = title.trim()
          ..fields['description'] = description.trim()
          ..fields['visibility'] = visibility.apiValue
          ..fields['allowComments'] = '$allowComments'
          ..fields['allowReplies'] = '$allowReplies';
    if (tagIds.isNotEmpty) request.fields['tagIds'] = tagIds.join(',');
    for (var index = 0; index < imageBytes.length; index++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          imageBytes[index],
          filename: 'community-post-${index + 1}.jpg',
        ),
      );
    }
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    return _post(_decodeMap(response), justNow: true);
  }

  Future<CommunityPost> updatePost({
    required String postId,
    required String title,
    required String description,
    List<Uint8List> imageBytes = const [],
    CommunityPostVisibility visibility = CommunityPostVisibility.public,
    bool allowComments = true,
    bool allowReplies = true,
    bool removeImage = false,
    List<int> tagIds = const [],
  }) async {
    final request = http.MultipartRequest('PUT', _uri('/api/v1/community/posts/$postId'))
      ..headers.addAll(await _headers(includeContentType: false))
      ..fields['title'] = title.trim()
      ..fields['description'] = description.trim()
      ..fields['visibility'] = visibility.apiValue
      ..fields['allowComments'] = '$allowComments'
      ..fields['allowReplies'] = '$allowReplies'
      ..fields['removeImage'] = '$removeImage';
    if (tagIds.isNotEmpty) request.fields['tagIds'] = tagIds.join(',');
    for (var index = 0; index < imageBytes.length; index++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          imageBytes[index],
          filename: 'community-post-${index + 1}.jpg',
        ),
      );
    }
    final response = await http.Response.fromStream(await _client.send(request));
    return _post(_decodeMap(response));
  }

  Future<void> deletePost(String postId) async {
    final response = await _client.delete(
      _uri('/api/v1/community/posts/$postId'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
  }

  Future<CommunityPost> toggleLike(String postId) async {
    final response = await _client.post(
      _uri('/api/v1/community/posts/$postId/like'),
      headers: await _headers(),
    );
    return _post(_decodeMap(response));
  }

  Future<void> sharePost(
    String postId, {
    List<String> recipientIds = const [],
  }) async {
    final response = await _client.post(
      _uri('/api/v1/community/posts/$postId/share'),
      headers: await _headers(),
      body: jsonEncode({
        'recipientIds': recipientIds.map(int.parse).toList(growable: false),
      }),
    );
    _ensureSuccess(response);
  }

  Future<List<CommunityComment>> getComments(String postId) async {
    final payload = await _getList('/api/v1/community/posts/$postId/comments');
    return payload.map((item) {
      final comment = Map<String, dynamic>.from(item as Map);
      comment['authorAvatarUrl'] = _absoluteUrl(
        '${comment['authorAvatarUrl'] ?? ''}',
      );
      return CommunityComment.fromJson(comment);
    }).toList(growable: false);
  }

  Future<CommunityComment> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/community/posts/$postId/comments'),
      headers: await _headers(),
      body: jsonEncode({
        'text': text.trim(),
        if (parentCommentId != null) 'parentCommentId': int.parse(parentCommentId),
      }),
    );
    final comment = _decodeMap(response);
    comment['authorAvatarUrl'] = _absoluteUrl(
      '${comment['authorAvatarUrl'] ?? ''}',
    );
    return CommunityComment.fromJson(comment);
  }

  Future<CommunityComment> toggleCommentLike(
    String postId,
    String commentId,
  ) async {
    final response = await _client.post(
      _uri('/api/v1/community/posts/$postId/comments/$commentId/like'),
      headers: await _headers(),
    );
    final comment = _decodeMap(response);
    comment['authorAvatarUrl'] = _absoluteUrl(
      '${comment['authorAvatarUrl'] ?? ''}',
    );
    return CommunityComment.fromJson(comment);
  }

  Future<String> toggleFollow(String userId) async {
    final response = await _client.post(
      _uri('/api/v1/community/people/$userId/follow'),
      headers: await _headers(),
    );
    return '${_decodeMap(response)['status'] ?? 'NONE'}';
  }

  CommunityPost _post(Map<String, dynamic> json, {bool justNow = false}) {
    json['imageUrl'] = _absoluteUrl('${json['imageUrl'] ?? ''}');
    json['imageUrls'] = (json['imageUrls'] as List<dynamic>? ?? const [])
        .map((url) => _absoluteUrl('$url'))
        .toList(growable: false);
    json['authorAvatarUrl'] = _absoluteUrl('${json['authorAvatarUrl'] ?? ''}');
    json['ageLabel'] =
        justNow ? 'Just now' : _ageLabel('${json['createdAt'] ?? ''}');
    json['isLiked'] = json['liked'] == true;
    return CommunityPost.fromJson(json);
  }

  Future<List<CommunityPerson>> _getPeople(FriendsView view) async {
    final apiView = switch (view) {
      FriendsView.friends => 'friends',
      FriendsView.followers => 'followers',
      FriendsView.following => 'following',
      FriendsView.addFriends => 'discover',
    };
    final payload = await _getList('/api/v1/community/people?view=$apiView');
    return payload.map((item) {
      final json = Map<String, dynamic>.from(item as Map);
      final detail = '${json['detail'] ?? ''}'.trim();
      return CommunityPerson(
        id: '${json['id']}',
        name: '${json['name'] ?? 'Community member'}',
        avatarUrl: _absoluteUrl('${json['avatarUrl'] ?? ''}'),
        detail: detail.isEmpty ? null : detail,
        tags:
            (json['tags'] as List<dynamic>? ?? const [])
                .map((tag) => '$tag')
                .toList(),
        mutualFriends: (json['mutualFriends'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<List<dynamic>> _getList(String path) async {
    final response = await _client.get(_uri(path), headers: await _headers());
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const CommunityException(
        'The server returned invalid community data.',
      );
    }
    return decoded;
  }

  Future<Map<String, String>> _headers({bool includeContentType = true}) async {
    final token = await _authService.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const CommunityException('Please sign in to use Community.');
    }
    return {
      'Accept': 'application/json',
      if (includeContentType) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CommunityException(
        'The server returned invalid community data.',
      );
    }
    return decoded;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    var message = 'Community request failed (${response.statusCode}).';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String) {
        message = body['message'] as String;
      }
    } on Object {
      /* Keep the HTTP fallback. */
    }
    throw CommunityException(message);
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');
  String _absoluteUrl(String value) =>
      value.startsWith('/') ? '${ApiConfig.baseUrl}$value' : value;
  String _ageLabel(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'Recently';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${difference.inDays}d ago';
  }
}

class CommunityException implements Exception {
  const CommunityException(this.message);
  final String message;
  @override
  String toString() => message;
}
