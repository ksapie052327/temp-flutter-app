// ── UserService ───────────────────────────────────────────────────────────────
// Manages user data in Firestore.
// FIX 2: resolveNames() — resolves senderId → display name for messages
//         Uses in-memory cache to avoid repeated Firestore reads
// ──────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../auth/auth_service.dart';

class UserService {
  UserService._();

  static final _db = FirebaseFirestore.instance;

  // ── FIX 2: In-memory name cache ────────────────────
  // uid → display name
  // Populated on first fetch, reused for all subsequent renders
  static final Map<String, String> _nameCache = {};

  // ── FIX 2: Resolve sender name ─────────────────────
  // Returns name from cache or fetches from Firestore once

  static Future<String> resolveName(String uid) async {
    if (_nameCache.containsKey(uid)) return _nameCache[uid]!;

    try {
      final doc =
          await _db.collection(kUsersCollection).doc(uid).get();
      final name = doc.data()?['name'] as String? ?? 'Unknown';
      _nameCache[uid] = name;
      return name;
    } catch (_) {
      return 'Unknown';
    }
  }

  // ── FIX 2: Resolve multiple names at once ──────────
  // Batch resolves all unique senderIds in a message list
  // Returns map of uid → name

  static Future<Map<String, String>> resolveNames(
      Set<String> uids) async {
    final result = <String, String>{};
    final toFetch = <String>[];

    // Check cache first
    for (final uid in uids) {
      if (_nameCache.containsKey(uid)) {
        result[uid] = _nameCache[uid]!;
      } else {
        toFetch.add(uid);
      }
    }

    // Batch fetch missing names
    if (toFetch.isNotEmpty) {
      for (final uid in toFetch) {
        try {
          final doc = await _db
              .collection(kUsersCollection)
              .doc(uid)
              .get();
          final name =
              doc.data()?['name'] as String? ?? 'Unknown';
          _nameCache[uid] = name;
          result[uid] = name;
        } catch (_) {
          result[uid] = 'Unknown';
        }
      }
    }

    return result;
  }

  // ── Clear name cache ───────────────────────────────
  // Call on logout

  static void clearCache() => _nameCache.clear();

  // ── Get single user ────────────────────────────────

  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db
          .collection(kUsersCollection)
          .doc(uid)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  // ── Stream single user ─────────────────────────────

  static Stream<UserModel?> userStream(String uid) {
    return _db
        .collection(kUsersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  // ── Get all verified users except me ──────────────

  static Future<List<UserModel>> getApprovedUsers() async {
    final myUid = AuthService.currentUid;
    try {
      final snap = await _db
          .collection(kUsersCollection)
          .where('isEmailVerified', isEqualTo: true)
          .get();
      return snap.docs
          .map((d) => UserModel.fromMap(d.data()))
          .where((u) => u.uid != myUid)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
