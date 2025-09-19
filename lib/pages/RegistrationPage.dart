import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'HomePage.dart'; // import your home page

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
  final TextEditingController phoneController = TextEditingController();
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
    phoneController.dispose();
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
          'email': emailController.text.trim(),
          // only fields you kept for testing
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

      // final UI update and navigation must run on the main/UI frame
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Check your email.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
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
      appBar: AppBar(title: const Text("Register")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Only keep the fields you need for testing
                TextField(controller: firstNameController, decoration: const InputDecoration(labelText: "First Name")),

                TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),

                TextField(controller: passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),

                // Commented out for now
                // TextField(controller: lastNameController, decoration: const InputDecoration(labelText: "Last Name")),
                // TextField(controller: dobController, decoration: const InputDecoration(labelText: "Date of Birth")),
                // TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address")),
                // TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone Number")),
                // TextField(controller: repeatPasswordController, decoration: const InputDecoration(labelText: "Repeat Password"), obscureText: true),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : registerUser,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Register"),
                ),
              ],
            )
            ,
          ),
        ),
      ),
    );
  }
}