import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>>? get _doc {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return _db.collection('users').doc(user.uid);
  }

  // Profile save karta hai. Success par null, warna error message.
  Future<String?> saveProfile(Map<String, dynamic> data) async {
    final doc = _doc;
    if (doc == null) return 'You are not signed in.';
    try {
      await doc.set(
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Permission denied. Check Firestore rules.';
      }
      return 'Could not save profile. Check your internet.';
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  // Saved profile wapas laata hai (nahi mila to null).
  Future<Map<String, dynamic>?> loadProfile() async {
    final doc = _doc;
    if (doc == null) return null;
    try {
      final snap = await doc.get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }
}