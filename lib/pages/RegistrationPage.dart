import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'LoginPage.dart';
import '../services/LocalizationProvider.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    addressController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    passwordController.dispose();
    repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    // dismiss keyboard and set loading on main thread
    FocusScope.of(context).unfocus();
    if (!mounted) return;
    setState(() => isLoading = true);
    debugPrint('registerUser: starting');

    try {
      debugPrint('registerUser: creating auth user...');
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final String uid = userCredential.user?.uid ?? '<no-uid>';
      debugPrint('registerUser: created user uid=$uid');

      // Fire and forget email verification (do not block navigation on failures)
      userCredential.user
          ?.sendEmailVerification()
          .then((_) => debugPrint('Verification email sent'))
          .catchError((e, st) {
        debugPrint('sendEmailVerification failed: $e');
      });

      // Try to write to Firestore but don't let a failure block the whole flow.
      try {
        debugPrint('registerUser: writing to Firestore for uid=$uid');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'dateOfBirth': dobController.text.trim(),
          'address': addressController.text.trim(),
          'phoneNumber': phoneNumberController.text.trim(),
          'email': emailController.text.trim(),
        })
            .timeout(const Duration(seconds: 120));
        debugPrint('registerUser: Firestore write succeeded for uid=$uid');
      } on TimeoutException {
        debugPrint('registerUser: Firestore write timed out');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firestore write timed out (check DB).')),
        );
      } catch (e, st) {
        debugPrint('registerUser: Firestore write failed: $e\n$st');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firestore write error: $e')),
        );
        // continue — don't block navigation
      }

      // ✅ ADDED: Sign out the user so they have to login manually
      await FirebaseAuth.instance.signOut();
      debugPrint('registerUser: signed out user after registration');

      // final UI update and navigation must run on the main/UI frame
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      });
    } on FirebaseAuthException catch (e, st) {
      debugPrint('registerUser: FirebaseAuthException ${e.code} ${e.message}\n$st');
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.message}')),
        );
      });
    } catch (e, st) {
      debugPrint('registerUser: unexpected error: $e\n$st');
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $e')),
        );
      });
    } finally {
      // ensure setState runs on the main frame (important with plugin thread warnings)
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => isLoading = false);
        debugPrint('registerUser: finished, isLoading=false');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('register')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);  // ✅ Just pop back to LoginPage
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextField(controller: firstNameController, decoration: InputDecoration(labelText: context.tr('first_name'))),
                TextField(controller: lastNameController, decoration: InputDecoration(labelText: context.tr('last_name'))),
                TextField(controller: emailController, decoration: InputDecoration(labelText: context.tr('email'))),
                TextField(controller: passwordController, decoration: InputDecoration(labelText: context.tr('password')), obscureText: true),
                TextField(
                  controller: dobController,
                  readOnly: true, // prevents keyboard from opening
                  decoration: InputDecoration(
                    labelText: context.tr('date_of_birth'),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );

                    if (pickedDate != null) {
                      // format the date as yyyy-MM-dd
                      String formattedDate =
                          "${pickedDate.day.toString().padLeft(2, '0')}/"
                          "${pickedDate.month.toString().padLeft(2, '0')}/"
                          "${pickedDate.year}";

                      setState(() {
                        dobController.text = formattedDate;
                      });
                    }
                  },
                ),
                TextField(controller: addressController, decoration: InputDecoration(labelText: context.tr('address'))),
                TextField(controller: phoneNumberController, decoration: InputDecoration(labelText: context.tr('phone'))),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : registerUser,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(context.tr('register')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}