import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/dryer_customer_summary.dart';
import '../models/dryer_visit_model.dart';
import '../providers/dryer_provider.dart';
import '../utils/dryer_calculator.dart';
import '../widgets/dryer_info_widgets.dart';

class DryerCustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const DryerCustomerDetailScreen({
    super.key,
    required this.customerId,
  });

  void _confirmDeleteVisit(
    BuildContext context,
    WidgetRef ref,
    DryerVisit visit,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Drying Visit',
        content:
            'Are you sure you want to delete the ${visit.product.label} drying visit from ${DryerCalculator.formatDate(visit.date)}? The customer profile will be preserved.',
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

  void _confirmDeleteCustomer(
    BuildContext context,
    WidgetRef ref,
    DryerCustomerSummary summary,
  ) {
    final visitText = summary.visitCount == 0
        ? ''
        : ' and all ${summary.visitCount} drying ${summary.visitCount == 1 ? 'visit' : 'visits'}';
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Customer Profile',
        content:
            'Are you sure you want to permanently delete ${summary.customer.name}$visitText? This action cannot be undone.',
        confirmLabel: 'Delete Customer',
        onConfirm: () async {
          try {
            await ref
                .read(dryerCustomersProvider.notifier)
                .deleteCustomer(summary.customer.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Customer profile deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.pop();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete customer: $e'),
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
        title: const Text('Customer Details'),
        centerTitle: true,
        actions: asyncSummaries.maybeWhen(
          data: (list) {
            final summary = list
                .cast<DryerCustomerSummary?>()
                .firstWhere((s) => s?.customer.id == customerId, orElse: () => null);
            if (summary == null) return null;
            return [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    context.push('/dryer/customer/$customerId/edit');
                  } else if (value == 'delete') {
                    _confirmDeleteCustomer(context, ref, summary);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Customer'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete Customer',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ];
          },
          orElse: () => null,
        ),
      ),
      body: SafeArea(
        child: asyncSummaries.when(
          loading: () =>
              const LoadingIndicator(message: 'Loading customer details...'),
          error: (err, stack) => EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Customer',
            description: err.toString(),
            actionLabel: 'Retry',
            onActionPressed: () => ref.invalidate(dryerCustomersProvider),
          ),
          data: (list) {
            final summary = list
                .cast<DryerCustomerSummary?>()
                .firstWhere((s) => s?.customer.id == customerId, orElse: () => null);

            if (summary == null) {
              return const EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Customer Not Found',
                description: 'This customer profile could not be found.',
              );
            }

            final customer = summary.customer;
            final visits = summary.visits;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Customer Profile Card
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
                              DryerSectionHeader(
                                icon: Icons.person_outline,
                                title: 'Customer Profile',
                                trailing: OutlinedButton.icon(
                                  onPressed: () => context.push(
                                    '/dryer/customer/$customerId/edit',
                                  ),
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Edit Customer'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              DryerDetailRow(
                                label: 'Customer Name',
                                value: customer.name,
                                valueStyle: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const Divider(height: 24),
                              DryerDetailRow(
                                label: 'Phone Number',
                                value: customer.phoneNumber,
                              ),
                              const Divider(height: 24),
                              DryerDetailRow(
                                label: 'Address',
                                value: customer.address,
                              ),
                              const Divider(height: 24),
                              DryerDetailRow(
                                label: 'Area Type',
                                value: customer.areaType.label,
                              ),
                              const Divider(height: 24),
                              DryerDetailRow(
                                label: 'Area Value',
                                value: DryerCalculator.formatArea(
                                  customer.areaType,
                                  customer.areaValue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Previous Visits Header
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Text(
                            'Previous Visits (${visits.length})',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => context.push(
                              '/dryer/add?customerId=${Uri.encodeComponent(customer.id)}',
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Visit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (visits.isEmpty)
                        Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: theme.dividerColor),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.local_fire_department_outlined,
                                  size: 40,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No Visits Remaining',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Customer profile is preserved. Add a new drying visit anytime.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visits.length,
                          itemBuilder: (context, index) {
                            final visit = visits[index];
                            return DryerVisitCard(
                              visit: visit,
                              onTap: () => context.push(
                                '/dryer/customer/$customerId/visit/${visit.id}',
                              ),
                              onEdit: () => context.push(
                                '/dryer/customer/$customerId/visit/${visit.id}/edit',
                              ),
                              onDelete: () =>
                                  _confirmDeleteVisit(context, ref, visit),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
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
