import 'package:flutter/material.dart';

class CurrencyService extends ChangeNotifier {
  String _selectedCurrency = 'USD';
  final Map<String, double> _conversionRates = {
    'USD': 1.0,
    'EUR': 0.92, // 1 USD = 0.92 EUR
    'GBP': 0.79, // 1 USD = 0.79 GBP
    'SOS': 27000.0, // 1 USD = 27000 SOS
  };

  String get selectedCurrency => _selectedCurrency;

  void setSelectedCurrency(String currency) {
    if (_conversionRates.containsKey(currency)) {
      if (_selectedCurrency != currency) {
        _selectedCurrency = currency;
        notifyListeners();
        print('Currency changed to: $_selectedCurrency'); // Debug log
      }
    }
  }

  double convertAmount(double amount) {
    if (_selectedCurrency == 'SOS') {
      // For SOS, multiply directly since we store the full rate
      return amount * _conversionRates['SOS']!;
    }
    // For other currencies, use the standard conversion
    final rate = _conversionRates[_selectedCurrency] ?? 1.0;
    final result = amount * rate;
    print('Converting $amount USD to $_selectedCurrency (rate: $rate)');
    print('Conversion result: $result');
    return result;
  }

  String getCurrencySymbol() {
    switch (_selectedCurrency) {
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'SOS':
        return 'Sh';
      default:
        return '\$';
    }
  }

  String formatAmount(double amount) {
    final convertedAmount = convertAmount(amount);
    // Use 0 decimal places for SOS, 2 for other currencies
    final decimalPlaces = _selectedCurrency == 'SOS' ? 0 : 2;
    return '${getCurrencySymbol()}${convertedAmount.toStringAsFixed(decimalPlaces)}';
  }
}
