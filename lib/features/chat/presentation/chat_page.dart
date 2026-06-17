import 'dart:async';

import 'package:dipl/app/app_colors.dart';
import 'package:dipl/app/widgets/main_bottom_nav.dart';
import 'package:dipl/features/chat/data/gemini_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      text: 'Салам! Мен ИИ жардамчымын. Билдирүү жазыңыз, мен жардам берем.',
      isUser: false,
    ),
  ];

  bool _isTyping = false;
  bool _speechReady = false;
  bool _isListening = false;
  String? _speechLocaleId;
  String _textBeforeSpeech = '';

  @override
  void dispose() {
    if (_speechReady) {
      _speechToText.cancel();
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат с ИИ'),
        actions: [
          IconButton(
            onPressed: _openApiKeyDialog,
            icon: const Icon(Icons.key_outlined),
            tooltip: 'Настроить Gemini API key',
          ),
        ],
      ),
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
            _ChatComposer(
              controller: _messageController,
              isSending: _isTyping,
              isListening: _isListening,
              onSend: _sendMessage,
              onVoiceInput: _toggleVoiceInput,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
      _messageController.clear();
    });
    _scrollToBottom();

    String reply;
    try {
      reply = await GeminiChatService.instance.sendMessage(
        _messages
            .map((_ChatMessage message) {
              return GeminiChatMessage(
                text: message.text,
                isUser: message.isUser,
              );
            })
            .toList(growable: false),
      );
    } on GeminiChatException catch (error) {
      reply = error.message;
    } catch (_) {
      reply = 'Не удалось получить ответ. Попробуйте еще раз.';
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isTyping = false;
    });
    _scrollToBottom();
  }

  Future<void> _openApiKeyDialog() async {
    final TextEditingController controller = TextEditingController();

    final String? apiKey = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Gemini API key'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API key',
              hintText: 'Вставьте новый ключ Gemini',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (apiKey == null) return;

    try {
      await GeminiChatService.instance.saveApiKey(apiKey);
      if (!mounted) return;
      _showInfo('Gemini API key сохранен');
    } on GeminiChatException catch (error) {
      if (!mounted) return;
      _showInfo(error.message);
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (_isTyping) return;

    if (_isListening) {
      await _speechToText.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    final bool available = _speechReady || await _initializeSpeech();
    if (!available) {
      if (!mounted) return;
      _showInfo('Распознавание речи недоступно или нет разрешения на микрофон');
      return;
    }

    _textBeforeSpeech = _messageController.text.trim();
    setState(() => _isListening = true);

    await _speechToText.listen(
      onResult: _handleSpeechResult,
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 45),
        localeId: _speechLocaleId,
      ),
    );
  }

  Future<bool> _initializeSpeech() async {
    final bool available = await _speechToText.initialize(
      onStatus: _handleSpeechStatus,
      onError: _handleSpeechError,
    );

    if (!available) return false;

    _speechReady = true;
    _speechLocaleId = await _chooseSpeechLocale();
    return true;
  }

  Future<String?> _chooseSpeechLocale() async {
    final List<stt.LocaleName> locales = await _speechToText.locales();
    const List<String> preferredLocales = <String>['ky_KG', 'ru_RU', 'ru'];

    for (final String localeId in preferredLocales) {
      for (final stt.LocaleName locale in locales) {
        if (locale.localeId == localeId ||
            locale.localeId.toLowerCase().startsWith(localeId.toLowerCase())) {
          return locale.localeId;
        }
      }
    }

    return (await _speechToText.systemLocale())?.localeId;
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    final String words = result.recognizedWords.trim();
    if (words.isEmpty || !mounted) return;

    final String nextText = _textBeforeSpeech.isEmpty
        ? words
        : '$_textBeforeSpeech $words';
    _messageController
      ..text = nextText
      ..selection = TextSelection.collapsed(offset: nextText.length);
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      setState(() => _isListening = false);
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() => _isListening = false);
    _showInfo('Не удалось распознать речь: ${error.errorMsg}');
  }

  void _showInfo(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.isSending,
    required this.isListening,
    required this.onSend,
    required this.onVoiceInput,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool isListening;
  final VoidCallback onSend;
  final VoidCallback onVoiceInput;

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
                enabled: !isSending,
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
              onPressed: isSending ? null : onVoiceInput,
              style: FilledButton.styleFrom(
                backgroundColor: isListening
                    ? const Color(0xFFE53935)
                    : AppColors.brandPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.indicatorInactive,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
              ),
              child: Icon(
                isListening ? Icons.stop_rounded : Icons.mic_rounded,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: isSending ? null : onSend,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.indicatorInactive,
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
      if (!mounted) return;
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
