// ── main.dart ─────────────────────────────────────────────────────────────────
// Entry point. Initializes everything before app starts.
// Decides first screen based on auth state.
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'security/art_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );

  // Black status bar + nav bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Init Hive — local encrypted storage
  await Hive.initFlutter();
  await Hive.openBox(kSecureBox);
  await Hive.openBox(kPrefsBox);

  // Init Firebase
  await Firebase.initializeApp();

  runApp(const KSApieApp());
}

class KSApieApp extends StatelessWidget {
  const KSApieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: KTheme.dark,
      // Always start at art screen
      // Auth check happens inside unlock flow
      home: const ArtScreen(),
    );
  }
}
