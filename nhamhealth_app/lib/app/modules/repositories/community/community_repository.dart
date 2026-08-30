import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/community/community_person.dart';
import '../../models/community/community_comment.dart';
import '../../models/community/community_post.dart';
import '../../models/community/community_tag.dart';
import '../../models/community/community_types.dart';
import '../../models/community/community_report_reason.dart';

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

  Future<CommunityPost> getPost(String postId) async {
    final response = await _client.get(
      _uri('/api/v1/community/posts/$postId'),
      headers: await _headers(),
    );
    return _post(_decodeMap(response));
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
        .map(
          (item) =>
              CommunityTag.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .where((tag) => tag.id > 0 && tag.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<CommunityTag> createTag(String name) async {
    final response = await _client.post(
      _uri('/api/v1/community/tags'),
      headers: await _headers(),
      body: jsonEncode({'name': name.trim()}),
    );
    return CommunityTag.fromJson(_decodeMap(response));
  }

  Future<String> uploadStepImage(Uint8List bytes) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/v1/recipes/step-images'),
    )..headers.addAll(await _headers(includeContentType: false));
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: 'recipe-step.jpg'),
    );
    final response = await http.Response.fromStream(await _client.send(request));
    return '${_decodeMap(response)['imageUrl'] ?? ''}';
  }

  Future<List<CommunityReportReason>> getReportReasons() async {
    final payload = await _getList('/api/v1/community/report-reasons');
    return payload
        .map(
          (item) => CommunityReportReason.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where((reason) => reason.id > 0 && reason.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> reportPost({
    required String postId,
    required int reasonId,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/community/posts/$postId/reports?reasonId=$reasonId'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
  }

  Future<void> reportComment({
    required String postId,
    required String commentId,
    required int reasonId,
  }) async {
    final response = await _client.post(
      _uri(
        '/api/v1/community/posts/$postId/comments/$commentId/reports?reasonId=$reasonId',
      ),
      headers: await _headers(),
    );
    _ensureSuccess(response);
  }

  Future<CommunityPost> createPost({
    required String mealName,
    required String description,
    required int cookingTimeMinutes,
    required int servings,
    required String difficulty,
    required List<MealPostIngredient> ingredients,
    required List<MealPostStep> steps,
    List<Uint8List> imageBytes = const [],
    CommunityPostVisibility visibility = CommunityPostVisibility.public,
    bool allowComments = true,
    bool allowReplies = true,
    List<int> tagIds = const [],
  }) async {
    final request =
        http.MultipartRequest('POST', _uri('/api/community/meals'))
          ..headers.addAll(await _headers(includeContentType: false))
          ..files.add(
            http.MultipartFile.fromString(
              'recipe',
              jsonEncode({
                'recipeName': mealName.trim(),
                'description': description.trim(),
                'cookingTimeMinutes': cookingTimeMinutes,
                'servings': servings,
                'difficulty': difficulty,
                'tagIds': tagIds,
                'ingredients':
                    ingredients.map((item) => item.toJson()).toList(),
                'steps': steps.map((item) => item.toJson()).toList(),
              }),
              contentType: MediaType('application', 'json'),
            ),
          );
    for (var index = 0; index < imageBytes.take(1).length; index++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes[index],
          filename: 'community-post-${index + 1}.jpg',
        ),
      );
    }
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    final created = _decodeMap(response);
    final recipeId = '${created['id']}';
    final published = await _client.post(
      _uri('/api/community/meals/$recipeId/publish'),
      headers: await _headers(),
    );
    _ensureSuccess(published);
    return getPost(recipeId);
  }

  Future<CommunityPost> updatePost({
    required String postId,
    required String mealName,
    required String description,
    required int cookingTimeMinutes,
    required int servings,
    required String difficulty,
    required List<MealPostIngredient> ingredients,
    required List<MealPostStep> steps,
    List<Uint8List> imageBytes = const [],
    CommunityPostVisibility visibility = CommunityPostVisibility.public,
    bool allowComments = true,
    bool allowReplies = true,
    bool removeImage = false,
    List<int> tagIds = const [],
  }) async {
    final request =
        http.MultipartRequest('PUT', _uri('/api/community/meals/$postId'))
          ..headers.addAll(await _headers(includeContentType: false))
          ..files.add(
            http.MultipartFile.fromString(
              'recipe',
              jsonEncode({
                'recipeName': mealName.trim(),
                'description': description.trim(),
                'cookingTimeMinutes': cookingTimeMinutes,
                'servings': servings,
                'difficulty': difficulty,
                'tagIds': tagIds,
                'ingredients':
                    ingredients.map((item) => item.toJson()).toList(),
                'steps': steps.map((item) => item.toJson()).toList(),
              }),
              contentType: MediaType('application', 'json'),
            ),
          );
    for (var index = 0; index < imageBytes.take(1).length; index++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes[index],
          filename: 'community-post-${index + 1}.jpg',
        ),
      );
    }
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    _decodeMap(response);
    await _client.post(
      _uri('/api/community/meals/$postId/ai-check'),
      headers: await _headers(),
    );
    return getPost(postId);
  }

  Future<void> deletePost(String postId) async {
    final response = await _client.delete(
      _uri('/api/community/meals/$postId'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
  }

  Future<CommunityPost> toggleSaved(String postId) async {
    final response = await _client.post(
      _uri('/api/community/meals/$postId/saved'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    return getPost(postId);
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

  Future<CommunityPost> sharePostToFeed(
    String postId, {
    String message = '',
    CommunityPostVisibility visibility = CommunityPostVisibility.public,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/community/posts/$postId/share-to-feed'),
      headers: await _headers(),
      body: jsonEncode({
        'message': message.trim(),
        'visibility': visibility.apiValue,
      }),
    );
    return _post(_decodeMap(response), justNow: true);
  }

  Future<List<CommunityComment>> getComments(String postId) async {
    final payload = await _getList('/api/v1/community/posts/$postId/comments');
    return payload
        .map((item) {
          final comment = Map<String, dynamic>.from(item as Map);
          comment['authorAvatarUrl'] = _absoluteUrl(
            '${comment['authorAvatarUrl'] ?? ''}',
          );
          return CommunityComment.fromJson(comment);
        })
        .toList(growable: false);
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
        if (parentCommentId != null)
          'parentCommentId': int.parse(parentCommentId),
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

  Future<void> deleteComment(String postId, String commentId) async {
    final response = await _client.delete(
      _uri('/api/v1/community/posts/$postId/comments/$commentId'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
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
    final sharedPayload = json['sharedPost'];
    if (sharedPayload is Map) {
      final shared = Map<String, dynamic>.from(sharedPayload);
      shared['imageUrl'] = _absoluteUrl('${shared['imageUrl'] ?? ''}');
      shared['imageUrls'] = (shared['imageUrls'] as List<dynamic>? ?? const [])
          .map((url) => _absoluteUrl('$url'))
          .toList(growable: false);
      shared['authorAvatarUrl'] = _absoluteUrl(
        '${shared['authorAvatarUrl'] ?? ''}',
      );
      shared['ageLabel'] = _ageLabel('${shared['createdAt'] ?? ''}');
      json['sharedPost'] = shared;
    }
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
      if (body is Map) {
        final serverMessage =
            body['message'] ?? body['detail'] ?? body['error'];
        if (serverMessage is String && serverMessage.trim().isNotEmpty) {
          message = serverMessage.trim();
        }
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
