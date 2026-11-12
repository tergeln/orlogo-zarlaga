import 'package:firebase_auth/firebase_auth.dart';

import 'db.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static User? get user => _auth.currentUser;

  static String get displayName {
    final u = _auth.currentUser;
    final name = u?.displayName;
    if (name != null && name.trim().isNotEmpty) return name;
    return u?.email?.split('@').first ?? 'Хэрэглэгч';
  }

  static Future<void> register(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(name.trim());
    await Db.createUser(name.trim(), email.trim());
  }

  static Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  static Future<void> logout() => _auth.signOut();

  /// Firebase-ийн алдааг хэрэглэгчид ойлгомжтой болгож буцаана.
  static String errorText(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Энэ имэйл хаяг бүртгэлтэй байна.';
        case 'invalid-email':
          return 'Имэйл хаяг буруу байна.';
        case 'weak-password':
          return 'Нууц үг хэт сул байна (дор хаяж 6 тэмдэгт).';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Имэйл эсвэл нууц үг буруу байна.';
        case 'network-request-failed':
          return 'Интернэт холболтоо шалгана уу.';
        case 'too-many-requests':
          return 'Хэт олон оролдлого хийлээ. Түр хүлээнэ үү.';
      }
      return 'Алдаа гарлаа: ${e.message ?? e.code}';
    }
    return 'Алдаа гарлаа: $e';
  }
}
