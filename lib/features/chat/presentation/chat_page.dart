import 'dart:async';

import 'package:dipl/app/app_colors.dart';
import 'package:dipl/app/widgets/main_bottom_nav.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      text: 'Салам! Мен ИИ жардамчымын. Билдирүү жазыңыз, мен жардам берем.',
      isUser: false,
    ),
  ];

  bool _isTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Чат с ИИ')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (BuildContext context, int index) {
                  if (_isTyping && index == _messages.length) {
                    return const _TypingIndicator();
                  }
                  final _ChatMessage message = _messages[index];
                  return _MessageBubble(message: message);
                },
              ),
            ),
            _ChatComposer(controller: _messageController, onSend: _sendMessage),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
      _messageController.clear();
    });
    _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 900));
    final String reply = _buildAiReply(text);

    if (!mounted) {
      return;
    }
    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _buildAiReply(String userText) {
    final String normalized = userText.toLowerCase();
    if (normalized.contains('курс')) {
      return 'Могу помочь с курсами: выбрать уровень, план уроков и цель на неделю.';
    }
    if (normalized.contains('словар')) {
      return 'Для словаря рекомендую повтор 10-15 слов в день и мини-тест в конце.';
    }
    if (normalized.contains('привет') || normalized.contains('салам')) {
      return 'Привет! Чем помочь в изучении кыргызского языка?';
    }
    return 'Билдирүү алынды: "$userText". Теманы түшүндүрүп, план түзүп, көнүгүүлөрдү бере алам.';
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Введите сообщение...',
                  filled: true,
                  fillColor: const Color(0xFFF2F4F7),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onSend,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.send_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final Alignment alignment = message.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final Color bgColor = message.isUser
        ? AppColors.brandPrimary
        : const Color(0xFFF2F4F7);
    final Color textColor = message.isUser
        ? Colors.white
        : AppColors.textPrimary;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, fontSize: 15, height: 1.3),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> {
  late final Timer _timer;
  int _dotsCount = 1;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _dotsCount = _dotsCount == 3 ? 1 : _dotsCount + 1;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'ИИ печатает${'.' * _dotsCount}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
