import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'state/conversation_controller.dart';

class VoiceCompanionApp extends StatelessWidget {
  const VoiceCompanionApp({super.key, required this.controller});

  final ConversationController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Companion',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F7A6B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(controller: controller),
    );
  }
}
