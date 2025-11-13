import 'package:flutter/material.dart';
import 'package:tubes_pm_kelompok1/assets/profile.dart';
import 'package:tubes_pm_kelompok1/dashboard.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardPage(),
    ProfilePage(),
    // JelajahiScreen(),
  //   TugasScreen(),
  ];

  void _onTabTapper(int index){
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: () async {
            var status = await Permission.camera.request();

            if(status.isGranted){
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Kamera diberi izin'))
              );
            }
            else if (status.isDenied){
              await Permission.camera.request();
            } else if (status.isPermanentlyDenied){
              openAppSettings();
            }
          },
          shape: CircleBorder(),
          backgroundColor: const Color(0xFFF1C854),
          tooltip: "Add",
          elevation: 8,
          child: Icon(
            Icons.add,
            size: 45,
            color: const Color(0xFF004D40),
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 7,
        color: const Color(0xFF004D40),
        child: Container(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Navbar Kiri
                Row(
                  children: [
                    _buildNavItem("Home", Icons.home_outlined, 0),
                    // _buildNavItem("Jelajahi", Icons.travel_explore_outlined, 1),
                  ],
                ),

                // Navbar Kanan
                Row(
                  children: [
                    // _buildNavItem("Tugas", Icons.assignment, 2),
                    _buildNavItem("Profile", Icons.person, 1),
                  ],
                ),
              ]
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
    );
  }

  Widget _buildNavItem(String title, IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFFF1ECDE):Colors.grey;
    return MaterialButton(
      minWidth: 40,
      onPressed: () => _onTabTapper(index),
      child: Column(
          children: [
            Icon(icon, size: 30, color: color,),
            Text(title,
              style: TextStyle(
                  fontSize: 15,
                  color: color
              ),
            )
          ]
      ),
    );
  }
}