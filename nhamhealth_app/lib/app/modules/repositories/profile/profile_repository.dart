import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as image;

import '../../../../config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/profile/profile_dashboard_model.dart';

class ProfileRepository {
  ProfileRepository({required AuthService authService, http.Client? client})
    : _authService = authService,
      _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  Future<int> getUnreadNotificationCount() async {
    final token = await _accessToken();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/unread-count'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) return 0;
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return (payload['count'] as num?)?.toInt() ?? 0;
  }

  Future<ProfileDashboardModel> getDashboard({DateTime? date}) async {
    final token = await _accessToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/dashboard');
    final requestUri =
        date == null
            ? uri
            : uri.replace(queryParameters: {'date': _dateOnly(date)});

    final response = await _client
        .get(
          requestUri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfileException(
        response.statusCode == 401 || response.statusCode == 403
            ? 'Your session has expired. Please sign in again.'
            : 'The profile server returned HTTP ${response.statusCode}.',
      );
    }

    try {
      return ProfileDashboardModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on Object {
      throw const ProfileException('The profile response is incomplete.');
    }
  }

  Future<ProfileDashboardModel> addDailyNutrition({
    double? calories,
    double? protein,
    double? water,
    double? fiber,
    double? sugar,
    String? aiRecommendation,
    DateTime? date,
  }) async {
    final token = await _accessToken();
    final response = await _client
        .post(
          Uri.parse(
            '${ApiConfig.baseUrl}/api/v1/users/me/daily-wellness/nutrients',
          ),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            if (date != null) 'date': _dateOnly(date),
            if (calories != null) 'calories': calories,
            if (protein != null) 'protein': protein,
            if (water != null) 'water': water,
            if (fiber != null) 'fiber': fiber,
            if (sugar != null) 'sugar': sugar,
            if (aiRecommendation != null) 'aiRecommendation': aiRecommendation,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _dashboardFromResponse(response);
  }

  Future<ProfileDashboardModel> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    required DateTime dateOfBirth,
    required String gender,
    required double heightCm,
    required double weightKg,
  }) async {
    final token = await _accessToken();
    final response = await _client
        .put(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/profile'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'fullName': fullName.trim(),
            'email': email.trim(),
            'phone': phone.trim(),
            'dateOfBirth': _dateOnly(dateOfBirth),
            'gender': gender,
            'heightCm': heightCm,
            'weightKg': weightKg,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _dashboardFromResponse(response);
  }

  Future<void> uploadProfileImage(String imagePath) async {
    final token = await _accessToken();
    final upload = await _prepareProfileImage(imagePath);
    final request =
        http.MultipartRequest(
            'PUT',
            Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/profile-image'),
          )
          ..headers.addAll({
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          })
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              upload.bytes,
              filename: 'profile.${upload.extension}',
              contentType: http.MediaType('image', upload.mediaSubtype),
            ),
          );
    final response = await http.Response.fromStream(
      await _client.send(request).timeout(const Duration(seconds: 30)),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfileException(_errorMessage(response));
    }
  }

  Future<_ProfileImageUpload> _prepareProfileImage(String imagePath) async {
    final path = imagePath.trim();
    if (path.isEmpty) {
      throw const ProfileException('Please choose a profile image first.');
    }

    try {
      final file = File(path);
      final size = await file.length();
      if (size > _maxProfileImageBytes) {
        throw const ProfileException(
          'Choose a JPG, PNG, or WebP image that is 5 MB or smaller.',
        );
      }
      final bytes = await file.readAsBytes();
      final _ProfileImageUpload upload;
      if (_isJpeg(bytes)) {
        upload = _ProfileImageUpload(
          bytes,
          extension: 'jpg',
          mediaSubtype: 'jpeg',
        );
      } else if (_isPng(bytes)) {
        upload = _ProfileImageUpload(
          bytes,
          extension: 'png',
          mediaSubtype: 'png',
        );
      } else if (_isWebp(bytes)) {
        upload = _ProfileImageUpload(
          bytes,
          extension: 'webp',
          mediaSubtype: 'webp',
        );
      } else {
        throw const ProfileException(
          'Choose a valid JPG, PNG, or WebP image, then try again.',
        );
      }

      final decodedImage = image.decodeImage(bytes);
      if (decodedImage == null ||
          decodedImage.width <= 0 ||
          decodedImage.height <= 0) {
        throw const ProfileException(
          'Choose a valid JPG, PNG, or WebP image, then try again.',
        );
      }
      return upload;
    } on ProfileException {
      rethrow;
    } on FileSystemException {
      throw const ProfileException(
        'The selected photo is no longer available. Please choose it again.',
      );
    }
  }

  bool _isJpeg(List<int> bytes) =>
      bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF;

  bool _isPng(List<int> bytes) {
    const signature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    if (bytes.length < signature.length) return false;
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) return false;
    }
    return true;
  }

  bool _isWebp(List<int> bytes) =>
      bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50;

  Future<String> _accessToken() async {
    final token = await _authService.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const ProfileException(
        'Your session has expired. Please sign in again.',
      );
    }
    return token;
  }

  ProfileDashboardModel _dashboardFromResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfileException(_errorMessage(response));
    }
    try {
      return ProfileDashboardModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on Object {
      throw const ProfileException('The profile response is incomplete.');
    }
  }

  String _errorMessage(http.Response response) {
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final message = payload['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
    } on Object {
      // Use the status-based message below.
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return 'Your session has expired. Please sign in again.';
    }
    return 'Unable to save your profile (HTTP ${response.statusCode}).';
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

const int _maxProfileImageBytes = 5 * 1024 * 1024;

class _ProfileImageUpload {
  const _ProfileImageUpload(
    this.bytes, {
    required this.extension,
    required this.mediaSubtype,
  });

  final List<int> bytes;
  final String extension;
  final String mediaSubtype;
}

class ProfileException implements Exception {
  const ProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}
