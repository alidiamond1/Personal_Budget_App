import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

/// A comprehensive reporting page that displays financial analytics and insights.
/// This page provides:
/// - Spending trends visualization with line charts
/// - Category-wise expense breakdown with pie charts
/// - Savings progress tracking
/// - Period-based filtering of data
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // Firebase instances for data access
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // State variables for managing data and UI
  bool _isLoading = false; // Controls loading indicator
  List<Map<String, dynamic>> _transactions = []; // Stores all transactions
  Map<String, double> _categoryExpenses = {}; // Category-wise expense totals
  double _totalSpending = 0; // Total expenses for selected period

  // Period selection for filtering data
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['Last 7 days', 'This Month', 'Last 30 days'];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  /// Loads transaction data from Firebase based on selected period
  /// Calculates category-wise expenses and total spending
  /// Updates the UI with loading states and error handling
  Future<void> _loadReportData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _transactions = [];
      _categoryExpenses = {};
      _totalSpending = 0;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      DateTime startDate = _getStartDate();

      final QuerySnapshot transactionSnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .orderBy('date', descending: true)
          .get();

      if (!mounted) return;

      setState(() {
        _transactions = transactionSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _calculateMetrics();
      });
    } catch (e) {
      print('Error loading report data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Calculates spending metrics from loaded transactions
  /// - Updates category-wise expense totals
  /// - Calculates total spending for the period
  void _calculateMetrics() {
    _categoryExpenses.clear();
    _totalSpending = 0;

    for (var transaction in _transactions) {
      if (transaction['type'] == 'expense') {
        final category = transaction['category'] as String;
        final amount = (transaction['amount'] as num).toDouble();
        _categoryExpenses[category] =
            (_categoryExpenses[category] ?? 0) + amount;
        _totalSpending += amount;
      }
    }
  }

  /// Builds the spending analytics section with a line chart
  /// Shows daily spending trends over time
  /// Includes:
  /// - Line chart with daily spending
  /// - Top spending category
  /// - Monthly total
  /// - Daily average
  Widget _buildSpendingAnalytics() {
    List<FlSpot> spots = [];
    final now = DateTime.now();

    Map<DateTime, double> dailySpending = {};
    for (int i = 5; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dailySpending[DateTime(date.year, date.month, date.day)] = 0;
    }

    for (var transaction in _transactions) {
      if (transaction['type'] == 'expense') {
        final date = (transaction['date'] as Timestamp).toDate();
        final dayKey = DateTime(date.year, date.month, date.day);
        if (dailySpending.containsKey(dayKey)) {
          dailySpending[dayKey] = (dailySpending[dayKey] ?? 0) +
              (transaction['amount'] as num).toDouble();
        }
      }
    }

    var index = 0;
    var maxAmount = 0.0;
    dailySpending.forEach((date, amount) {
      maxAmount = math.max(maxAmount, amount);
      spots.add(FlSpot(index.toDouble(), amount));
      index++;
    });

    if (maxAmount == 0) {
      spots = List.generate(6, (index) => FlSpot(index.toDouble(), 10));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spending Analytics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxAmount > 0 ? maxAmount / 4 : 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('');
                      return Text(
                        '\$${value.toInt()}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date =
                          now.subtract(Duration(days: 5 - value.toInt()));
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('dd').format(date),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.purple,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.purple,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.purple.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(TextSpan(
              text: 'Top Category\n',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              children: [
                TextSpan(
                  text: _categoryExpenses.isEmpty
                      ? 'None'
                      : _categoryExpenses.entries
                          .reduce((a, b) => a.value > b.value ? a : b)
                          .key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            )),
            Text.rich(TextSpan(
              text: 'This Month\n',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              children: [
                TextSpan(
                  text: '\$${_totalSpending.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            )),
            Text.rich(TextSpan(
              text: 'Avg. Daily\n',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              children: [
                TextSpan(
                  text: '\$${(_totalSpending / 30).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  /// Builds the category breakdown section with a pie chart
  /// Shows proportion of spending across different categories
  /// Features:
  /// - Interactive pie chart
  /// - Percentage breakdown
  /// - Category labels and color coding
  /// - Fallback UI for no data
  Widget _buildCategoryBreakdown() {
    if (_categoryExpenses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Category Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No expenses recorded for this period',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      );
    }

    final total = _categoryExpenses.values.fold(0.0, (a, b) => a + b);
    final sections = _categoryExpenses.entries.map((e) {
      final percentage = (e.value / total) * 100;
      final color = Colors.primaries[
          _categoryExpenses.keys.toList().indexOf(e.key) %
              Colors.primaries.length];
      return PieChartSectionData(
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: 100,
        color: color,
        badgeWidget: _categoryExpenses.length <= 4
            ? Text(
                e.key,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
        showTitle: _categoryExpenses.length > 4,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Category Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              startDegreeOffset: -90,
            ),
          ),
        ),
        if (_categoryExpenses.length > 4) ...[
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _categoryExpenses.entries.map((e) {
              final color = Colors.primaries[
                  _categoryExpenses.keys.toList().indexOf(e.key) %
                      Colors.primaries.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    e.key,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// Builds the savings overview section
  /// Displays:
  /// - Monthly savings goal
  /// - Current savings (Income - Expenses)
  /// - Progress bar towards goal
  /// - Percentage completion
  Widget _buildSavingsOverview() {
    double totalIncome = 0;
    for (var transaction in _transactions) {
      if (transaction['type'] == 'income') {
        totalIncome += (transaction['amount'] as num).toDouble();
      }
    }

    final savings = totalIncome - _totalSpending;
    final monthlyGoal = 1000.0;
    final progress =
        monthlyGoal > 0 ? (savings / monthlyGoal).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Savings Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Goal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '\$${monthlyGoal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Savings',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '\$${savings.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: savings >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0 ? Colors.green : Colors.purple,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${(progress * 100).toStringAsFixed(1)}% of monthly goal',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: DropdownButton<String>(
                underline: Container(),
                icon:
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                items: _periods.map((String period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(period),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedPeriod = val!;
                    _loadReportData();
                  });
                },
                value: _selectedPeriod,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSpendingAnalytics(),
                    const SizedBox(height: 16),
                    _buildCategoryBreakdown(),
                    const SizedBox(height: 16),
                    _buildSavingsOverview(),
                  ],
                ),
              ),
      ),
    );
  }
}
