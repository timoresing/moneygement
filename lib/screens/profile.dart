import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/auth_service.dart';
import 'package:flutter/services.dart'; // Import ini wajib

class ProfilePage extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const ProfilePage({super.key, this.onProfileTap});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();

  void _showLimitDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Coming Soon"),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _updateDisplayName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && _nameController.text.isNotEmpty) {
      try {
        String newName = _nameController.text.trim();

        await user.updateDisplayName(newName);
        await user.reload();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'displayName': newName});

        setState(() {});

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Username updated successfully!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(20),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print("Error updating name: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(20),
            duration: Duration(seconds: 2),),
        );
      }
    }
  }

  // Fungsi Menampilkan Dialog Edit
  void _showEditNameDialog(String currentName) {
    _nameController.text = currentName;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Username"),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "New Username",
              hintText: "Enter your name",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
              onPressed: _updateDisplayName,
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Fungsi Change Password
  void _showChangePasswordDialog() {
    _currentPassController.clear();
    _newPassController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Current Password",
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _newPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "New Password",
                  prefixIcon: Icon(Icons.vpn_key),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
              onPressed: () async {
                if (_currentPassController.text.isEmpty || _newPassController.text.isEmpty) {
                  return;
                }

                String? result = await AuthService().changePassword(
                  currentPassword: _currentPassController.text.trim(),
                  newPassword: _newPassController.text.trim(),
                );

                if (mounted) {
                  if (result == null) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password updated!"),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(20),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text("Update", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menampilkan dialog konfirmasi logout
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Log Out"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                if (mounted) {
                  Navigator.pop(context);
                }
                AuthService().signOut();
              },
              child: const Text("Log Out", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // LOGIKA SAPAAN USER
  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour >= 0 && hour < 11) return 'Morning';
    if (hour >= 11 && hour < 16) return 'Afternoon';
    if (hour >= 16 && hour < 18) return 'Evening';
    return 'Night';
  }

  @override
  Widget build(BuildContext context) {
    final Color darkGreen = const Color(0xFF004D40);
    final Color goldAccent = const Color(0xFFE0AA00);
    final Color creamBg = const Color(0xFFF1ECDE);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final User? user = snapshot.data;

        // Logika menyembunyikan ganti password jika login via Google
        bool isGoogleUser = user?.providerData.any(
                (userInfo) => userInfo.providerId == 'google.com') ?? false;
        bool enableSecurityButton = !isGoogleUser;

        final String displayName = user?.displayName ?? "User";
        final String email = user?.email ?? "";
        final String? photoUrl = user?.photoURL;

        return Scaffold(
          backgroundColor: creamBg,
          appBar: AppBar(
            backgroundColor: darkGreen,
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: true,
            title: const Text(
              "Profile",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            elevation: 0,
          ),

          drawer: Drawer(
            backgroundColor: const Color(0xFFF1ECDE),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF004D40)),
                  child: Column(
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
                      Text("Hi, Good ${_getGreeting()}", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                      Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
                ListTile(leading: const Icon(Icons.home),
                    title: const Text('Dashboard'),
                    onTap: () => Navigator.pop(context)),
                ListTile(leading: const Icon(Icons.person),
                    title: const Text('Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onProfileTap != null) widget.onProfileTap!();
                    }),
                ListTile(leading: const Icon(Icons.logout),
                    title: const Text('Log Out'),
                    onTap: _showLogoutConfirmationDialog
                ),
              ],
            ),
          ),

          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // KARTU IDENTITAS USER
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: darkGreen,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: darkGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            shape: BoxShape.circle,
                            border: Border.all(color: goldAccent, width: 2),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
                            ),
                          ),
                          child: photoUrl == null ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _showEditNameDialog(displayName),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.verified, size: 14, color: goldAccent),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w400),
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

                  // MENU SECTIONS
                  _buildSectionHeader("Account"),
                  _buildProfileOption(Icons.person_outline, "Personal Data", darkGreen, onTap: () => _showEditNameDialog(displayName)),
                  _buildProfileOption(Icons.warning_amber_rounded, "Set Daily Limit", darkGreen, onTap: _showLimitDialog),

                  const SizedBox(height: 20),

                  _buildSectionHeader("Settings"),
                  _buildProfileOption(Icons.lock_outline, "Security & PIN", darkGreen, onTap: enableSecurityButton ? () => _showChangePasswordDialog() : null),

                  const SizedBox(height: 30),

                  GestureDetector(
                    onTap: _showLogoutConfirmationDialog,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: const Center(
                        child: Text("Log Out",
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // MENU OPTION
  Widget _buildProfileOption(IconData icon, String title, Color color, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black87)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}