import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final authProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authProvider).authStateChanges();
});

class AuthController {
  final FirebaseAuth _auth;

  AuthController(this._auth);

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _saveUserToFirestore(credential.user);
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password, {String? name, File? profileImage}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      String? photoUrl;
      if (profileImage != null && credential.user != null) {
        final bytes = await profileImage.readAsBytes();
        final base64String = base64Encode(bytes);
        photoUrl = 'base64:$base64String';
        
        // Update auth profile
        await credential.user!.updatePhotoURL(photoUrl);
      }
      
      await _saveUserToFirestore(credential.user, providedName: name, photoUrl: photoUrl);
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? '915275399638-4sogssisj7u6tv46g3gp6lcg9eb7ran3.apps.googleusercontent.com' : null,
      );
      
      // Force web prompt by using disconnect or ensuring clean state could be done if needed, 
      // but standard signIn() is fine for now.
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _saveUserToFirestore(userCredential.user);
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveUserToFirestore(User? user, {String? providedName, String? photoUrl}) async {
    if (user == null) return;
    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      
      String displayName = providedName ?? user.displayName ?? '';
      if (displayName.isEmpty && user.email != null) {
        displayName = user.email!.split('@')[0];
      }
      
      Map<String, dynamic> updateData = {
        'email': user.email ?? '',
      };
      
      final data = userDoc.data() ?? {};
      if (!userDoc.exists || (data['displayName'] ?? '').toString().trim().isEmpty) {
        updateData['displayName'] = displayName;
      }
      if (!userDoc.exists || (data['photoUrl'] ?? '').toString().trim().isEmpty) {
        if (photoUrl != null || user.photoURL != null) {
          updateData['photoUrl'] = photoUrl ?? user.photoURL;
        }
      }
      if (!userDoc.exists) {
        updateData['createdAt'] = FieldValue.serverTimestamp();
      }
      
      if (updateData.isNotEmpty) {
        await firestore.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving user to firestore: $e');
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(authProvider));
});
