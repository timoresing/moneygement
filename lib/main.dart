import 'package:firebase_auth/firebase_auth.dart'; // Tambahkan ini
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tubes_pm_kelompok1/firebase_options.dart';
import 'package:tubes_pm_kelompok1/screens/Nav/navbar.dart';
import 'package:tubes_pm_kelompok1/screens/login.dart';
import 'package:tubes_pm_kelompok1/screens/splash.dart';
// import 'package:tubes_pm_kelompok1/screens/splash.dart'; // Opsional jika ingin loading pakai splash

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moneygement',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF3EEDF),
      ),
      // StreamBuilder memantau status login secara real-time
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Jika sedang proses cek status (loading awal)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
            // Atau return const SplashScreen(); jika ingin tetap pakai splash
          }

          // 2. Jika ada data User (Berarti sedang Login)
          if (snapshot.hasData) {
            return const Navbar(); // Langsung masuk ke Menu Utama
          }

          // 3. Jika tidak ada data (Berarti Logout/Belum Login)
          return const LoginPage();
        },
      ),
    );
  }
}