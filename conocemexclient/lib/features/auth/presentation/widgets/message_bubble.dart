import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String content;
  final String senderName;
  final String? avatarUrl;
  final bool isMine;
  final String time;
  final bool isTranslating;

  const MessageBubble({
    super.key,
    required this.content,
    required this.senderName,
    this.avatarUrl,
    required this.isMine,
    required this.time,
    this.isTranslating = false,
  });

  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _primaryGreen.withValues(alpha: 0.15),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(
                      senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primaryGreen),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine
                    ? _primaryGreen.withValues(alpha: 0.15)
                    : const Color(0xFFF3F3F4),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        senderName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _primaryGreen,
                        ),
                      ),
                    ),
                  if (isTranslating)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 12, width: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: _darkBlue.withValues(alpha: 0.3)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          content,
                          style: TextStyle(fontSize: 14, color: _darkBlue.withValues(alpha: 0.4)),
                        ),
                      ],
                    )
                  else
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        color: _darkBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: _darkBlue.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
