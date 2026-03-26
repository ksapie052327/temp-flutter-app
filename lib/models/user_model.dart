class UserModel {
  final String uid;
  final String email;
  final String name;
  final bool isEmailVerified;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final String? publicKey;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.isEmailVerified,
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
    this.publicKey,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      isOnline: map['isOnline'] as bool? ?? false,
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'] as int)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
      publicKey: map['publicKey'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        'isEmailVerified': isEmailVerified,
        'isOnline': isOnline,
        'lastSeen': lastSeen?.millisecondsSinceEpoch,
        'createdAt': createdAt?.millisecondsSinceEpoch,
        'publicKey': publicKey,
      };

  UserModel copyWith({
    String? name,
    bool? isEmailVerified,
    bool? isOnline,
    DateTime? lastSeen,
    String? publicKey,
  }) =>
      UserModel(
        uid: uid,
        email: email,
        name: name ?? this.name,
        isEmailVerified: isEmailVerified ?? this.isEmailVerified,
        isOnline: isOnline ?? this.isOnline,
        lastSeen: lastSeen ?? this.lastSeen,
        createdAt: createdAt,
        publicKey: publicKey ?? this.publicKey,
      );
}
