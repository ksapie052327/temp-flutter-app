// FIX 2: senderName comes from resolved UserService — not Firestore message data

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final bool showName;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.msg,
    required this.isMe,
    this.showName = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment:
            isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.74,
          ),
          decoration: BoxDecoration(
            color: isMe
                ? kGold.withOpacity(0.14)
                : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            border: Border.all(
              color: isMe
                  ? kGold.withOpacity(0.28)
                  : Colors.grey[850]!,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FIX 2: senderName resolved by ChatScreen via UserService
              if (showName && !isMe && msg.senderName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    msg.senderName,
                    style: const TextStyle(
                        color: kGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),

              // Reply preview
              if (msg.replyToText != null) _replyPreview(),

              // Content
              _content(),

              const SizedBox(height: 4),

              // Time + status
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.isEdited)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text('edited',
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 9,
                              fontStyle: FontStyle.italic)),
                    ),
                  Text(
                    DateFormat('hh:mm a').format(msg.timestamp),
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 10),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    _statusIcon(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _replyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border:
            const Border(left: BorderSide(color: kGold, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.replyToSender != null)
            Text(msg.replyToSender!,
                style: const TextStyle(
                    color: kGold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          Text(msg.replyToText!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.grey[400], fontSize: 11)),
        ],
      ),
    );
  }

  Widget _content() {
    if (msg.isDeleted) {
      return Text('This message was deleted',
          style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontStyle: FontStyle.italic));
    }
    switch (msg.type) {
      case MsgType.sticker:
        return Text(msg.text,
            style: const TextStyle(fontSize: 42));
      case MsgType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(msg.text,
              width: 200, fit: BoxFit.cover),
        );
      case MsgType.audio:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.play_circle_outline, color: kGold),
          const SizedBox(width: 8),
          Text('Voice message',
              style:
                  TextStyle(color: Colors.grey[400], fontSize: 13)),
        ]);
      case MsgType.video:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.videocam_outlined, color: kGold),
          const SizedBox(width: 8),
          Text('Video',
              style:
                  TextStyle(color: Colors.grey[400], fontSize: 13)),
        ]);
      case MsgType.text:
      default:
        return Text(msg.text,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, height: 1.4));
    }
  }

  Widget _statusIcon() {
    switch (msg.status) {
      case MsgStatus.sending:
        return Icon(Icons.access_time,
            size: 12, color: Colors.grey[600]);
      case MsgStatus.sent:
        return Icon(Icons.check,
            size: 12, color: Colors.grey[600]);
      case MsgStatus.delivered:
        return Icon(Icons.done_all,
            size: 12, color: Colors.grey[600]);
      case MsgStatus.seen:
        return const Icon(Icons.done_all, size: 12, color: kGold);
    }
  }
}
