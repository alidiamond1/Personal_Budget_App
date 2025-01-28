import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedPeriod = 'Last 30 days';
  final List<String> _periods = ['Last 30 days', 'Last 7 days', 'This Month'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: DropdownButton<String>(
              underline: Container(),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              items: _periods.map((String period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedPeriod = val!;
                });
              },
              value: _selectedPeriod,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSpendingAnalytics(),
            _buildCategoryBreakdown(),
            _buildSavingsOverview(),
            _buildCustomReports(),
          ],
        ),
      ),
    );
  }

  // Spending Analytics Section
  Widget _buildSpendingAnalytics() {
    return _buildCard(
      child: Column(
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
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: true)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1200),
                      FlSpot(1, 800),
                      FlSpot(2, 800),
                      FlSpot(3, 1000),
                      FlSpot(4, 1300),
                      FlSpot(5, 1300),
                    ],
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(TextSpan(
                text: 'Top Category\n',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                children: [
                  TextSpan(
                    text: 'Food & Dining',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ],
              )),
              Text.rich(TextSpan(
                text: 'This Month\n',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                children: [
                  TextSpan(
                    text: '\$2,340',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  TextSpan(
                    text: ' +12%',
                    style: TextStyle(color: Colors.green, fontSize: 14),
                  ),
                ],
              )),
              Text.rich(TextSpan(
                text: 'Avg. Daily\n',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                children: [
                  TextSpan(
                    text: '\$78',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  // Category Breakdown Section
  Widget _buildCategoryBreakdown() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'See Details',
                style: TextStyle(
                    color: Colors.purple, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  _buildPieSection(25, Colors.orange, 'Entertainment'),
                  _buildPieSection(35, Colors.purple, 'Food'),
                  _buildPieSection(20, Colors.green, 'Shopping'),
                  _buildPieSection(20, Colors.grey, 'Transportation'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieSection(
      double value, Color color, String title) {
    return PieChartSectionData(
      value: value,
      color: color,
      radius: 50,
      title: '$title\n${value.toInt()}%',
      titleStyle: const TextStyle(
          fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  // Savings Overview Section
  Widget _buildSavingsOverview() {
    return _buildCard(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Savings Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Progress to Goal  75%',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          SizedBox(height: 5),
          LinearProgressIndicator(
            value: 0.75,
            backgroundColor: Colors.grey,
            color: Colors.purple,
            minHeight: 8,
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(TextSpan(
                text: 'Monthly Goal\n',
                style: TextStyle(color: Colors.grey),
                children: [
                  TextSpan(
                    text: '\$1,000',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              )),
              Text.rich(TextSpan(
                text: 'Total Saved\n',
                style: TextStyle(color: Colors.grey),
                children: [
                  TextSpan(
                    text: '\$750',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  // Custom Reports Section
  Widget _buildCustomReports() {
    return _buildCard(
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CustomButton(icon: FontAwesomeIcons.filePdf, label: 'Export PDF'),
          _CustomButton(icon: FontAwesomeIcons.fileCsv, label: 'Export CSV'),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: child,
      ),
    );
  }
}

class _CustomButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CustomButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FaIcon(icon, size: 30, color: Colors.purple),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
