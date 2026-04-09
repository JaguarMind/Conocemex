import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/di/setup_dependencies.dart';
import '/core/services/community_chat_service.dart';
import '/core/services/deepl_service.dart';
import '/core/services/locale_service.dart';
import '/l10n/app_localizations.dart';
import '../widgets/message_bubble.dart';

class DirectChatPage extends StatefulWidget {
  final String conversationId;
  final String otherName;
  final String? otherAvatar;

  const DirectChatPage({
    super.key,
    required this.conversationId,
    required this.otherName,
    this.otherAvatar,
  });

  @override
  State<DirectChatPage> createState() => _DirectChatPageState();
}

class _DirectChatPageState extends State<DirectChatPage> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _bgGrey = Color(0xFFF3F3F4);

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  late final CommunityChatService _chatService;
  bool _hasDeepL = false;
  DeepLService? _deeplService;

  final Map<String, String> _translatedMessages = {};
  final Set<String> _translatingIds = {};

  String get _currentUserId => Supabase.instance.client.auth.currentUser?.id ?? '';
  String get _userLang => getIt<LocaleService>().locale.languageCode;

  @override
  void initState() {
    super.initState();
    _chatService = getIt<CommunityChatService>();
    _hasDeepL = GetIt.instance.isRegistered<DeepLService>();
    if (_hasDeepL) _deeplService = getIt<DeepLService>();
    _chatService.markAsRead(widget.conversationId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await _chatService.sendDirectMessage(
        conversationId: widget.conversationId,
        content: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _translateMessage(String messageId, String content) async {
    if (_translatedMessages.containsKey(messageId) || !_hasDeepL) return;
    if (_translatingIds.contains(messageId)) return;

    _translatingIds.add(messageId);
    final translated = await _deeplService!.translate(content, _userLang);
    _translatedMessages[messageId] = translated;
    _translatingIds.remove(messageId);
    if (mounted) setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String? ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _darkBlue), onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _primaryGreen.withValues(alpha: 0.15),
              backgroundImage: widget.otherAvatar != null ? NetworkImage(widget.otherAvatar!) : null,
              child: widget.otherAvatar == null
                  ? Text(widget.otherName.isNotEmpty ? widget.otherName[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: _primaryGreen, fontSize: 14))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.otherName, style: const TextStyle(fontWeight: FontWeight.w800, color: _darkBlue, fontSize: 16), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.watchDirectMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: _primaryGreen));
                }

                final messages = snapshot.data!.where((m) => m['is_deleted'] != true).toList();

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: _darkBlue.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        Text(l.noMessages, style: TextStyle(color: _darkBlue.withValues(alpha: 0.4), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }

                // Marcar como leido al recibir mensajes
                _chatService.markAsRead(widget.conversationId);
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    final senderId = m['sender_id'] as String? ?? '';
                    final isMine = senderId == _currentUserId;
                    final content = m['content'] as String? ?? '';
                    final messageId = m['id'] as String? ?? '$i';
                    final time = _formatTime(m['created_at'] as String?);

                    final displayContent = _translatedMessages[messageId] ?? content;
                    final isTranslating = _translatingIds.contains(messageId);

                    if (!_translatedMessages.containsKey(messageId) && content.isNotEmpty) {
                      _translateMessage(messageId, content);
                    }

                    return MessageBubble(
                      content: displayContent,
                      senderName: isMine ? '' : widget.otherName,
                      avatarUrl: isMine ? null : widget.otherAvatar,
                      isMine: isMine,
                      time: time,
                      isTranslating: isTranslating,
                    );
                  },
                );
              },
            ),
          ),

          // Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: const TextStyle(fontWeight: FontWeight.w500, color: _darkBlue),
                        decoration: InputDecoration(
                          hintText: l.typeMessage,
                          hintStyle: TextStyle(color: _darkBlue.withValues(alpha: 0.3)),
                          filled: true, fillColor: _bgGrey,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: _primaryGreen, borderRadius: BorderRadius.circular(14)),
                      child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _send),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
