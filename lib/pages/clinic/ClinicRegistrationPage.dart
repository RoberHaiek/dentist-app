import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dentist_app/services/LocalizationProvider.dart';
import '../LoginPage.dart';

class ClinicRegistrationPage extends StatefulWidget {
  final String? agentName;

  const ClinicRegistrationPage({
    super.key,
    this.agentName,
  });

  @override
  State<ClinicRegistrationPage> createState() => _ClinicRegistrationPageState();
}

class _ClinicRegistrationPageState extends State<ClinicRegistrationPage> with SingleTickerProviderStateMixin {
  int _currentStep = 0;

  final _formKey = GlobalKey<FormState>();
  final _clinicNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
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
    _clinicNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _generateRegistrationCode() {
    // Generate 6-digit alphanumeric code (no confusing characters)
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return String.fromCharCodes(
        Iterable.generate(
            6,
                (_) => chars.codeUnitAt(random.nextInt(chars.length))
        )
    );
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user?.uid;

      if (uid != null) {
        // Generate unique registration code
        final registrationCode = _generateRegistrationCode();

        await FirebaseFirestore.instance.collection('clinics').doc(uid).set({
          'clinicName': _clinicNameController.text.trim(),
          'address': _addressController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'accountType': 'clinic',
          'registrationCode': registrationCode,
          'patients': [],  // Initialize empty patients array
          'setupComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await userCredential.user?.sendEmailVerification();
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('registration_successful')),
              backgroundColor: const Color(0xFF7DD3C0),
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = context.tr('registration_failed');
      if (e.code == 'email-already-in-use') {
        message = context.tr('email_already_in_use');
      } else if (e.code == 'weak-password') {
        message = context.tr('password_too_weak');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      body: SafeArea(
        child: _currentStep == 0 ? _buildWelcomeScreen() : _buildRegistrationForm(),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Container(
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
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.tr('welcome_to_dentech'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  context.tr('clinic_registration_subtitle'),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        Icons.calendar_today,
                        context.tr('manage_appointments'),
                        context.tr('easy_scheduling'),
                      ),
                      const Divider(height: 24),
                      _buildFeatureItem(
                        Icons.people,
                        context.tr('patient_management'),
                        context.tr('all_in_one_place'),
                      ),
                      const Divider(height: 24),
                      _buildFeatureItem(
                        Icons.analytics,
                        context.tr('track_performance'),
                        context.tr('insights_analytics'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
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
                    onPressed: () {
                      setState(() => _currentStep = 1);
                      _animationController.reset();
                      _animationController.forward();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.tr('get_started'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: Text(
                    context.tr('already_have_account'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF7DD3C0).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF7DD3C0), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Stack(
      children: [
        Positioned(
          top: 12,
          left: 12,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
            onPressed: () => setState(() => _currentStep = 0),
          ),
        ),

        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 50),

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
                      controller: _clinicNameController,
                      label: context.tr('clinic_name'),
                      hint: context.tr('clinic_name_hint'),
                      icon: Icons.business,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_clinic_name');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _addressController,
                      label: context.tr('address'),
                      hint: context.tr('address_hint'),
                      icon: Icons.location_on,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_address');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _phoneController,
                      label: context.tr('phone'),
                      hint: context.tr('phone_hint'),
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_phone');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _emailController,
                      label: context.tr('email'),
                      hint: context.tr('email_hint'),
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_email');
                        }
                        if (!value.contains('@')) {
                          return context.tr('please_enter_valid_email');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _passwordController,
                      label: context.tr('password'),
                      hint: context.tr('password_hint'),
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
                        if (value == null || value.isEmpty) {
                          return context.tr('please_enter_password');
                        }
                        if (value.length < 8) {
                          return context.tr('password_must_be_8_chars');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

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
                        onPressed: _isLoading ? null : _completeRegistration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          context.tr('create_account'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
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
        validator: validator,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF333333),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
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