import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const DashboardPage({super.key, this.onProfileTap});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  // DIALOG EDIT
  void _showEditDialog(String id, String currentTitle, int currentAmount, String currentType, DateTime currentDate, String? currentDesc) {
    final titleController = TextEditingController(text: currentTitle);
    final amountController = TextEditingController(text: currentAmount.toString());
    final descController = TextEditingController(text: currentDesc ?? "");

    DateTime selectedDate = currentDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(currentDate);
    String selectedType = currentType;

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
                          decoration: const InputDecoration(labelText: "Amount"),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text("Income", style: TextStyle(fontSize: 12)),
                                value: "income",
                                groupValue: selectedType.toLowerCase(),
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setDialogState(() => selectedType = "income"),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text("Expense", style: TextStyle(fontSize: 12)),
                                value: "expense",
                                groupValue: selectedType.toLowerCase(),
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setDialogState(() => selectedType = "expense"),
                              ),
                            ),
                          ],
                        ),
                        // DATE PICKER
                        ListTile(
                          title: Text("Date: ${_formatDateFull(selectedDate)}"),
                          trailing: const Icon(Icons.calendar_month),
                          onTap: () async {
                            final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030)
                            );
                            if (picked != null) setDialogState(() => selectedDate = picked);
                          },
                        ),

                        TextField(
                          controller: descController,
                          decoration: const InputDecoration(labelText: "Description"),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
                      onPressed: () {
                        if (titleController.text.isEmpty || amountController.text.isEmpty) return;

                        int newAmount = int.parse(amountController.text);
                        DateTime finalDateTime = DateTime(
                            selectedDate.year, selectedDate.month, selectedDate.day,
                            selectedTime.hour, selectedTime.minute
                        );
                        _updateTransaction(
                          transId: id,
                          newAmount: newAmount,
                          newType: selectedType,
                          newTitle: titleController.text,
                          newDesc: descController.text,
                          newDate: finalDateTime,
                        );
                      },
                      child: const Text("Save", style: TextStyle(color: Colors.white)),
                    )
                  ],
                );
              }
          );
        }
    );
  }

  // BACKEND UPDATE
  Future<void> _updateTransaction({
    required String transId,
    required int newAmount,
    required String newType,
    required String newTitle,
    required String newDesc,
    required DateTime newDate,
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
        'description': newDesc,
        'date': Timestamp.fromDate(newDate),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Successfully updated!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(20),
            duration: Duration(seconds: 2),),
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }
  String _searchQuery = "";
  String _selectedFilter = "All";

  // RUPIAH FORMATER
  String formatRupiah(num number) {
    return "Rp${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  // FORMAT TANGGAL
  String _formatDateFull(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date);
  }

  // FORMAT WAKTU
  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  // BACKEND DELETE
  Future<void> _deleteTransaction(String transId, int amount, String type) async {
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
          const SnackBar(content: Text("Successfully deleted!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(20),
            duration: Duration(seconds: 2),),
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  // DIALOG DETAIL CARD AKTIVITAS SATUAN
  void _showDetailDialog(String id, String title, int amount, String type, DateTime date, String? description, category) {
    bool isIncome = type == 'income';
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
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${_formatDateFull(date)} • ${_formatTime(date)}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      formatRupiah(amount),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                    if (!isIncome && category.isNotEmpty) ...[
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
                              category,
                              style: TextStyle(
                                color: Colors.blueGrey[800],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          description,
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
                              _showEditDialog(id, title, amount, type, date, description);
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
                                  // ALERT SEBELUM MENGHAPOS
                                  builder: (c) => AlertDialog(
                                    title: const Text("Delete Transaction?"),
                                    content: const Text("This action cannot be undone."),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(c);
                                            _deleteTransaction(id, amount, type);
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

  // DIALOG TAMBAH BALANCE/SALDO
  void showAddBalanceDialog() {
    TextEditingController titleController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 5)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Add Balance",
                      style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: "Transaction Name",
                        hintText: "e.g. Monthly Salary",
                        hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
                        prefixIcon: const Icon(Icons.edit_note, color: Color(0xFF004D40)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // --- INPUT AMOUNT DI SINI ---
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      // 2. TAMBAHAN PENTING: HANYA BOLEH ANGKA
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: "Enter amount",
                        hintText: "e.g. 100000",
                        hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
                        prefixIcon: const Icon(Icons.money, color: Color(0xFF004D40)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDFA900)),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
                          onPressed: () async {
                            String cleanValue = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
                            int? amount = int.tryParse(cleanValue);
                            String title = titleController.text.trim();
                            if (title.isEmpty) title = "Top Up Balance";

                            if (amount != null && amount > 0 && user != null) {
                              try {
                                DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user!.uid);
                                await userDoc.collection('transactions').add({
                                  'title': title,
                                  'description': 'Manual income entry',
                                  'amount': amount,
                                  'type': 'income',
                                  'category': 'primary',
                                  'date': FieldValue.serverTimestamp(),
                                });
                                await userDoc.update({
                                  'balance': FieldValue.increment(amount),
                                  'income': FieldValue.increment(amount),
                                });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Balance added successfully!"),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.all(20),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print("Error: $e");
                              }
                            }
                          },
                          child: const Text("Save", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = const Color(0xFFF1ECDE);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
          backgroundColor: const Color(0xFF004D40),
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          title: const Text('Moneygement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFF1ECDE),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF004D40)),
              child: Builder(builder: (context) {
                final User? user = FirebaseAuth.instance.currentUser;
                final String userName = user?.displayName ?? "User";
                final String? photoUrl = user?.photoURL;
                String getGreeting() {
                  var hour = DateTime.now().hour;
                  if (hour >= 0 && hour < 11) return 'Morning';
                  if (hour >= 11 && hour < 16) return 'Afternoon';
                  if (hour >= 16 && hour < 18) return 'Evening';
                  return 'Night';
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF1C854), width: 2),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: photoUrl != null
                              ? NetworkImage(photoUrl)
                              : const AssetImage('assets/default_avatar.png') as ImageProvider,
                        ),
                      ),
                      child: photoUrl == null ? const Icon(Icons.person, size: 35, color: Colors.white) : null,
                    ),
                    const SizedBox(height: 12),
                    Text("Hi, Good ${getGreeting()}", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                    Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                );
              }),
            ),
            ListTile(leading: const Icon(Icons.home), title: const Text('Dashboard'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.person), title: const Text('Profile'), onTap: () {
              Navigator.pop(context);
              if (widget.onProfileTap != null) widget.onProfileTap!();
            }),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () async => await AuthService().signOut()),
          ],
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('transactions')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          int totalIncome = 0;
          int totalExpense = 0;
          int totalBalance = 0;

          var allDocs = snapshot.data?.docs ?? [];

          for (var doc in allDocs) {
            var data = doc.data() as Map<String, dynamic>;
            int amount = data['amount'] ?? 0;
            String type = (data['type'] ?? 'expense').toString().toLowerCase();
            if (type == 'income') {
              totalIncome += amount;
            } else {
              totalExpense += amount;
            }
          }

          totalBalance = totalIncome - totalExpense;

          return Column(
            children: [
              Container(
                color: backgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Column(
                  children: [
                    // CARD BALANCE
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF004D40),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Balance", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15)),
                                const SizedBox(height: 8),
                                Text(formatRupiah(totalBalance), style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // BUTTON ADD
                        GestureDetector(
                          onTap: showAddBalanceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0AA00),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4))],
                            ),
                            child: const Icon(Icons.add, color: Colors.black, size: 28),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // CARD INCOME & EXPENSE
                    Row(
                      children: [
                        Expanded(child: _moneyCard("Expense", totalExpense, Colors.red)),
                        const SizedBox(width: 14),
                        Expanded(child: _moneyCard("Income", totalIncome, Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),

              // BAGIAN BAWAH (LIST RIWAYAT)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFEBDD),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Recent Activity", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFFC86623), fontSize: 20)),
                            const SizedBox(height: 25),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  const Icon(Icons.filter_alt_outlined, color: Color(0xFFC86623)),
                                  const SizedBox(width: 8),
                                  Text("Filter:", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 10),
                                  _buildFilterChip("All"),
                                  const SizedBox(width: 6),
                                  _buildFilterChip("Income"),
                                  const SizedBox(width: 6),
                                  _buildFilterChip("Expense"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: allDocs.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: allDocs.length,
                          itemBuilder: (context, index) {
                            var doc = allDocs[index];
                            var data = doc.data() as Map<String, dynamic>;

                            // Logic Filter & Search Manual
                            String title = data['title'].toString();
                            String type = data['type'].toString().toLowerCase();
                            String category = (data['category'] ?? '').toString();

                            // Filter logic simple
                            if (_selectedFilter != "All" && type != _selectedFilter.toLowerCase()) {
                              return const SizedBox();
                            }

                            // Render Item
                            return _activityItem(
                                doc.id,
                                title,
                                data['amount'] ?? 0,
                                type,
                                (data['date'] as Timestamp).toDate(),
                                data['description'],
                                category
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // WIDGET HELPERS (All, Income, Expense)
  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF004D40) : Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFF004D40) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            )
        ),
      ),
    );
  }

  // KALAU BELUM/TIDAK ADA TRANKSAKSI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 50, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text("No transactions yet", style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }

  // WIDGET CARD INCOME/EXPENSE BESERTA LOGIC
  Widget _moneyCard(String title, int amount, Color typeColor) {
    bool isZero = amount == 0;
    Color activeColor = isZero ? Colors.grey.shade400 : typeColor;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: activeColor.withOpacity(isZero ? 0.3 : 0.4), width: 2),
        boxShadow: isZero ? [] : [BoxShadow(color: typeColor.withOpacity(0.15), blurRadius: 10, offset: const Offset(2, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isZero ? Colors.grey.shade200 : typeColor.withOpacity(0.15),
            child: Icon(isZero ? Icons.remove : (title == "Expense" ? Icons.arrow_downward : Icons.arrow_upward), color: activeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade700)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(formatRupiah(amount), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: isZero ? Colors.grey.shade500 : typeColor)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // CARD-CARD AKTIVITAS
  Widget _activityItem(String id, String title, int amount, String type, DateTime date, String? description, category) {
    Color color = (type == 'income') ? Colors.green : Colors.red;
    return InkWell(
      onTap: () {
        _showDetailDialog(id, title, amount, type, date, description, category);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(1, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(color == Colors.red ? Icons.arrow_downward : Icons.arrow_upward, color: color),
                const SizedBox(width: 8),
                Text(title, style: GoogleFonts.poppins(fontSize: 14)),
              ],
            ),
            Text(formatRupiah(amount), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}