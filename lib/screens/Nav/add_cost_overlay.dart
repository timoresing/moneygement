import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void showAddCostOverlay(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true, // Bisa ditutup dengan klik luar
    barrierLabel: "Add Cost", // Label untuk aksesibilitas
    barrierColor: Colors.black.withOpacity(0.2), // Warna gelap background
    transitionDuration: const Duration(milliseconds: 250), // Kecepatan animasi

    // --- ANIMASI MUNCUL (Scale & Fade) ---
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Menggunakan Kurva animasi agar membal (seperti easeOutBack)
      final curvedValue = Curves.easeOutBack.transform(animation.value);

      return Transform.scale(
        scale: curvedValue,
        child: Opacity(
          opacity: animation.value,
          child: child,
        ),
      );
    },

    // --- ISI DIALOG ---
    pageBuilder: (context, animation, secondaryAnimation) {
      return Stack(
        children: [
          // 1. Efek Blur Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.transparent),
          ),

          // 2. Dialog Form
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EBD8),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                // Panggil Form kamu disini
                child: _AddCostForm(
                  // Karena ini Dialog, tutupnya pakai Navigator.pop
                  onClose: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _AddCostForm extends StatefulWidget {
  final VoidCallback onClose;

  const _AddCostForm({
    super.key,
    required this.onClose,
  });
  @override
  State<_AddCostForm> createState() => _AddCostFormState();
}

class _AddCostFormState extends State<_AddCostForm> {
  // 1. Controller untuk menangkap input Text
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Variabel Dropdown
  String? _selectedCategory;

  // Loading state agar user tidak klik 2x
  bool _isLoading = false;

  @override
  void dispose() {
    // Wajib dispose controller biar memori hp gak bocor
    _titleController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // === FUNGSI UTAMA: SIMPAN PENGELUARAN KE FIRESTORE ===
  Future<void> _submitCost() async {
    final user = FirebaseAuth.instance.currentUser;

    // 1. Validasi Input Dasar
    if (_titleController.text.isEmpty || _amountController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon isi Judul, Jumlah, dan Kategori!")),
      );
      return;
    }

    // 2. Bersihkan Input Angka (Hapus titik/koma)
    String cleanValue = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    int amount = int.tryParse(cleanValue) ?? 0;

    if (amount <= 0) return; // Kalau 0 jangan disimpan

    setState(() => _isLoading = true); // Mulai loading

    try {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user!.uid);

      // A. SIMPAN RIWAYAT (History)
      await userDoc.collection('transactions').add({
        'title': _titleController.text,
        'description': _descController.text, // Deskripsi boleh kosong
        'amount': amount,
        'type': 'expense',       // <--- PENTING: Tipe Expense
        'category': _selectedCategory,
        'date': FieldValue.serverTimestamp(),
      });

      // B. UPDATE SALDO & TOTAL PENGELUARAN
      await userDoc.update({
        'balance': FieldValue.increment(-amount), // Saldo BERKURANG (Minus)
        'expense': FieldValue.increment(amount),  // Total Pengeluaran BERTAMBAH
      });

      // C. Sukses! Tutup Dialog
      if (mounted) {
        widget.onClose();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pengeluaran berhasil dicatat!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(20),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error add cost: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan data")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Add New Cost",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF014037),
          ),
        ),

        const SizedBox(height: 20),

        // Input 1: Title
        TextField(
          controller: _titleController, // Pasang Controller
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: "Cost title",
            fillColor: Colors.white,
            hintText: 'Go To Restaurant',
            hintStyle: TextStyle(
              color: Colors.black.withOpacity(0.4),
            ),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 15),

        // Input 2: Dropdown Category
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCategory,
              items: const [
                DropdownMenuItem(value: "Food", child: Text("Food & Drink")),
                DropdownMenuItem(value: "Transport", child: Text("Transport")),
                DropdownMenuItem(value: "Bill", child: Text("Bill & Utilities")),
                DropdownMenuItem(value: "Shopping", child: Text("Shopping")),
                DropdownMenuItem(value: "Miscellaneous", child: Text("Miscellaneous")),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              hint: const Text("Pick category"),
            ),
          ),
        ),

        const SizedBox(height: 15),

        // Input 3: Description
        TextField(
          controller: _descController, // Pasang Controller
          maxLines: 3, // Kurangi dikit biar gak kepanjangan
          decoration: InputDecoration(
            labelText: "Description (Optional)",
            hintText: 'Bought seafood & Chicken wings',
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 15),

        // Input 4: Amount
        TextField(
          controller: _amountController, // Pasang Controller
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Amount",
            hintText: '100000',
            prefixIcon: const Icon(Icons.money, size: 20), // Icon uang keluar
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 25),

        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: widget.onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF014037),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Back", style: TextStyle(color: Colors.white)),
            ),

            ElevatedButton(
              // Kalau lagi loading, tombol disable biar gak double klik
              onPressed: _isLoading ? null : _submitCost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004D40),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Add", style: TextStyle(color: Color(0xFFFFFFFF))),
            ),
          ],
        )
      ],
    );
  }
}