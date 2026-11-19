import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../models/dryer_visit_model.dart';
import '../providers/dryer_provider.dart';
import '../widgets/dryer_drying_fields_section.dart';

class DryerVisitEditScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String visitId;

  const DryerVisitEditScreen({
    super.key,
    required this.customerId,
    required this.visitId,
  });

  @override
  ConsumerState<DryerVisitEditScreen> createState() =>
      _DryerVisitEditScreenState();
}

class _DryerVisitEditScreenState extends ConsumerState<DryerVisitEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dryingController = DryerDryingFormController();

  DryerVisit? _existingVisit;
  bool _isLoading = true;
  String? _loadError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVisit());
  }

  @override
  void dispose() {
    _dryingController.dispose();
    super.dispose();
  }

  Future<void> _loadVisit() async {
    try {
      final service = ref.read(dryerServiceProvider);
      final visit = await service.getVisitById(widget.visitId);
      if (!mounted) return;
      if (visit == null) {
        setState(() {
          _isLoading = false;
          _loadError = 'Drying visit record not found.';
        });
        return;
      }

      _dryingController.loadFromVisit(visit);
      setState(() {
        _existingVisit = visit;
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
    if (_isSaving || _existingVisit == null) return;
    if (!_formKey.currentState!.validate()) return;
    if (_dryingController.selectedProduct == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(dryerCustomersProvider.notifier).updateVisit(
            existingVisit: _existingVisit!,
            date: _dryingController.selectedDate,
            greenQuantity: _dryingController.parsedGreenQuantity,
            product: _dryingController.selectedProduct!,
            dryQuantity: _dryingController.parsedDryQuantity,
            rate: _dryingController.parsedRate,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Drying visit updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
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
        title: const Text('Edit Drying Visit'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const LoadingIndicator(message: 'Loading visit record...')
            : _loadError != null
                ? EmptyState(
                    icon: Icons.error_outline,
                    title: 'Unable to Load Visit',
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
                              DryerDryingFieldsSection(
                                controller: _dryingController,
                              ),
                              const SizedBox(height: 24),
                              PrimaryButton(
                                text: 'Update Drying Visit',
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
