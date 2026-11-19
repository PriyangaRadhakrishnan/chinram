import '../models/dryer_customer_model.dart';

class DryerCalculator {
  DryerCalculator._();

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Rounds a finite value to 2 decimal places while compensating for IEEE-754
  /// representation artifacts (e.g. `0.3 / 0.1 == 2.9999999999999996`).
  static double roundTo2(double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'Value must be finite');
    }
    final adjusted = value >= 0 ? value + 1e-11 : value - 1e-11;
    final rounded = double.parse(adjusted.toStringAsFixed(2));
    return rounded == 0 ? 0.0 : rounded;
  }

  /// Calculates drying ratio/percentage as `greenQuantity / dryQuantity`.
  ///
  /// Both quantities must be finite and strictly greater than zero.
  static double calculatePercentage(double greenQuantity, double dryQuantity) {
    if (!greenQuantity.isFinite || greenQuantity <= 0) {
      throw ArgumentError.value(
        greenQuantity,
        'greenQuantity',
        'Green quantity must be greater than zero',
      );
    }
    if (!dryQuantity.isFinite || dryQuantity <= 0) {
      throw ArgumentError.value(
        dryQuantity,
        'dryQuantity',
        'Dry quantity must be greater than zero',
      );
    }
    final result = greenQuantity / dryQuantity;
    if (!result.isFinite) {
      throw ArgumentError('Percentage calculation produced a non-finite value');
    }
    return roundTo2(result);
  }

  /// Safely computes percentage from form text inputs for real-time display.
  /// Returns `null` when either input is missing, invalid, or <= 0.
  static double? tryCalculatePercentage(String greenText, String dryText) {
    final green = double.tryParse(greenText.trim());
    final dry = double.tryParse(dryText.trim());
    if (green == null || !green.isFinite || green <= 0) return null;
    if (dry == null || !dry.isFinite || dry <= 0) return null;
    final result = green / dry;
    if (!result.isFinite) return null;
    return roundTo2(result);
  }

  /// Calculates drying charges as `greenQuantity * rate`.
  ///
  /// [greenQuantity] must be > 0 and [rate] must be >= 0.
  static double calculateCharges(double greenQuantity, double rate) {
    if (!greenQuantity.isFinite || greenQuantity <= 0) {
      throw ArgumentError.value(
        greenQuantity,
        'greenQuantity',
        'Green quantity must be greater than zero',
      );
    }
    if (!rate.isFinite || rate < 0) {
      throw ArgumentError.value(
        rate,
        'rate',
        'Rate must be zero or greater',
      );
    }
    final result = greenQuantity * rate;
    if (!result.isFinite) {
      throw ArgumentError('Charges calculation produced a non-finite value');
    }
    return roundTo2(result);
  }

  /// Safely computes charges from form text inputs for real-time display.
  /// Returns `null` when inputs are invalid or out of range.
  static double? tryCalculateCharges(String greenText, String rateText) {
    final green = double.tryParse(greenText.trim());
    final rate = double.tryParse(rateText.trim());
    if (green == null || !green.isFinite || green <= 0) return null;
    if (rate == null || !rate.isFinite || rate < 0) return null;
    final result = green * rate;
    if (!result.isFinite) return null;
    return roundTo2(result);
  }

  /// Formats a numeric value cleanly without trailing fractional zeroes.
  /// Examples: `5.0` -> `5`, `4.80` -> `4.8`, `6.18` -> `6.18`.
  static String formatNumber(double value, {int maxDecimals = 2}) {
    if (!value.isFinite) return '0';
    final epsilon = value >= 0 ? 1e-11 : -1e-11;
    var formatted = (value + epsilon).toStringAsFixed(maxDecimals);
    if (formatted.contains('.')) {
      formatted = formatted
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
    return formatted == '-0' ? '0' : formatted;
  }

  static String formatPercentage(double percentage) {
    return formatNumber(percentage, maxDecimals: 2);
  }

  static String formatQuantity(double quantity) {
    return formatNumber(quantity, maxDecimals: 3);
  }

  static String formatArea(DryerAreaType areaType, double areaValue) {
    final valueText = formatNumber(areaValue, maxDecimals: 3);
    final unitText = switch (areaType) {
      DryerAreaType.acre => areaValue == 1 ? 'Acre' : 'Acres',
      DryerAreaType.plants => areaValue == 1 ? 'Plant' : 'Plants',
    };
    return '$valueText $unitText';
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _months[date.month - 1];
    return '$day $month ${date.year}';
  }

  static bool isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Normalizes phone numbers for duplicate detection and returning-customer lookup.
  static String normalizePhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 &&
        digits.startsWith('91') &&
        RegExp(r'^[6-9]').hasMatch(digits.substring(2))) {
      return digits.substring(2);
    }
    if (digits.length == 11 &&
        digits.startsWith('0') &&
        RegExp(r'^[6-9]').hasMatch(digits.substring(1))) {
      return digits.substring(1);
    }
    return digits;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final trimmed = value.trim();
    if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(trimmed)) {
      return 'Enter a valid phone number';
    }
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Enter a valid phone number (10-15 digits)';
    }
    if (RegExp(r'^0+$').hasMatch(digits)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validateRequiredText(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateNumericInput(
    String? value, {
    required String fieldName,
    bool allowZero = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || !parsed.isFinite) {
      return 'Enter a valid $fieldName';
    }
    if (allowZero) {
      if (parsed < 0) {
        return '$fieldName must be zero or greater';
      }
    } else {
      if (parsed <= 0) {
        return '$fieldName must be greater than zero';
      }
    }
    return null;
  }
}
