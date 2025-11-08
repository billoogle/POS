import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign Up with Email & Password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String businessName,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'fullName': fullName,
        'businessName': businessName,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'owner',
      });

      return {'success': true, 'user': userCredential.user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // Sign In with Email & Password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return {'success': true, 'user': userCredential.user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // Forgot Password
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Password reset email sent'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // === NEW: Update User Profile Data (Name, Business Name) ===
  Future<Map<String, dynamic>> updateUserData({
    required String fullName,
    required String businessName,
  }) async {
    if (currentUser == null) {
      return {'success': false, 'message': 'User not authenticated'};
    }
    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'fullName': fullName,
        'businessName': businessName,
      });
      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error updating profile'};
    }
  }

  // === NEW: Re-authenticate user (required for sensitive operations) ===
  Future<AuthCredential?> _reauthenticateUser(String password) async {
    if (currentUser == null) return null;
    try {
      return EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );
    } catch (e) {
      return null;
    }
  }

  // === NEW: Update User Email ===
  Future<Map<String, dynamic>> updateUserEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    if (currentUser == null) {
      return {'success': false, 'message': 'User not authenticated'};
    }
    try {
      final credential = await _reauthenticateUser(currentPassword);
      if (credential == null) {
        return {'success': false, 'message': 'Re-authentication failed'};
      }

      await currentUser!.reauthenticateWithCredential(credential);
      
      // Use verifyBeforeUpdateEmail for better security
      await currentUser!.verifyBeforeUpdateEmail(newEmail);

      // Update email in Firestore as well
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'email': newEmail,
      });

      return {
        'success': true,
        'message': 'Verification email sent to $newEmail. Please verify to update.'
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // === NEW: Update User Password ===
  Future<Map<String, dynamic>> updateUserPassword({
    required String newPassword,
    required String currentPassword,
  }) async {
    if (currentUser == null) {
      return {'success': false, 'message': 'User not authenticated'};
    }
    try {
      final credential = await _reauthenticateUser(currentPassword);
      if (credential == null) {
        return {'success': false, 'message': 'Re-authentication failed'};
      }

      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.updatePassword(newPassword);

      return {'success': true, 'message': 'Password updated successfully'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // Error message handler
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'requires-recent-login':
        return 'This operation is sensitive and requires recent authentication. Please log in again.';
      default:
        return 'An error occurred. Please try again';
    }
  }
}