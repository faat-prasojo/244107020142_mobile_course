enum AiRole { user, model }

/// Satu giliran percakapan yang dikirim ke AI API.
class AiTurn {
  const AiTurn({required this.role, required this.text});

  final AiRole role;
  final String text;

  Map<String, dynamic> toJson() => {
    'type': role == AiRole.user ? 'user_input' : 'model_output',
    'content': [
      {'type': 'text', 'text': text},
    ],
  };
}

enum ChatMessageStatus { done, streaming, error }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.status = ChatMessageStatus.done,
  });

  const ChatMessage.user(this.text)
    : role = AiRole.user,
      status = ChatMessageStatus.done;

  const ChatMessage.assistantStreaming()
    : role = AiRole.model,
      text = '',
      status = ChatMessageStatus.streaming;

  final AiRole role;
  final String text;
  final ChatMessageStatus status;

  bool get isUser => role == AiRole.user;
  bool get isError => status == ChatMessageStatus.error;
  bool get isStreaming => status == ChatMessageStatus.streaming;

  ChatMessage copyWith({String? text, ChatMessageStatus? status}) {
    return ChatMessage(
      role: role,
      text: text ?? this.text,
      status: status ?? this.status,
    );
  }
}

class AiChatState {
  const AiChatState({
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final bool isSending;

  /// Error yang tidak terkait satu bubble, mis. API key belum diatur.
  final String? errorMessage;

  bool get isEmpty => messages.isEmpty;

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
