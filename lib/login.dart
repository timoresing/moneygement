import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pm_kelompok1/assets/Nav/navbar.dart';
import 'package:tubes_pm_kelompok1/dashboard.dart';
import 'register.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
            top: -40,
            left: 0,
            right: 0,
            child: Image.asset(
              'lib/assets/images/top-ornament.png',
              width: screen.width,
              height: screen.height * 0.27, // 25% dari tinggi layar
              fit: BoxFit.cover,
            ),
          ),

          // ORNAMENT BAWAH
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'lib/assets/images/bottom-ornament.png',
              width: screen.width,
              height: screen.height * 0.18, // 18% dari tinggi layar
              fit: BoxFit.cover,
            ),
          ),

          // KONTEN LOGIN
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 110),

                    // LOGO
                    Image.asset(
                      'lib/assets/images/Logo.png',
                      height: screen.height * 0.21,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),

                    // JUDUL
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 12),
                      child: Text(
                        'Login',
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC86623),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // EMAIL FIELD
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'johndoe@gmail.com',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PASSWORD FIELD
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Your Password',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Navbar()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCE9B00),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 21,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // FORGOT PASSWORD
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // REGISTER LINK
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterPage()),
                            );
                          },
                          child: Text(
                            'Register here',
                            style: TextStyle(
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
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
