import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'auth_service.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';
import '../screens/chat_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

 Future<void> _login() async {
  if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
    setState(() => _error = 'Please fill all fields');
    return;
  }

  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );

    final user = cred.user;

    if (user != null) {
      await user.reload();

      if (!mounted) return;

      if (user.emailVerified) {
        await AuthService.setPresence(isOnline: true);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatHomeScreen()),
        );
      } else {
        setState(() => _loading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
        );
      }
    }
  } on FirebaseAuthException catch (e) {
    setState(() {
      _error = e.message ?? "Login failed";
      _loading = false;
    });
  } catch (e) {
    setState(() {
      _error = "Something went wrong";
      _loading = false;
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kGold, width: 1.5),
                        color: kGold.withOpacity(0.08),
                      ),
                      child: const Center(
                        child: Text('✨', style: TextStyle(fontSize: 32)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      kAppName,
                      style: TextStyle(
                        color: kGold,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'private · encrypted · yours',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          letterSpacing: 2),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              const Text('Welcome back',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Login to continue',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),

              const SizedBox(height: 28),

              if (_error != null) ...[
                _errorBox(_error!),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Email address',
                  prefixIcon:
                      Icon(Icons.email_outlined, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: Colors.white),
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                        size: 20),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: kBlack))
                      : const Text('Login'),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegisterScreen()),
                  ),
                  child: Text("Don't have an account? Sign up",
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[900]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red[800]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: const TextStyle(
                    color: Colors.redAccent, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
