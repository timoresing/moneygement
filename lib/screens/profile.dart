import 'package:flutter/material.dart';
import 'package:tubes_pm_kelompok1/screens/Nav/navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/dashboard.dart';
import '../service/auth_service.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const ProfilePage({super.key, this.onProfileTap});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

final User? user = FirebaseAuth.instance.currentUser;
final String displayName = user?.displayName ?? "Pengguna";
final String email = user?.email ?? "";
final String? photoUrl = user?.photoURL;

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    // Definisi warna tema agar konsisten
    final Color darkGreen = const Color(0xFF004D40);
    final Color goldAccent = const Color(0xFFE0AA00);
    final Color creamBg = const Color(0xFFF1ECDE); // Warna background Drawer kamu

    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        backgroundColor: darkGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          "Profile", // Judul halaman diganti Profile agar lebih jelas
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600
          ),
        ),
        elevation: 0,
      ),

      drawer: Drawer(
        backgroundColor: const Color(0xFFF1ECDE),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF004D40),
              ),
              child: Builder(
                  builder: (context) {
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
                        // FOTO PROFIL (Circular)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF1C854), width: 2), // Border emas biar bagus
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              // Cek apakah ada foto google? Jika ada pakai, jika tidak pakai icon default
                              image: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                  : const AssetImage('assets/default_avatar.png') as ImageProvider, // Ganti dengan asset lokal kamu atau hapus baris ini dan gunakan child Icon
                            ),
                          ),
                          child: photoUrl == null
                              ? const Icon(Icons.person, size: 35, color: Colors.white)
                              : null,
                        ),

                        const SizedBox(height: 12),

                        // TEKS SAPAAN
                        Text(
                          "Hi, Good ${getGreeting()}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // Agar tidak nabrak jika nama panjang
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  }
              ),
            ),

            // === LIST MENU BAWAH ===
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                if (widget.onProfileTap != null) {
                  widget.onProfileTap!();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async => await AuthService().signOut(),
            ),
          ],
        ),
      ),

      // === ISI TAMPILAN PROFIL (BODY) ===
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // 1. KARTU IDENTITAS USER (Hijau)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: darkGreen, // Pastikan variabel darkGreen sudah ada
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: darkGreen.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            shape: BoxShape.circle,
                            border: Border.all(color: goldAccent, width: 2), // Border emas
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: photoUrl != null
                                  ? NetworkImage(photoUrl!)
                                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
                            ),
                          ),
                          // Fallback jika image null & asset belum ada, pakai Icon
                          child: photoUrl == null
                              ? const Icon(Icons.person, size: 40, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(width: 15),

                    // 2. INFO NAMA & STATUS
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.verified, size: 14, color: goldAccent),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  email, // Menampilkan Email
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 2. MENU SECTIONS
              _buildSectionHeader("Account"),
              _buildProfileOption(Icons.person_outline, "Personal Data", darkGreen),
              _buildProfileOption(Icons.account_balance_wallet_outlined, "Bank & Cards", darkGreen),

              const SizedBox(height: 20),

              _buildSectionHeader("Settings"),
              _buildProfileOption(Icons.notifications_outlined, "Notifications", darkGreen),
              _buildProfileOption(Icons.lock_outline, "Security & PIN", darkGreen),

              const SizedBox(height: 30),

              // 3. LOGOUT BUTTON (Tombol Merah di Bawah)
              GestureDetector(
                onTap: () async => await AuthService().signOut(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Center(
                    child: Text(
                      "Log Out",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER AGAR KODE RAPI ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Item Menu Putih
  Widget _buildProfileOption(IconData icon, String title, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black87),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          // Tambahkan navigasi di sini nanti
        },
      ),
    );
  }
}