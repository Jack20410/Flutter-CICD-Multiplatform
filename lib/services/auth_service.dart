// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = true;

  AuthService() {
    // Listen to authentication state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Getters
  User? get currentUser => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get userEmail => _user?.email;
  String? get userName => _user?.displayName;
  String? get userId => _user?.uid;
  String get userInitials {
    if (_user?.displayName != null && _user!.displayName!.isNotEmpty) {
      final names = _user!.displayName!.split(' ');
      return names.length > 1
          ? '${names[0][0]}${names[1][0]}'.toUpperCase()
          : names[0][0].toUpperCase();
    } else if (_user?.email != null) {
      return _user!.email![0].toUpperCase();
    }
    return 'U';
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // In your AuthService class
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user currently signed in');
      }

      // Clean up Firestore data first
      final firestore = FirebaseFirestore.instance;
      final userDoc = firestore.collection('users').doc(user.uid);

      // Delete all user notes
      final notesQuery = await userDoc.collection('notes').get();
      for (var doc in notesQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user document
      await userDoc.delete();

      // Now try to delete the auth account
      await user.delete();
    } catch (e) {
      debugPrint('Delete account error: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName}) async {
    try {
      await _user?.updateDisplayName(displayName);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _user?.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  // Check if email is verified
  bool get isEmailVerified => _user?.emailVerified ?? false;

  // Reload user data
  Future<void> reloadUser() async {
    try {
      await _user?.reload();
      _user = _auth.currentUser;
      notifyListeners();
      // ignore: empty_catches
    } catch (e) {}
  }
}
