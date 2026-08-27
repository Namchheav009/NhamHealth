class AssistantMessage {
  const AssistantMessage({
    required this.role,
    required this.content,
    this.isError = false,
  });

  final String role;
  final String content;
  final bool isError;

  bool get isUser => role == 'user';

  Map<String, String> toJson() => {'role': role, 'content': content};
}
