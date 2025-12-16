import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class AnalyticPage extends StatefulWidget {
  final VoidCallback onBack;
  const AnalyticPage({super.key, required this.onBack});

  @override
  State<AnalyticPage> createState() => _AnalyticPageState();
}

class _AnalyticPageState extends State<AnalyticPage> {
  int currentMonth = DateTime.now().month;
  int currentYear = DateTime.now().year; // <-- TAMBAHAN

  /// Format data dummy:
  /// [primary, bill, miscellaneous]
  Map<int, List<double>> monthlyData = {
    1: [50, 30, 20],
    2: [60, 25, 15],
    3: [55, 30, 15],
    4: [45, 35, 20],
    5: [70, 20, 10],
    6: [65, 25, 10],
    7: [40, 40, 20],
    8: [58, 30, 12],
    9: [52, 28, 20],
    10: [62, 22, 16],
    11: [48, 35, 17],
    12: [55, 25, 20],
  };

  List<String> kategori = ["Primary", "Bill", "Misc"];

  List<String> monthNames = [
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
  ];

  // ==================== UPDATE FUNGSI NAVIGASI ====================
  void nextMonth() {
    setState(() {
      if (currentMonth == 12) {
        currentMonth = 1;
        currentYear++;        // naik tahun
      } else {
        currentMonth++;
      }
    });
  }

  void prevMonth() {
    setState(() {
      if (currentMonth == 1) {
        currentMonth = 12;
        currentYear--;       // balik tahun
      } else {
        currentMonth--;
      }
    });
  }

  // Contoh FloatingActionButton → update random
  void addNewEntry() {
    setState(() {
      monthlyData[currentMonth] = [
        Random().nextInt(100).toDouble(),
        Random().nextInt(100).toDouble(),
        Random().nextInt(100).toDouble(),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = monthlyData[currentMonth]!;

    return Scaffold(
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
            Text(
              'Monthly Money Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF014037),
              ),
            ),

            // ================= HEADER BULAN + TAHUN =================
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

            const SizedBox(height: 20),

            // ======================= GRAFIK =========================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            int index = value.toInt();
                            return Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                kategori[index],
                                style: const TextStyle(fontSize: 15),
                              ),
                            );
                          },
                        ),
                      ),

                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          getTitlesWidget: (v, _) =>
                              Text("${v.toInt()}%", style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),

                    barGroups: List.generate(data.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[i],
                            width: 35,
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.teal, Colors.greenAccent],
                            ),
                          ),
                        ],
                      );
                    }),
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