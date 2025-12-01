import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart'; // pastikan file login_page.dart sudah ada

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();

    // Animasi logo fade-in
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();

    // Setelah 3 detik, navigasi ke halaman login dengan transisi fade
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 900),
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF3EEDF),
      body: Stack(
        children: [
          // ORNAMENT ATAS
          Positioned(
            top: -50,
            left: 0,
            right: 0,
            child: Image.asset(
              'lib/assets/images/top-ornament.png',
              width: screen.width,
              height: screen.height * 0.35,
              fit: BoxFit.cover,
            ),
          ),

          // ORNAMENT BAWAH
          Positioned(
            bottom: -50,
            left: 0,
            right: 0,
            child: Image.asset(
              'lib/assets/images/bottom-ornament.png',
              width: screen.width,
              height: screen.height * 0.25,
              fit: BoxFit.cover,
            ),
          ),

          // LOGO DAN TEKS
          Center(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'lib/assets/images/Logo.png',
                    width: screen.width * 0.6,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
