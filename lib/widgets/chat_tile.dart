import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/chat_model.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String myUid;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.myUid,
    required this.onTap,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('hh:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('dd/MM/yy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = chat.otherName(myUid);
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Colors.grey[900]!, width: 1)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGold.withOpacity(0.1),
                border: Border.all(
                    color: kGold.withOpacity(0.3), width: 1.5),
              ),
              child: Center(
                child: Text(
                  chat.isGroup ? '👥' : initial,
                  style: TextStyle(
                    color: kGold,
                    fontSize: chat.isGroup ? 20 : 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(
                    chat.lastMessage ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),

            // Time
            Text(
              _formatTime(chat.updatedAt),
              style: TextStyle(color: Colors.grey[700], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
