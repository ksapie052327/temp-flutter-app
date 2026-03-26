// ── ArtScreen ─────────────────────────────────────────────────────────────────
// The disguise layer. Looks like a drawing app.
// Calls PatternService and BiometricService — never Firebase directly.
// After unlock success → checks AuthService → navigates accordingly.
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../security/pattern_service.dart';
import '../security/biometric_service.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../auth/verify_email_screen.dart';
import '../screens/chat_home_screen.dart';

// ── Draw point ────────────────────────────────────────
class _DP {
  final double x;
  final double y;
  final Color color;
  final double size;
  _DP(this.x, this.y, this.color, this.size);
}

// ── Painter ───────────────────────────────────────────
class _Painter extends CustomPainter {
  final List<_DP?> pts;
  final Color bg;
  _Painter(this.pts, this.bg);

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height),
        Paint()..color = bg);
    for (int i = 0; i < pts.length - 1; i++) {
      if (pts[i] != null && pts[i + 1] != null) {
        c.drawLine(
          Offset(pts[i]!.x, pts[i]!.y),
          Offset(pts[i + 1]!.x, pts[i + 1]!.y),
          Paint()
            ..color = pts[i]!.color
            ..strokeWidth = pts[i]!.size
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      } else if (pts[i] != null && pts[i + 1] == null) {
        c.drawCircle(
          Offset(pts[i]!.x, pts[i]!.y),
          pts[i]!.size / 2,
          Paint()..color = pts[i]!.color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Painter old) => true;
}

// ── Art Screen ────────────────────────────────────────
class ArtScreen extends StatefulWidget {
  const ArtScreen({super.key});

  @override
  State<ArtScreen> createState() => _ArtScreenState();
}

class _ArtScreenState extends State<ArtScreen> {
  // Drawing state
  final List<_DP?> _pts = [];
  Color _color = Colors.black;
  Color _canvas = Colors.white;
  double _size = 4.0;

  // Unlock state
  bool _blackCanvas = false;
  bool _goldColor = false;
  bool _showBar = false;
  bool _showHello = false;
  bool _busy = false;

  static const _gold = kGold;

  final _colors = <Color>[
    Colors.black, Colors.white, Colors.red, Colors.blue,
    Colors.green, Colors.purple, Colors.orange, Colors.pink,
    Colors.brown, Colors.teal, kGold, Colors.grey, Colors.cyan,
  ];

  // ── Color selected ─────────────────────────────────
  void _onColor(Color c) {
    setState(() {
      _color = c;
      _goldColor = _blackCanvas && c == _gold;
      _showBar = _goldColor;
      if (!_goldColor) _showHello = false;
    });
  }

  // ── Canvas selected ────────────────────────────────
  void _onCanvas(Color c) {
    setState(() {
      _canvas = c;
      _pts.clear();
      _blackCanvas = c == Colors.black;
      if (!_blackCanvas) {
        _goldColor = false;
        _showBar = false;
        _showHello = false;
      }
    });
  }

  // ── Bar double tapped ──────────────────────────────
  Future<void> _onBarTap() async {
    if (!_blackCanvas || !_goldColor || _busy) return;

    setState(() {
      _showHello = true;
      _busy = true;
    });

    // Small delay so "Hello" text is visible before biometric prompt
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    await _unlock();

    if (mounted) setState(() => _busy = false);
  }

  // ── Unlock flow ────────────────────────────────────
  // Pattern → Biometric → Auth check → Navigate
  Future<void> _unlock() async {
    // Convert points for PatternService
    final drawn = _pts
        .where((p) => p != null)
        .map((p) => DrawPoint(p!.x, p.y))
        .toList();

    // First time — save pattern
    if (!PatternService.hasPattern()) {
      if (drawn.length < kMinPatternPoints) {
        _snack('Draw your signature first!');
        setState(() => _showHello = false);
        return;
      }
      await PatternService.savePattern(drawn);
      _snack('Signature saved! ✅ Draw again to unlock.');
      setState(() => _showHello = false);
      return;
    }

    // Compare pattern
    final patternOk = PatternService.compare(drawn);
    if (!patternOk) {
      // Silent fail — no error shown
      setState(() => _showHello = false);
      return;
    }

    // Biometric
    final bioOk = await BiometricService.authenticate();
    if (!bioOk || !mounted) {
      setState(() => _showHello = false);
      return;
    }

    // Not logged in → go to login
    if (!AuthService.isLoggedIn) {
      _navigate(const LoginScreen());
      return;
    }

    // Reload to get fresh verification status
    await AuthService.reloadUser();
    if (!mounted) return;

    // Email not verified → go to verify screen
    if (!AuthService.isEmailVerified) {
      _navigate(const VerifyEmailScreen());
      return;
    }

    // All good → go to chat
    await AuthService.setPresence(isOnline: true);
    if (mounted) _navigate(const ChatHomeScreen());
  }

  void _navigate(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.black87,
      duration: const Duration(seconds: 2),
    ));
  }

  bool get _isDark => _canvas == Colors.black;

  String get _helloText {
    final user = AuthService.currentUid;
    if (user == null) return 'Hello there';
    // Will use cached name in next phase
    return 'Hello ✨';
  }

  // ── Build ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          kAppName,
          style: TextStyle(
            color: _isDark ? _gold : Colors.black87,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: _isDark ? _gold : Colors.black87),
            onPressed: () => setState(() {
              _pts.clear();
              _showHello = false;
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas
          Expanded(
            child: GestureDetector(
              onPanStart: (d) => setState(() => _pts
                  .add(_DP(d.localPosition.dx, d.localPosition.dy,
                      _color, _size))),
              onPanUpdate: (d) => setState(() => _pts
                  .add(_DP(d.localPosition.dx, d.localPosition.dy,
                      _color, _size))),
              onPanEnd: (_) => setState(() => _pts.add(null)),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _Painter(_pts, _canvas),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),

          // Secret bar
          if (_showBar)
            GestureDetector(
              onDoubleTap: _onBarTap,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    top: BorderSide(
                        color: _gold.withOpacity(0.25), width: 1),
                  ),
                ),
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showHello ? 1.0 : 0.1,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _showHello ? _helloText : '— — —',
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Canvas selector
          Container(
            color: _isDark ? const Color(0xFF0A0A0A) : Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Row(
              children: [
                Text('Canvas:',
                    style: TextStyle(
                        fontSize: 12,
                        color: _isDark
                            ? Colors.grey[600]
                            : Colors.black54)),
                const SizedBox(width: 8),
                _canvasBtn(Colors.white, 'White'),
                _canvasBtn(Colors.black, 'Black'),
                _canvasBtn(const Color(0xFFFFFDE7), 'Cream'),
                _canvasBtn(const Color(0xFFE8F5E9), 'Mint'),
              ],
            ),
          ),

          // Palette + brush
          Container(
            color: _isDark
                ? const Color(0xFF0D0D0D)
                : Colors.grey[100],
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colors.length,
                    itemBuilder: (_, i) {
                      final c = _colors[i];
                      final sel = _color == c;
                      return GestureDetector(
                        onTap: () => _onColor(c),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: sel
                                  ? Colors.blue
                                  : Colors.grey[600]!,
                              width: sel ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.brush,
                        size: 16,
                        color: _isDark
                            ? Colors.grey[600]
                            : Colors.black54),
                    Expanded(
                      child: Slider(
                        value: _size,
                        min: 1,
                        max: 24,
                        activeColor: _isDark ? _gold : Colors.blue,
                        onChanged: (v) =>
                            setState(() => _size = v),
                      ),
                    ),
                    Text(
                      '${_size.toInt()}px',
                      style: TextStyle(
                          fontSize: 11,
                          color: _isDark
                              ? Colors.grey[600]
                              : Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _canvasBtn(Color c, String label) {
    final sel = _canvas == c;
    return GestureDetector(
      onTap: () => _onCanvas(c),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: sel ? Colors.blue : Colors.grey[600]!,
              width: sel ? 2 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: c == Colors.black ? Colors.white : Colors.black87,
                fontWeight:
                    sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
