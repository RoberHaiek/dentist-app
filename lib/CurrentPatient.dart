import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CurrentPatient {
  static final CurrentPatient _instance = CurrentPatient._internal();
  factory CurrentPatient() => _instance;
  CurrentPatient._internal();

  String firstName = "";
  String lastName = "";
  String email = "";

  bool _loaded = false;

  String get fullName => "$firstName $lastName";

  Future<void> loadFromFirestore() async {
    if (_loaded) return;

    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        firstName = userDoc.data()?['firstName'] ?? "";
        lastName = userDoc.data()?['lastName'] ?? "";
        email = userDoc.data()?['email'] ?? "";
        _loaded = true;
      }
    } catch (e) {
      print("Error loading patient: $e");
    }
  }
}
