import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // 1. Membuat objek _auth untuk mengakses layanan autentikasi Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      return userCredential.user;

    } on FirebaseAuthException catch (e) {
      // Menangkap error spesifik dari Firebase (Contoh: Koneksi internet putus, atau konfigurasi SHA-1 salah).
      print("Firebase Auth Error: ${e.message}");
      return null; // Kembalikan null karena login gagal.
    } catch (e) {
      // Menangkap error umum, termasuk jika menekan tombol 'Back' atau batal memilih akun.
      print("Google Sign-In Error / Cancelled: $e");
      return null; // Kembalikan null karena login gagal.
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