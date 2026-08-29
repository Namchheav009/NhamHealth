import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_back_header.dart';
import '../../controllers/assistant/assistant_controller.dart';
import '../../models/assistant/assistant_message.dart';

class AssistantView extends GetView<AssistantController> {
  const AssistantView({super.key});

  static const _suggestions = [
    'How is my wellness progress today?',
    'What can I do in NhamHealth?',
    'Explain my nutrition dashboard',
    'How many calories do I have left today?',
    'How can I reach my protein goal?',
    'How do I add food to Daily Wellness?',
    'How does AI food photo analysis work?',
    'How do meal recommendations work?',
    'Where can I find my favorite meals?',
    'How do I change the app language?',
    'What special features are available?',
    'Guide me through health monitoring',
    'Help me configure my app settings',
    'How do I use NhamHealth step by step?',
    'Help me plan a new health feature',
  ];

  static const _suggestionIcons = [
    Icons.monitor_heart_rounded,
    Icons.help_rounded,
    Icons.donut_large_rounded,
    Icons.local_fire_department_rounded,
    Icons.bolt_rounded,
    Icons.add_circle_rounded,
    Icons.camera_alt_rounded,
    Icons.restaurant_menu_rounded,
    Icons.favorite_rounded,
    Icons.translate_rounded,
    Icons.auto_awesome_rounded,
    Icons.health_and_safety_rounded,
    Icons.tune_rounded,
    Icons.map_rounded,
    Icons.lightbulb_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        toolbarHeight: 70,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0x19000000),
        backgroundColor: context.appSurface,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 10,
        title: AppBackHeader(
          title: 'NhamHealth AI',
          onBack: Get.back,
          backButtonKey: const ValueKey<String>('assistant-back-button'),
          titleWidget: const _AssistantHeaderIdentity(),
          trailing: IconButton(
            tooltip: 'Open Daily Wellness',
            onPressed: () => Get.toNamed<void>(AppRoutes.wellness),
            style: IconButton.styleFrom(
              backgroundColor: context.appSoftGreen,
              foregroundColor: context.appColorScheme.primary,
            ),
            icon: const Icon(Icons.monitor_heart_rounded, size: 21),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Obx(
                () => ListView.builder(
                  key: const ValueKey<String>('assistant-message-list'),
                  controller: controller.scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                  itemCount:
                      controller.messages.length +
                      (controller.isSending.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.messages.length) {
                      return const _TypingBubble();
                    }
                    final message = controller.messages[index];
                    return _MessageBubble(
                      message: message,
                      canReload: index > 0 && !message.isUser,
                      isReloading: controller.isSending.value,
                      onReload: () => controller.reloadReply(index),
                    );
                  },
                ),
              ),
            ),
            Container(
              key: const ValueKey<String>('assistant-suggested-questions'),
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.appSurface,
                border: Border(top: BorderSide(color: context.appBorder)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 9, 0, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 15,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Quick questions',
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          key: const ValueKey<String>(
                            'assistant-all-questions',
                          ),
                          onPressed: () => _showAllQuestions(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            minimumSize: const Size(0, 28),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.grid_view_rounded, size: 14),
                          label: const Text(
                            'All questions',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    height: 42,
                    child: Obx(() {
                      final isSending = controller.isSending.value;
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 16),
                        itemCount: _suggestions.length,
                        separatorBuilder:
                            (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return ActionChip(
                            key: ValueKey<String>('assistant-question-$index'),
                            avatar: Icon(
                              _suggestionIcons[index],
                              size: 17,
                              color: _questionColor(index),
                            ),
                            label: Text(_questionLabel(index)),
                            onPressed:
                                isSending
                                    ? null
                                    : () =>
                                        controller.send(_suggestions[index]),
                            backgroundColor: _questionBackground(
                              context,
                              index,
                            ),
                            disabledColor: _questionBackground(context, index),
                            side: BorderSide(
                              color: _questionColor(index).withAlpha(45),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            labelStyle: TextStyle(
                              color: context.appText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: context.appSurface,
                border: Border(top: BorderSide(color: context.appBorder)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey<String>('assistant-input'),
                      controller: controller.inputController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => controller.send(),
                      decoration: InputDecoration(
                        hintText: 'Ask about your wellness...',
                        hintStyle: TextStyle(
                          color: context.appMutedText,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 19,
                          color: AppColors.primaryGreen,
                        ),
                        filled: true,
                        fillColor: context.appMutedSurface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: context.appBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: context.appBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: context.appColorScheme.primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => SizedBox.square(
                      dimension: 48,
                      child: IconButton.filled(
                        key: const ValueKey<String>('assistant-send'),
                        tooltip: 'Send message',
                        onPressed:
                            controller.isSending.value ? null : controller.send,
                        style: IconButton.styleFrom(
                          backgroundColor: context.appColorScheme.primary,
                          disabledBackgroundColor: context.appMutedSurface,
                          shadowColor: const Color(0x5500A651),
                          elevation: 3,
                        ),
                        icon:
                            controller.isSending.value
                                ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.send_rounded, size: 21),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _questionLabel(int index) {
    const labels = [
      'My wellness',
      'App help',
      'Nutrition',
      'Calories left',
      'Protein goal',
      'Add food',
      'Food photo AI',
      'Meal ideas',
      'Favorites',
      'Language',
      'Features',
      'Health monitoring',
      'Settings',
      'App guide',
      'Plan a feature',
    ];
    return labels[index];
  }

  Color _questionColor(int index) {
    const colors = [
      AppColors.primaryGreen,
      Color(0xFF2879D9),
      Color(0xFF7559D9),
      Color(0xFFF26A2E),
      Color(0xFF00A66A),
      Color(0xFFE95A9D),
    ];
    return colors[index % colors.length];
  }

  Color _questionBackground(BuildContext context, int index) {
    const backgrounds = [
      Color(0xFFEAF9F1),
      Color(0xFFEAF4FF),
      Color(0xFFF2EEFF),
      Color(0xFFFFF1EA),
      Color(0xFFEAF9F4),
      Color(0xFFFFEDF6),
    ];
    return context.appIsDark
        ? Color.alphaBlend(
          _questionColor(index).withValues(alpha: 0.13),
          context.appSurface,
        )
        : backgrounds[index % backgrounds.length];
  }

  Future<void> _showAllQuestions(BuildContext context) {
    FocusScope.of(context).unfocus();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.5,
            maxChildSize: 0.92,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.appColorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: context.appSoftGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.question_answer_rounded,
                                color: AppColors.primaryGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ask NhamHealth AI',
                                    style: TextStyle(
                                      color: context.appText,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Choose any question below',
                                    style: TextStyle(
                                      color: context.appMutedText,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: context.appBorder),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _suggestions.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return Obx(
                              () => Material(
                                color: _questionBackground(context, index),
                                borderRadius: BorderRadius.circular(16),
                                child: ListTile(
                                  enabled: !controller.isSending.value,
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    controller.send(_suggestions[index]);
                                  },
                                  minTileHeight: 58,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  leading: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: context.appElevatedSurface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _suggestionIcons[index],
                                      color: _questionColor(index),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    _suggestions[index],
                                    style: TextStyle(
                                      color: context.appText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: _questionColor(index),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}

class _AssistantHeaderIdentity extends StatelessWidget {
  const _AssistantHeaderIdentity();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: context.appSoftGreen,
                shape: BoxShape.circle,
                border: Border.all(color: context.appBorder),
              ),
              child: ClipOval(
                child: Lottie.asset(
                  'assets/animations/chatbot.json',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF35D07F),
                  shape: BoxShape.circle,
                  border: Border.all(color: context.appSurface, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NhamHealth AI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 12,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  const Flexible(
                    child: Text(
                      'Connected to your wellness data',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.canReload,
    required this.isReloading,
    required this.onReload,
  });

  final AssistantMessage message;
  final bool canReload;
  final bool isReloading;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const _ChatAvatar(isUser: false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  message.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                if (!message.isUser) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.isError ? 'Could not reply' : 'NhamHealth AI',
                        style: TextStyle(
                          color:
                              message.isError
                                  ? AppColors.errorCoral
                                  : context.appMutedText,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!message.isError) ...[
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.verified_rounded,
                          size: 11,
                          color: AppColors.primaryGreen,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.sizeOf(context).width *
                        (message.isUser ? 0.76 : 0.82),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color:
                        message.isError
                            ? context.appDangerSurface
                            : message.isUser
                            ? AppColors.primaryGreen
                            : context.appElevatedSurface,
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomRight:
                          message.isUser ? const Radius.circular(5) : null,
                      bottomLeft:
                          message.isUser ? null : const Radius.circular(5),
                    ),
                    border:
                        message.isUser
                            ? null
                            : Border.all(
                              color:
                                  message.isError
                                      ? context.appOnDangerSurface.withValues(
                                        alpha: 0.45,
                                      )
                                      : context.appBorder,
                            ),
                    boxShadow: [
                      BoxShadow(
                        color: context.appShadow,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child:
                      message.isUser
                          ? Text(message.content, style: _messageStyle(context))
                          : _AssistantReplyText(
                            content: message.content,
                            isError: message.isError,
                          ),
                ),
                if (!message.isUser)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Copy reply',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: message.content),
                            );
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text('Reply copied'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                          },
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            foregroundColor: context.appMutedText,
                            minimumSize: const Size(30, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.copy_rounded, size: 15),
                        ),
                        if (canReload)
                          IconButton(
                            key: ValueKey<String>(
                              'assistant-reload-${message.hashCode}',
                            ),
                            tooltip:
                                message.isError ? 'Try again' : 'Reload reply',
                            onPressed: isReloading ? null : onReload,
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(
                              foregroundColor: context.appMutedText,
                              minimumSize: const Size(30, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: Icon(
                              message.isError
                                  ? Icons.replay_rounded
                                  : Icons.refresh_rounded,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const _ChatAvatar(isUser: true),
          ],
        ],
      ),
    );
  }

  TextStyle _messageStyle(BuildContext context) => TextStyle(
    color:
        message.isError
            ? AppColors.errorCoral
            : message.isUser
            ? Colors.white
            : context.appText,
    fontSize: 13,
    height: 1.45,
  );
}

class _AssistantReplyText extends StatelessWidget {
  const _AssistantReplyText({required this.content, required this.isError});

  final String content;
  final bool isError;

  static final RegExp _bulletPattern = RegExp(r'^\s*[-•]\s+(.+)$');
  static final RegExp _numberedPattern = RegExp(r'^\s*(\d+)[.)]\s+(.+)$');
  static final RegExp _emphasisPattern = RegExp(
    r'(\*\*[^*]+\*\*|\b\d+(?:\.\d+)?(?:\s*/\s*\d+(?:\.\d+)?)?\s*(?:kcal|g|glasses?|%|kg|cm|ml|L)\b)',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final lines = content.trim().split('\n');
    final baseStyle = TextStyle(
      color: isError ? AppColors.errorCoral : context.appText,
      fontSize: 13,
      height: 1.5,
    );

    return SelectionArea(
      key: const ValueKey<String>('assistant-reply-structured'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < lines.length; index++) ...[
            if (lines[index].trim().isEmpty)
              const SizedBox(height: 7)
            else
              _buildLine(context, lines[index], baseStyle, index),
            if (index < lines.length - 1 &&
                lines[index].trim().isNotEmpty &&
                lines[index + 1].trim().isNotEmpty)
              const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildLine(
    BuildContext context,
    String line,
    TextStyle baseStyle,
    int lineIndex,
  ) {
    final bullet = _bulletPattern.firstMatch(line);
    if (bullet != null) {
      return Row(
        key: ValueKey<String>('assistant-reply-bullet-$lineIndex'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              size: 16,
              color: isError ? AppColors.errorCoral : AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(child: Text.rich(_richText(bullet.group(1)!, baseStyle))),
        ],
      );
    }

    final numbered = _numberedPattern.firstMatch(line);
    if (numbered != null) {
      return Row(
        key: ValueKey<String>('assistant-reply-numbered-$lineIndex'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appSoftGreen,
              shape: BoxShape.circle,
            ),
            child: Text(
              numbered.group(1)!,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(child: Text.rich(_richText(numbered.group(2)!, baseStyle))),
        ],
      );
    }

    final trimmed = line.trim();
    final isShortHeading = trimmed.endsWith(':') && trimmed.length <= 48;
    return Text.rich(
      _richText(
        trimmed,
        isShortHeading
            ? baseStyle.copyWith(
              color:
                  isError
                      ? AppColors.errorCoral
                      : context.appColorScheme.primary,
              fontWeight: FontWeight.w700,
            )
            : baseStyle,
      ),
    );
  }

  TextSpan _richText(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    var start = 0;

    for (final match in _emphasisPattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      final token = match.group(0)!;
      final isMarkdownBold = token.startsWith('**') && token.endsWith('**');
      spans.add(
        TextSpan(
          text: isMarkdownBold ? token.substring(2, token.length - 2) : token,
          style: TextStyle(
            color:
                isError
                    ? AppColors.errorCoral
                    : isMarkdownBold
                    ? baseStyle.color
                    : AppColors.primaryGreen,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return TextSpan(style: baseStyle, children: spans);
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.isUser});

  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color:
            isUser
                ? Color.alphaBlend(
                  const Color(0xFF2879D9).withValues(alpha: 0.14),
                  context.appSurface,
                )
                : context.appSoftGreen,
        shape: BoxShape.circle,
        border: Border.all(
          color:
              isUser
                  ? const Color(0xFF2879D9).withValues(alpha: 0.35)
                  : context.appBorder,
        ),
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.health_and_safety_rounded,
        size: 17,
        color: isUser ? const Color(0xFF2879D9) : AppColors.primaryGreen,
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ChatAvatar(isUser: false),
        const SizedBox(width: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            border: Border.fromBorderSide(BorderSide(color: context.appBorder)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Checking your wellness...',
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
