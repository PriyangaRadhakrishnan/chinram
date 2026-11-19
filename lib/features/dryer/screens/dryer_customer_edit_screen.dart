import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../models/dryer_customer_model.dart';
import '../providers/dryer_provider.dart';
import '../widgets/dryer_customer_fields_section.dart';

class DryerCustomerEditScreen extends ConsumerStatefulWidget {
  final String customerId;

  const DryerCustomerEditScreen({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<DryerCustomerEditScreen> createState() =>
      _DryerCustomerEditScreenState();
}

class _DryerCustomerEditScreenState
    extends ConsumerState<DryerCustomerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = DryerCustomerFormController();

  DryerCustomer? _existingCustomer;
  bool _isLoading = true;
  String? _loadError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustomer());
  }

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomer() async {
    try {
      final service = ref.read(dryerServiceProvider);
      final customer = await service.getCustomerById(widget.customerId);
      if (!mounted) return;
      if (customer == null) {
        setState(() {
          _isLoading = false;
          _loadError = 'Customer profile not found.';
        });
        return;
      }

      _customerController.loadFromCustomer(customer);
      setState(() {
        _existingCustomer = customer;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _saveForm() async {
    if (_isSaving || _existingCustomer == null) return;
    if (!_formKey.currentState!.validate()) return;
    if (_customerController.selectedAreaType == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = _existingCustomer!.copyWith(
        name: _customerController.nameController.text.trim(),
        phoneNumber: _customerController.phoneController.text.trim(),
        address: _customerController.addressController.text.trim(),
        areaType: _customerController.selectedAreaType!,
        areaValue: _customerController.parsedAreaValue,
      );

      await ref.read(dryerCustomersProvider.notifier).updateCustomer(updated);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer profile updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Bad state: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Customer'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const LoadingIndicator(message: 'Loading customer profile...')
            : _loadError != null
                ? EmptyState(
                    icon: Icons.error_outline,
                    title: 'Unable to Load Customer',
                    description: _loadError!,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DryerCustomerFieldsSection(
                                controller: _customerController,
                              ),
                              const SizedBox(height: 24),
                              PrimaryButton(
                                text: 'Update Customer Profile',
                                isLoading: _isSaving,
                                onPressed: _saveForm,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
