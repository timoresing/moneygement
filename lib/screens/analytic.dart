import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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

  // LABEL & CONFIG KATEGORI
  final List<String> kategoriLabel = ["F&D", "Trans", "Bills", "Shop", "Misc"];
  final List<String> kategoriFullNames = ["Food & Drink", "Transport", "Bills & Utilities", "Shopping", "Miscellaneous"];
  final List<IconData> kategoriIcons = [Icons.fastfood, Icons.directions_car, Icons.receipt_long, Icons.shopping_bag, Icons.category];

  // Warna berbeda untuk setiap kategori agar grafik lebih cantik
  final List<Color> kategoriColors = [
    const Color(0xFFEF5350), // Merah (F&D)
    const Color(0xFF42A5F5), // Biru (Trans)
    const Color(0xFFFFCA28), // Kuning (Bills)
    const Color(0xFFAB47BC), // Ungu (Shop)
    const Color(0xFF8D6E63), // Coklat (Misc)
  ];

  final List<String> monthNames = [
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
  ];

  // LOGIC KATEGORI (Sama seperti sebelumnya)
  int _getCategoryIndex(String category, String title) {
    String combined = "$category $title".toLowerCase();
    if (combined.contains('food') || combined.contains('drink') || combined.contains('makan') || combined.contains('minum') || combined.contains('jajan')) return 0;
    if (combined.contains('trans') || combined.contains('bensin') || combined.contains('ojek') || combined.contains('parkir') || combined.contains('grab') || combined.contains('gojek')) return 1;
    if (combined.contains('bill') || combined.contains('listrik') || combined.contains('air') || combined.contains('pulsa') || combined.contains('internet') || combined.contains('wifi')) return 2;
    if (combined.contains('shop') || combined.contains('belanja') || combined.contains('beli') || combined.contains('mall')) return 3;
    return 4;
  }

  String formatRupiah(double number) {
    return "Rp${number.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
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
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan range tanggal untuk query Stream
    DateTime startOfMonth = DateTime(currentYear, currentMonth, 1);
    DateTime endOfMonth = DateTime(currentYear, currentMonth + 1, 0, 23, 59, 59);

    return Scaffold(
      backgroundColor: const Color(0xFFF1ECDE), // Cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D40),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
        title: const Text("Analytics", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Column(
        children: [
          // 1. HEADER BULAN (Sticky di atas)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF004D40),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20)
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: prevMonth, icon: const Icon(Icons.chevron_left, color: Colors.white)),
                Text(
                  "${monthNames[currentMonth - 1]} $currentYear",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(onPressed: nextMonth, icon: const Icon(Icons.chevron_right, color: Colors.white)),
              ],
            ),
          ),

          // 2. STREAM BUILDER (Content)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .collection('transactions')
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
                  .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text("No data for this month", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  );
                }

                // --- PROSES DATA ---
                List<double> totals = [0, 0, 0, 0, 0];
                double totalExpenseMonth = 0;

                for (var doc in snapshot.data!.docs) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  String type = (data['type'] ?? '').toString().toLowerCase();

                  // Hanya ambil pengeluaran (expense)
                  if (type != 'expense' && type != 'pengeluaran') continue;

                  String cat = (data['category'] ?? '').toString();
                  String title = (data['title'] ?? '').toString();
                  double amount = double.tryParse(data['amount'].toString()) ?? 0;

                  int index = _getCategoryIndex(cat, title);
                  totals[index] += amount;
                  totalExpenseMonth += amount;
                }

                // Hitung Persentase
                List<double> percentages = [0, 0, 0, 0, 0];
                if (totalExpenseMonth > 0) {
                  for (int i = 0; i < 5; i++) {
                    percentages[i] = (totals[i] / totalExpenseMonth) * 100;
                  }
                }

                // Jika tidak ada expense sama sekali walau ada data (misal income semua)
                if (totalExpenseMonth == 0) {
                  return const Center(child: Text("No expenses found."));
                }

                // --- UI CONTENT ---
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // A. KARTU TOTAL PENGELUARAN
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          children: [
                            Text("Total Expense", style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                            const SizedBox(height: 5),
                            Text(formatRupiah(totalExpenseMonth), style: const TextStyle(fontSize: 28, color: Color(0xFF004D40), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // B. GRAFIK BATANG (Bar Chart)
                      Container(
                        height: 250,
                        padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: BarChart(
                          BarChartData(
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (group) => Colors.blueGrey,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                        "${kategoriFullNames[group.x]}\n",
                                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        children: [
                                          TextSpan(text: formatRupiah(totals[group.x]), style: const TextStyle(color: Colors.yellowAccent)),
                                        ]
                                    );
                                  }
                              ),
                            ),
                            gridData: FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        kategoriLabel[value.toInt()],
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: List.generate(5, (index) {
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: percentages[index],
                                    color: kategoriColors[index],
                                    width: 20,
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: 100, // Max height background selalu 100%
                                      color: Colors.grey[100],
                                    ),
                                  ),
                                ],
                              );
                            }),
                            maxY: 100,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // C. RINCIAN KATEGORI (LIST)
                      Column(
                        children: List.generate(5, (index) {
                          // Hanya tampilkan kategori yang ada pengeluarannya (> 0)
                          if (totals[index] == 0) return const SizedBox.shrink();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              children: [
                                // Icon Box
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: kategoriColors[index].withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(kategoriIcons[index], color: kategoriColors[index], size: 24),
                                ),
                                const SizedBox(width: 15),

                                // Nama & Progress
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(kategoriFullNames[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          Text("${percentages[index].toStringAsFixed(1)}%", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: percentages[index] / 100,
                                          backgroundColor: Colors.grey[100],
                                          color: kategoriColors[index],
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 15),

                                // Total Uang
                                Text(
                                  formatRupiah(totals[index]),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kategoriColors[index]),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}