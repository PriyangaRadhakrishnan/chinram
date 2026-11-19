import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/dryer_customer_model.dart';
import '../utils/dryer_calculator.dart';
import 'dryer_info_widgets.dart';

class DryerCustomerFormController extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController areaValueController = TextEditingController();

  DryerAreaType? _selectedAreaType;
  int _areaTypeResetVersion = 0;

  DryerAreaType? get selectedAreaType => _selectedAreaType;
  int get areaTypeResetVersion => _areaTypeResetVersion;

  void setAreaType(DryerAreaType? type) {
    _selectedAreaType = type;
    notifyListeners();
  }

  void loadFromCustomer(DryerCustomer customer) {
    nameController.text = customer.name;
    phoneController.text = customer.phoneNumber;
    addressController.text = customer.address;
    _selectedAreaType = customer.areaType;
    _areaTypeResetVersion++;
    areaValueController.text = DryerCalculator.formatNumber(
      customer.areaValue,
      maxDecimals: 3,
    );
    notifyListeners();
  }

  void clear() {
    nameController.clear();
    phoneController.clear();
    addressController.clear();
    _selectedAreaType = null;
    _areaTypeResetVersion++;
    areaValueController.clear();
    notifyListeners();
  }

  double get parsedAreaValue => double.parse(areaValueController.text.trim());

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    areaValueController.dispose();
    super.dispose();
  }
}

class DryerCustomerFieldsSection extends StatelessWidget {
  final DryerCustomerFormController controller;
  final ValueChanged<String>? onPhoneChanged;
  final List<DryerCustomer> phoneSuggestions;
  final DryerCustomer? selectedExistingCustomer;
  final ValueChanged<DryerCustomer>? onSelectExistingCustomer;
  final VoidCallback? onClearExistingCustomer;

  const DryerCustomerFieldsSection({
    super.key,
    required this.controller,
    this.onPhoneChanged,
    this.phoneSuggestions = const [],
    this.selectedExistingCustomer,
    this.onSelectExistingCustomer,
    this.onClearExistingCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DryerSectionHeader(
                  icon: Icons.person_outline,
                  title: 'Customer Information',
                  trailing: selectedExistingCustomer != null &&
                          onClearExistingCustomer != null
                      ? TextButton.icon(
                          onPressed: onClearExistingCustomer,
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
                          label: const Text('New Customer'),
                        )
                      : null,
                ),
                if (selectedExistingCustomer != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 18,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Returning customer selected (${selectedExistingCustomer!.name}). Saving will record a new drying visit under this profile without creating a duplicate customer.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // 1. Customer Name
                TextFormField(
                  controller: controller.nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    hintText: 'Enter customer full name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (val) => DryerCalculator.validateRequiredText(
                    val,
                    'Customer name',
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Phone Number (Primary returning customer identifier)
                TextFormField(
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: onPhoneChanged,
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    hintText:
                        'Enter phone number (searches returning customers)',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    suffixIcon: controller.phoneController.text.isNotEmpty &&
                            onPhoneChanged != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            tooltip: 'Clear phone number',
                            onPressed: () {
                              controller.phoneController.clear();
                              onPhoneChanged!('');
                            },
                          )
                        : null,
                  ),
                  validator: DryerCalculator.validatePhoneNumber,
                ),

                // Phone lookup suggestions
                if (phoneSuggestions.isNotEmpty &&
                    onSelectExistingCustomer != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                          child: Text(
                            'Returning Customers Found',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ...phoneSuggestions.take(5).map((customer) {
                          final areaText = DryerCalculator.formatArea(
                            customer.areaType,
                            customer.areaValue,
                          );
                          return InkWell(
                            onTap: () => onSelectExistingCustomer!(customer),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customer.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${customer.phoneNumber} • $areaText',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Select',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // 3. Address
                TextFormField(
                  controller: controller.addressController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Address *',
                    hintText: 'Enter customer address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (val) =>
                      DryerCalculator.validateRequiredText(val, 'Address'),
                ),
                const SizedBox(height: 16),

                // 4. Area Type
                DropdownButtonFormField<DryerAreaType>(
                  key: ValueKey(
                    'dryer_area_type_${controller.areaTypeResetVersion}',
                  ),
                  initialValue: controller.selectedAreaType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Area Type *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  hint: const Text('Select Acre or Plants'),
                  items: DryerAreaType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    );
                  }).toList(),
                  onChanged: controller.setAreaType,
                  validator: (val) {
                    if (val == null) {
                      return 'Area type is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 5. Area Value
                TextFormField(
                  controller: controller.areaValueController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Area Value *',
                    hintText: controller.selectedAreaType == DryerAreaType.plants
                        ? 'e.g. 500'
                        : 'e.g. 2 or 2.5',
                    prefixIcon: const Icon(Icons.straighten_outlined),
                    suffixText: controller.selectedAreaType?.label,
                  ),
                  validator: (val) => DryerCalculator.validateNumericInput(
                    val,
                    fieldName: 'Area value',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
