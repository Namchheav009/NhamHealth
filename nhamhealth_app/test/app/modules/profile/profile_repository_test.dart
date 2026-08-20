import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as image;
import 'package:nhamhealth_flutter/app/modules/repositories/profile/profile_repository.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'nhamhealth-profile-upload-',
    );
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  const formats = <({String extension, String mediaSubtype})>[
    (extension: 'jpg', mediaSubtype: 'jpeg'),
    (extension: 'png', mediaSubtype: 'png'),
    (extension: 'webp', mediaSubtype: 'webp'),
  ];

  for (final format in formats) {
    test(
      'uploads ${format.extension.toUpperCase()} with its canonical MIME type',
      () async {
        late http.Request capturedRequest;
        final client = MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({'saved': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final file = File('${temporaryDirectory.path}/picker-result.bin');
        await file.writeAsBytes(_encodedImage(format.extension));
        final repository = ProfileRepository(
          authService: _AuthenticatedAuthService(),
          client: client,
        );

        await repository.uploadProfileImage(file.path);

        expect(capturedRequest.method, 'PUT');
        expect(capturedRequest.url.path, '/api/v1/users/me/profile-image');
        expect(capturedRequest.headers['authorization'], 'Bearer test-token');
        final multipartBody = latin1.decode(capturedRequest.bodyBytes);
        expect(
          multipartBody,
          contains('name="file"; filename="profile.${format.extension}"'),
        );
        expect(
          multipartBody,
          contains('content-type: image/${format.mediaSubtype}'),
        );
      },
    );
  }

  test('rejects unsupported bytes before starting the upload', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      return http.Response('{}', 200);
    });
    final file = File('${temporaryDirectory.path}/not-an-image.jpg');
    await file.writeAsBytes(const [1, 2, 3, 4]);
    final repository = ProfileRepository(
      authService: _AuthenticatedAuthService(),
      client: client,
    );

    await expectLater(
      repository.uploadProfileImage(file.path),
      throwsA(
        isA<ProfileException>().having(
          (error) => error.message,
          'message',
          contains('valid JPG, PNG, or WebP'),
        ),
      ),
    );
    expect(requestCount, 0);
  });
}

class _AuthenticatedAuthService extends AuthService {
  @override
  Future<String?> readAccessToken() async => 'test-token';
}

List<int> _encodedImage(String extension) {
  final bitmap = image.Image(width: 2, height: 2);
  return switch (extension) {
    'jpg' => image.encodeJpg(bitmap),
    'png' => image.encodePng(bitmap),
    'webp' => image.encodeWebP(bitmap),
    _ => throw ArgumentError.value(extension),
  };
}
