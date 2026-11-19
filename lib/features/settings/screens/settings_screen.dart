import 'package:flutter/material.dart';
import '../../../shared/widgets/empty_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: Icons.settings_outlined,
          title: 'System Settings',
          description: 'This module is coming soon in the next phase.',
        ),
      ),
    );
  }
}
