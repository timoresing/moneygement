import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class TransactionDetail {
  final String id;
  final String title;
  final int amount;
  final String type;
  final String category;
  final DateTime date;
  final String? description;

  TransactionDetail({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.description,
  });

  factory TransactionDetail.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionDetail(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      amount: data['amount'] ?? 0,
      type: (data['type'] ?? 'expense').toString().toLowerCase(),
      category: data['category'] ?? 'Not Set',
      date: (data['date'] as Timestamp).toDate(),
      description: data['description'],
    );
  }
}

class KalenderPage extends StatefulWidget {
  final VoidCallback onBack;
  const KalenderPage({super.key, required this.onBack});

  @override
  State<KalenderPage> createState() => _KalenderPageState();
}

class _KalenderPageState extends State<KalenderPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<TransactionDetail>> _groupedEvents = {};
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _streamSubscription;

  final List<String> _categories = [
    'Food & Drink', 'Transport', 'Bill & Utilities', 'Shopping', 'Miscellaneous', 'Not Set'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _listenToEvents();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  // LISTEN EVENTS
  void _listenToEvents() {
    if (user == null) return;

    _streamSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {

      Map<DateTime, List<TransactionDetail>> tempGrouped = {};

      for (var doc in snapshot.docs) {
        final trx = TransactionDetail.fromFirestore(doc);
        final dateKey = DateTime(trx.date.year, trx.date.month, trx.date.day);

        if (tempGrouped[dateKey] == null) {
          tempGrouped[dateKey] = [];
        }
        tempGrouped[dateKey]!.add(trx);
      }

      if (mounted) {
        setState(() {
          _groupedEvents = tempGrouped;
          _isLoading = false;
        });
      }
    }, onError: (e) {
      print("Error fetching calendar events: $e");
      if (mounted) setState(() => _isLoading = false);
    });
  }

  // FUNGSI UPDATE
  Future<void> _updateTransaction({
    required String transId,
    required String newTitle,
    required int newAmount,
    required String newType,
    required String newCategory,
    required DateTime newDate,
    required String newDesc,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('transactions')
          .doc(transId)
          .update({
        'title': newTitle,
        'amount': newAmount,
        'type': newType,
        'category': newCategory,
        'description': newDesc,
        'date': Timestamp.fromDate(newDate),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Successfully updated!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(20),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error updating: $e");
    }
  }

  // FUNGSI DELETE
  Future<void> _deleteTransaction(String transId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('transactions')
          .doc(transId)
          .delete();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Successfully deleted!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(20),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error deleting: $e");
    }
  }

  // DIALOG EDIT
  void _showEditDialog(TransactionDetail trx) {
    final titleController = TextEditingController(text: trx.title);
    final amountController = TextEditingController(text: trx.amount.toString());
    final descController = TextEditingController(text: trx.description ?? '');

    String selectedType = trx.type;
    String selectedCategory = _categories.contains(trx.category) ? trx.category : _categories.first;
    DateTime selectedDate = trx.date;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(trx.date);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Transaction"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Title"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: "Amount (Rp)"),
                    ),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Income", style: TextStyle(fontSize: 12)),
                            value: "income",
                            groupValue: selectedType,
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF43A047),
                            onChanged: (val) => setDialogState(() => selectedType = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Expense", style: TextStyle(fontSize: 12)),
                            value: "expense",
                            groupValue: selectedType,
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFFE53935),
                            onChanged: (val) => setDialogState(() => selectedType = val!),
                          ),
                        ),
                      ],
                    ),

                    if (selectedType == 'expense') ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: "Category",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
                        items: _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setDialogState(() => selectedCategory = newValue!);
                        },
                      ),
                    ],

                    const SizedBox(height: 5),

                    // Date Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Date: ${_formatDateFull(selectedDate)}"),
                      trailing: const Icon(Icons.calendar_today, size: 16),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null) setDialogState(() => selectedDate = pickedDate);
                      },
                    ),

                    // Time Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Time: ${selectedTime.format(context)}"),
                      trailing: const Icon(Icons.access_time, size: 16),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (pickedTime != null) setDialogState(() => selectedTime = pickedTime);
                      },
                    ),

                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: "Description"),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
                  onPressed: () {
                    FocusScope.of(context).unfocus();

                    if (titleController.text.isEmpty || amountController.text.isEmpty) return;

                    final newDateTime = DateTime(
                      selectedDate.year, selectedDate.month, selectedDate.day,
                      selectedTime.hour, selectedTime.minute,
                    );

                    String finalCategory = (selectedType == 'income') ? 'Income' : selectedCategory;

                    _updateTransaction(
                      transId: trx.id,
                      newTitle: titleController.text,
                      newAmount: int.parse(amountController.text),
                      newType: selectedType,
                      newCategory: finalCategory,
                      newDate: newDateTime,
                      newDesc: descController.text,
                    );
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // DETAIL DIALOG
  void _showDetailDialog(TransactionDetail trx) {
    bool isIncome = trx.type == 'income';
    Color typeColor = isIncome ? const Color(0xFF43A047) : const Color(0xFFE53935);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          backgroundColor: Colors.white,
          child: Stack(
            children: [
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: typeColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      trx.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${_formatDateFull(trx.date)} • ${_formatTime(trx.date)}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _formatCurrency(trx.amount),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),

                    if (!isIncome && trx.category.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.category_outlined, size: 14, color: Colors.blueGrey[700]),
                            const SizedBox(width: 6),
                            Text(
                              trx.category,
                              style: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (trx.description != null && trx.description!.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          trx.description!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditDialog(trx);
                            },
                            icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                            label: const Text("Edit", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF1C854),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  // SAMA KEK DI DASHBOARD
                                  builder: (c) => AlertDialog(
                                    title: const Text("Delete Transaction?"),
                                    content: const Text("This action cannot be undone."),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(c);
                                            _deleteTransaction(trx.id);
                                          },
                                          child: const Text("Delete", style: TextStyle(color: Colors.red))
                                      ),
                                    ],
                                  )
                              );
                            },
                            icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                            label: const Text("Delete", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // HELPERS
  List<TransactionDetail> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _groupedEvents[normalizedDay] ?? [];
  }

  // RUPIAH FORMAT
  String _formatCurrency(int amount) {
    return "Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  // FORMAT WAKTU
  String _formatTime(DateTime date) {
    return DateFormat('HH:mm', 'en_US').format(date);
  }

  // FORMAT TANGGAL
  String _formatDateFull(DateTime date) {
    return DateFormat('d MMMM yyyy', 'en_US').format(date);
  }

  // FORMAT SINGKATAN BULAN
  String _getMonthName(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }

  // LOGIKA KALKULASI KESELURUHAN
  Map<String, int> _calculateSummary(List<TransactionDetail> transactions) {
    int income = 0;
    int expense = 0;
    for (var trx in transactions) {
      if (trx.type == 'income') income += trx.amount;
      else expense += trx.amount;
    }
    return {'income': income, 'expense': expense};
  }

  // LOGIKA WARNA SAAT KLIK TANGGAL
  Widget _buildCustomDay(DateTime day, bool isSelected, bool isToday) {
    final events = _getEventsForDay(day);
    Color? markerColor;

    if (events.isNotEmpty) {
      final summary = _calculateSummary(events);
      if (summary['income']! >= summary['expense']!) {
        markerColor = const Color(0xFF43A047);
      } else {
        markerColor = const Color(0xFFE53935);
      }
    }

    Color bgCircle = Colors.transparent;
    Color textColor = const Color(0xFF004D40);

    if (isSelected) {
      bgCircle = const Color(0xFF004D40);
      textColor = Colors.white;
    } else if (isToday) {
      bgCircle = const Color(0xFFF1C854);
      textColor = Colors.black;
    }

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bgCircle,
        shape: BoxShape.circle,
        boxShadow: isSelected ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))] : [],
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
          if (markerColor != null) ...[
            const SizedBox(height: 4),
            Container(
              width: 5, height: 5,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : markerColor,
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
      backgroundColor: const Color(0xFFF1ECDE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D40),
        elevation: 0,
        centerTitle: true,
        title: const Text("Calendar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)))
          : Column(
        children: [
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
            child: TableCalendar(
              locale: 'en_US',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 1, 1),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
                leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFFF1C854)),
                rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFFF1C854)),
              ),
              calendarStyle: const CalendarStyle(outsideDaysVisible: false),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) => const SizedBox(),
                defaultBuilder: (context, day, focusedDay) => _buildCustomDay(day, false, false),
                selectedBuilder: (context, day, focusedDay) => _buildCustomDay(day, true, false),
                todayBuilder: (context, day, focusedDay) {
                  bool isSelected = isSameDay(day, _selectedDay);
                  return _buildCustomDay(day, isSelected, true);
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: Builder(
              builder: (context) {
                final selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);
                String dateString = "";
                if (_selectedDay != null) {
                  dateString = "${_selectedDay!.day} ${_getMonthName(_selectedDay!.month)} ${_selectedDay!.year}";
                }

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8, right: 16, left: 16),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))
                      ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Transaction List", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          Text(dateString, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                        ],
                      ),
                      const Divider(height: 20),

                      Expanded(
                        child: selectedEvents.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notes, size: 40, color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              Text("No transactions available.", style: TextStyle(color: Colors.grey[400])),
                            ],
                          ),
                        )
                            : ListView.separated(
                          itemCount: selectedEvents.length,
                          padding: const EdgeInsets.only(bottom: 20),
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final trx = selectedEvents[index];
                            return _buildTransactionCard(trx);
                          },
                        ),
                      ),
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

  // CARD BAGIAN BAWAH UTK NAMPILIN DETAIL
  Widget _buildTransactionCard(TransactionDetail trx) {
    bool isIncome = trx.type == 'income';
    Color mainColor = isIncome ? const Color(0xFF43A047) : const Color(0xFFE53935);
    Color bgColor = isIncome ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    IconData icon = isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return InkWell(
      onTap: () => _showDetailDialog(trx),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: mainColor, width: 5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: mainColor, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trx.title,
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${isIncome ? 'Income' : 'Expense'} • ${_formatTime(trx.date)}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              _formatCurrency(trx.amount),
              style: TextStyle(color: mainColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}