import 'package:flutter/material.dart';
import '../theme.dart';

class ChatMessage {
  final String text;
  final bool fromUser;
  ChatMessage(this.text, this.fromUser);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage('Ask me about your careers, skills, resume or interviews.', false),
  ];

  final List<String> _suggestions = [
    'What should I learn first?',
    'Is my profile strong enough to apply?',
    'How do I answer "tell me about yourself"?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    final message = text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(message, true));
      // TODO: replace this line with the real AI reply from the backend.
      _messages.add(ChatMessage('The AI reply will appear here once the backend is connected.', false));
    });
    _controller.clear();

    // Scroll down to the newest message.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(18),
            children: [
              for (final m in _messages) _bubble(m),
              if (_messages.length == 1)
                Wrap(
                  spacing: 8,
                  children: [
                    for (final s in _suggestions)
                      ActionChip(
                        label: Text(s),
                        backgroundColor: Colors.white,
                        onPressed: () => _send(s),
                      ),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: _send,
                  decoration:
                      const InputDecoration(hintText: 'Ask a career question'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _send(_controller.text),
                style: IconButton.styleFrom(backgroundColor: kPrimary),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bubble(ChatMessage m) {
    return Align(
      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: m.fromUser ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: m.fromUser ? null : Border.all(color: kLine),
        ),
        child: Text(m.text,
            style: TextStyle(color: m.fromUser ? Colors.white : kInk)),
      ),
    );
  }
}
