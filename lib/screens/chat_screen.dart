// FIX 2: Resolves senderName from UserService — not from message data
// FIX 3: edit/delete pass senderId to ChatService for verification
// FIX 4: marks messages as seen when chat is opened

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/input_field.dart';

class ChatScreen extends StatefulWidget {
  final ChatModel chat;
  final UserModel me;

  const ChatScreen({super.key, required this.chat, required this.me});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scroll = ScrollController();
  MessageModel? _replyTo;
  bool _showStickers = false;

  // FIX 2: name cache for this chat session
  final Map<String, String> _names = {};

  static const _stickers = [
    '😂','😭','🥰','😍','🤩','😎','🤣','😅','😊','🥺',
    '😢','😤','🤔','😏','🙄','😴','🤯','😱','🤗','😘',
    '💀','👀','🫶','💅','🔥','✨','💫','⭐','🌙','❤️',
    '💕','💖','🎉','🎊','👑','💎','🌸','🦋','🍕','🎂',
  ];

  @override
  void initState() {
    super.initState();
    // Seed my own name in cache
    _names[widget.me.uid] = widget.me.name;
  }

  @override
  void dispose() {
    ChatService.setTyping(chatId: widget.chat.chatId, isTyping: false);
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // FIX 2: Resolve names for all messages in list
  Future<List<MessageModel>> _resolveNames(
      List<MessageModel> msgs) async {
    final uids =
        msgs.map((m) => m.senderId).toSet();
    final resolved =
        await UserService.resolveNames(uids);
    _names.addAll(resolved);
    return msgs
        .map((m) => m.withName(_names[m.senderId] ?? ''))
        .toList();
  }

  Future<void> _send(String text) async {
    final reply = _replyTo;
    setState(() {
      _replyTo = null;
      _showStickers = false;
    });
    await ChatService.sendMessage(
      chatId: widget.chat.chatId,
      text: text,
      replyToId: reply?.msgId,
      replyToText: reply?.text,
      replyToSender: reply?.senderName,
    );
    _scrollToBottom();
  }

  Future<void> _sendSticker(String sticker) async {
    setState(() => _showStickers = false);
    await ChatService.sendMessage(
      chatId: widget.chat.chatId,
      text: sticker,
      type: MsgType.sticker,
    );
    _scrollToBottom();
  }

  // FIX 4: Mark messages as seen
  Future<void> _markMessagesAsSeen(List<MessageModel> msgs) async {
    for (final msg in msgs) {
      if (msg.senderId != widget.me.uid &&
          !msg.seenBy.contains(widget.me.uid)) {
        await ChatService.markSeen(
          chatId: widget.chat.chatId,
          msgId: msg.msgId,
          senderId: msg.senderId,
        );
      }
    }
  }

  void _onLongPress(MessageModel msg) {
    final isMe = msg.senderId == widget.me.uid;
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 8),
          if (!msg.isDeleted) ...[
            ListTile(
              leading: const Icon(Icons.reply, color: kGold),
              title: const Text('Reply',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyTo = msg);
              },
            ),
            // FIX 3: Only show edit/delete for own messages
            if (isMe) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined,
                    color: kGold),
                title: const Text('Edit',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(msg);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.redAccent),
                title: const Text('Delete',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(context);
                  // FIX 3: senderId passed — verified in ChatService
                  await ChatService.deleteMessage(
                    chatId: widget.chat.chatId,
                    msgId: msg.msgId,
                    senderId: msg.senderId,
                  );
                },
              ),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showEditDialog(MessageModel msg) {
    final ctrl = TextEditingController(text: msg.text);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Edit Message',
            style: TextStyle(color: kGold)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          maxLines: null,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (ctrl.text.trim().isNotEmpty) {
                // FIX 3: senderId passed — verified in ChatService
                await ChatService.editMessage(
                  chatId: widget.chat.chatId,
                  msgId: msg.msgId,
                  newText: ctrl.text.trim(),
                  senderId: msg.senderId,
                );
              }
            },
            child: const Text('Save',
                style: TextStyle(color: kGold)),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final displayName = widget.chat.otherName(widget.me.uid);

    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGold.withOpacity(0.1),
                border: Border.all(
                    color: kGold.withOpacity(0.3), width: 1.5),
              ),
              child: Center(
                child: Text(
                  widget.chat.isGroup
                      ? '👥'
                      : displayName[0].toUpperCase(),
                  style: TextStyle(
                    color: kGold,
                    fontSize: widget.chat.isGroup ? 15 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(displayName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: ChatService.messagesStream(
                  widget.chat.chatId),
              builder: (context, snap) {
                if (snap.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: kGold));
                }

                final rawMsgs = snap.data ?? [];

                if (rawMsgs.isEmpty) {
                  return Center(
                    child: Text(
                      '🔐\nSay something!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          height: 1.8),
                    ),
                  );
                }

                // FIX 4: Mark unseen messages as seen
                WidgetsBinding.instance
                    .addPostFrameCallback((_) {
                  _markMessagesAsSeen(rawMsgs);
                  _scrollToBottom();
                });

                // FIX 2: Resolve names then build list
                return FutureBuilder<List<MessageModel>>(
                  future: _resolveNames(rawMsgs),
                  builder: (context, nameSnap) {
                    final msgs =
                        nameSnap.data ?? rawMsgs;
                    return ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(
                          12, 12, 12, 4),
                      itemCount: msgs.length,
                      itemBuilder: (_, i) {
                        final msg = msgs[i];
                        final showDate = i == 0 ||
                            !_isSameDay(
                                msgs[i - 1].timestamp,
                                msg.timestamp);
                        return Column(
                          children: [
                            if (showDate)
                              _dateDivider(msg.timestamp),
                            MessageBubble(
                              msg: msg,
                              isMe: msg.senderId ==
                                  widget.me.uid,
                              showName: widget.chat.isGroup,
                              onLongPress: () =>
                                  _onLongPress(msg),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Reply bar
          if (_replyTo != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              color: kSurface,
              child: Row(
                children: [
                  Container(
                      width: 3, height: 36, color: kGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyTo!.senderName.isNotEmpty
                              ? _replyTo!.senderName
                              : _names[_replyTo!.senderId] ??
                                  '',
                          style: const TextStyle(
                              color: kGold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(_replyTo!.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.grey, size: 18),
                    onPressed: () =>
                        setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),

          // Sticker panel
          if (_showStickers)
            Container(
              height: 180,
              color: kSurface,
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                scrollDirection: Axis.horizontal,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _stickers.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _sendSticker(_stickers[i]),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(_stickers[i],
                          style:
                              const TextStyle(fontSize: 26)),
                    ),
                  ),
                ),
              ),
            ),

          // Input
          InputField(
            onSend: _send,
            onStickerTap: () => setState(
                () => _showStickers = !_showStickers),
            showStickers: _showStickers,
          ),
        ],
      ),
    );
  }

  Widget _dateDivider(DateTime dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[850])),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              DateFormat('MMMM dd, yyyy').format(dt),
              style: TextStyle(
                  color: Colors.grey[600], fontSize: 11),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[850])),
        ],
      ),
    );
  }
}
