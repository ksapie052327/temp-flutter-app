// ── BiometricService ──────────────────────────────────────────────────────────
// Handles ONLY fingerprint/biometric authentication.
// No UI code. No Firebase. No pattern logic.
// Returns bool — authenticated or not.
// ──────────────────────────────────────────────────────────────────────────────

import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._();

  static final _auth = LocalAuthentication();

  // ── Can use biometrics? ────────────────────────────

  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  // ── Authenticate ───────────────────────────────────
  // Returns true if fingerprint verified
  // Returns false if failed or unavailable
  // Silent fail — never throws to UI

  static Future<bool> authenticate() async {
    try {
      final available = await isAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: ' ', // blank — no system prompt text shown
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,         // keeps prompt open if app goes background
          sensitiveTransaction: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
