import 'dart:ui';
import 'package:flutter/material.dart';

void showAddCostOverlay(BuildContext context) {
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) {
      return Material(
        color: Colors.transparent,
          child: Stack(
            children: [
              AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: () => overlayEntry.remove(),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                ),
              ),

              Center(
                child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
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
                      onClose: () => overlayEntry.remove(),
                    ),
                  ),
                ),
              ),
            ],
          ),
      );
    },
  );

  Overlay.of(context).insert(overlayEntry);
}

// -------------------------------------------------------------
// Form Widget
// -------------------------------------------------------------

class _AddCostForm extends StatelessWidget {
  final VoidCallback onClose;

  const _AddCostForm({required this.onClose});

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

        TextField(
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

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              items: const [
                DropdownMenuItem(value: "food", child: Text("Food")),
                DropdownMenuItem(value: "transport", child: Text("Transport")),
              ],
              onChanged: (value) {},
              hint: const Text("Pick one"),
            ),
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          maxLines: 4,
          decoration: InputDecoration(
            labelText: "Description",
            hintText: 'Bought seafood & Chicken wings',
            hintStyle: TextStyle(
              color: Colors.black.withOpacity(0.4),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Amount",
            hintText: '100000',
            hintStyle: TextStyle(
              color: Colors.black.withOpacity(0.4),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 25),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF014037),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Back", style: TextStyle(color: Colors.white)),
            ),

            ElevatedButton(
              onPressed: () {
                onClose();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1C854),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Add",
                style: TextStyle(color: Color(0xFF4A4A4A)),
              ),
            ),
          ],
        )
      ],
    );
  }
}
