// ── ChatService ───────────────────────────────────────────────────────────────
// FIX 1: serverTimestamp() for all message writes
// FIX 2: senderName NOT stored — only senderId
// FIX 3: edit/delete check senderId == currentUid before writing
// FIX 4: message status flow — sent → delivered → seen
// FIX 5: deterministic chatId prevents duplicate private chats
// FIX 6: chats always filtered by participants arrayContains
// FIX 7: no debug prints, clean imports
// ──────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../auth/auth_service.dart';

class ChatService {
  ChatService._();

  static final _db = FirebaseFirestore.instance;

  // ── FIX 6: Chats stream ────────────────────────────
  // Always filtered by participants arrayContains — never bypass this

  static Stream<List<ChatModel>> chatsStream() {
    final uid = AuthService.currentUid!;
    return _db
        .collection(kChatsCollection)
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Messages stream ────────────────────────────────
  // FIX 1: ordered by server timestamp ascending

  static Stream<List<MessageModel>> messagesStream(String chatId) {
    return _db
        .collection(kChatsCollection)
        .doc(chatId)
        .collection(kMessagesCollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ── FIX 1 + 2: Send message ────────────────────────
  // Uses FieldValue.serverTimestamp() — NOT DateTime.now()
  // Does NOT store senderName — only senderId

  static Future<void> sendMessage({
    required String chatId,
    required String text,
    MsgType type = MsgType.text,
    String? replyToId,
    String? replyToText,
    String? replyToSender,
  }) async {
    final uid = AuthService.currentUid!;

    final msgRef = _db
        .collection(kChatsCollection)
        .doc(chatId)
        .collection(kMessagesCollection)
        .doc();

    final batch = _db.batch();

    // FIX 1: serverTimestamp for consistent ordering across devices
    // FIX 2: only senderId stored — senderName resolved at display time
    batch.set(msgRef, {
      'text': type == MsgType.text ? text : text,
      'senderId': uid,
      // senderName intentionally NOT stored here
      'type': type.index,
      'status': MsgStatus.sent.index,
      'timestamp': FieldValue.serverTimestamp(), // ← FIX 1
      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToSender': replyToSender, // snapshot acceptable for reply context
      'isEdited': false,
      'isDeleted': false,
      'seenBy': [uid], // sender has seen their own message
    });

    // Update chat summary
    batch.update(
      _db.collection(kChatsCollection).doc(chatId),
      {
        'lastMessage': type == MsgType.text ? text : _typePreview(type),
        'updatedAt': FieldValue.serverTimestamp(), // ← FIX 1
        'lastSenderId': uid,
      },
    );

    await batch.commit();
  }

  // ── FIX 3: Edit message ────────────────────────────
  // Verifies senderId == currentUid before writing

  static Future<void> editMessage({
    required String chatId,
    required String msgId,
    required String newText,
    required String senderId, // passed from UI — checked here
  }) async {
    final uid = AuthService.currentUid!;

    // FIX 3: Only sender can edit their own message
    if (senderId != uid) return;

    await _db
        .collection(kChatsCollection)
        .doc(chatId)
        .collection(kMessagesCollection)
        .doc(msgId)
        .update({
      'text': newText.trim(),
      'isEdited': true,
    });
  }

  // ── FIX 3: Delete message ──────────────────────────
  // Verifies senderId == currentUid before writing

  static Future<void> deleteMessage({
    required String chatId,
    required String msgId,
    required String senderId, // passed from UI — checked here
  }) async {
    final uid = AuthService.currentUid!;

    // FIX 3: Only sender can delete their own message
    if (senderId != uid) return;

    await _db
        .collection(kChatsCollection)
        .doc(chatId)
        .collection(kMessagesCollection)
        .doc(msgId)
        .update({
      'isDeleted': true,
      'text': '',
    });
  }

  // ── FIX 4: Mark delivered ──────────────────────────
  // Called when message is received by other user

  static Future<void> markDelivered({
    required String chatId,
    required String msgId,
    required String senderId,
  }) async {
    final uid = AuthService.currentUid!;

    // Don't mark your own messages as delivered
    if (senderId == uid) return;

    await _db
        .collection(kChatsCollection)
        .doc(chatId)
        .collection(kMessagesCollection)
        .doc(msgId)
        .update({
      'status': MsgStatus.delivered.index,
    });
  }

  // ── FIX 4: Mark seen ───────────────────────────────
  // Called when chat is opened and messages are visible

  static Future<void> markSeen({
    required String chatId,
    required String msgId,
    required String senderId,
  }) async {
    final uid = AuthService.currentUid!;

    // Don't mark your own messages
    if (senderId == uid) return;

    await _db
        .collection(kChatsCollection)
        .doc(chatId)
        .collection(kMessagesCollection)
        .doc(msgId)
        .update({
      'seenBy': FieldValue.arrayUnion([uid]), // FIX 4
      'status': MsgStatus.seen.index,
    });
  }

  // ── Typing indicator ───────────────────────────────

  static Future<void> setTyping({
    required String chatId,
    required bool isTyping,
  }) async {
    final uid = AuthService.currentUid!;
    try {
      await _db.collection(kChatsCollection).doc(chatId).update({
        'typing.$uid': isTyping,
      });
    } catch (_) {}
  }

  // ── FIX 5: Create private chat ─────────────────────
  // Deterministic chatId = sorted UIDs joined with '_'
  // Prevents duplicate chats between same 2 users

  static Future<String> createPrivateChat({
    required String otherUid,
    required String otherName,
    required String myName,
  }) async {
    final myUid = AuthService.currentUid!;

    // FIX 5: deterministic ID — always same for same pair
    final ids = [myUid, otherUid]..sort();
    final chatId = ids.join('_');

    final ref = _db.collection(kChatsCollection).doc(chatId);
    final existing = await ref.get();

    // Already exists → return same id
    if (existing.exists) return chatId;

    // Create new
    await ref.set({
      'participants': [myUid, otherUid],
      'participantNames': [myName, otherName],
      'type': 'private',
      'name': otherName,
      'lastMessage': null,
      'updatedAt': FieldValue.serverTimestamp(), // FIX 1
      'lastSenderId': null,
    });

    return chatId;
  }

  // ── Create group chat ──────────────────────────────

  static Future<String> createGroupChat({
    required String groupName,
    required List<String> memberUids,
    required List<String> memberNames,
  }) async {
    final ref = _db.collection(kChatsCollection).doc();

    await ref.set({
      'participants': memberUids,
      'participantNames': memberNames,
      'type': 'group',
      'name': groupName,
      'lastMessage': null,
      'updatedAt': FieldValue.serverTimestamp(), // FIX 1
      'lastSenderId': null,
    });

    return ref.id;
  }

  // ── Update background ──────────────────────────────

  static Future<void> updateBackground({
    required String chatId,
    String? backgroundAsset,
  }) async {
    await _db
        .collection(kChatsCollection)
        .doc(chatId)
        .update({'backgroundAsset': backgroundAsset});
  }

  // ── Helper ─────────────────────────────────────────

  static String _typePreview(MsgType type) {
    switch (type) {
      case MsgType.image:   return '📷 Photo';
      case MsgType.video:   return '🎥 Video';
      case MsgType.audio:   return '🎤 Voice message';
      case MsgType.sticker: return '🎭 Sticker';
      case MsgType.text:    return '';
    }
  }
}
