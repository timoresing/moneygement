import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticPage extends StatefulWidget {
  final VoidCallback onBack;
  const AnalyticPage({super.key, required this.onBack});

  @override
  State<AnalyticPage> createState() => _AnalyticPageState();
}

class _AnalyticPageState extends State<AnalyticPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  int currentMonth = DateTime.now().month;
  int currentYear = DateTime.now().year;

  // Data Grafik Persentase (0-100%) & Total Uangnya
  List<double> _chartPercentages = [0, 0, 0, 0, 0];
  List<double> _chartTotals = [0, 0, 0, 0, 0];
  bool _isLoading = false;

  // LABEL KATEGORI
  final List<String> kategoriLabel = ["F&D", "Trans", "Bills", "Shop", "Misc"];

  // FORMAT RUPIAH
  String formatRupiah(double number) {
    return "Rp${number.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  // LOGIC KATEGORI
  int _getCategoryIndex(String category, String title) {
    String combined = "$category $title".toLowerCase();
    if (combined.contains('food') || combined.contains('drink') || combined.contains('makan') || combined.contains('minum') || combined.contains('jajan')) return 0;
    if (combined.contains('trans') || combined.contains('bensin') || combined.contains('ojek') || combined.contains('parkir') || combined.contains('grab') || combined.contains('gojek')) return 1;
    if (combined.contains('bill') || combined.contains('listrik') || combined.contains('air') || combined.contains('pulsa') || combined.contains('internet') || combined.contains('wifi')) return 2;
    if (combined.contains('shop') || combined.contains('belanja') || combined.contains('beli') || combined.contains('mall')) return 3;
    return 4;
  }

  // LIST BULAN
  final List<String> monthNames = [
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
  ];

  @override
  void initState() {
    super.initState();
    _fetchMonthlyData();
  }

  Future<void> _fetchMonthlyData() async {
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      DateTime startOfMonth = DateTime(currentYear, currentMonth, 1);
      DateTime endOfMonth = DateTime(currentYear, currentMonth + 1, 0, 23, 59, 59);

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      List<double> totals = [0, 0, 0, 0, 0];
      double totalExpenseMonth = 0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        String type = (data['type'] ?? '').toString().toLowerCase();
        if (type != 'expense' && type != 'pengeluaran') continue;

        String cat = (data['category'] ?? '').toString();
        String title = (data['title'] ?? '').toString();
        double amount = double.tryParse(data['amount'].toString()) ?? 0;

        int index = _getCategoryIndex(cat, title);
        totals[index] += amount;
        totalExpenseMonth += amount;
      }

      List<double> percentages = [0, 0, 0, 0, 0];
      if (totalExpenseMonth > 0) {
        for (int i = 0; i < 5; i++) {
          percentages[i] = (totals[i] / totalExpenseMonth) * 100;
        }
      }

      if (mounted) {
        setState(() {
          _chartPercentages = percentages;
          _chartTotals = totals;
          _isLoading = false;
        });
      }

    } catch (e) {
      print("Error fetching analytic: $e");
      setState(() => _isLoading = false);
    }
  }

  void nextMonth() {
    setState(() {
      if (currentMonth == 12) {
        currentMonth = 1;
        currentYear++;
      } else {
        currentMonth++;
      }
    });
    _fetchMonthlyData();
  }

  void prevMonth() {
    setState(() {
      if (currentMonth == 1) {
        currentMonth = 12;
        currentYear--;
      } else {
        currentMonth--;
      }
    });
    _fetchMonthlyData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1ECDE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D40),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text("Analytic", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Monthly Expense Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF014037),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: prevMonth, icon: const Icon(Icons.chevron_left)),
                Text(
                  "${monthNames[currentMonth - 1]} $currentYear",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF014037)),
                ),
                IconButton(onPressed: nextMonth, icon: const Icon(Icons.chevron_right)),
              ],
            ),

            const SizedBox(height: 30),

            // Grafik
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)))
                  : _chartPercentages.every((val) => val == 0)
                  ? Center(child: Text("No expenses this month", style: TextStyle(color: Colors.grey[600])))
                  : Padding(
                padding: const EdgeInsets.only(bottom: 60, left: 10, right: 10),
                child: BarChart(
                  BarChartData(
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => const Color(0xFF004D40),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          // Ambil total uang dari list _chartTotals
                          double totalAmount = _chartTotals[group.x];

                          // SAAT TAP BAR CHART
                          return BarTooltipItem(
                            // Persentase (Putih Tebal)
                            '${rod.toY.toStringAsFixed(1)}%\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            children: [
                              // Rupiah (Putih Pudar)
                              TextSpan(
                                text: formatRupiah(totalAmount),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            int index = value.toInt();
                            if (index < 0 || index >= kategoriLabel.length) return const SizedBox();

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                kategoriLabel[index],
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 20,
                          getTitlesWidget: (v, _) =>
                              Text("${v.toInt()}%", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),

                    barGroups: List.generate(_chartPercentages.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: _chartPercentages[i],
                            width: 22,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xFF004D40), Color(0xFF009688)],
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 100,
                              color: Colors.black12,
                            ),
                          ),
                        ],
                      );
                    }),
                    maxY: 100,
                    minY: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}