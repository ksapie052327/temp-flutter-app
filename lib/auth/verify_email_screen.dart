// ── VerifyEmailScreen ─────────────────────────────────────────────────────────
// Shown after register OR when user logs in but email not verified.
// User opens email → clicks link → comes back → taps "I verified it"
// Firebase confirms verification → enter app.
// ──────────────────────────────────────────────────────────────────────────────
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'auth_service.dart';
import '../screens/chat_home_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _resending = false;
  bool _checking = false;
  String? _message;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    // Auto-check every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _autoCheck());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _autoCheck() async {
    await AuthService.reloadUser();
    if (AuthService.isEmailVerified && mounted) {
      _timer?.cancel();
      await AuthService.setPresence(isOnline: true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatHomeScreen()),
      );
    }
  }

  Future<void> _manualCheck() async {
    setState(() => _checking = true);
    await AuthService.reloadUser();
    if (!mounted) return;

    if (AuthService.isEmailVerified) {
      _timer?.cancel();
      await AuthService.setPresence(isOnline: true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatHomeScreen()),
      );
    } else {
      setState(() {
        _checking = false;
        _message = 'Email not verified yet. Check your inbox.';
      });
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    setState(() => _resending = true);

    final error = await AuthService.resendVerification();

    if (!mounted) return;

    setState(() {
      _resending = false;
      _message = error ?? 'Verification email sent!';
      _resendCooldown = 30;
    });

    // Countdown timer
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) t.cancel();
    });
  }

  Future<void> _logout() async {
    _timer?.cancel();
    await AuthService.logout();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📧', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),

              const Text(
                'Verify your email',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'We sent a verification link to\n${FirebaseAuth.instance.currentUser?.email ?? 'your email'}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.6),
              ),

              const SizedBox(height: 8),
              Text(
                'Open the email and tap the link, then come back here.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5),
              ),

              const SizedBox(height: 32),

              // Message feedback
              if (_message != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _message!.contains('sent')
                          ? Colors.greenAccent
                          : Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Main CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checking ? null : _manualCheck,
                  child: _checking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: kBlack))
                      : const Text("I've verified my email"),
                ),
              ),

              const SizedBox(height: 12),

              // Resend
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: (_resending || _resendCooldown > 0)
                      ? null
                      : _resend,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _resending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: kGold))
                      : Text(
                          _resendCooldown > 0
                              ? 'Resend in ${_resendCooldown}s'
                              : 'Resend email',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              TextButton(
                onPressed: _logout,
                child: Text('Use a different account',
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
