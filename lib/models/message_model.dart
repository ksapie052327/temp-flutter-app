// ── MessageModel ──────────────────────────────────────────────────────────────
// FIX 1: Timestamp — handles null from serverTimestamp() on first render
// FIX 2: senderName removed from storage — only senderId stored
//         senderName is resolved at display time via UserService
// ──────────────────────────────────────────────────────────────────────────────

enum MsgType { text, image, video, audio, sticker }
enum MsgStatus { sending, sent, delivered, seen }

class MessageModel {
  final String msgId;
  final String text;
  final String senderId;       // Firebase UID only — never trust client name
  final String senderName;     // Resolved at display time — NOT stored in Firestore
  final MsgType type;
  final MsgStatus status;
  final DateTime timestamp;    // Never null in model — fallback to now() if null
  final String? replyToId;
  final String? replyToText;
  final String? replyToSender; // Snapshot of name at reply time — acceptable
  final bool isEdited;
  final bool isDeleted;
  final List<String> seenBy;   // List of UIDs who have seen

  const MessageModel({
    required this.msgId,
    required this.text,
    required this.senderId,
    this.senderName = '',      // Empty by default — resolved by UI
    required this.type,
    required this.status,
    required this.timestamp,
    this.replyToId,
    this.replyToText,
    this.replyToSender,
    this.isEdited = false,
    this.isDeleted = false,
    this.seenBy = const [],
  });

  // ── Firestore → Model ──────────────────────────────
  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    // FIX 1: serverTimestamp() returns null on first snapshot
    // Handle safely — fallback to now() prevents crash
    DateTime timestamp;
    final raw = map['timestamp'];
    if (raw is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(raw);
    } else {
      // serverTimestamp() pending — use now() as fallback
      // Message will re-render with correct time on next snapshot
      timestamp = DateTime.now();
    }

    return MessageModel(
      msgId: id,
      text: map['text'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: '',           // NOT read from Firestore — resolved by UI
      type: MsgType.values[map['type'] as int? ?? 0],
      status: MsgStatus.values[map['status'] as int? ?? 1],
      timestamp: timestamp,
      replyToId: map['replyToId'] as String?,
      replyToText: map['replyToText'] as String?,
      replyToSender: map['replyToSender'] as String?,
      isEdited: map['isEdited'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      seenBy: List<String>.from(map['seenBy'] as List? ?? []),
    );
  }

  // ── Model → Firestore ──────────────────────────────
  // FIX 2: senderName is NOT included — only senderId
  // Timestamp is handled separately as FieldValue.serverTimestamp()
  Map<String, dynamic> toMap() => {
        'text': text,
        'senderId': senderId,
        // senderName intentionally excluded — resolved at display time
        'type': type.index,
        'status': status.index,
        // timestamp handled as FieldValue.serverTimestamp() in ChatService
        'replyToId': replyToId,
        'replyToText': replyToText,
        'replyToSender': replyToSender,
        'isEdited': isEdited,
        'isDeleted': isDeleted,
        'seenBy': seenBy,
      };

  // ── For chat list preview ──────────────────────────
  String get preview {
    if (isDeleted) return 'Message deleted';
    switch (type) {
      case MsgType.image:   return '📷 Photo';
      case MsgType.video:   return '🎥 Video';
      case MsgType.audio:   return '🎤 Voice message';
      case MsgType.sticker: return '🎭 Sticker';
      case MsgType.text:    return text;
    }
  }

  // ── Copy with resolved name ────────────────────────
  // Used by UI to attach resolved sender name without re-fetching
  MessageModel withName(String name) => MessageModel(
        msgId: msgId,
        text: text,
        senderId: senderId,
        senderName: name,
        type: type,
        status: status,
        timestamp: timestamp,
        replyToId: replyToId,
        replyToText: replyToText,
        replyToSender: replyToSender,
        isEdited: isEdited,
        isDeleted: isDeleted,
        seenBy: seenBy,
      );

  MessageModel copyWith({
    String? text,
    MsgStatus? status,
    bool? isEdited,
    bool? isDeleted,
    List<String>? seenBy,
  }) =>
      MessageModel(
        msgId: msgId,
        text: text ?? this.text,
        senderId: senderId,
        senderName: senderName,
        type: type,
        status: status ?? this.status,
        timestamp: timestamp,
        replyToId: replyToId,
        replyToText: replyToText,
        replyToSender: replyToSender,
        isEdited: isEdited ?? this.isEdited,
        isDeleted: isDeleted ?? this.isDeleted,
        seenBy: seenBy ?? this.seenBy,
      );
}
