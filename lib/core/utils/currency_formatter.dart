String formatINR(double amount) {
  final isNegative = amount < 0;
  final absoluteAmount = amount.abs();
  final str = absoluteAmount.toStringAsFixed(2);
  final parts = str.split('.');
  final whole = parts[0];
  final decimal = parts.length > 1 ? parts[1] : '00';
  
  String formattedWhole;
  if (whole.length <= 3) {
    formattedWhole = whole;
  } else {
    final lastThree = whole.substring(whole.length - 3);
    final remaining = whole.substring(0, whole.length - 3);
    
    String formattedRemaining = '';
    int count = 0;
    for (int i = remaining.length - 1; i >= 0; i--) {
      formattedRemaining = remaining[i] + formattedRemaining;
      count++;
      if (count == 2 && i > 0) {
        formattedRemaining = ',$formattedRemaining';
        count = 0;
      }
    }
    formattedWhole = '$formattedRemaining,$lastThree';
  }
  
  return '${isNegative ? '-' : ''}₹$formattedWhole.$decimal';
}
