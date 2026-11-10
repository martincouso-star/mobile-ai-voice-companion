import 'dart:async';

import 'package:flutter/material.dart';

import '../state/conversation_controller.dart';
import '../widgets/chat_transcript.dart';
import '../widgets/composer_bar.dart';
import '../widgets/push_to_talk_button.dart';
import 'settings_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final ConversationController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final phase = controller.phase;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Voice Companion'),
            actions: [
              IconButton(
                tooltip: 'New conversation',
                onPressed: () => unawaited(controller.newConversation()),
                icon: const Icon(Icons.add_comment_outlined),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: () =>
                    unawaited(showCompanionSettings(context, controller)),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      controller.errorMessage!,
                      key: const Key('error-text'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Expanded(
                  child: controller.messages.isEmpty
                      ? const _EmptyConversation()
                      : ChatTranscript(messages: controller.messages),
                ),
                if (controller.partialTranscript.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      controller.partialTranscript,
                      key: const Key('partial-transcript'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    _statusLabel(phase),
                    key: const Key('status-label'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                if (controller.providerName != null)
                  Text(
                    'Replies from ${controller.providerName}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 12, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      PushToTalkButton(
                        listening: phase == CompanionPhase.listening,
                        enabled: phase != CompanionPhase.thinking,
                        onPressStart: () => unawaited(controller.pressMic()),
                        onPressEnd: () => unawaited(controller.releaseMic()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ComposerBar(
                          enabled: controller.canSend,
                          onSend: (text) =>
                              unawaited(controller.sendText(text)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusLabel(CompanionPhase phase) {
    switch (phase) {
      case CompanionPhase.listening:
        return 'Listening…';
      case CompanionPhase.thinking:
        return 'Thinking…';
      case CompanionPhase.speaking:
        return 'Speaking…';
      case CompanionPhase.idle:
        return 'Hold to talk';
    }
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mic_none,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hold the mic and talk, or type a message.',
                      textAlign: TextAlign.center,
                      style: style,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
