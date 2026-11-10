import 'package:flutter/material.dart';

class ComposerBar extends StatefulWidget {
  const ComposerBar({super.key, required this.enabled, required this.onSend});

  final bool enabled;
  final ValueChanged<String> onSend;

  @override
  State<ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends State<ComposerBar> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    if (!widget.enabled) {
      return;
    }
    final value = _text.text;
    if (value.trim().isEmpty) {
      return;
    }
    widget.onSend(value);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('message-field'),
            controller: _text,
            enabled: widget.enabled,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'Or type a message',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          key: const Key('send-button'),
          tooltip: 'Send',
          onPressed: widget.enabled ? _submit : null,
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }
}
