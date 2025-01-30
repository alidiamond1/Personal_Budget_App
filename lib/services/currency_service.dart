import 'package:flutter/material.dart';

/// A service that manages currency conversion and formatting
/// Features:
/// - Currency selection and persistence
/// - Currency conversion with predefined rates
/// - Currency symbol management
/// - Amount formatting with appropriate decimals
class CurrencyService extends ChangeNotifier {
  String _selectedCurrency = 'USD'; // Default selected currency

  /// Conversion rates for supported currencies
  /// All rates are relative to USD (base currency)
  final Map<String, double> _conversionRates = {
    'USD': 1.0, // US Dollar (base currency)
    'EUR': 0.92, // Euro (1 USD = 0.92 EUR)
    'GBP': 0.79, // British Pound (1 USD = 0.79 GBP)
    'SOS': 26000.0, // Somali Shilling (1 USD = 26000 SOS)
  };

  /// Returns the currently selected currency code
  String get selectedCurrency => _selectedCurrency;

  /// Updates the selected currency and notifies listeners
  /// Only changes if the new currency is supported
  void setSelectedCurrency(String currency) {
    if (_conversionRates.containsKey(currency)) {
      if (_selectedCurrency != currency) {
        _selectedCurrency = currency;
        notifyListeners();
        print('Currency changed to: $_selectedCurrency'); // Debug log
      }
    }
  }

  /// Converts an amount from USD to the selected currency
  /// Uses stored conversion rates
  /// Special handling for SOS due to large conversion rate
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

  /// Returns the appropriate currency symbol for the selected currency
  /// Supports €, £, $, and Sh symbols
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

  /// Formats an amount with the appropriate currency symbol and decimal places
  /// Uses 0 decimal places for SOS, 2 for other currencies
  String formatAmount(double amount) {
    final convertedAmount = convertAmount(amount);
    // Use 0 decimal places for SOS, 2 for other currencies
    final decimalPlaces = _selectedCurrency == 'SOS' ? 0 : 2;
    return '${getCurrencySymbol()}${convertedAmount.toStringAsFixed(decimalPlaces)}';
  }
}
