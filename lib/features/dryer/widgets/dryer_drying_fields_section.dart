import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/dryer_visit_model.dart';
import '../utils/dryer_calculator.dart';
import 'dryer_info_widgets.dart';

class DryerDryingFormController extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DryerProduct? _selectedProduct;
  int _productResetVersion = 0;

  final TextEditingController greenQuantityController = TextEditingController();
  final TextEditingController dryQuantityController = TextEditingController();
  final TextEditingController percentageController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController chargesController = TextEditingController();

  DryerDryingFormController() {
    greenQuantityController.addListener(recalculate);
    dryQuantityController.addListener(recalculate);
    rateController.addListener(recalculate);
  }

  DateTime get selectedDate => _selectedDate;
  DryerProduct? get selectedProduct => _selectedProduct;
  int get productResetVersion => _productResetVersion;

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setProduct(DryerProduct? product) {
    _selectedProduct = product;
    notifyListeners();
  }

  void loadFromVisit(DryerVisit visit) {
    _selectedDate = visit.date;
    greenQuantityController.text = DryerCalculator.formatNumber(
      visit.greenQuantity,
      maxDecimals: 3,
    );
    _selectedProduct = visit.product;
    _productResetVersion++;
    dryQuantityController.text = DryerCalculator.formatNumber(
      visit.dryQuantity,
      maxDecimals: 3,
    );
    rateController.text = DryerCalculator.formatNumber(
      visit.rate,
      maxDecimals: 2,
    );
    recalculate();
    notifyListeners();
  }

  void recalculate() {
    final pct = DryerCalculator.tryCalculatePercentage(
      greenQuantityController.text,
      dryQuantityController.text,
    );
    percentageController.text =
        pct != null ? DryerCalculator.formatPercentage(pct) : '';

    final charges = DryerCalculator.tryCalculateCharges(
      greenQuantityController.text,
      rateController.text,
    );
    chargesController.text = charges != null ? formatINR(charges) : '';
  }

  double get parsedGreenQuantity =>
      double.parse(greenQuantityController.text.trim());
  double get parsedDryQuantity =>
      double.parse(dryQuantityController.text.trim());
  double get parsedRate => double.parse(rateController.text.trim());

  @override
  void dispose() {
    greenQuantityController.removeListener(recalculate);
    dryQuantityController.removeListener(recalculate);
    rateController.removeListener(recalculate);
    greenQuantityController.dispose();
    dryQuantityController.dispose();
    percentageController.dispose();
    rateController.dispose();
    chargesController.dispose();
    super.dispose();
  }
}

class DryerDryingFieldsSection extends StatelessWidget {
  final DryerDryingFormController controller;

  const DryerDryingFieldsSection({
    super.key,
    required this.controller,
  });

  Future<void> _pickVisitDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      controller.setDate(picked);
    }
  }

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
                const DryerSectionHeader(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Drying Details',
                ),
                const SizedBox(height: 20),

                // 1. Date
                InkWell(
                  onTap: () => _pickVisitDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date *',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      DryerCalculator.formatDate(controller.selectedDate),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Green Quantity (kg)
                TextFormField(
                  controller: controller.greenQuantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Green Quantity (kg) *',
                    hintText: 'e.g. 600',
                    prefixIcon: Icon(Icons.scale_outlined),
                    suffixText: 'kg',
                  ),
                  validator: (val) => DryerCalculator.validateNumericInput(
                    val,
                    fieldName: 'Green quantity',
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Product
                DropdownButtonFormField<DryerProduct>(
                  key: ValueKey(
                    'dryer_product_${controller.productResetVersion}',
                  ),
                  initialValue: controller.selectedProduct,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Product *',
                    prefixIcon: Icon(Icons.eco_outlined),
                  ),
                  hint: const Text('Select Cardamom, Pepper, or Coffee'),
                  items: DryerProduct.values.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text(product.label),
                    );
                  }).toList(),
                  onChanged: controller.setProduct,
                  validator: (val) {
                    if (val == null) {
                      return 'Product is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 4. Dry Quantity (kg)
                TextFormField(
                  controller: controller.dryQuantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Dry Quantity (kg) *',
                    hintText: 'e.g. 120',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                    suffixText: 'kg',
                  ),
                  validator: (val) => DryerCalculator.validateNumericInput(
                    val,
                    fieldName: 'Dry quantity',
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Percentage (Auto-calculated, Read-only)
                TextFormField(
                  controller: controller.percentageController,
                  readOnly: true,
                  canRequestFocus: false,
                  enableInteractiveSelection: false,
                  decoration: InputDecoration(
                    labelText: 'Percentage',
                    hintText: 'Auto-calculated (Green ÷ Dry)',
                    prefixIcon: const Icon(Icons.calculate_outlined),
                    fillColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.04),
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Rate
                TextFormField(
                  controller: controller.rateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Rate (₹) *',
                    hintText: 'e.g. 10',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (val) => DryerCalculator.validateNumericInput(
                    val,
                    fieldName: 'Rate',
                    allowZero: true,
                  ),
                ),
                const SizedBox(height: 16),

                // 7. Charges (Auto-calculated, Read-only)
                TextFormField(
                  controller: controller.chargesController,
                  readOnly: true,
                  canRequestFocus: false,
                  enableInteractiveSelection: false,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Charges (₹)',
                    hintText: 'Auto-calculated (Green × Rate)',
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    fillColor:
                        theme.colorScheme.primary.withValues(alpha: 0.05),
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
