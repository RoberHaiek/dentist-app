import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'patient/PatientHomePage.dart';
import 'clinic/ClinicHomePage.dart';
import 'ForgotPage.dart';
import 'RegistrationPage.dart';
import '../services/LocalizationProvider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  static const bool isDebug = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocus = FocusNode();

  bool isButtonEnabled = false;
  bool emailValid = true;
  bool isLoading = false;
  bool rememberMe = false;
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

    emailController.addListener(_validateForm);
    passwordController.addListener(_validateForm);

    emailFocus.addListener(() {
      if (!emailFocus.hasFocus) {
        _validateEmail();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoLogin();
    });
  }

  Future<void> _checkAutoLogin() async {
    try {
      if (isDebug) {
        debugPrint('Debug mode enabled - skipping login');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PatientHomePage()),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final shouldRemember = prefs.getBool('rememberMe') ?? false;

        if (shouldRemember) {
          debugPrint('Remember me enabled - auto-logging in');
          await _navigateToCorrectHome(user.uid);
        } else {
          await FirebaseAuth.instance.signOut();
          debugPrint('User logged out - remember me was not enabled');
        }
      }
    } catch (e) {
      debugPrint('initState: Firebase check currentUser failed: $e');
    }
  }

  void _validateForm() {
    final emailText = emailController.text;
    final passwordText = passwordController.text;
    final isValidEmail = _isValidEmail(emailText);

    if (mounted) {
      setState(() {
        isButtonEnabled =
            emailText.isNotEmpty && passwordText.isNotEmpty && isValidEmail;
      });
    }
  }

  void _validateEmail() {
    if (mounted) {
      setState(() {
        emailValid = _isValidEmail(emailController.text);
      });
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex =
    RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _navigateToCorrectHome(String uid) async {
    try {
      // Check if user is a clinic
      final clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(uid)
          .get();

      if (clinicDoc.exists) {
        // User is a clinic
        debugPrint('User is a clinic, navigating to ClinicHomePage');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ClinicHomePage()),
          );
        }
        return;
      }

      // Check if user is a patient
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        // User is a patient
        debugPrint('User is a patient, navigating to HomePage');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PatientHomePage()),
          );
        }
        return;
      }

      // User exists in Auth but not in either collection (shouldn't happen)
      debugPrint('Warning: User authenticated but not found in clinics or users collection');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('account_setup_incomplete')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to home: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _login() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    FocusScope.of(context).unfocus();

    debugPrint('login: start for email=${emailController.text.trim()}');

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', rememberMe);
      debugPrint('Remember me preference saved: $rememberMe');

      if (!mounted) return;

      // Navigate to correct home based on account type
      await _navigateToCorrectHome(cred.user!.uid);

    } on FirebaseAuthException catch (e, st) {
      debugPrint('login: FirebaseAuthException ${e.code} ${e.message}\n$st');

      final message = (e.code == 'user-not-found')
          ? context.tr('user_not_found')
          : (e.code == 'wrong-password')
          ? context.tr('wrong_password')
          : (e.message ?? context.tr('login_failed'));

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        });
      }
    } catch (e, st) {
      debugPrint('login: unexpected error $e\n$st');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.tr('error')}: $e'), backgroundColor: Colors.red),
          );
        });
      }
    } finally {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => isLoading = false);
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    super.dispose();
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('app_name'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      context.tr('your_smile_matters'),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF666666),
                      ),
                    ),

                    const SizedBox(height: 40),

                    _buildTextField(
                      controller: emailController,
                      focusNode: emailFocus,
                      label: context.tr('email'),
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    if (!emailValid)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            context.tr('invalid_email'),
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
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
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: rememberMe,
                            onChanged: (value) {
                              setState(() {
                                rememberMe = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF7DD3C0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('remember_me'),
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotPage()),
                            );
                          },
                          child: Text(
                            context.tr('forgot_password'),
                            style: const TextStyle(
                              color: Color(0xFF7DD3C0),
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(27),
                        gradient: isButtonEnabled
                            ? const LinearGradient(
                          colors: [Color(0xFF7DD3C0), Color(0xFF5AB9A8)],
                        )
                            : null,
                        color: isButtonEnabled ? null : const Color(0xFFCCCCCC),
                        boxShadow: isButtonEnabled
                            ? [
                          BoxShadow(
                            color: const Color(0xFF7DD3C0).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                            : null,
                      ),
                      child: ElevatedButton(
                        onPressed: isButtonEnabled && !isLoading ? _login : null,
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
                          context.tr('login'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegistrationPage()),
                            );
                          },
                          child: Text(
                            context.tr('register'),
                            style: const TextStyle(
                              color: Color(0xFF7DD3C0),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
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
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
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
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}