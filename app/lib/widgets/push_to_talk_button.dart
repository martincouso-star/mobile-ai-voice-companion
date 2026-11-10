import 'package:flutter/material.dart';

class PushToTalkButton extends StatelessWidget {
  const PushToTalkButton({
    super.key,
    required this.listening,
    required this.enabled,
    required this.onPressStart,
    required this.onPressEnd,
  });

  final bool listening;
  final bool enabled;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = listening ? scheme.tertiaryContainer : scheme.primary;
    final foreground = listening
        ? scheme.onTertiaryContainer
        : scheme.onPrimary;

    return Listener(
      key: const Key('push-to-talk'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: enabled ? (_) => onPressStart() : null,
      onPointerUp: (_) => onPressEnd(),
      onPointerCancel: (_) => onPressEnd(),
      child: Semantics(
        button: true,
        label: listening ? 'Release to send' : 'Hold to talk',
        child: Material(
          color: background,
          shape: const CircleBorder(),
          elevation: listening ? 0 : 2,
          child: SizedBox(
            width: 76,
            height: 76,
            child: Icon(
              listening ? Icons.graphic_eq : Icons.mic,
              color: foreground,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}
