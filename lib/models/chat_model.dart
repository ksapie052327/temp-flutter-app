// Firestore structure:
// chats/{chatId}
//   participants: [uid1, uid2]
//   type: "private" | "group"
//   lastMessage: string
//   updatedAt: timestamp
//   messages/{messageId} → see MessageModel

class ChatModel {
  final String chatId;
  final List<String> participants; // Firebase UIDs
  final List<String> participantNames; // for display
  final String type; // "private" or "group"
  final String name; // group name OR other user's name
  final String? lastMessage;
  final DateTime? updatedAt;
  final String? lastSenderId;

  const ChatModel({
    required this.chatId,
    required this.participants,
    required this.participantNames,
    required this.type,
    required this.name,
    this.lastMessage,
    this.updatedAt,
    this.lastSenderId,
  });

  bool get isGroup => type == 'group';

  // Other person's name in a private chat
  String otherName(String myUid) {
    if (isGroup) return name;
    final idx = participants.indexOf(myUid);
    if (participantNames.length < 2) return name;
    return idx == 0 ? participantNames[1] : participantNames[0];
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    // Handle updatedAt — can be null on first write (serverTimestamp race)
    DateTime? updatedAt;
    final raw = map['updatedAt'];
    if (raw is int) {
      updatedAt = DateTime.fromMillisecondsSinceEpoch(raw);
    }

    return ChatModel(
      chatId: id,
      participants: List<String>.from(map['participants'] as List? ?? []),
      participantNames:
          List<String>.from(map['participantNames'] as List? ?? []),
      type: map['type'] as String? ?? 'private',
      name: map['name'] as String? ?? '',
      lastMessage: map['lastMessage'] as String?,
      updatedAt: updatedAt,
      lastSenderId: map['lastSenderId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'participants': participants,
        'participantNames': participantNames,
        'type': type,
        'name': name,
        'lastMessage': lastMessage,
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
        'lastSenderId': lastSenderId,
      };
}
