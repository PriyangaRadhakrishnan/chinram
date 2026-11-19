import 'package:flutter/material.dart';

class FilterState {
  final DateTime? date;
  final String? month;
  final String? year;
  final String? category;
  final String? gender;
  final String? status;

  const FilterState({
    this.date,
    this.month,
    this.year,
    this.category,
    this.gender,
    this.status,
  });

  FilterState copyWith({
    DateTime? Function()? date,
    String? Function()? month,
    String? Function()? year,
    String? Function()? category,
    String? Function()? gender,
    String? Function()? status,
  }) {
    return FilterState(
      date: date != null ? date() : this.date,
      month: month != null ? month() : this.month,
      year: year != null ? year() : this.year,
      category: category != null ? category() : this.category,
      gender: gender != null ? gender() : this.gender,
      status: status != null ? status() : this.status,
    );
  }
}

class FilterBarWidget extends StatelessWidget {
  final FilterState filters;
  final List<String> categories;
  final ValueChanged<FilterState> onFiltersChanged;
  final bool isWorkerFilter;

  const FilterBarWidget({
    super.key,
    required this.filters,
    this.categories = const [],
    required this.onFiltersChanged,
    this.isWorkerFilter = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => (currentYear - 2 + index).toString());

    final hasActiveFilters = isWorkerFilter
        ? (filters.gender != null || filters.status != null)
        : (filters.date != null || filters.month != null || filters.year != null || filters.category != null);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Filters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      onFiltersChanged(const FilterState());
                    },
                    child: const Text('Clear All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: isWorkerFilter
                  ? [
                      // Gender Filter
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: filters.gender,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All Genders')),
                            DropdownMenuItem(value: 'Male', child: Text('Male')),
                            DropdownMenuItem(value: 'Female', child: Text('Female')),
                          ],
                          onChanged: (val) {
                            onFiltersChanged(filters.copyWith(gender: () => val));
                          },
                        ),
                      ),
                      // Status Filter
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: filters.status,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All Statuses')),
                            DropdownMenuItem(value: 'Active', child: Text('Active')),
                            DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                          ],
                          onChanged: (val) {
                            onFiltersChanged(filters.copyWith(status: () => val));
                          },
                        ),
                      ),
                    ]
                  : [
                      // Category Filter
                      SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<String>(
                          initialValue: filters.category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Categories')),
                            ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                          ],
                          onChanged: (val) {
                            onFiltersChanged(filters.copyWith(category: () => val));
                          },
                        ),
                      ),
                      
                      // Month Filter
                      SizedBox(
                        width: 140,
                        child: DropdownButtonFormField<String>(
                          initialValue: filters.month,
                          decoration: const InputDecoration(
                            labelText: 'Month',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Months')),
                            ...months.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                          ],
                          onChanged: (val) {
                            onFiltersChanged(filters.copyWith(month: () => val));
                          },
                        ),
                      ),

                      // Year Filter
                      SizedBox(
                        width: 120,
                        child: DropdownButtonFormField<String>(
                          initialValue: filters.year,
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Years')),
                            ...years.map((y) => DropdownMenuItem(value: y, child: Text(y))),
                          ],
                          onChanged: (val) {
                            onFiltersChanged(filters.copyWith(year: () => val));
                          },
                        ),
                      ),

                      // Date Picker Filter Button
                      OutlinedButton.icon(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: filters.date ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (selected != null) {
                            onFiltersChanged(filters.copyWith(date: () => selected));
                          }
                        },
                        icon: const Icon(Icons.calendar_month, size: 18),
                        label: Text(
                          filters.date == null
                              ? 'Select Date'
                              : '${filters.date!.day}/${filters.date!.month}/${filters.date!.year}',
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      if (filters.date != null)
                        IconButton(
                          icon: const Icon(Icons.clear_outlined, size: 18),
                          onPressed: () {
                            onFiltersChanged(filters.copyWith(date: () => null));
                          },
                        ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}
