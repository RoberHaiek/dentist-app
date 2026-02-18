import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'LoginPage.dart';
import 'clinic/ClinicRegistrationPage.dart';
import '../services/LocalizationProvider.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool _passwordVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    addressController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

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

      userCredential.user
          ?.sendEmailVerification()
          .then((_) => debugPrint('Verification email sent'))
          .catchError((e, st) {
        debugPrint('sendEmailVerification failed: $e');
      });

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
          'accountType': 'patient',
          'createdAt': FieldValue.serverTimestamp(),
        })
            .timeout(const Duration(seconds: 120));
        debugPrint('registerUser: Firestore write succeeded for uid=$uid');
      } on TimeoutException {
        debugPrint('registerUser: Firestore write timed out');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('timeout_error')), backgroundColor: Colors.red),
        );
      } catch (e, st) {
        debugPrint('registerUser: Firestore write failed: $e\n$st');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e'), backgroundColor: Colors.red),
        );
      }

      await FirebaseAuth.instance.signOut();
      debugPrint('registerUser: signed out user after registration');

      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('registration_successful')),
            backgroundColor: const Color(0xFF7DD3C0),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      });
    } on FirebaseAuthException catch (e, st) {
      debugPrint('registerUser: FirebaseAuthException ${e.code} ${e.message}\n$st');
      if (!mounted) return;

      String message = context.tr('registration_failed');
      if (e.code == 'email-already-in-use') {
        message = context.tr('email_already_in_use');
      } else if (e.code == 'weak-password') {
        message = context.tr('password_too_weak');
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      });
    } catch (e, st) {
      debugPrint('registerUser: unexpected error: $e\n$st');
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e'), backgroundColor: Colors.red),
        );
      });
    } finally {
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
      backgroundColor: const Color(0xFFF2EBE2),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF7DD3C0).withOpacity(0.1),
              const Color(0xFFF2EBE2),
              const Color(0xFF7DD3C0).withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              context.tr('create_your_account'),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 6),

                            Text(
                              context.tr('fill_details_below'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 28),

                            _buildTextField(
                              controller: firstNameController,
                              label: context.tr('first_name'),
                              icon: Icons.person,
                              validator: (value) => value?.trim().isEmpty ?? true
                                  ? context.tr('please_enter_first_name')
                                  : null,
                            ),

                            const SizedBox(height: 14),

                            _buildTextField(
                              controller: lastNameController,
                              label: context.tr('last_name'),
                              icon: Icons.person_outline,
                              validator: (value) => value?.trim().isEmpty ?? true
                                  ? context.tr('please_enter_last_name')
                                  : null,
                            ),

                            const SizedBox(height: 14),

                            _buildTextField(
                              controller: emailController,
                              label: context.tr('email'),
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value?.trim().isEmpty ?? true) {
                                  return context.tr('please_enter_email');
                                }
                                if (!value!.contains('@')) {
                                  return context.tr('please_enter_valid_email');
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            _buildTextField(
                              controller: passwordController,
                              label: context.tr('password'),
                              icon: Icons.lock,
                              obscureText: !_passwordVisible,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _passwordVisible ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF999999),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _passwordVisible = !_passwordVisible);
                                },
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return context.tr('please_enter_password');
                                }
                                if (value!.length < 8) {
                                  return context.tr('password_must_be_8_chars');
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            _buildTextField(
                              controller: dobController,
                              label: context.tr('date_of_birth'),
                              icon: Icons.calendar_today,
                              readOnly: true,
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(2000),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );

                                if (pickedDate != null) {
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

                            const SizedBox(height: 14),

                            _buildTextField(
                              controller: addressController,
                              label: context.tr('address'),
                              icon: Icons.location_on,
                            ),

                            const SizedBox(height: 14),

                            _buildTextField(
                              controller: phoneNumberController,
                              label: context.tr('phone'),
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),

                            const SizedBox(height: 28),

                            Container(
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(27),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7DD3C0), Color(0xFF5AB9A8)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7DD3C0).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : registerUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : Text(
                                  context.tr('register'),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ClinicRegistrationPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  context.tr('register_as_business'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF333333),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF7DD3C0), size: 20),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}