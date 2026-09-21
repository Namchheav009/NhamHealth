class AssistantMessage {
  const AssistantMessage({
    required this.role,
    required this.content,
    this.isError = false,
    this.actions = const [],
  });

  final String role;
  final String content;
  final bool isError;
  final List<String> actions;

  bool get isUser => role == 'user';

  Map<String, String> toJson() => {'role': role, 'content': content};
}
