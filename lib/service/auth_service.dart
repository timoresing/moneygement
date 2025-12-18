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

      // Jika sukses sampai sini, kembalikan data User (nama, email, uid) ke pemanggil fungsi.
      User? user = userCredential.user;

      if (user != null) {
        await _checkAndCreateUserInFirestore(user);
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
      if (user != null) {
        await _checkAndCreateUserInFirestore(user);
      }
      return user;
    } catch (e) {
      print("Error Login Email: $e");
      return null;
    }
  }

  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String name
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
        await _firestore.collection('users').doc(user!.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': finalName,
          'photoURL': null,
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

  Future<void> _checkAndCreateUserInFirestore(User user) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? "User",
        'photoURL': user.photoURL,
        'income': 0,
        'expense': 0,
        'balance': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("User database created in Firestore!");
    } else {
      print("User exists in Firestore, data is safe.");
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    User? user = _auth.currentUser;

    // 1. Safety Check: Ensure user is logged in
    if (user == null) return "No user logged in";

    // 2. Safety Check: Block Google Users
    bool isGoogleUser = user.providerData
        .any((userInfo) => userInfo.providerId == 'google.com');

    if (isGoogleUser) {
      return "Google accounts cannot change passwords here.";
    }

    print("Attempting Re-Auth for email: ${user.email}");
    print("Password length sent: ${currentPassword.length}");

    try {
      String email = user.email!;

      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return "Current password is incorrect.";
      } else if (e.code == 'weak-password') {
        return "Password must be at least 6 characters.";
      }
      return "Error: ${e.message}";
    } catch (e) {
      return "An unknown error occurred.";
    }
  }

  // Fungsi untuk Logout (Keluar Akun)
  Future<void> signOut() async {

    // Mengecek apakah log in menggunakan akun Google atau bukan
    try {
      final user = _auth.currentUser;
      if (user?.providerData.first.providerId == 'google.com') {
        // Memutuskan koneksi dengan Google agar saat login lagi, bisa memilih akun berbeda.
        await _googleSignIn.signOut();
      }
    } catch (e) {
      print("Error Google Sign Out: $e");
    } finally {
      // Menghapus sesi login dari Firebase Auth di aplikasi.
      await _auth.signOut();
    }
  }
}