import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/profile_service.dart';
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
  final _chat = ChatService();
  final _profileService = ProfileService();

  final List<ChatMessage> _messages = [];
  String _context = '';
  bool _loadingHistory = true;
  bool _sending = false;
  String? _errorText;
  String? _lastUserText; // Try again ke liye

  static const _greeting =
      'Ask me about your careers, skills, resume or interviews.';

  final List<String> _suggestions = [
    'What should I learn first?',
    'Is my profile strong enough to apply?',
    'How do I answer "tell me about yourself"?',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Profile aur purani chat load karta hai.
  Future<void> _init() async {
    final p = await _profileService.loadProfile();
    final saved = p?['chatHistory'];
    final loaded = <ChatMessage>[];
    if (saved is List) {
      for (final m in saved) {
        if (m is Map && m['text'] != null) {
          loaded.add(ChatMessage(m['text'].toString(), m['role'] == 'user'));
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _context = ChatService.profileContext(p);
      _messages.addAll(loaded);
      _loadingHistory = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Aakhri 20 messages Firestore ma save.
  Future<void> _save() async {
    final recent = _messages.length > 20
        ? _messages.sublist(_messages.length - 20)
        : _messages;
    await _profileService.saveProfile({
      'chatHistory': recent
          .map((m) => {'role': m.fromUser ? 'user' : 'model', 'text': m.text})
          .toList(),
    });
  }

  void _send(String text) {
    var message = text.trim();
    if (message.isEmpty || _sending || _loadingHistory) return;
    if (message.length > 500) message = message.substring(0, 500);

    setState(() {
      _messages.add(ChatMessage(message, true));
      _sending = true;
      _errorText = null;
      _lastUserText = message;
    });
    _controller.clear();
    _scrollDown();
    _ask(message);
  }

  Future<void> _ask(String message) async {
    // Is message se pehle ke aakhri 10 messages AI ko bhejte hain.
    final past = _messages.sublist(0, _messages.length - 1);
    final recent = past.length > 10 ? past.sublist(past.length - 10) : past;
    final history = recent
        .map((m) => {'role': m.fromUser ? 'user' : 'model', 'text': m.text})
        .toList();

    final reply = await _chat.reply(
      history: history,
      message: message,
      context: _context,
    );
    if (!mounted) return;

    if (reply == null) {
      setState(() {
        _sending = false;
        _errorText = _chat.lastError ?? 'Could not get a reply.';
      });
      _scrollDown();
      return;
    }

    setState(() {
      _messages.add(ChatMessage(reply, false));
      _sending = false;
      _lastUserText = null;
    });
    _scrollDown();
    await _save();
  }

  void _retry() {
    final text = _lastUserText;
    if (text == null || _sending) return;
    setState(() {
      _sending = true;
      _errorText = null;
    });
    _scrollDown();
    _ask(text);
  }

  Future<void> _clearChat() async {
    setState(() {
      _messages.clear();
      _errorText = null;
      _lastUserText = null;
    });
    await _profileService.saveProfile({'chatHistory': <Map<String, String>>[]});
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(18),
            children: [
              _bubble(ChatMessage(_greeting, false)),
              for (final m in _messages) _bubble(m),
              if (_messages.isEmpty)
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
              if (_sending) _thinkingBubble(),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    children: [
                      Text(_errorText!,
                          style:
                          const TextStyle(color: Colors.red, fontSize: 13),
                          textAlign: TextAlign.center),
                      TextButton(
                          onPressed: _retry, child: const Text('Try again')),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (_messages.isNotEmpty && !_sending)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _clearChat,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear chat'),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_sending,
                  onSubmitted: _send,
                  decoration:
                  const InputDecoration(hintText: 'Ask a career question'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : () => _send(_controller.text),
                style: IconButton.styleFrom(backgroundColor: kPrimary),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _thinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kLine),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Thinking...', style: TextStyle(color: kMuted)),
          ],
        ),
      ),
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