class CurrencyConverter {
  // Fixed exchange rate (you might want to use a real API for live rates)
  static const double EUR_TO_USD = 1.08; // 1 EUR = 1.08 USD

  static double convert(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    
    if (fromCurrency == 'EUR' && toCurrency == 'USD') {
      return amount * EUR_TO_USD;
    } else if (fromCurrency == 'USD' && toCurrency == 'EUR') {
      return amount / EUR_TO_USD;
    }
    
    return amount; // Return original amount if conversion not supported
  }

  static String formatCurrency(double amount, String currency) {
    return '${currency == 'EUR' ? '€' : '\$'}${amount.toStringAsFixed(2)}';
  }
}
