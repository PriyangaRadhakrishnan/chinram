import 'package:flutter/material.dart';
import '../../../shared/widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: Icons.notifications_outlined,
          title: 'Notifications Center',
          description: 'This module is coming soon in the next phase.',
        ),
      ),
    );
  }
}
