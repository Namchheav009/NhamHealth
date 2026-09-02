import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/assistant/assistant_message.dart';
import '../../providers/assistant/assistant_provider.dart';

class AssistantController extends GetxController {
  AssistantController({required AssistantProvider provider})
    : _provider = provider;

  final AssistantProvider _provider;
  final TextEditingController inputController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late final RxList<AssistantMessage> messages =
      <AssistantMessage>[
        AssistantMessage(
          role: 'assistant',
          content:
              "Hi! I'm your NhamHealth AI Assistant. Ask me about the app or your wellness dashboard today."
                  .tr,
        ),
      ].obs;
  final RxBool isSending = false.obs;

  Future<void> send([String? suggestedMessage]) async {
    final text = (suggestedMessage ?? inputController.text).trim();
    if (text.isEmpty || isSending.value) return;

    final history = _conversationHistory();
    inputController.clear();
    messages.add(AssistantMessage(role: 'user', content: text));
    await _requestReply(message: text, history: history);
  }

  Future<void> reloadReply(int assistantIndex) async {
    if (isSending.value ||
        assistantIndex <= 0 ||
        assistantIndex >= messages.length ||
        messages[assistantIndex].isUser) {
      return;
    }

    var userIndex = assistantIndex - 1;
    while (userIndex >= 0 && !messages[userIndex].isUser) {
      userIndex--;
    }
    if (userIndex < 0) return;

    final userMessage = messages[userIndex].content;
    final history = messages
        .skip(1)
        .take(userIndex - 1)
        .where((item) => !item.isError)
        .toList(growable: false);
    messages.removeAt(assistantIndex);
    await _requestReply(message: userMessage, history: history);
  }

  List<AssistantMessage> _conversationHistory() =>
      messages.skip(1).where((item) => !item.isError).toList(growable: false);

  Future<void> _requestReply({
    required String message,
    required List<AssistantMessage> history,
  }) async {
    isSending.value = true;
    _scrollToBottom();
    try {
      final reply = await _provider.sendMessage(
        message: message,
        history: history,
      );
      messages.add(AssistantMessage(role: 'assistant', content: reply));
    } on AssistantException catch (error) {
      messages.add(
        AssistantMessage(
          role: 'assistant',
          content: '${error.message} ${'Tap reload below to try again.'.tr}',
          isError: true,
        ),
      );
    } finally {
      isSending.value = false;
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void onClose() {
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
