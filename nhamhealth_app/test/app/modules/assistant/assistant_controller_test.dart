import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/assistant/assistant_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/assistant/assistant_message.dart';
import 'package:nhamhealth_flutter/app/modules/providers/assistant/assistant_provider.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'reload replaces an assistant reply without duplicating the question',
    () async {
      final provider = _FakeAssistantProvider();
      final controller = AssistantController(provider: provider);
      addTearDown(controller.onClose);

      await controller.send('What can I do in NhamHealth?');
      expect(
        controller.messages.where((message) => message.isUser),
        hasLength(1),
      );
      expect(controller.messages.last.content, 'Reply 1');

      await controller.reloadReply(2);

      expect(
        controller.messages.where((message) => message.isUser),
        hasLength(1),
      );
      expect(controller.messages.last.content, 'Reply 2');
      expect(provider.requests, hasLength(2));
      expect(provider.requests.last.history, isEmpty);
    },
  );

  test('assistant sends the device-local wellness date', () async {
    Map<String, dynamic>? requestBody;
    final provider = AssistantProvider(
      authService: _TokenAuthService(),
      client: MockClient((request) async {
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'reply': 'Your data is ready.',
            'actions': ['daily_wellness'],
          }),
          200,
        );
      }),
    );

    final response = await provider.sendMessage(
      message: 'Show my wellness',
      history: const [],
    );

    final now = DateTime.now();
    final expected =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    expect(requestBody?['date'], expected);
    expect(response.actions, ['daily_wellness']);
  });

  test('long conversations send a bounded window of recent messages', () async {
    final provider = _FakeAssistantProvider();
    final controller = AssistantController(provider: provider);
    addTearDown(controller.onClose);

    for (var index = 1; index <= 7; index++) {
      await controller.send('Food question $index');
    }

    final history = provider.requests.last.history;
    expect(history, hasLength(10));
    expect(history.first.content, 'Food question 2');
    expect(history.last.content, 'Reply 6');
  });
}

class _TokenAuthService extends AuthService {
  @override
  Future<String?> readAccessToken() async => 'test-token';
}

class _FakeAssistantProvider extends AssistantProvider {
  _FakeAssistantProvider() : super(authService: AuthService());

  final List<_Request> requests = [];

  @override
  Future<AssistantReply> sendMessage({
    required String message,
    required List<AssistantMessage> history,
  }) async {
    requests.add(_Request(message: message, history: history));
    return AssistantReply(reply: 'Reply ${requests.length}');
  }
}

class _Request {
  const _Request({required this.message, required this.history});

  final String message;
  final List<AssistantMessage> history;
}
