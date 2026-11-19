import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../models/dryer_customer_model.dart';
import '../providers/dryer_provider.dart';
import '../utils/dryer_calculator.dart';
import '../widgets/dryer_customer_fields_section.dart';
import '../widgets/dryer_drying_fields_section.dart';

class DryerAddFormScreen extends ConsumerStatefulWidget {
  final String? initialCustomerId;

  const DryerAddFormScreen({
    super.key,
    this.initialCustomerId,
  });

  @override
  ConsumerState<DryerAddFormScreen> createState() => _DryerAddFormScreenState();
}

class _DryerAddFormScreenState extends ConsumerState<DryerAddFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _customerController = DryerCustomerFormController();
  final _dryingController = DryerDryingFormController();

  DryerCustomer? _selectedExistingCustomer;
  List<DryerCustomer> _allCustomers = const [];
  List<DryerCustomer> _phoneSuggestions = const [];
  bool _isInitializingCustomer = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _customerController.dispose();
    _dryingController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitializingCustomer = widget.initialCustomerId != null;
    });

    try {
      final service = ref.read(dryerServiceProvider);
      final customers = await service.getAllCustomers();
      if (!mounted) return;

      DryerCustomer? preselected;
      if (widget.initialCustomerId != null) {
        for (final c in customers) {
          if (c.id == widget.initialCustomerId) {
            preselected = c;
            break;
          }
        }
        preselected ??=
            await service.getCustomerById(widget.initialCustomerId!);
      }

      if (!mounted) return;
      setState(() {
        _allCustomers = customers;
        _isInitializingCustomer = false;
      });

      if (preselected != null) {
        _selectExistingCustomer(preselected);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializingCustomer = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load existing customers: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onPhoneChanged(String value) {
    final trimmed = value.trim();
    final digits = DryerCalculator.normalizePhoneNumber(trimmed);

    List<DryerCustomer> matches = const [];
    if (trimmed.isNotEmpty && (digits.isNotEmpty || trimmed.length >= 2)) {
      matches = _allCustomers.where((customer) {
        if (_selectedExistingCustomer?.id == customer.id) {
          return false;
        }
        final custNormalized =
            DryerCalculator.normalizePhoneNumber(customer.phoneNumber);
        final custDigits = customer.phoneNumber.replaceAll(RegExp(r'\D'), '');
        final inputDigits = trimmed.replaceAll(RegExp(r'\D'), '');

        if (digits.isNotEmpty && custNormalized.contains(digits)) {
          return true;
        }
        if (inputDigits.isNotEmpty && custDigits.contains(inputDigits)) {
          return true;
        }
        return customer.phoneNumber
            .toLowerCase()
            .contains(trimmed.toLowerCase());
      }).toList();
    }

    setState(() {
      _phoneSuggestions = matches;
    });
  }

  void _selectExistingCustomer(DryerCustomer customer) {
    _customerController.loadFromCustomer(customer);
    setState(() {
      _selectedExistingCustomer = customer;
      _phoneSuggestions = const [];
    });
  }

  void _clearExistingCustomer() {
    _customerController.clear();
    setState(() {
      _selectedExistingCustomer = null;
      _phoneSuggestions = const [];
    });
  }

  Future<void> _saveForm() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_customerController.selectedAreaType == null ||
        _dryingController.selectedProduct == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result =
          await ref.read(dryerCustomersProvider.notifier).saveCustomerAndVisit(
                existingCustomerId: _selectedExistingCustomer?.id,
                name: _customerController.nameController.text,
                phoneNumber: _customerController.phoneController.text,
                address: _customerController.addressController.text,
                areaType: _customerController.selectedAreaType!,
                areaValue: _customerController.parsedAreaValue,
                visitDate: _dryingController.selectedDate,
                greenQuantity: _dryingController.parsedGreenQuantity,
                product: _dryingController.selectedProduct!,
                dryQuantity: _dryingController.parsedDryQuantity,
                rate: _dryingController.parsedRate,
              );

      if (!mounted) return;
      final message = result.isNewCustomer
          ? 'Customer and drying visit saved successfully'
          : 'New drying visit saved for ${result.customer.name}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
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
        title: Text(
          _selectedExistingCustomer != null
              ? 'Add Drying Visit'
              : 'Add Customer',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isInitializingCustomer
            ? const LoadingIndicator(message: 'Loading customer profile...')
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
                            onPhoneChanged: _onPhoneChanged,
                            phoneSuggestions: _phoneSuggestions,
                            selectedExistingCustomer: _selectedExistingCustomer,
                            onSelectExistingCustomer: _selectExistingCustomer,
                            onClearExistingCustomer: _clearExistingCustomer,
                          ),
                          const SizedBox(height: 20),
                          DryerDryingFieldsSection(
                            controller: _dryingController,
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            text: _selectedExistingCustomer != null
                                ? 'Save Drying Visit'
                                : 'Save Customer & Visit',
                            isLoading: _isSaving,
                            onPressed: _saveForm,
                          ),
                          const SizedBox(height: 16),
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
