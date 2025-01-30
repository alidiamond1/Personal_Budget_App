import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:personal_pudget/services/firebase_service.dart';
import 'package:personal_pudget/main.dart';
import 'add_expense_dialog.dart';
import 'add_income_dialog.dart';
import 'add_budget_dialog.dart';

/// The HomePage widget represents the main dashboard of the application.
/// It displays financial overview, recent transactions, and budget status.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// The state class for HomePage that manages all the data and UI logic
class _HomePageState extends State<HomePage> {
  int touchedIndex = -1; // Index of the currently touched chart section
  final FirebaseService _firebaseService = FirebaseService();
  double _totalIncome = 0; // Total income for the current period
  double _totalExpenses = 0; // Total expenses for the current period
  Map<String, double> _expensesByCategory = {}; // Expenses grouped by category
  Map<String, double> _budgets = {}; // Budget limits for each category
  List<Map<String, dynamic>> _recentTransactions =
      []; // List of recent transactions
  bool _isLoading = true; // Loading state indicator
  String _selectedCurrency = 'USD'; // Currently selected currency

  // Currency conversion rates relative to USD
  final Map<String, double> _conversionRates = {
    'USD': 1.0,
    'EUR': 0.92, // 1 USD = 0.92 EUR
    'GBP': 0.79, // 1 USD = 0.79 GBP
    'SOS': 26000.0, // 1 USD = 27000 SOS
  };

  /// Converts an amount from USD to the selected currency
  /// Uses predefined conversion rates
  double _convertAmount(double amount) {
    try {
      if (_selectedCurrency == 'SOS') {
        // Direct conversion to SOS
        return amount * 27000.0;
      } else if (_selectedCurrency == 'USD') {
        return amount;
      } else {
        // For other currencies (EUR, GBP)
        final targetRate = _conversionRates[_selectedCurrency] ?? 1.0;
        return amount * targetRate;
      }
    } catch (e) {
      print('Error converting amount: $e');
      return amount;
    }
  }

  /// Returns the appropriate currency symbol based on the selected currency
  String _getCurrencySymbol() {
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

  /// Initializes the widget and loads initial data
  @override
  void initState() {
    super.initState();
    _loadData(); // Soo jiidashada xogta
  }

  /// Loads all essential data from Firebase
  /// Including income, expenses, budgets, and recent transactions
  /// Updates the UI accordingly and handles any errors
  Future<void> _loadData() async {
    print('Starting to load data...');
    setState(() => _isLoading = true);
    try {
      print('Getting current user...');
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        print('No user logged in');
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view your data')),
        );
        return;
      }

      print('Loading income data...');
      final income = await _firebaseService.getCurrentMonthIncome();
      print('Income loaded: $income');

      print('Loading expenses data...');
      final expenses = await _firebaseService.getCurrentMonthExpenses();
      print('Expenses loaded: $expenses');

      print('Loading expenses by category...');
      final expensesByCategory =
          await _firebaseService.getCurrentMonthExpensesByCategory();
      print('Expenses by category loaded: $expensesByCategory');

      print('Loading budgets...');
      final budgets = await _firebaseService.getCurrentMonthBudgets();
      print('Budgets loaded: $budgets');

      print('Loading recent transactions...');
      final recentTransactions = await _firebaseService.getRecentTransactions();
      print('Recent transactions loaded: ${recentTransactions.length} items');

      if (mounted) {
        setState(() {
          _totalIncome = income;
          _totalExpenses = expenses;
          _expensesByCategory = expensesByCategory;
          _budgets = budgets;
          _recentTransactions = recentTransactions;
          _isLoading = false;
        });
        print('Data loaded successfully');
      }
    } catch (e, stackTrace) {
      print('Error loading data: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }

  /// Builds the main UI of the home page
  /// Includes authentication check, currency selector, and main content sections
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          print('No authenticated user found');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Please sign in to view your data'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: const Text('Go to Sign In'),
                  ),
                ],
              ),
            ),
          );
        }

        print('User is authenticated: ${snapshot.data?.uid}');
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
                  value: _selectedCurrency,
                  underline: Container(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  items: <String>['USD', 'EUR', 'GBP', 'SOS']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: const TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCurrency = newValue;
                      });
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
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBalanceCard(),
                          const SizedBox(height: 16),
                          _buildActionButtons(context),
                          const SizedBox(height: 16),
                          _buildSpendingOverview(),
                          const SizedBox(height: 16),
                          _buildRecentTransactions(),
                          const SizedBox(height: 16),
                          _buildBudgetStatus(),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  /// Builds the balance card widget showing total balance
  /// Displays income vs expenses in a mini pie chart
  /// Shows formatted amounts in selected currency
  Widget _buildBalanceCard() {
    final balance = _totalIncome - _totalExpenses;
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(),
      decimalDigits: _selectedCurrency == 'SOS' ? 0 : 2,
    );
    final convertedBalance = _convertAmount(balance);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Balance',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                    Text(formatter.format(convertedBalance),
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
                SizedBox(
                  width: 64,
                  height: 64,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: Colors.white,
                          value: _totalIncome,
                          title: '',
                          radius: 12,
                        ),
                        PieChartSectionData(
                          color: Colors.grey[700]!,
                          value: _totalExpenses,
                          title: '',
                          radius: 12,
                        ),
                      ],
                      sectionsSpace: 0,
                      centerSpaceRadius: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Income',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                    Text(formatter.format(_convertAmount(_totalIncome)),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Expenses',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                    Text(formatter.format(_convertAmount(_totalExpenses)),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a dialog for adding a new expense
  /// Creates and displays the AddExpenseDialog widget
  void _showAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddExpenseDialog();
      },
    );
  }

  /// Shows a dialog for adding new income
  /// Creates and displays the AddIncomeDialog widget
  void _showAddIncomeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddIncomeDialog();
      },
    );
  }

  /// Shows a dialog for setting a new budget
  /// Creates and displays the AddBudgetDialog widget
  void _showAddBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddBudgetDialog();
      },
    );
  }

  /// Builds the action buttons section
  /// Contains buttons for adding expenses, income, and setting budgets
  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              _showAddExpenseDialog(context);
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Expense',
                style: TextStyle(fontSize: 16, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              _showAddIncomeDialog(context);
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Income',
                style: TextStyle(
                  fontSize: 16,
                )),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              _showAddBudgetDialog(context);
            },
            icon: const Icon(Icons.account_balance_wallet, size: 20),
            label: const Text('Set Budget', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the spending overview section
  /// Shows a pie chart of expenses by category
  /// Includes a legend with category names and amounts
  Widget _buildSpendingOverview() {
    if (_expensesByCategory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No expenses recorded this month'),
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Spending Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 5,
                  centerSpaceRadius: 60,
                  sections: _expensesByCategory.entries.map((entry) {
                    final isTouched = touchedIndex ==
                        _expensesByCategory.keys.toList().indexOf(entry.key);
                    final fontSize = isTouched ? 16.0 : 12.0;
                    final radius = isTouched ? 60.0 : 50.0;

                    return PieChartSectionData(
                      color: _getCategoryColor(entry.key),
                      value: entry.value,
                      title: isTouched ? entry.key : '',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _expensesByCategory.entries.map((entry) {
                  return Row(
                    children: [
                      Icon(Icons.circle,
                          color: _getCategoryColor(entry.key), size: 14),
                      const SizedBox(width: 4),
                      Text(entry.key, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                          NumberFormat.currency(
                            symbol: _getCurrencySymbol(),
                            decimalDigits: _selectedCurrency == 'SOS' ? 0 : 2,
                          ).format(_convertAmount(entry.value)),
                          style: const TextStyle(fontSize: 12)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a color for each expense category
  /// Maintains consistent colors for better visualization
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
        return Colors.indigo;
      case 'transportation':
        return Colors.amber;
      case 'shopping':
        return Colors.green;
      case 'entertainment':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  /// Builds the recent transactions section
  /// Shows a list of recent income and expenses
  /// Includes transaction details and amounts
  Widget _buildRecentTransactions() {
    if (_recentTransactions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No recent transactions'),
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Transactions',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    // Navigate to transactions page using bottom navigation
                    if (context.findAncestorStateOfType<MainScreenState>() !=
                        null) {
                      context
                          .findAncestorStateOfType<MainScreenState>()!
                          .onPageChanged(1); // 1 is the index for Transactions
                    }
                  },
                  child: const Text('See All',
                      style: TextStyle(color: Colors.indigo)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._recentTransactions.map((transaction) {
              final isIncome = transaction['type'] == 'income';
              final amount = (transaction['amount'] as num).toDouble();
              final date = (transaction['date'] as Timestamp).toDate();
              final description =
                  transaction['description'] ?? transaction['notes'] ?? '';
              final category =
                  transaction['category'] ?? transaction['source'] ?? '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isIncome ? Colors.green[100] : Colors.red[100],
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(category),
                subtitle: Text(description),
                trailing: Text(
                  '${isIncome ? '+' : '-'}${NumberFormat.currency(
                    symbol: _getCurrencySymbol(),
                    decimalDigits: _selectedCurrency == 'SOS' ? 0 : 2,
                  ).format(_convertAmount(amount))}',
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Builds the budget status section
  /// Shows progress bars for each budget category
  /// Compares current spending against budget limits
  Widget _buildBudgetStatus() {
    if (_budgets.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No budgets set for this month'),
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Budget Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._budgets.entries.map((entry) {
              final category = entry.key;
              final budgetAmount = entry.value;
              final spent = _expensesByCategory[category] ?? 0;
              return Column(
                children: [
                  _buildBudgetProgress(
                    category,
                    spent,
                    budgetAmount,
                    _getCategoryColor(category),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Builds a progress indicator for a budget category
  /// Shows current spending vs total budget
  /// Includes formatted amounts in selected currency
  Widget _buildBudgetProgress(
      String label, double current, double total, Color color) {
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(),
      decimalDigits: _selectedCurrency == 'SOS' ? 0 : 2,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
                '${formatter.format(_convertAmount(current))}/${formatter.format(_convertAmount(total))}'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: total > 0 ? (current / total).clamp(0.0, 1.0) : 0,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  /// Handles navigation to different pages of the app
  /// Uses named routes for navigation
  void _navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/login');
        break;
      case 1:
        Navigator.pushNamed(context, '/home');
        break;
      case 2:
        Navigator.pushNamed(context, '/transactions');
        break;
      case 3:
        Navigator.pushNamed(context, '/reports');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }
}
