import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class TransactionSummary {
  final int income;
  final int expense;

  TransactionSummary({required this.income, required this.expense});
}

class KalenderPage extends StatelessWidget {
  KalenderPage({super.key});

  final ValueNotifier<DateTime?> selectedDay = ValueNotifier(null);
  final ValueNotifier<DateTime> focusedDay = ValueNotifier(DateTime.now());

  final Map<DateTime, TransactionSummary> dailySummary = {
    DateTime(2025, 11, 12): TransactionSummary(income: 500000, expense: 0),
    DateTime(2025, 11, 12): TransactionSummary(income: 0, expense: 200000),
    DateTime(2025, 11, 12): TransactionSummary(income: 100000, expense: 50000),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1ECDE),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // ------------------  KALENDER  ------------------
          ValueListenableBuilder(
            valueListenable: focusedDay,
            builder: (context, DateTime fDay, _) {
              return Padding(
                padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 1, 1),
                  focusedDay: fDay,
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {
                    CalendarFormat.month: "Month"
                  },

                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF014037),
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left,
                        color: Color(0xFF014037)),
                    rightChevronIcon: const Icon(Icons.chevron_right,
                        color: Color(0xFF014037)),
                  ),

                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFFF1C854),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: const Color(0xFF014037),
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold,),
                    defaultTextStyle: const TextStyle(color: Colors.black),
                  ),

                  selectedDayPredicate: (day) =>
                      isSameDay(selectedDay.value, day),

                  onDaySelected: (day, fday) {
                    selectedDay.value = day;
                    focusedDay.value = fday;
                  },

                  onPageChanged: (fDay) {
                    focusedDay.value = fDay;
                  },

                  // ------------------  MARKERS  ------------------
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, _) {
                      final key = DateTime(day.year, day.month, day.day);
                      final summary = dailySummary[key];

                      Color? indicator;

                      if (summary != null) {
                        if (summary.income > summary.expense) {
                          indicator = const Color(0xFF4CAF50);
                        } else if (summary.expense > summary.income) {
                          indicator = const Color(0xFFE53935);
                        }
                      }

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Text("${day.day}"),
                          if (indicator != null)
                            Positioned(
                              bottom: 6,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: indicator,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // ------------------  DETAIL PANEL DI BAWAH  ------------------
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: selectedDay,
              builder: (context, DateTime? day, _) {
                if (day == null) {
                  return const Center(
                    child: Text(
                      "Pilih tanggal untuk melihat transaksi",
                      style: TextStyle(
                        color: Color(0xFF014037),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                final summary = dailySummary[
                DateTime(day.year, day.month, day.day)];

                if (summary == null) {
                  return _buildPanel(
                      day, "Tidak ada transaksi", null, null);
                }

                return _buildPanel(
                  day,
                  "Detail Transaksi",
                  summary.income,
                  summary.expense,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ----------------  PANEL GENERATOR (Flat di bawah)  ----------------
  Widget _buildPanel(DateTime day, String title, int? income, int? expense) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF2EBD8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title - ${day.day}/${day.month}/${day.year}",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF014037),
            ),
          ),
          const SizedBox(height: 20),

          if (income != null)
            Text("Pemasukan: Rp$income",
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),

          if (expense != null)
            Text("Pengeluaran: Rp$expense",
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
        ],
      ),
    );
  }
}
