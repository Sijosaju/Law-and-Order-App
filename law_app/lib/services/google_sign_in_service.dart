import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleSignInService {
  // Initialize GoogleSignIn with proper configuration
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'profile',
    ],
  );

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Clear any existing sign-in state
      await _googleSignIn.signOut();
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // If user cancels the sign-in
      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Check if we have the required tokens
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        print('Failed to obtain Google authentication tokens');
        return null;
      }

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      print('Google Sign-In successful for user: ${userCredential.user?.email}');
      return userCredential;

    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return null;
    } on Exception catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  // Optional: Sign out method
  static Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        FirebaseAuth.instance.signOut(),
      ]);
      print('User signed out successfully');
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Optional: Check if user is currently signed in
  static Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      print('Error checking sign-in status: $e');
      return false;
    }
  }
}
