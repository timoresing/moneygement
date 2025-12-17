import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // --- 1. STATE UNTUK SEARCH & FILTER ---
  String _searchQuery = "";
  String _selectedFilter = "All"; // Pilihan: 'All', 'Income', 'Expense'

  String formatRupiah(num number) {
    return "Rp${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

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
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Enter amount",
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
                                      content: Text("Succesfully adding balance!"),
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

      // --- BODY UTAMA ---
      body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

            int currentBalance = 0;
            int currentIncome = 0;
            int currentExpense = 0;

            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              currentIncome = data['income'] ?? 0;
              currentExpense = data['expense'] ?? 0;
              currentBalance = data['balance'] ?? (currentIncome - currentExpense);
            }

            return Column(
              children: [
                // 1. FIXED TOP AREA
                Container(
                  color: backgroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Column(
                    children: [
                      // Balance Card
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
                                  Text(formatRupiah(currentBalance), style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
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
                      Row(
                        children: [
                          Expanded(child: _moneyCard("Expense", currentExpense, Colors.red)),
                          const SizedBox(width: 14),
                          Expanded(child: _moneyCard("Income", currentIncome, Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),

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
                              Text("Recently activity", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFFC86623), fontSize: 20)),
                              const SizedBox(height: 25),

                              // --- FILTER CHIPS AKTIF ---
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    const Icon(Icons.filter_alt_outlined, color: Color(0xFFC86623)),
                                    const SizedBox(width: 8),
                                    Text("Filter:", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 10),

                                    // Pilihan Filter: All, Income, Expense
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

                        // --- LIST DATA DENGAN LOGIKA FILTER ---
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user?.uid)
                                .collection('transactions')
                                .orderBy('date', descending: true)
                                .limit(50)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();
                              var docs = snapshot.data!.docs;

                              // 2. LAKUKAN FILTERING DI SINI (CLIENT SIDE)
                              var filteredDocs = docs.where((doc) {
                                var data = doc.data() as Map<String, dynamic>;
                                String title = data['title'].toString().toLowerCase();
                                String type = data['type'].toString().toLowerCase();

                                // Filter A: Search Text
                                bool matchesSearch = title.contains(_searchQuery);

                                // Filter B: Chips Category
                                bool matchesFilter = true;
                                if (_selectedFilter != "All") {
                                  // Kalau pilih Income, data harus income. Kalau Expense, harus expense.
                                  matchesFilter = type == _selectedFilter.toLowerCase();
                                }

                                return matchesSearch && matchesFilter;
                              }).toList();

                              // 3. JIKA HASIL FILTER KOSONG
                              if (filteredDocs.isEmpty) {
                                return Center(
                                  child: Text("Not found anything", style: GoogleFonts.poppins(color: Colors.grey)),
                                );
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: filteredDocs.length,
                                itemBuilder: (context, index) {
                                  var doc = filteredDocs[index];
                                  var data = doc.data() as Map<String, dynamic>;

                                  String title = data['title'] ?? 'Tanpa Judul';
                                  int amount = data['amount'] ?? 0;
                                  String type = data['type'] ?? 'expense';
                                  Color color = (type == 'income') ? Colors.green : Colors.red;

                                  return _activityItem(title, formatRupiah(amount), color);
                                },
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
          }
      ),
    );
  }

  // --- WIDGET HELPERS ---

  // Widget Filter Chip yang bisa diklik
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 50, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text("Belum ada transaksi", style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }

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

  Widget _activityItem(String title, String value, Color color) {
    return Container(
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
          Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}