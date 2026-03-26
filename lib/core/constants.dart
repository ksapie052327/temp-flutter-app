import 'package:flutter/material.dart';

// ── Colors ──────────────────────────────────────────
const kGold = Color(0xFFFFD700);
const kBlack = Color(0xFF000000);
const kSurface = Color(0xFF111111);
const kBorder = Color(0xFF222222);

// ── Firestore Collections ────────────────────────────
const kUsersCollection = 'users';
const kChatsCollection = 'chats';
const kMessagesCollection = 'messages';
const kKeysCollection = 'keys';

// ── Hive Boxes ───────────────────────────────────────
const kSecureBox = 'ksapie_secure';
const kPrefsBox = 'ksapie_prefs';

// ── Hive Keys ────────────────────────────────────────
const kPatternKey = 'unlock_pattern';
const kPrivateKeyKey = 'private_key';
const kUserNameKey = 'user_name';

// ── App Config ───────────────────────────────────────
const kAppName = 'KSApie';
const kMaxUsers = 100;
const kPatternSimilarityThreshold = 75.0;
const kPatternTolerance = 85.0;
const kMinPatternPoints = 10;
