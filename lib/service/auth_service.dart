import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // 1. Membuat objek _auth untuk mengakses layanan autentikasi Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // 2. Membuat objek _googleSignIn untuk berinteraksi ke server Google
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Fungsi login yang bersifat 'Future' karena prosesnya butuh waktu (asynchronous).
  // Mengembalikan objek User jika berhasil, atau null jika gagal.
  Future<User?> signInWithGoogle() async {
    try {
      // 3. Menginisialisasi sistem login Google sebelum digunakan
      await _googleSignIn.initialize();

      // 4. Membuka jendela (pop-up) login Google dan menunggu siswa memilih akun.
      // Jika user menutup jendela/batal, baris ini akan melempar error (masuk ke catch).
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // 5. Mengambil token keamanan (ID Token & Access Token) dari akun Google yang dipilih tadi.
      // Token ini ibarat KTP yang membuktikan akun tersebut asli.
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 6. Membuat "Surat Jalan" (Credential) untuk diserahkan ke Firebase.
      // Kita menukar token dari Google menjadi format yang dimengerti oleh Firebase.
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 7. Proses Login Final: Menyerahkan credential ke Firebase.
      // Firebase akan memverifikasi, lalu membuat sesi login di aplikasi kita.
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Jika sukses sampai sini, kembalikan data User (nama, email, foto, uid) ke pemanggil fungsi.
      User? user = userCredential.user;

      if (user != null) {
        // === TAMBAHAN LOGIKA FIRESTORE DI SINI ===

        // 1. Cek apakah user ini sudah ada di database?
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        // 2. Jika data TIDAK ADA (!exists), berarti dia user baru login pertama kali
        if (!userDoc.exists) {
          // 3. Buat data awal (Income 0, Expense 0)
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'income': 0,    // <-- Set Income 0
            'expense': 0,   // <-- Set Cost/Expense 0
            'balance': 0,   // <-- Total Balance (Income - Expense)
            'createdAt': FieldValue.serverTimestamp(), // Catat waktu pembuatan
          });
          print("User baru dibuatkan database di Firestore!");
        } else {
          print("User lama login, data aman.");
        }
        // =========================================
      }
      return user;
    } catch (e) {
      print("Error Login: $e");
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      // Login ke Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      User? user = result.user;

      // Kita tidak perlu cek/buat Firestore di sini karena asumsinya
      // data sudah dibuat saat Register.

      return user;
    } catch (e) {
      print("Error Login Email: $e");
      return null;
    }
  }

  // ==========================================================
  // 2. REGISTER MANUAL (EMAIL & PASSWORD)
  // ==========================================================
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String name // Username dari input
  }) async {
    try {
      // A. Buat Akun di Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      User? user = result.user;

      if (user != null) {
        // B. Update Display Name di Auth (Penting!)
        // Jika nama kosong, kita set default jadi "User"
        String finalName = name.isEmpty ? "User" : name;
        await user.updateDisplayName(finalName);
        await user.reload();
        user = _auth.currentUser;

        // C. Buat Data di Firestore (SAMAKAN STRUKTURNYA DENGAN GOOGLE)
        // Perhatikan: Kita TIDAK menyimpan password di sini.
        await _firestore.collection('users').doc(user!.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': finalName, // Nama dari input register
          'photoURL': null, // User manual biasanya gak punya foto awal
          'income': 0,
          'expense': 0,
          'balance': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print("Error Register: $e");
      return null;
    }
  }

  // Fungsi untuk Logout (Keluar Akun)
  Future<void> signOut() async {
    // Memutuskan koneksi dengan Google agar saat login lagi, bisa memilih akun berbeda.
    await _googleSignIn.disconnect();

    // Menghapus sesi login dari Firebase Auth di aplikasi.
    await _auth.signOut();
  }
}