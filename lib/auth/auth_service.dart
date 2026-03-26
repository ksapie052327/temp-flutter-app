// ── AuthService ───────────────────────────────────────────────────────────────
// All auth operations. No admin approval. Access = email verified.
// OTP = Firebase email verification (sent automatically on register).
// ──────────────────────────────────────────────────────────────────────────────

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import '../services/user_service.dart';

class AuthService {
  AuthService._();

  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // ── Identity ───────────────────────────────────────
  static User? get _fbUser => _auth.currentUser;
  static String? get currentUid => _fbUser?.uid;
  static bool get isLoggedIn => _fbUser != null;
  static bool get isEmailVerified => _fbUser?.emailVerified ?? false;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Register ───────────────────────────────────────
  // Creates account + sends email verification
  // Returns null on success, error string on failure

  static Future<String?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;

      // Send verification email immediately
      await cred.user!.sendEmailVerification();

      // Create Firestore user document
      final user = UserModel(
        uid: uid,
        email: email.trim(),
        name: name.trim(),
        isEmailVerified: false,
        createdAt: DateTime.now(),
      );
      await _db.collection(kUsersCollection).doc(uid).set(user.toMap());

      return null; // success
    } on FirebaseAuthException catch (e) {
      return _errorMsg(e.code);
    } catch (_) {
      return 'Something went wrong. Try again.';
    }
  }

  // ── Login ──────────────────────────────────────────
  // Returns null on success, error string on failure

  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _errorMsg(e.code);
    } catch (_) {
      return 'Something went wrong. Try again.';
    }
  }

  // ── Resend verification email ──────────────────────

  static Future<String?> resendVerification() async {
    try {
      await _fbUser?.sendEmailVerification();
      return null;
    } catch (_) {
      return 'Failed to send email. Try again.';
    }
  }

  // ── Reload user (check verification status) ────────
  // Call this when user returns from email link

  static Future<void> reloadUser() async {
    await _fbUser?.reload();
    // Update Firestore if now verified
    if (_auth.currentUser?.emailVerified == true) {
      final uid = currentUid;
      if (uid != null) {
        await _db.collection(kUsersCollection).doc(uid).update({
          'isEmailVerified': true,
        });
      }
    }
  }

  // ── Logout ─────────────────────────────────────────

  static Future<void> logout() async {
    await setPresence(isOnline: false);
    await _auth.signOut();
    UserService.clearCache(); // FIX 2: clear name cache on logout
  }

  // ── Get current user from Firestore ───────────────

  static Future<UserModel?> getCurrentUser() async {
    final uid = currentUid;
    if (uid == null) return null;
    try {
      final doc =
          await _db.collection(kUsersCollection).doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  // ── Stream current user ────────────────────────────

  static Stream<UserModel?> currentUserStream() {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);
    return _db
        .collection(kUsersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  // ── Presence ───────────────────────────────────────

  static Future<void> setPresence({required bool isOnline}) async {
    final uid = currentUid;
    if (uid == null) return;
    try {
      await _db.collection(kUsersCollection).doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  // ── Update name ────────────────────────────────────

  static Future<String?> updateName(String name) async {
    final uid = currentUid;
    if (uid == null) return 'Not logged in';
    try {
      await _db
          .collection(kUsersCollection)
          .doc(uid)
          .update({'name': name.trim()});
      return null;
    } catch (_) {
      return 'Failed to update name';
    }
  }

  // ── Get all users except me ────────────────────────

  static Future<List<UserModel>> getAllUsers() async {
    final myUid = currentUid;
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

  // ── Error messages ─────────────────────────────────

  static String _errorMsg(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'network-request-failed':
        return 'No internet connection';
      default:
        return 'Authentication failed. Try again';
    }
  }
}
