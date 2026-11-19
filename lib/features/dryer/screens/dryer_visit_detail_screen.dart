import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../models/dryer_customer_summary.dart';
import '../models/dryer_visit_model.dart';
import '../providers/dryer_provider.dart';
import '../utils/dryer_calculator.dart';
import '../widgets/dryer_info_widgets.dart';

class DryerVisitDetailScreen extends ConsumerWidget {
  final String customerId;
  final String visitId;

  const DryerVisitDetailScreen({
    super.key,
    required this.customerId,
    required this.visitId,
  });

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DryerVisit visit,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Drying Visit',
        content:
            'Are you sure you want to delete this ${visit.product.label} visit from ${DryerCalculator.formatDate(visit.date)}? The customer profile will remain unchanged.',
        confirmLabel: 'Delete',
        onConfirm: () async {
          try {
            await ref.read(dryerCustomersProvider.notifier).deleteVisit(visit.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Drying visit deleted successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.pop();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete visit: $e'),
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
    final asyncSummaries = ref.watch(dryerCustomersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drying Visit Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: asyncSummaries.when(
          loading: () =>
              const LoadingIndicator(message: 'Loading visit details...'),
          error: (err, stack) => EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Visit',
            description: err.toString(),
          ),
          data: (summaries) {
            final summary = summaries
                .cast<DryerCustomerSummary?>()
                .firstWhere(
                  (s) => s?.customer.id == customerId,
                  orElse: () => null,
                );
            final visit = summary?.visits
                .cast<DryerVisit?>()
                .firstWhere((v) => v?.id == visitId, orElse: () => null);

            if (summary == null || visit == null) {
              return const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Visit Not Found',
                description: 'This drying visit record could not be found.',
              );
            }

            final customer = summary.customer;

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
                              SizedBox(
                                width: double.infinity,
                                child: Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    CategoryChip(category: visit.product.label),
                                    Text(
                                      DryerCalculator.formatDate(visit.date),
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                customer.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${customer.phoneNumber} • ${DryerCalculator.formatArea(customer.areaType, customer.areaValue)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Divider(height: 32),
                              DryerDetailRow(
                                label: 'Visit Date',
                                value: DryerCalculator.formatDate(visit.date),
                              ),
                              const Divider(height: 24),
                              DryerDetailRow(
                                label: 'Product',
                                value: visit.product.label,
                              ),
                              const Divider(height: 24),
                              DryerDetailRow(
                                label: 'Green Quantity',
                                value:
                                    '${DryerCalculator.formatQuantity(visit.greenQuantity)} kg',
                              ),
                              const Divider(height: 24),
                              DryerDetailRow(
                                label: 'Dry Quantity',
                                value:
                                    '${DryerCalculator.formatQuantity(visit.dryQuantity)} kg',
                              ),
                              const Divider(height: 24),
                              DryerDetailRow(
                                label: 'Percentage',
                                value: DryerCalculator.formatPercentage(
                                  visit.percentage,
                                ),
                              ),
                              const Divider(height: 24),
                              DryerDetailRow(
                                label: 'Rate',
                                value: formatINR(visit.rate),
                              ),
                              const Divider(height: 24),
                              DryerDetailRow(
                                label: 'Charges',
                                value: formatINR(visit.charges),
                                valueStyle:
                                    theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Edit Visit',
                        onPressed: () => context.push(
                          '/dryer/customer/$customerId/visit/$visitId/edit',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        text: 'Delete Visit',
                        onPressed: () => _confirmDelete(context, ref, visit),
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
