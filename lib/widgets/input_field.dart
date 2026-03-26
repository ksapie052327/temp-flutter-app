// ── InputField ────────────────────────────────────────────────────────────────
// Message input bar. Pure UI widget.
// Callbacks go up to ChatScreen — no service calls here.
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../core/constants.dart';

class InputField extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback onStickerTap;
  final bool showStickers;

  const InputField({
    super.key,
    required this.onSend,
    required this.onStickerTap,
    this.showStickers = false,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  final _ctrl = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _ctrl.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      decoration: BoxDecoration(
        color: kBlack,
        border: Border(top: BorderSide(color: Colors.grey[900]!)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Sticker button
          IconButton(
            icon: Icon(
              widget.showStickers
                  ? Icons.keyboard
                  : Icons.emoji_emotions_outlined,
              color: Colors.grey[600],
            ),
            onPressed: widget.onStickerTap,
          ),

          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey[850]!),
              ),
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: Colors.grey[700]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: _hasText ? _send : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _hasText ? kGold : Colors.grey[850],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                color: _hasText ? kBlack : Colors.grey[600],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
