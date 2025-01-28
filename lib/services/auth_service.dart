import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_pudget/services/firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Up
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      print('Starting sign up process...');
      // Create auth user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('User created with ID: ${userCredential.user?.uid}');

      // Create user document in Firestore
      await _db.collection('users').doc(userCredential.user!.uid).set({
        'fullName': fullName,
        'email': email,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        'budget': 0,
        'expenses': [],
        'income': [],
      });
      print('User document created in Firestore');

      // Initialize user document
      await _firebaseService.initializeUserDocument();
      print('User document initialized');

      return userCredential;
    } catch (e, stackTrace) {
      print('Error in signUp: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Sign In
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('Starting sign in process...');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('User signed in with ID: ${userCredential.user?.uid}');

      // Update last login
      try {
        await _db.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': Timestamp.now(),
        });
        print('Last login timestamp updated');
      } catch (e) {
        print('Error updating lastLogin: $e'); // Non-critical error
      }

      // Initialize user document
      await _firebaseService.initializeUserDocument();
      print('User document initialized after sign in');

      return userCredential;
    } catch (e, stackTrace) {
      print('Error in signIn: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    print('Signing out user...');
    await _auth.signOut();
    print('User signed out successfully');
  }

  // Check if user is signed in
  bool isUserSignedIn() {
    final user = _auth.currentUser;
    print('Checking if user is signed in: ${user != null}');
    return user != null;
  }
}
