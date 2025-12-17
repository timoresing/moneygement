import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pm_kelompok1/screens/Nav/navbar.dart';
import 'package:tubes_pm_kelompok1/service/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleRegister() async {
    setState(() => _isLoading = true);

    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPass = _confirmPassController.text.trim();

    // Validasi Input Dasar
    if (email.isEmpty || password.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      setState(() => _isLoading = false);
      return;
    }

    // Validasi Password Match
    if (password != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      setState(() => _isLoading = false);
      return;
    }

    // Panggil Auth Service
    final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name
    );

    setState(() => _isLoading = false);

    if (user != null) {
      // Registrasi Berhasil Maka Masuk Dashboard
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Navbar()),
              (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration Failed. Email might be already in use.")));
      }
    }
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
                    Image.asset('lib/assets/images/Logo.png', height: screen.height * 0.14, fit: BoxFit.contain),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Text('Register', style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w700, color: const Color(0xFFC86623))),
                    ),
                    const SizedBox(height: 8),

                    // USERNAME FIELD
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'johndoe123',
                        hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // EMAIL FIELD
                    TextField(
                      controller: _emailController,
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
                      controller: _passwordController,
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
                    const SizedBox(height: 16),

                    // CONFIRM PASSWORD FIELD
                    TextField(
                      controller: _confirmPassController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter your password',
                        hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // REGISTER BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCE9B00),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Register', style: TextStyle(fontSize: 21, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // LOGIN LINK
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text('Login here', style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
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