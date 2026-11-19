import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/salary_configuration_model.dart';
import '../providers/salary_provider.dart';

class SalaryConfigurationScreen extends ConsumerStatefulWidget {
  const SalaryConfigurationScreen({super.key});

  @override
  ConsumerState<SalaryConfigurationScreen> createState() => _SalaryConfigurationScreenState();
}

class _SalaryConfigurationScreenState extends ConsumerState<SalaryConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _maleWageController;
  late final TextEditingController _femaleWageController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _maleWageController = TextEditingController();
    _femaleWageController = TextEditingController();
  }

  @override
  void dispose() {
    _maleWageController.dispose();
    _femaleWageController.dispose();
    super.dispose();
  }

  void _save(SalaryConfigurationModel currentConfig) async {
    if (_formKey.currentState!.validate()) {
      final maleWage = double.tryParse(_maleWageController.text) ?? currentConfig.maleDailyWage;
      final femaleWage = double.tryParse(_femaleWageController.text) ?? currentConfig.femaleDailyWage;

      final updatedConfig = SalaryConfigurationModel(
        maleDailyWage: maleWage,
        femaleDailyWage: femaleWage,
      );

      await ref.read(salaryConfigProvider.notifier).saveConfiguration(updatedConfig);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salary configuration saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _reset() {
    setState(() {
      _maleWageController.text = '800.0';
      _femaleWageController.text = '700.0';
    });
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(salaryConfigProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Configuration'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: configAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading configuration...'),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (config) {
            if (!_initialized) {
              _maleWageController.text = config.maleDailyWage.toString();
              _femaleWageController.text = config.femaleDailyWage.toString();
              _initialized = true;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wages Settings',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure the base daily wages used for automatic and manual salary calculations.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Male Daily Wage (₹)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _maleWageController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 800.0',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Please enter male daily wage';
                        if (double.tryParse(val) == null) return 'Please enter a valid number';
                        if (double.parse(val) <= 0) return 'Wage must be greater than 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Female Daily Wage (₹)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _femaleWageController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 700.0',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Please enter female daily wage';
                        if (double.tryParse(val) == null) return 'Please enter a valid number';
                        if (double.parse(val) <= 0) return 'Wage must be greater than 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 48),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _reset,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Reset Defaults'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _save(config),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Save Configuration'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
