import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

void showAddCostOverlay(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Add Cost",
    barrierColor: Colors.black.withOpacity(0.2),
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedValue = Curves.easeOutBack.transform(animation.value);
      return Transform.scale(
        scale: curvedValue,
        child: Opacity(
          opacity: animation.value,
          child: child,
        ),
      );
    },

    // ISI DIALOG
    pageBuilder: (context, animation, secondaryAnimation) {
      return Stack(
        children: [
          // Efek Blur Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.transparent),
          ),

          // Dialog Form
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
                child: _AddCostForm(
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
  // Controller
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Variabel Dropdown
  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // SIMPAN CATATAN KE FIRESTORE
  Future<void> _submitCost() async {
    final user = FirebaseAuth.instance.currentUser;

    // Validasi Input Dasar
    if (_titleController.text.isEmpty || _amountController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill the title, amount & category!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
          duration: Duration(seconds: 2),),
      );
      return;
    }

    // Bersihkan Input Angka (Hapus titik/koma)
    String cleanValue = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    int amount = int.tryParse(cleanValue) ?? 0;

    if (amount <= 0) return;
    setState(() => _isLoading = true);

    try {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user!.uid);

      // SIMPAN RIWAYAT (History)
      await userDoc.collection('transactions').add({
        'title': _titleController.text,
        'description': _descController.text,
        'amount': amount,
        'type': 'expense',
        'category': _selectedCategory,
        'date': FieldValue.serverTimestamp(),
      });

      // UPDATE SALDO & TOTAL PENGELUARAN
      await userDoc.update({
        'balance': FieldValue.increment(-amount),
        'expense': FieldValue.increment(amount),
      });

      // Tutup Dialog
      if (mounted) {
        widget.onClose();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Successfully Adding Post!"),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to store data!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
          duration: Duration(seconds: 2),));
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
          controller: _titleController,
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
          controller: _descController,
          maxLines: 3,
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
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            labelText: "Amount",
            hintText: '100000',
            prefixIcon: const Icon(Icons.money, size: 20),
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

        // BUTTONS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: widget.onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDFA900),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Back", style: TextStyle(color: Colors.white)),
            ),

            ElevatedButton(
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