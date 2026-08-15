import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../models/profile_dashboard_model.dart';

class ProfileRepository {
  ProfileRepository({
    required AuthService authService,
    http.Client? client,
  }) : _authService = authService,
       _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  Future<ProfileDashboardModel> getDashboard() async {
    final token = await _accessToken();

    final response = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/dashboard'),
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
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/profile-image'),
    )
      ..headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      })
      ..files.add(await http.MultipartFile.fromPath('file', imagePath));
    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(seconds: 30)),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfileException(_errorMessage(response));
    }
  }

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

class ProfileException implements Exception {
  const ProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}
