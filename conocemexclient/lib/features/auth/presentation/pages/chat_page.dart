import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/di/setup_dependencies.dart';
import '/core/services/community_chat_service.dart';
import '/core/services/deepl_service.dart';
import '/core/services/locale_service.dart';
import '/l10n/app_localizations.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String communityId;
  final String communityName;

  const ChatPage({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _bgGrey = Color(0xFFF3F3F4);

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  late final CommunityChatService _chatService;
  late final DeepLService _deeplService;

  // Cache de traducciones por messageId
  final Map<String, String> _translatedMessages = {};
  final Set<String> _translatingIds = {};

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  String get _userLang => getIt<LocaleService>().locale.languageCode;

  @override
  void initState() {
    super.initState();
    _chatService = getIt<CommunityChatService>();
    _deeplService = getIt<DeepLService>();
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
      await _chatService.sendMessage(
        communityId: widget.communityId,
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

  Future<String> _getTranslation(String messageId, String content) async {
    // Si ya esta traducido, retornar cache
    if (_translatedMessages.containsKey(messageId)) {
      return _translatedMessages[messageId]!;
    }

    // Traducir en background
    if (!_translatingIds.contains(messageId)) {
      _translatingIds.add(messageId);
      final translated = await _deeplService.translate(content, _userLang);
      _translatedMessages[messageId] = translated;
      _translatingIds.remove(messageId);
      if (mounted) setState(() {});
    }

    return content; // Retorna original mientras traduce
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

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
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
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.groups, color: _primaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.chat,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: _darkBlue, fontSize: 16),
                ),
                Text(
                  widget.communityName,
                  style: TextStyle(fontSize: 11, color: _darkBlue.withValues(alpha: 0.4), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ─── Mensajes ───
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.watchMessages(widget.communityId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryGreen),
                  );
                }

                final messages = snapshot.data!
                    .where((m) => m['is_deleted'] != true)
                    .toList();

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

                    // Traduccion
                    final isTranslating = _translatingIds.contains(messageId);
                    final displayContent = _translatedMessages[messageId] ?? content;

                    // Lanzar traduccion si no existe
                    if (!_translatedMessages.containsKey(messageId) &&
                        content.isNotEmpty &&
                        !_translatingIds.contains(messageId)) {
                      _getTranslation(messageId, content);
                    }

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _chatService.getSenderProfile(senderId),
                      builder: (context, profileSnap) {
                        final profile = profileSnap.data;
                        final senderName = profile?['full_name'] as String? ?? 'Usuario';
                        final avatarUrl = profile?['avatar_url'] as String?;

                        return MessageBubble(
                          content: displayContent,
                          senderName: senderName,
                          avatarUrl: avatarUrl,
                          isMine: isMine,
                          time: time,
                          isTranslating: isTranslating,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // ─── Input ───
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _darkBlue,
                        ),
                        decoration: InputDecoration(
                          hintText: l.typeMessage,
                          hintStyle: TextStyle(
                            color: _darkBlue.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: _bgGrey,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _primaryGreen,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: _send,
                      ),
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
