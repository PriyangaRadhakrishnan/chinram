import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../models/dryer_expense_model.dart';
import '../providers/dryer_expense_provider.dart';
import '../utils/dryer_calculator.dart';
import '../widgets/dryer_info_widgets.dart';

class DryerExpenseDetailScreen extends ConsumerWidget {
  final String expenseId;

  const DryerExpenseDetailScreen({
    super.key,
    required this.expenseId,
  });

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DryerExpense expense,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Expense',
        content:
            'Are you sure you want to permanently delete "${expense.category}" (${formatINR(expense.amount)}) from ${DryerCalculator.formatDate(expense.date)}?',
        confirmLabel: 'Delete',
        onConfirm: () async {
          try {
            await ref
                .read(dryerExpensesProvider.notifier)
                .deleteExpense(expense.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Expense deleted successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.pop();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete expense: $e'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncExpenses = ref.watch(dryerExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: asyncExpenses.when(
          loading: () =>
              const LoadingIndicator(message: 'Loading expense details...'),
          error: (err, stack) => EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Expense',
            description: err.toString(),
            actionLabel: 'Retry',
            onActionPressed: () => ref.invalidate(dryerExpensesProvider),
          ),
          data: (expenses) {
            final expense = expenses
                .cast<DryerExpense?>()
                .firstWhere((e) => e?.id == expenseId, orElse: () => null);

            if (expense == null) {
              return const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Expense Not Found',
                description: 'This expense record could not be found.',
              );
            }

            final hasNotes =
                expense.notes != null && expense.notes!.trim().isNotEmpty;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const DryerSectionHeader(
                                icon: Icons.receipt_long_outlined,
                                title: 'Other Expense Summary',
                              ),
                              const SizedBox(height: 20),
                              DryerDetailRow(
                                label: 'Date',
                                value: DryerCalculator.formatDate(expense.date),
                              ),
                              const Divider(height: 24),
                              DryerDetailRow(
                                label: 'Expense Category',
                                value: expense.category,
                              ),
                              const Divider(height: 24),
                              DryerDetailRow(
                                label: 'Amount',
                                value: formatINR(expense.amount),
                                valueStyle:
                                    theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const Divider(height: 24),
                              DryerDetailRow(
                                label: 'Notes',
                                value: hasNotes ? expense.notes! : 'No notes added',
                                valueStyle: hasNotes
                                    ? theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      )
                                    : theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Edit Expense',
                        onPressed: () =>
                            context.push('/dryer/expenses/edit/$expenseId'),
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        text: 'Delete Expense',
                        onPressed: () => _confirmDelete(context, ref, expense),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
