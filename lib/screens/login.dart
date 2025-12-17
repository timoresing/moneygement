import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pm_kelompok1/screens/Nav/navbar.dart';
// import 'package:tubes_pm_kelompok1/screens/dashboard.dart'; // Sesuaikan import dashboard kamu
import 'register.dart';
import 'package:tubes_pm_kelompok1/service/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controller untuk mengambil teks input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Fungsi Login Manual
  void _handleEmailLogin() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and Password cannot be empty")),
      );
      setState(() => _isLoading = false);
      return;
    }

    final user = await _authService.signInWithEmail(email, password);

    setState(() => _isLoading = false);

    if (user != null) {
      // Pindah ke Dashboard/Navbar
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Navbar()), // Ganti Navbar() atau DashboardPage()
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Failed. Check email/password.")),
        );
      }
    }
  }

  // Fungsi Login Google
  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Navbar()),
          );
        }
      }
    } catch (e) {
      print("Error: ${e}");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF3EEDF),
      body: Stack(
        children: [
          // ORNAMENT ATAS
          Positioned(
            top: -40, left: 0, right: 0,
            child: Image.asset('lib/assets/images/top-ornament.png', width: screen.width, height: screen.height * 0.27, fit: BoxFit.cover),
          ),
          // ORNAMENT BAWAH
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset('lib/assets/images/bottom-ornament.png', width: screen.width, height: screen.height * 0.18, fit: BoxFit.cover),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 110),
                    Image.asset('lib/assets/images/Logo.png', height: screen.height * 0.21, fit: BoxFit.contain),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 12),
                      child: Text('Login', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: const Color(0xFFC86623))),
                    ),
                    const SizedBox(height: 8),

                    // EMAIL FIELD
                    TextField(
                      controller: _emailController, // Tambahkan Controller
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'johndoe@gmail.com',
                        hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PASSWORD FIELD
                    TextField(
                      controller: _passwordController, // Tambahkan Controller
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Your Password',
                        hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleEmailLogin, // Panggil Fungsi
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCE9B00),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Login', style: TextStyle(fontSize: 21, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // DIVIDER
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[400])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text("Or continue with", style: TextStyle(color: Colors.black)),
                        ),
                        Expanded(child: Divider(color: Colors.grey[400])),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // GOOGLE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        icon: Image.asset('lib/assets/images/google-icon.png', height: 20, width: 20),
                        label: Text('Sign in with Google', style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.grey, width: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // REGISTER LINK
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Try another way? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                          },
                          child: Text('Register manually', style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}