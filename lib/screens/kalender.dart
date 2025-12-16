import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Tambahkan intl di pubspec.yaml jika mau format uang otomatis, tapi saya pakai manual di bawah.

// 1. Model Data
class TransactionSummary {
  final int income;
  final int expense;

  TransactionSummary({required this.income, required this.expense});
}

class KalenderPage extends StatelessWidget {
  final VoidCallback onBack;
  KalenderPage({super.key, required this.onBack});

  final ValueNotifier<DateTime?> selectedDay = ValueNotifier(null);
  final ValueNotifier<DateTime> focusedDay = ValueNotifier(DateTime.now());

  // 2. PERBAIKAN DATA DUMMY (Pastikan tanggalnya beda agar tidak tertimpa)
  final Map<DateTime, TransactionSummary> dailySummary = {
    DateTime(2025, 11, 10): TransactionSummary(income: 500000, expense: 0),
    DateTime(2025, 11, 12): TransactionSummary(income: 0, expense: 200000),
    DateTime(2025, 11, 15): TransactionSummary(income: 150000, expense: 50000),
  };

  // Helper format rupiah sederhana
  String _formatCurrency(int amount) {
    return "Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  // 3. WIDGET TANGGAL YANG DIPERBAIKI (CUSTOM CELL)
  Widget _buildCustomDay(DateTime day, bool isSelected, bool isToday, TransactionSummary? summary) {
    Color? markerColor;
    if (summary != null) {
      if (summary.income > summary.expense) {
        markerColor = const Color(0xFF43A047); // Hijau segar
      } else {
        markerColor = const Color(0xFFE53935); // Merah terang
      }
    }

    // Warna Background Lingkaran Utama
    Color bgCircle = Colors.transparent;
    Color textColor = const Color(0xFF004D40); // Default text hijau tua

    if (isSelected) {
      bgCircle = const Color(0xFF004D40); // Selected: Hijau Tua Solid
      textColor = Colors.white;
    } else if (isToday) {
      bgCircle = const Color(0xFFF1C854); // Today: Kuning Emas
      textColor = Colors.black;
    }

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bgCircle,
        shape: BoxShape.circle,
        // Tambahkan shadow sedikit jika selected biar pop-up
        boxShadow: isSelected ? [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ] : [],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${day.day}",
            style: TextStyle(
              color: textColor,
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          // MARKER: Titik kecil di bawah angka
          if (markerColor != null) ...[
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : markerColor, // Jika selected, titik jadi putih biar kontras
                shape: BoxShape.circle,
              ),
            ),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1ECDE), // Background Cream
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D40),
        elevation: 0,
        centerTitle: true,
        title: const Text("Calendar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBack,
        ),
      ),
      body: Column(
        children: [
          // KOTAK KALENDER DENGAN STYLE BARU
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ValueListenableBuilder(
              valueListenable: focusedDay,
              builder: (context, DateTime fDay, _) {
                return TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 1, 1),
                  focusedDay: fDay,
                  calendarFormat: CalendarFormat.month,
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFFF1C854)),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFFF1C854)),
                  ),
                  calendarStyle: const CalendarStyle(
                    outsideDaysVisible: false, // Hilangkan tanggal bulan lain agar bersih
                  ),
                  selectedDayPredicate: (day) => isSameDay(selectedDay.value, day),
                  onDaySelected: (day, fday) {
                    selectedDay.value = day;
                    focusedDay.value = fday;
                  },
                  onPageChanged: (fDay) {
                    focusedDay.value = fDay;
                  },

                  // BUILDER UNTUK KUSTOMISASI TAMPILAN
                  calendarBuilders: CalendarBuilders(
                    // Builder Default (Hari biasa)
                    defaultBuilder: (context, day, focusedDay) {
                      final key = DateTime(day.year, day.month, day.day);
                      return _buildCustomDay(day, false, false, dailySummary[key]);
                    },
                    // Builder Selected (Hari dipilih)
                    selectedBuilder: (context, day, focusedDay) {
                      final key = DateTime(day.year, day.month, day.day);
                      return _buildCustomDay(day, true, false, dailySummary[key]);
                    },
                    // Builder Today (Hari ini)
                    todayBuilder: (context, day, focusedDay) {
                      final key = DateTime(day.year, day.month, day.day);
                      // Cek apakah hari ini juga sedang dipilih?
                      bool isSelected = isSameDay(day, selectedDay.value);
                      return _buildCustomDay(day, isSelected, true, dailySummary[key]);
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // PANEL DETAIL TRANSAKSI
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: selectedDay,
              builder: (context, DateTime? day, _) {
                if (day == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text(
                          "Pilih tanggal untuk melihat detail",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final summary = dailySummary[DateTime(day.year, day.month, day.day)];

                return _buildDetailCard(day, summary);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 4. WIDGET KARTU DETAIL YANG LEBIH BAGUS
  Widget _buildDetailCard(DateTime day, TransactionSummary? summary) {
    // Format tanggal cantik
    String dateString = "${day.day} ${_getMonthName(day.month)} ${day.year}";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Tanggal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Transaksi Harian", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text(dateString, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
            ],
          ),
          const Divider(height: 30),

          if (summary == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Tidak ada transaksi pada tanggal ini.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ),
            )
          else
            Column(
              children: [
                // Item Pemasukan
                _buildTransactionItem(
                    "Pemasukan",
                    summary.income,
                    Icons.arrow_circle_up_rounded,
                    const Color(0xFF43A047),
                    const Color(0xFFE8F5E9)
                ),
                const SizedBox(height: 15),
                // Item Pengeluaran
                _buildTransactionItem(
                    "Pengeluaran",
                    summary.expense,
                    Icons.arrow_circle_down_rounded,
                    const Color(0xFFE53935),
                    const Color(0xFFFFEBEE)
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, int amount, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                Text(
                  _formatCurrency(amount),
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"];
    return months[month - 1];
  }
}