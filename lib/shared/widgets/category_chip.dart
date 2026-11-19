import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String category;

  const CategoryChip({
    super.key,
    required this.category,
  });

  Color _getBackgroundColor(BuildContext context, String cat) {
    final theme = Theme.of(context);
    switch (cat.toLowerCase()) {
      case 'coconut':
        return Colors.brown.withValues(alpha: 0.1);
      case 'mango':
        return Colors.orange.withValues(alpha: 0.1);
      case 'milk':
        return Colors.indigo.withValues(alpha: 0.1);
      case 'coffee':
        return theme.colorScheme.primary.withValues(alpha: 0.1);
      case 'pepper':
        return Colors.blueGrey.withValues(alpha: 0.1);
      case 'cardamom':
        return Colors.green.withValues(alpha: 0.1);
      case 'areca nut (pakku)':
      case 'areca nut':
        return Colors.amber.withValues(alpha: 0.1);
      case 'avocado':
        return theme.colorScheme.secondary.withValues(alpha: 0.1);
      case 'banana':
        return Colors.orange.withValues(alpha: 0.1);
      case 'clove (kirambu)':
      case 'clove':
        return Colors.purple.withValues(alpha: 0.1);
      case 'nutmeg (jathika)':
      case 'nutmeg':
        return Colors.red.withValues(alpha: 0.1);
      case 'jackfruit':
        return Colors.brown.withValues(alpha: 0.1);
      default:
        return Colors.teal.withValues(alpha: 0.1);
    }
  }

  Color _getTextColor(BuildContext context, String cat) {
    final theme = Theme.of(context);
    switch (cat.toLowerCase()) {
      case 'coconut':
        return Colors.brown.shade800;
      case 'mango':
        return Colors.orange.shade900;
      case 'milk':
        return Colors.indigo.shade800;
      case 'coffee':
        return theme.colorScheme.primary;
      case 'pepper':
        return Colors.blueGrey.shade800;
      case 'cardamom':
        return Colors.green.shade800;
      case 'areca nut (pakku)':
      case 'areca nut':
        return Colors.amber.shade900;
      case 'avocado':
        return theme.colorScheme.secondary;
      case 'banana':
        return Colors.orange.shade900;
      case 'clove (kirambu)':
      case 'clove':
        return Colors.purple.shade800;
      case 'nutmeg (jathika)':
      case 'nutmeg':
        return Colors.red.shade800;
      case 'jackfruit':
        return Colors.brown.shade800;
      default:
        return Colors.teal.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context, category),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: _getTextColor(context, category),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
