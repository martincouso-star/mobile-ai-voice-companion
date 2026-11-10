enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({required this.role, required this.text});

  const ChatMessage.user(String text) : this(role: ChatRole.user, text: text);

  const ChatMessage.assistant(String text)
    : this(role: ChatRole.assistant, text: text);

  final ChatRole role;
  final String text;
}
