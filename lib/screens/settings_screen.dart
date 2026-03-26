import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../auth/auth_service.dart';
import '../security/art_screen.dart';
import '../security/pattern_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _name = user.name;
        _email = user.email;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Profile', [
            _tile(
              icon: Icons.person_outline,
              title: 'Display Name',
              subtitle: _name,
              onTap: () => _changeName(),
            ),
            _tile(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: _email,
              onTap: null,
            ),
          ]),
          const SizedBox(height: 16),
          _section('Security', [
            _tile(
              icon: Icons.gesture,
              title: 'Reset Unlock Signature',
              subtitle: 'You\'ll draw a new one on next unlock',
              onTap: () => _resetSignature(),
            ),
          ]),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text('Logout',
                style: TextStyle(color: Colors.redAccent)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _logout(),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  letterSpacing: 2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: kGold, size: 22),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style:
              TextStyle(color: Colors.grey[600], fontSize: 12)),
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: Colors.grey[700])
          : null,
      onTap: onTap,
    );
  }

  void _changeName() {
    final ctrl = TextEditingController(text: _name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Change Name',
            style: TextStyle(color: kGold)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (ctrl.text.trim().isNotEmpty) {
                await AuthService.updateName(ctrl.text.trim());
                setState(() => _name = ctrl.text.trim());
              }
            },
            child:
                const Text('Save', style: TextStyle(color: kGold)),
          ),
        ],
      ),
    );
  }

  void _resetSignature() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Reset Signature?',
            style: TextStyle(color: kGold)),
        content: const Text(
          'Your current signature will be deleted.\nDraw a new one on next unlock.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await PatternService.deletePattern();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signature reset ✅'),
                    backgroundColor: Colors.black87,
                  ),
                );
              }
            },
            child: const Text('Reset',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ArtScreen()),
        (_) => false,
      );
    }
  }
}
