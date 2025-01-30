/// This page displays all financial transactions made by the user
/// Features:
/// - View all income and expenses
/// - Filter transactions by category
/// - Currency conversion support
/// - Pull to refresh functionality
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_pudget/services/firebase_service.dart';
import 'package:personal_pudget/services/currency_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

/// The main transaction page widget that displays all financial activities
class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

/// The state class for TransactionPage that manages transaction data and UI
class _TransactionPageState extends State<TransactionPage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _transactions = []; // All transactions
  List<String> _categories = []; // Available transaction categories
  String? _selectedCategory; // Currently selected category filter
  bool _isLoading = true; // Loading state indicator

  @override
  void initState() {
    super.initState();
    _loadData(); // Soo jiidashada xogta marka ugu horeysa
  }

  /// Loads transaction data and categories from Firebase
  /// Updates the UI with the fetched data
  /// Handles any errors during data loading
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load categories
      final categories = await _firebaseService.getCategories();
      // Load all transactions
      final transactions = await _firebaseService.getAllTransactions();

      if (mounted) {
        setState(() {
          _categories = categories;
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }

  /// Builds the main UI for the transactions page
  /// Includes:
  /// - Currency selector in app bar
  /// - Category filter dropdown
  /// - Scrollable list of transactions
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          padding: const EdgeInsets.all(8),
          child: const Icon(
            Icons.account_balance_wallet,
            size: 32,
            color: Colors.indigo,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: Provider.of<CurrencyService>(context).selectedCurrency,
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: <String>['USD', 'EUR', 'GBP', 'SOS']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child:
                      Text(value, style: const TextStyle(color: Colors.black)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  Provider.of<CurrencyService>(context, listen: false)
                      .setSelectedCurrency(newValue);
                }
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('All Transactions',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: _selectedCategory,
                          hint: const Text('All Categories'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Categories'),
                            ),
                            ..._categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          },
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _transactions.isEmpty
                          ? const Center(
                              child: Text('No transactions found'),
                            )
                          : ListView.builder(
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = _transactions[index];
                                final isIncome =
                                    transaction['type'] == 'income';
                                final amount =
                                    (transaction['amount'] as num).toDouble();
                                final date =
                                    (transaction['date'] as Timestamp).toDate();
                                final description =
                                    transaction['description'] ??
                                        transaction['notes'] ??
                                        '';
                                final category = transaction['category'] ??
                                    transaction['source'] ??
                                    '';

                                // Filter by category if one is selected
                                if (_selectedCategory != null &&
                                    category != _selectedCategory) {
                                  return const SizedBox.shrink();
                                }

                                return _buildTransactionItem(
                                  _getCategoryIcon(category),
                                  _getCategoryColor(category),
                                  description,
                                  DateFormat('MMM dd, yyyy').format(date),
                                  category,
                                  '${isIncome ? '+' : '-'}${Provider.of<CurrencyService>(context).getCurrencySymbol()}${Provider.of<CurrencyService>(context).convertAmount(amount).toStringAsFixed(2)}',
                                  isIncome ? Colors.green : Colors.red,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Returns the appropriate icon for each transaction category
  /// Maps category names to their corresponding Material icons
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'groceries':
        return Icons.shopping_basket;
      case 'salary':
        return Icons.business;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.electric_bolt;
      case 'dining':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      default:
        return Icons.attach_money;
    }
  }

  /// Returns a specific color for each transaction category
  /// Maintains consistent color coding throughout the app
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'groceries':
        return Colors.blue;
      case 'salary':
        return Colors.green;
      case 'entertainment':
        return Colors.purple;
      case 'utilities':
        return Colors.orange;
      case 'dining':
        return Colors.red;
      case 'transportation':
        return Colors.indigo;
      default:
        return Colors.blueGrey;
    }
  }

  /// Builds an individual transaction list item
  /// Displays transaction details including:
  /// - Category icon and color
  /// - Transaction description and date
  /// - Amount with appropriate color (green for income, red for expenses)
  Widget _buildTransactionItem(
    IconData icon,
    Color iconBgColor,
    String title,
    String date,
    String category,
    String amount,
    Color amountColor,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconBgColor.withOpacity(0.2),
        child: Icon(icon, color: iconBgColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$date • $category'),
      trailing:
          Text(amount, style: TextStyle(color: amountColor, fontSize: 16)),
    );
  }
}
