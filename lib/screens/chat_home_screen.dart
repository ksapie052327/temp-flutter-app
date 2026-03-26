import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../auth/auth_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/chat_tile.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  UserModel? _me;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadMe();
    AuthService.setPresence(isOnline: true);
  }

  @override
  void dispose() {
    AuthService.setPresence(isOnline: false);
    super.dispose();
  }

  Future<void> _loadMe() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) setState(() => _me = user);
  }

  @override
  Widget build(BuildContext context) {
    final myUid = AuthService.currentUid ?? '';

    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        title: const Text(kAppName),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (v) =>
                  setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: Icon(Icons.search,
                    color: Colors.grey[600], size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // Chat list
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: ChatService.chatsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: kGold));
                }

                final chats = (snap.data ?? [])
                    .where((c) =>
                        _search.isEmpty ||
                        c.name.toLowerCase().contains(_search))
                    .toList();

                if (chats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('✨',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        const Text('No chats yet',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16)),
                        const SizedBox(height: 6),
                        Text('Tap + to start a conversation',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (_, i) => ChatTile(
                    chat: chats[i],
                    myUid: myUid,
                    onTap: () {
                      if (_me == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chat: chats[i],
                            me: _me!,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kGold,
        foregroundColor: kBlack,
        child: const Icon(Icons.chat_bubble_outline),
        onPressed: () => _showNewChatSheet(),
      ),
    );
  }

  void _showNewChatSheet() async {
    if (_me == null) return;
    final users = await AuthService.getAllUsers();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NewChatSheet(users: users, me: _me!),
    );
  }
}

// ── New Chat Sheet ─────────────────────────────────────
class _NewChatSheet extends StatelessWidget {
  final List<UserModel> users;
  final UserModel me;
  const _NewChatSheet({required this.users, required this.me});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 14),
        const Text('New Chat',
            style: TextStyle(
                color: kGold,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        if (users.isEmpty)
          Expanded(
            child: Center(
              child: Text('No other users yet',
                  style: TextStyle(color: Colors.grey[500])),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (ctx, i) {
                final u = users[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: kGold.withOpacity(0.15),
                    child: Text(u.name[0].toUpperCase(),
                        style: const TextStyle(color: kGold)),
                  ),
                  title: Text(u.name,
                      style:
                          const TextStyle(color: Colors.white)),
                  subtitle: Text(u.email,
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: u.isOnline
                              ? Colors.greenAccent
                              : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        u.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          color: u.isOnline
                              ? Colors.greenAccent
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final chatId =
                        await ChatService.createPrivateChat(
                      otherUid: u.uid,
                      otherName: u.name,
                      myName: me.name,
                    );
                    if (ctx.mounted) {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chat: ChatModel(
                              chatId: chatId,
                              participants: [me.uid, u.uid],
                              participantNames: [me.name, u.name],
                              type: 'private',
                              name: u.name,
                            ),
                            me: me,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
