import 'package:flutter/material.dart';
import '../../../shared/widgets/empty_state.dart';

class EstateSubPlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const EstateSubPlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: SafeArea(
        child: EmptyState(
          icon: icon,
          title: title,
          description: 'This estate sub-module is under construction and will be implemented in a later phase.',
        ),
      ),
    );
  }
}
