import 'dart:async';

import 'package:flutter/material.dart';

import '../state/conversation_controller.dart';

Future<void> showCompanionSettings(
  BuildContext context,
  ConversationController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => CompanionSettingsSheet(controller: controller),
  );
}

class CompanionSettingsSheet extends StatefulWidget {
  const CompanionSettingsSheet({super.key, required this.controller});

  final ConversationController controller;

  @override
  State<CompanionSettingsSheet> createState() => _CompanionSettingsSheetState();
}

class _CompanionSettingsSheetState extends State<CompanionSettingsSheet> {
  late final TextEditingController _url = TextEditingController(
    text: widget.controller.settings.baseUrl,
  );
  String? _urlError;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await widget.controller.updateBackendUrl(_url.text);
    if (!mounted) {
      return;
    }
    if (!saved) {
      setState(() {
        _urlError = 'Enter a full http or https URL.';
      });
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Settings', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                key: const Key('backend-url-field'),
                controller: _url,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Backend URL',
                  errorText: _urlError,
                  helperText:
                      'Android emulator: http://10.0.2.2:8080. '
                      'iOS simulator: http://127.0.0.1:8080.',
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: const Key('save-backend-url'),
                  onPressed: () => unawaited(_save()),
                  child: const Text('Save URL'),
                ),
              ),
              SwitchListTile(
                key: const Key('speak-replies-switch'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Speak replies'),
                value: widget.controller.speakReplies,
                onChanged: (value) {
                  unawaited(widget.controller.setSpeakReplies(value));
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
